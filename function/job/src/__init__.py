"""Job — central engine for the `.rice` stack: Polars ETL, NumPy/SciPy, Mojo kernels, export, pipelines.

On import, the package warms optional native libraries, provisions a process-wide
:class:`~parallel.JobExecutor`, and logs readiness via Loguru. Import-time failures
in optional stacks (Mojo drivers, strict Polars checks) are recorded but do not
prevent the rest of the API from loading.
"""

from __future__ import annotations

import os
import sys
from importlib.metadata import PackageNotFoundError, version
from typing import Any, TextIO

from loguru import logger

# --- Package metadata ---------------------------------------------------------

__author__ = "Code-Rice"
__status__ = "SAGE_READY"

try:
    __version__ = version("job")
except PackageNotFoundError:  # pragma: no cover — editable / vendored tree
    __version__ = "0.1.0"

# --- Submodules (public namespaces) -------------------------------------------

from . import array
from . import bridge
from . import export
from . import frame
from . import ingest
from . import interpolate
from . import linalg
from . import memory
from . import optimize
from . import parallel
from . import pipeline
from . import signal
from . import stats
from . import transform

from .array import (
    NonContiguousArrayError,
    RiceArray,
    RiceSparse,
    SparseMojoBuffers,
    TensorBufferInfo,
)
from .bridge import (
    BUILD_DIR,
    DEFAULT_MOJOPKG,
    KernelNotFoundError,
    KernelRegistry,
    MOJO_PACKAGE_DIR,
    MOJO_TO_NUMPY,
    NUMPY_TO_MOJO_DTYPE,
    MojoKernelBridge,
    MojoLibrary,
    build_mojopkg,
    execute_kernel,
    execute_kernel_async,
    get_kernel,
    max_engine_available,
    resolve_mojo_shared_library,
    warmup,
)
from .export import (
    atomic_write,
    check_path_integrity,
    partitioned_export,
    schema_export,
    to_arrow,
    to_csv,
    to_numpy,
    to_parquet,
    to_sql,
    to_url,
    write_csv,
    write_database,
    write_delta,
    write_parquet,
)
from .frame import (
    HorizontalPartitionSpec,
    RiceFrame,
    RiceGroupBy,
    SchemaValidationError,
    as_rice,
    collect_lazy,
    concat_vertical,
    empty_frame,
    from_rows,
    iter_batches,
    scan_csv_lazy,
    scan_ndjson_lazy,
    scan_parquet_lazy,
    sink_parquet_lazy,
)
from .ingest import (
    auto_schema_inference,
    batch_loader,
    batch_loader_async,
    from_arrow_ipc,
    read_csv,
    read_json,
    read_ndjson,
    read_parquet,
    scan_csv,
    scan_ipc,
    scan_ndjson,
    scan_parquet,
    smart_load,
    smart_load_async,
    stream_from_url,
)
from .interpolate import (
    align_series,
    extrapolate,
    grid_interp,
    griddata_points,
    interp_1d_linear,
    linear_interp,
    missing_data_filler,
    rbf_interp,
    rbf_interpolate,
    spline_interp,
)
from .linalg import (
    batched_matmul,
    det,
    dot,
    eig_decompose,
    eigen,
    eigvalsh_symmetric,
    inverse,
    is_positive_definite,
    is_symmetric,
    matmul,
    matrix_rank,
    norm_vector,
    solve,
    solve_linear,
    svd,
    svd_decompose,
    transpose,
)
from .memory import (
    BufferMetadata,
    MemoryAnchor,
    anchor,
    as_c_array_ptr,
    as_c_void_p,
    buffer_metadata,
    get_raw_address,
    is_contiguous,
    release,
    shared_buffer,
)
from .optimize import (
    ConstraintSet,
    EarlyStoppingConfig,
    add_constraint,
    curve_fit_model,
    early_stopping,
    find_root,
    find_root_scalar,
    fit_model,
    linprog_simple,
    minimize_func,
    minimize_nlp,
    minimize_scalar_bounded,
    minimize_vector,
    minimized_parameters,
    register_objective,
    stochastic_optimizer,
)
from .parallel import (
    CircuitBreaker,
    CircuitOpenError,
    Heartbeat,
    JobExecutor,
    TaskPriority,
    TaskQueue,
    anchor_payload_for_thread,
    default_executor,
    heartbeat_loop,
    parallel_map,
    run_async,
)
from .pipeline import (
    JobContext,
    JobPipeline,
    STEP_REGISTRY,
    deserialize_pipeline,
    lazy_aggregate_then_collect,
    numeric_feature_pipeline,
    register_step,
    serialize_pipeline,
)
from .signal import (
    apply_filter,
    apply_window,
    bandpass,
    butter_lowpass,
    convolve,
    convolve_same,
    cross_correlate,
    fft,
    fft_rfft,
    filtfilt_zero_phase,
    find_peaks_1d,
    highpass,
    ifft,
    lowpass,
    power_spectrum,
    resample,
    stft,
    welch_psd,
)
from .stats import (
    anova,
    chi2_contingency,
    chi_square,
    correlation_matrix,
    describe_sample,
    fit_distribution,
    ks_2samp_test,
    mannwhitneyu_test,
    monte_carlo_summary,
    normal_pdf,
    p_value_check,
    pearsonr_corr,
    quantile_analysis,
    rolling_stats,
    sampling,
    spearmanr_corr,
    summary,
    t_test,
    ttest_ind_samples,
    z_score_normalization,
)
from .transform import (
    apply_custom,
    cast_types,
    discretize,
    drop_nulls_adaptive,
    explode,
    feature_cross,
    filter_by_expr,
    group_agg,
    join_inner,
    join_left,
    melt,
    melt_unpivot,
    min_max_scale,
    one_hot_encode,
    pivot_table,
    robust_scale,
    select_columns,
    sort_by,
    standardize,
    transform_partitions,
    with_derived,
)

# --- Intuitive aliases --------------------------------------------------------

load = smart_load
save = to_parquet

# --- Bootstrap state ----------------------------------------------------------

_INIT_NOTICES: list[str] = []


def _mojo_loaded_library_count() -> int:
    try:
        reg = KernelRegistry.instance()
        return len(getattr(reg, "_cdll_by_path", {}))
    except Exception:
        return 0


def _bootstrap_job_engine() -> JobExecutor:
    """Warm Mojo artifacts (best effort), create the default executor, log readiness."""
    from . import const

    ex = default_executor()
    n_cpu = os.cpu_count() or 0
    mojo_libs = _mojo_loaded_library_count()

    try:
        import polars as pl

        ver = getattr(pl, "__version__", "unknown")
        try:
            major_s, minor_s, *_ = ver.split(".", 2)
            if (int(major_s), int(minor_s)) < (1, 5):
                msg = f"Polars {ver} is below the declared minimum (1.5); some APIs may fail."
                _INIT_NOTICES.append(msg)
                logger.warning(msg)
        except (TypeError, ValueError):
            _INIT_NOTICES.append(f"Could not parse Polars version {ver!r}.")
    except ImportError as e:
        msg = "Polars is not installed; most job APIs will be unavailable."
        _INIT_NOTICES.append(msg)
        logger.warning("{} ({})", msg, e)

    try:
        warmup(const.RICE_MOJO_ARRAY_LIB)
        mojo_libs = _mojo_loaded_library_count()
    except KernelNotFoundError:
        logger.info(
            "Mojo warmup skipped: no shared library for stem={!r} (set RICE_MOJO_LIB_DIR or build native libs).",
            const.RICE_MOJO_ARRAY_LIB,
        )
    except OSError as e:
        msg = f"Mojo warmup I/O/driver issue: {e}"
        _INIT_NOTICES.append(msg)
        logger.warning(msg)
    except Exception as e:  # pragma: no cover — defensive import surface
        msg = f"Mojo warmup failed (non-fatal for Python-only flows): {e!r}"
        _INIT_NOTICES.append(msg)
        logger.warning(msg)

    logger.info(
        "Job Engine Initialized | cpus={} | mojo_shared_libs_loaded={} | executor_threads={} executor_processes={} | status={} v={}",
        n_cpu,
        mojo_libs,
        ex.max_threads,
        ex.max_processes,
        __status__,
        __version__,
    )
    return ex


def _bootstrap_job_engine_safe() -> JobExecutor:
    """Run startup; never abort package import on optional native / IO failures."""
    try:
        return _bootstrap_job_engine()
    except Exception as e:  # pragma: no cover — last-resort guardrail
        msg = f"Job engine bootstrap failed; using minimal executor: {e!r}"
        _INIT_NOTICES.append(msg)
        logger.exception(msg)
        return JobExecutor(max_threads=max(1, (os.cpu_count() or 2) // 2), max_processes=1)


executor: JobExecutor = _bootstrap_job_engine_safe()


def info(*, stream: TextIO | None = None) -> None:
    """Print a concise snapshot: memory pins, pipeline step registry, and key libraries."""
    out = stream or sys.stdout
    print("=== job (.rice) engine ===", file=out)
    print(f"version={__version__} author={__author__!r} status={__status__}", file=out)
    if _INIT_NOTICES:
        print("init notices:", file=out)
        for line in _INIT_NOTICES:
            print(f"  - {line}", file=out)

    print("\n--- executor ---", file=out)
    print(
        f"max_threads={executor.max_threads} max_processes={executor.max_processes}",
        file=out,
    )

    print("\n--- memory (MemoryAnchor) ---", file=out)
    pinned = getattr(MemoryAnchor, "_pinned", None)
    refcount = getattr(MemoryAnchor, "_refcount", None)
    if isinstance(pinned, dict) and isinstance(refcount, dict):
        print(f"pinned_objects={len(pinned)} refcount_entries={len(refcount)}", file=out)
    else:
        print("  (MemoryAnchor registry not introspectable)", file=out)

    print("\n--- pipelines ---", file=out)
    print(
        f"registered_step_ids={len(STEP_REGISTRY)} (no global in-flight tracker; use JobContext meta if needed)",
        file=out,
    )
    if STEP_REGISTRY:
        keys = sorted(STEP_REGISTRY.keys())
        preview = keys[:12]
        print("  sample:", ", ".join(preview) + (" …" if len(keys) > 12 else ""), file=out)

    print("\n--- libraries ---", file=out)
    for name in ("polars", "numpy", "scipy", "pyarrow", "yaml", "psutil"):
        try:
            mod = __import__(name)
            ver = getattr(mod, "__version__", "?")
            print(f"  {name}: {ver}", file=out)
        except ImportError:
            print(f"  {name}: (not installed)", file=out)

    print("\n--- Mojo bridge ---", file=out)
    print(f"  max_engine_available={max_engine_available()}", file=out)
    print(f"  loaded_shared_libraries={_mojo_loaded_library_count()}", file=out)
    print(f"  MOJO_PACKAGE_DIR={MOJO_PACKAGE_DIR}", file=out)


__all__ = [
    "BUILD_DIR",
    "BufferMetadata",
    "CircuitBreaker",
    "CircuitOpenError",
    "ConstraintSet",
    "DEFAULT_MOJOPKG",
    "EarlyStoppingConfig",
    "Heartbeat",
    "HorizontalPartitionSpec",
    "JobContext",
    "JobExecutor",
    "JobPipeline",
    "KernelNotFoundError",
    "KernelRegistry",
    "MOJO_PACKAGE_DIR",
    "MOJO_TO_NUMPY",
    "MemoryAnchor",
    "NonContiguousArrayError",
    "NUMPY_TO_MOJO_DTYPE",
    "MojoKernelBridge",
    "MojoLibrary",
    "RiceArray",
    "RiceFrame",
    "RiceGroupBy",
    "RiceSparse",
    "STEP_REGISTRY",
    "SchemaValidationError",
    "SparseMojoBuffers",
    "TaskPriority",
    "TaskQueue",
    "TensorBufferInfo",
    "__author__",
    "__status__",
    "__version__",
    "add_constraint",
    "align_series",
    "anchor",
    "anchor_payload_for_thread",
    "anova",
    "apply_custom",
    "apply_filter",
    "apply_window",
    "array",
    "as_c_array_ptr",
    "as_c_void_p",
    "as_rice",
    "atomic_write",
    "auto_schema_inference",
    "bandpass",
    "batch_loader",
    "batch_loader_async",
    "batched_matmul",
    "bridge",
    "build_mojopkg",
    "buffer_metadata",
    "butter_lowpass",
    "cast_types",
    "check_path_integrity",
    "chi2_contingency",
    "chi_square",
    "collect_lazy",
    "concat_vertical",
    "convolve",
    "convolve_same",
    "correlation_matrix",
    "cross_correlate",
    "curve_fit_model",
    "default_executor",
    "describe_sample",
    "deserialize_pipeline",
    "det",
    "discretize",
    "dot",
    "drop_nulls_adaptive",
    "eig_decompose",
    "eigen",
    "eigvalsh_symmetric",
    "early_stopping",
    "empty_frame",
    "executor",
    "explode",
    "export",
    "extrapolate",
    "execute_kernel",
    "execute_kernel_async",
    "feature_cross",
    "fft",
    "fft_rfft",
    "filter_by_expr",
    "find_peaks_1d",
    "find_root",
    "find_root_scalar",
    "filtfilt_zero_phase",
    "fit_distribution",
    "fit_model",
    "frame",
    "from_arrow_ipc",
    "from_rows",
    "get_kernel",
    "get_raw_address",
    "grid_interp",
    "griddata_points",
    "group_agg",
    "heartbeat_loop",
    "highpass",
    "ifft",
    "ingest",
    "info",
    "interpolate",
    "inverse",
    "is_contiguous",
    "is_positive_definite",
    "is_symmetric",
    "interp_1d_linear",
    "iter_batches",
    "join_inner",
    "join_left",
    "ks_2samp_test",
    "lazy_aggregate_then_collect",
    "linalg",
    "linear_interp",
    "linprog_simple",
    "load",
    "lowpass",
    "mannwhitneyu_test",
    "matmul",
    "matrix_rank",
    "max_engine_available",
    "memory",
    "melt",
    "melt_unpivot",
    "min_max_scale",
    "minimize_func",
    "minimize_nlp",
    "minimize_scalar_bounded",
    "minimize_vector",
    "minimized_parameters",
    "missing_data_filler",
    "monte_carlo_summary",
    "normal_pdf",
    "norm_vector",
    "numeric_feature_pipeline",
    "one_hot_encode",
    "optimize",
    "parallel",
    "parallel_map",
    "partitioned_export",
    "pearsonr_corr",
    "p_value_check",
    "pivot_table",
    "pipeline",
    "power_spectrum",
    "quantile_analysis",
    "rbf_interp",
    "rbf_interpolate",
    "read_csv",
    "read_json",
    "read_ndjson",
    "read_parquet",
    "register_objective",
    "register_step",
    "release",
    "resample",
    "resolve_mojo_shared_library",
    "robust_scale",
    "rolling_stats",
    "run_async",
    "sampling",
    "save",
    "scan_csv",
    "scan_csv_lazy",
    "scan_ipc",
    "scan_ndjson",
    "scan_ndjson_lazy",
    "scan_parquet",
    "scan_parquet_lazy",
    "schema_export",
    "select_columns",
    "serialize_pipeline",
    "shared_buffer",
    "signal",
    "sink_parquet_lazy",
    "smart_load",
    "smart_load_async",
    "solve",
    "solve_linear",
    "sort_by",
    "spearmanr_corr",
    "spline_interp",
    "stft",
    "standardize",
    "stats",
    "stochastic_optimizer",
    "stream_from_url",
    "summary",
    "svd",
    "svd_decompose",
    "to_arrow",
    "to_csv",
    "to_numpy",
    "to_parquet",
    "to_sql",
    "to_url",
    "transform",
    "transform_partitions",
    "transpose",
    "t_test",
    "ttest_ind_samples",
    "warmup",
    "welch_psd",
    "with_derived",
    "write_csv",
    "write_database",
    "write_delta",
    "write_parquet",
    "z_score_normalization",
]
