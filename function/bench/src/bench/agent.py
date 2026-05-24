"""Benchmarks for the ``agent`` package (Pydantic message models; no LLM calls)."""

from __future__ import annotations

import importlib

from ._resolve import agent_module
from ._timing import TimingSample, bench_call


def run_agent_benchmarks(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    try:
        _a = agent_module()
        typed = importlib.import_module(f"{_a.__name__}.typed")
        RiceMessage = typed.RiceMessage
    except Exception as exc:  # noqa: BLE001 — optional stack (instructor, litellm, …)
        return [
            TimingSample(
                name="agent.RiceMessage (skipped)",
                seconds_mean=0.0,
                seconds_stdev=0.0,
                iterations=0,
                warmup=0,
                note=f"import agent.typed failed: {exc!r}",
            ),
        ]

    sample = {
        "role": "user",
        "content": "hello " * 80,
        "metadata": {"bench": True, "n": 42},
    }

    def validate_message() -> None:
        RiceMessage.model_validate(sample)

    def model_dump() -> None:
        m = RiceMessage.model_validate(sample)
        m.model_dump(mode="json")

    return [
        bench_call("agent.RiceMessage.model_validate", validate_message, repeat=repeat, warmup=warmup),
        bench_call("agent.RiceMessage.model_dump(json)", model_dump, repeat=repeat, warmup=warmup),
    ]
