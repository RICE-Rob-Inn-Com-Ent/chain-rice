"""Composable job pipelines — chained steps, lazy Polars fusion, telemetry, optional Mojo-style anchors."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import inspect
import json
import time
from collections.abc import Callable, Sequence
from concurrent.futures import Future
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal

import numpy as np
import polars as pl
from loguru import logger

from .array import RiceArray
from .frame import RiceFrame
from .memory import MemoryAnchor

try:  # pragma: no cover
    import yaml
except ImportError:  # pragma: no cover
    yaml = None  # type: ignore[assignment]

try:  # pragma: no cover
    import psutil

    _PS = psutil.Process()
except ImportError:  # pragma: no cover
    _PS = None

# --- Step registry (for serialize / reload) -----------------------------------------

STEP_REGISTRY: dict[str, Callable[..., Any]] = {}


def register_step(step_id: str) -> Callable[[Callable[..., Any]], Callable[..., Any]]:
    """Decorator: ``@register_step("ingest.read_parquet")`` so :func:`serialize_pipeline` can round-trip."""

    def deco(fn: Callable[..., Any]) -> Callable[..., Any]:
        STEP_REGISTRY[step_id.strip()] = fn
        setattr(fn, "__pipeline_step_id__", step_id.strip())
        return fn

    return deco


def resolve_step(step_id: str) -> Callable[..., Any]:
    if step_id not in STEP_REGISTRY:
        msg = f"unknown pipeline step_id {step_id!r}; register with @register_step"
        raise KeyError(msg)
    return STEP_REGISTRY[step_id]


# --- Context ------------------------------------------------------------------------


@dataclass
class JobContext:
    """Mutable state carried through :class:`JobPipeline` execution."""

    data: Any = None
    meta: dict[str, Any] = field(default_factory=dict)
    started_at: float = field(default_factory=time.perf_counter)
    step_spans: list[tuple[str, str, float]] = field(default_factory=list)  # (name, module_tag, seconds)
    pinned: list[Any] = field(default_factory=list)
    peak_rss_bytes: int | None = None

    def touch_peak_rss(self) -> None:
        if _PS is not None:
            self.peak_rss_bytes = int(_PS.memory_info().rss)

    def record_step(self, name: str, module_tag: str, dt_s: float) -> None:
        self.step_spans.append((name, module_tag, dt_s))

    def pin(self, obj: Any) -> None:
        """Pin ``obj`` for the pipeline lifetime (:class:`memory.MemoryAnchor`)."""
        MemoryAnchor.anchor(obj)
        self.pinned.append(obj)

    def release_all(self) -> None:
        for o in reversed(self.pinned):
            MemoryAnchor.release(o)
        self.pinned.clear()


@dataclass(slots=True)
class _Step:
    name: str
    fn: Callable[..., Any]
    kwargs: dict[str, Any]
    module_tag: str
    parallel_group: int | None
    merge_polars: bool
    step_id: str | None


# --- Pipeline -----------------------------------------------------------------------


class JobPipeline:
    """Ordered steps ``fn(ctx, **kwargs)`` — optional Polars lazy fusion and parallel groups."""

    __slots__ = (
        "_built",
        "_failure_cb",
        "_optimized_steps",
        "_steps",
    )

    def __init__(self, *, on_failure: Callable[[JobContext, str, BaseException], None] | None = None) -> None:
        self._steps: list[_Step] = []
        self._failure_cb = on_failure
        self._built = False
        self._optimized_steps: list[_Step] | None = None

    def add_step(
        self,
        func: Callable[..., Any],
        *,
        name: str | None = None,
        step_id: str | None = None,
        module_tag: str = "user",
        parallel_group: int | None = None,
        merge_polars: bool = False,
        **kwargs: Any,
    ) -> JobPipeline:
        """Append ``func`` — invoked as ``func(ctx, **kwargs)`` (may mutate ``ctx.data`` or return a value)."""
        nm = name or getattr(func, "__name__", "step")
        sid = step_id or getattr(func, "__pipeline_step_id__", None)
        self._steps.append(
            _Step(name=nm, fn=func, kwargs=dict(kwargs), module_tag=module_tag, parallel_group=parallel_group, merge_polars=merge_polars, step_id=sid),
        )
        self._built = False
        self._optimized_steps = None
        return self

    def add_step_by_id(self, step_id: str, **kwargs: Any) -> JobPipeline:
        """Append a registered step by id (for deserialized pipelines)."""
        return self.add_step(resolve_step(step_id), name=step_id, step_id=step_id, **kwargs)

    def build(self) -> JobPipeline:
        """Fuse consecutive Polars-lazy ``merge_polars`` steps into one plan where possible."""
        if not self._steps:
            self._optimized_steps = []
            self._built = True
            return self
        out: list[_Step] = []
        i = 0
        while i < len(self._steps):
            s = self._steps[i]
            if s.merge_polars and i + 1 < len(self._steps) and self._steps[i + 1].merge_polars:
                a, b = s, self._steps[i + 1]

                def _fused(ctx: JobContext, *, _a: _Step = a, _b: _Step = b) -> None:
                    """Fused Polars lazy steps; each part ``fn`` must accept ``(ctx, lf, **kwargs) -> LazyFrame``."""
                    lf = _ensure_lazy(ctx.data)
                    for p in (_a, _b):
                        out_lf = p.fn(ctx, lf, **p.kwargs)
                        lf = out_lf.lazy() if isinstance(out_lf, pl.DataFrame) else out_lf
                        if not isinstance(lf, pl.LazyFrame):
                            msg = "merge_polars step must return DataFrame or LazyFrame"
                            raise TypeError(msg)
                    if isinstance(ctx.data, RiceFrame):
                        ctx.data = RiceFrame(lf, ctx.data.partition_spec)
                    else:
                        ctx.data = lf

                fused = _Step(
                    name=f"{a.name}+{b.name}",
                    fn=_fused,
                    kwargs={},
                    module_tag=a.module_tag,
                    parallel_group=a.parallel_group,
                    merge_polars=False,
                    step_id=None,
                )
                out.append(fused)
                i += 2
                continue
            out.append(s)
            i += 1
        self._optimized_steps = out
        self._built = True
        logger.debug("JobPipeline.build steps={} optimized={}", len(self._steps), len(out))
        return self

    def dry_run(self, sample: Any | None = None) -> JobContext:
        """Validate callables and optionally run steps that accept ``dry_run=True`` without heavy IO."""
        steps = self._optimized_steps if self._built and self._optimized_steps is not None else self._steps
        ctx = JobContext(data=sample, meta={"dry_run": True})
        for st in steps:
            sig = inspect.signature(st.fn)
            params = list(sig.parameters.keys())
            if not params or params[0] != "ctx":
                logger.info("pipeline dry_run skip step={} (first arg must be ``ctx``)", st.name)
                continue
            kw = dict(st.kwargs)
            if "dry_run" in sig.parameters:
                kw["dry_run"] = True
            try:
                st.fn(ctx, **kw)
            except TypeError:
                logger.info("pipeline dry_run skip step={} (TypeError)", st.name)
        ctx.touch_peak_rss()
        return ctx

    def run(self, initial_data: Any | None = None) -> Any:
        """Execute the pipeline; returns final ``ctx.data`` (often :class:`frame.RiceFrame` / :class:`array.RiceArray`)."""
        if not self._built:
            self.build()
        assert self._optimized_steps is not None
        steps = self._optimized_steps
        ctx = JobContext(data=initial_data, meta={"dry_run": False})
        ctx.touch_peak_rss()
        if initial_data is not None and _is_pinnable(initial_data):
            ctx.pin(initial_data)
        t_pipeline = time.perf_counter()
        last_step = "?"
        try:
            i = 0
            while i < len(steps):
                batch, n = _take_parallel_batch(steps, i)
                last_step = batch[0].name
                if n == 1:
                    _run_one_step(self, ctx, batch[0])
                else:
                    _run_parallel_batch(self, ctx, batch)
                i += n
        except BaseException:
            logger.exception("JobPipeline.run failed last_step={}", last_step)
            raise
        finally:
            ctx.touch_peak_rss()
            _emit_job_report(ctx, time.perf_counter() - t_pipeline)
            ctx.release_all()
        return ctx.data

    def to_dict(self) -> dict[str, Any]:
        """Serializable plan (requires ``step_id`` on each registered step)."""
        out: list[dict[str, Any]] = []
        for st in self._steps:
            if st.step_id is None:
                msg = f"step {st.name!r} has no step_id — cannot serialize"
                raise ValueError(msg)
            out.append({"step_id": st.step_id, "kwargs": st.kwargs, "name": st.name, "module_tag": st.module_tag, "parallel_group": st.parallel_group, "merge_polars": st.merge_polars})
        return {"version": 1, "steps": out}

    @classmethod
    def from_dict(cls, doc: dict[str, Any], *, on_failure: Callable[[JobContext, str, BaseException], None] | None = None) -> JobPipeline:
        if int(doc.get("version", 1)) != 1:
            msg = "unsupported pipeline document version"
            raise ValueError(msg)
        p = cls(on_failure=on_failure)
        for s in doc["steps"]:
            sid = s["step_id"]
            fn = resolve_step(sid)
            p._steps.append(
                _Step(
                    name=str(s.get("name", sid)),
                    fn=fn,
                    kwargs=dict(s.get("kwargs", {})),
                    module_tag=str(s.get("module_tag", "user")),
                    parallel_group=s.get("parallel_group"),
                    merge_polars=bool(s.get("merge_polars", False)),
                    step_id=sid,
                ),
            )
        p._built = False
        p._optimized_steps = None
        return p


def serialize_pipeline(pipeline: JobPipeline, *, format: Literal["json", "yaml"] = "json") -> str:
    """Dump :meth:`JobPipeline.to_dict` to JSON or YAML (YAML requires PyYAML)."""
    doc = pipeline.to_dict()
    if format == "yaml":
        if yaml is None:
            msg = "PyYAML not installed — use format='json' or pip install pyyaml"
            raise RuntimeError(msg)
        return yaml.safe_dump(doc, sort_keys=False)
    return json.dumps(doc, indent=2)


def deserialize_pipeline(raw: str | Path, *, format: Literal["json", "yaml"] | None = None) -> JobPipeline:
    """Load a pipeline from disk or string."""
    text = Path(raw).read_text(encoding="utf-8") if isinstance(raw, Path) else raw
    fmt = format or ("yaml" if text.lstrip().startswith("---") or "\nstep_id:" in text else "json")
    if fmt == "yaml":
        if yaml is None:
            msg = "PyYAML not installed"
            raise RuntimeError(msg)
        doc = yaml.safe_load(text)
    else:
        doc = json.loads(text)
    return JobPipeline.from_dict(doc)


# --- Internals ----------------------------------------------------------------------


def _is_pinnable(obj: Any) -> bool:
    return isinstance(obj, (np.ndarray, RiceArray, RiceFrame, pl.Series, pl.DataFrame))


def _ensure_lazy(data: Any) -> pl.LazyFrame:
    if isinstance(data, RiceFrame):
        inner = data.inner
        return inner.lazy() if isinstance(inner, pl.DataFrame) else inner
    if isinstance(data, pl.DataFrame):
        return data.lazy()
    if isinstance(data, pl.LazyFrame):
        return data
    msg = "merge_polars requires RiceFrame / DataFrame / LazyFrame in ctx.data"
    raise TypeError(msg)


def _take_parallel_batch(steps: Sequence[_Step], start: int) -> tuple[list[_Step], int]:
    s0 = steps[start]
    g = s0.parallel_group
    if g is None:
        return [s0], 1
    batch = [s0]
    j = start + 1
    while j < len(steps) and steps[j].parallel_group == g:
        batch.append(steps[j])
        j += 1
    return batch, len(batch)


def _run_one_step(pipeline: JobPipeline, ctx: JobContext, st: _Step) -> None:
    t0 = time.perf_counter()
    try:
        out = st.fn(ctx, **st.kwargs)
        if out is not None:
            ctx.data = out
        if ctx.data is not None and _is_pinnable(ctx.data):
            ctx.pin(ctx.data)
    except BaseException as exc:
        logger.exception("pipeline step failed name={}", st.name)
        if pipeline._failure_cb is not None:
            pipeline._failure_cb(ctx, st.name, exc)
        raise
    dt = time.perf_counter() - t0
    ctx.record_step(st.name, st.module_tag, dt)


def _run_parallel_batch(pipeline: JobPipeline, ctx: JobContext, batch: list[_Step]) -> None:
    from .parallel import default_executor

    ex = default_executor().thread_pool

    def _work(st: _Step) -> tuple[str, Any, float, BaseException | None]:
        t0 = time.perf_counter()
        try:
            c = JobContext(data=ctx.data, meta=dict(ctx.meta), started_at=ctx.started_at, step_spans=[], pinned=[], peak_rss_bytes=ctx.peak_rss_bytes)
            out = st.fn(c, **st.kwargs)
            data = out if out is not None else c.data
            return st.name, data, time.perf_counter() - t0, None
        except BaseException as e:
            return st.name, None, time.perf_counter() - t0, e

    futures: list[Future[tuple[str, Any, float, BaseException | None]]] = [ex.submit(_work, st) for st in batch]
    results = [f.result() for f in futures]
    errs = [r for r in results if r[3] is not None]
    if errs:
        for st, (_, _, _, err) in zip(batch, results, strict=True):
            if err is not None and pipeline._failure_cb is not None:
                pipeline._failure_cb(ctx, st.name, err)
        first = errs[0][3]
        assert first is not None
        raise first
    for name, data, dt, _ in results:
        ctx.record_step(name, batch[0].module_tag, dt)
        if data is not None:
            ctx.data = data
            if _is_pinnable(data):
                ctx.pin(data)


def _emit_job_report(ctx: JobContext, wall_s: float) -> None:
    by_mod: dict[str, float] = {}
    for _name, tag, dt in ctx.step_spans:
        by_mod[tag] = by_mod.get(tag, 0.0) + dt
    lines = [f"JobReport wall_s={wall_s:.4f} peak_rss_bytes={ctx.peak_rss_bytes}"]
    for tag, sec in sorted(by_mod.items(), key=lambda x: -x[1]):
        lines.append(f"  module={tag!r} total_s={sec:.4f}")
    for name, tag, sec in ctx.step_spans:
        lines.append(f"    step={name!r} tag={tag!r} s={sec:.4f}")
    logger.info("\n".join(lines))


# --- Legacy examples (ingest / transform / export) ------------------------------------


def numeric_feature_pipeline(
    path: str | Path,
    *,
    value_col: str,
    group_col: str,
    out_parquet: str | Path | None = None,
) -> pl.DataFrame:
    """Example: Parquet → group stats → numpy z-score in group → Polars column."""
    from . import array as array_mod
    from . import export, ingest, transform

    df = ingest.read_parquet(path)
    g = transform.group_agg(
        df,
        group_col,
        [
            pl.col(value_col).mean().alias("mean_v"),
            pl.col(value_col).std().alias("std_v"),
            pl.col(value_col).count().alias("n"),
        ],
    )
    merged = df.join(g, on=group_col, how="left")
    arr = merged[value_col].to_numpy().astype(np.float64)
    means = merged["mean_v"].to_numpy().astype(np.float64)
    stds = merged["std_v"].to_numpy().astype(np.float64)
    stds = np.where(stds > 1e-12, stds, 1.0)
    z = array_mod.clip_range((arr - means) / stds, -10.0, 10.0)
    out = merged.with_columns(pl.Series("zscore", z))
    if out_parquet is not None:
        export.write_parquet(out, out_parquet)
    return out


def lazy_aggregate_then_collect(
    parquet_glob: str,
    *,
    key: str,
    streaming: bool = False,
) -> pl.DataFrame:
    """Lazy scan → group → collect (optional streaming)."""
    from . import frame

    lf = pl.scan_parquet(parquet_glob).group_by(key).agg(pl.len().alias("cnt"))
    return frame.collect_lazy(lf, streaming=streaming)


__all__ = [
    "JobContext",
    "JobPipeline",
    "deserialize_pipeline",
    "lazy_aggregate_then_collect",
    "numeric_feature_pipeline",
    "register_step",
    "serialize_pipeline",
]
