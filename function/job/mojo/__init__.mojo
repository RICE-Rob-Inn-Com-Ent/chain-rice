"""SAGE Mojo package root — unified kernel API for ``job`` / ``bridge.py``.

Build (from the ``function/`` project root)::

    mojo package job/src/mojo -o job/src/mojo/build/sage.mojopkg

Input tree is ``job/src/mojo`` (``MOJO_PACKAGE_DIR`` in ``job.src.const``). ``bridge.py`` loads the
compiled shared library with ``ctypes.CDLL`` and resolves symbols exported from this package
(same names as in submodule sources unless re-wrapped here).

Interop:

- Prefer returning ``SAGE_OK`` / ``SAGE_ERR_*`` from high-level ``sage_*`` entry points so Python can
  map ``ctypes.c_int`` without parsing Mojo errors (segfaults remain uncatchable in CPython).
- Call ``sage_engine_create`` once per process (or ``sage_engine_refresh`` after fork) to capture
  compile-time SIMD width / coarse flags for logging or host-side kernel selection.
- Low-level kernels stay available via the explicit ``from .simd import …`` re-exports below.
"""

from memory.unsafe_pointer import UnsafePointer

from .conv import (
    avg_pool2d_k2_f32,
    avg_pool2d_k3_f32,
    conv1d,
    conv1d_same_f32x8_k3,
    conv2d,
    depthwise_conv2d_f32,
    depthwise_separable_conv2d_f32,
    max_pool2d_k2_f32,
    max_pool2d_k3_f32,
    pointwise_1x1_f32,
)
from .embed import (
    EMBED_METRIC_COSINE,
    EMBED_METRIC_DOT,
    EMBED_METRIC_L2_SQ,
    cosine_f32x8,
    cosine_similarity,
    dequantize_i8_to_f32,
    dot_product_f32,
    dot_product_f32_fma,
    euclidean_distance,
    euclidean_squared_f32,
    find_top_k,
    gemv_bias_f32,
    hamming_distance_u8,
    l2_norm_f32x8,
    l2_normalize_f32_inplace,
    norm_squared_f32_fma,
    pack_sign_binary_u8,
    pq_codes_l2_squared,
    pq_query_residual_squared,
    quantize_symmetric_i8,
)
from .fft import (
    apply_hamming_window,
    apply_hann_window,
    dft4_real_f32,
    fft_1d,
    fft_2d,
    fft_prepare_twiddles_forward,
    fft_prepare_twiddles_inverse,
    hann_window_4,
    ifft4_real_energy_placeholder,
    ifft_1d,
    is_power_of_two,
    log2_int,
    spectrogram_mag2,
)
from .matrix import (
    det_2x2_f32,
    inverse_2x2_f32,
    load_col_f32,
    lu_decompose_2x2_f32,
    mat_elem_add_f32,
    mat_elem_mul_f32,
    mat_elem_sub_f32,
    matmul,
    matmul_small_f32,
    matmul_2x2_f32,
    matmul_tiled_parallel_f32,
    matrix_norm_frobenius_f32,
    memset_zero_f32,
    transpose_2x2_f32,
    transpose_inplace_square_f32,
    transpose_out_f32,
)
from .monte import (
    MonteSummary,
    Xor128p,
    calculate_var,
    lcg_u64,
    mean_f32_buffer,
    monte_init_worker_rng,
    monte_summarize_paths,
    simulate_gbm,
    simulate_gbm_barrier,
    standard_deviation_f32_buffer,
    u01_from_u64,
    variance_f32_buffer,
    xor128p_seed,
)
from .ode import (
    OdeRhs,
    euler_scalar_exp_step,
    integrate_to,
    integrate_to_rk45,
    rk4_scalar_exp_step,
    rk4_step,
    rk4_work_elems,
    rk45_cash_karp_step,
    rk45_work_elems,
    rhs_exp_autonomous,
    simulate_ensemble,
)
from .polars import (
    DataFrame,
    LazyOp,
    LazyOpPtr,
    LazyPlan,
    LAZY_FILTER_F32,
    LAZY_GROUPBY,
    LAZY_JOIN,
    LAZY_NOP,
    POLAR_CMP_EQ,
    POLAR_CMP_GE,
    POLAR_CMP_GT,
    POLAR_CMP_LE,
    POLAR_CMP_LT,
    POLAR_CMP_NE,
    bridge_register_csv_layout,
    bridge_register_parquet_layout,
    col_max_f32,
    col_mean_f32,
    col_min_f32,
    col_std_f32,
    col_sum_f32,
    df_col_ptr,
    df_slice,
    filter_column,
    filter_f32_column_mask,
    groupby_count_i64_range_parallel,
    groupby_sum_f32_bucket_parallel,
    hash_join_count_i64,
    lazy_materialize_hint,
    lazy_plan_init,
    lazy_plan_push_filter,
    mean_f32x8,
    rolling_sum_f32x8,
)
from .simd import (
    F32Vec,
    F32x8,
    F64Vec,
    I32x8,
    NATIVE_F32_LANES,
    NATIVE_F64_LANES,
    broadcast_f32x8,
    dot_f32x8,
    dot_i32x8,
    fma_f32x8,
    load,
    load_native_f32,
    load_native_f64,
    load_offset,
    simdwidthof,
    store,
    store_native_f32,
    store_native_f64,
    store_offset,
    v_add,
    v_add_f32n,
    v_add_f64n,
    v_div,
    v_exp,
    v_fma,
    v_log,
    v_max,
    v_min,
    v_mul,
    v_rsqrt,
    v_select,
    v_sqrt,
    v_sqrt_via_rsqrt,
    v_sub,
    v_sum,
)
from .tokenize import (
    UTF8_ERR,
    UTF8_OK,
    I32Ptr,
    U32Ptr,
    U64Ptr,
    U8Ptr,
    bpe_merge_one_pass,
    bpe_pad_to_multiple,
    bpe_reduce_ids,
    clean_text,
    encode_paragraphs_parallel,
    encode_utf8_bpe,
    paragraph_offsets_from_newlines,
    utf8_validate,
    utf8_validate_scalar,
    utf8_validate_simd_ascii_run,
    vocab_lookup_bounded,
)

# --- Status / ABI (stable ``Int`` codes for ``ctypes.c_int`` from ``bridge.py``) ---------------

alias SAGE_OK: Int = 0
alias SAGE_ERR_INVALID_ARG: Int = 1
alias SAGE_ERR_TOKENIZE: Int = 2
alias SAGE_ERR_UTF8: Int = 3
alias SAGE_ERR_RANGE: Int = 4
alias SAGE_ERR_DIM: Int = 5
alias SAGE_ERR_INTERNAL: Int = 99

alias SAGE_ABI_VERSION: Int = 1

# Bit in ``SageEngine.hw_flags``: native ``float32`` SIMD width ≥ 16 (typical AVX-512 class).
alias SAGE_HW_WIDE_F32: UInt32 = 1


alias F32Ptr = UnsafePointer[Scalar[DType.float32]]


# --- Engine snapshot (host-managed singleton; Mojo side is POD + probe helpers) ----------------


# Hardware-facing snapshot: lane counts from ``simd_width_of`` at compile time + coarse flags.
@register_passable("trivial")
struct SageEngine:
    var initialized: Bool
    var native_f32_lanes: Int
    var native_f64_lanes: Int
    var hw_flags: UInt32


fn sage_engine_abi_version() -> Int:
    return SAGE_ABI_VERSION


fn sage_engine_create() -> SageEngine:
    var flags = UInt32(0)
    if NATIVE_F32_LANES >= 16:
        flags = flags | SAGE_HW_WIDE_F32
    return SageEngine(True, NATIVE_F32_LANES, NATIVE_F64_LANES, flags)


fn sage_engine_refresh(inout state: SageEngine):
    state = sage_engine_create()


# --- Unified compute (multi-kernel pipelines, status-first) ------------------------------------


fn sage_tokenize_first_token_dot_query(
    text: U8Ptr,
    text_len: Int,
    out_ids: U32Ptr,
    out_cap: Int,
    work_ids: U32Ptr,
    work_cap: Int,
    bucket_count: Int,
    merge_keys: U64Ptr,
    merge_ranks: I32Ptr,
    merge_new_id: U32Ptr,
    byte_to_id: U32Ptr,
    unk_id: UInt32,
    bos_id: UInt32,
    eos_id: UInt32,
    add_bos: Bool,
    add_eos: Bool,
    require_valid_utf8: Bool,
    embed_table: F32Ptr,
    vocab_size: UInt32,
    ld: Int,
    query: F32Ptr,
    dim: Int,
    out_dot: F32Ptr,
) -> Int:
    var nt = encode_utf8_bpe(
        text,
        text_len,
        out_ids,
        out_cap,
        work_ids,
        work_cap,
        bucket_count,
        merge_keys,
        merge_ranks,
        merge_new_id,
        byte_to_id,
        unk_id,
        bos_id,
        eos_id,
        add_bos,
        add_eos,
        require_valid_utf8,
    )
    if nt < 0:
        return SAGE_ERR_TOKENIZE
    if nt == 0:
        return SAGE_ERR_RANGE
    var tid = (out_ids + 0).load[width=1]()[0]
    if tid >= vocab_size:
        return SAGE_ERR_RANGE
    if dim <= 0 or ld < dim:
        return SAGE_ERR_INVALID_ARG
    var row = embed_table + Int(tid) * ld
    var d = dot_product_f32(row, query, dim)
    out_dot.store[width=1](SIMD[DType.float32, 1](d))
    return SAGE_OK


fn sage_buffer_mean_std(x: F32Ptr, n: Int, out_mean: F32Ptr, out_std: F32Ptr) -> Int:
    if n <= 0:
        return SAGE_ERR_INVALID_ARG
    var m = mean_f32_buffer(x, n)
    out_mean.store[width=1](SIMD[DType.float32, 1](m))
    var s = standard_deviation_f32_buffer(x, n, m)
    out_std.store[width=1](SIMD[DType.float32, 1](s))
    return SAGE_OK


fn sage_utf8_validate_and_score_ascii(text: U8Ptr, nbytes: Int, out_ok: I32Ptr) -> Int:
    if nbytes < 0:
        return SAGE_ERR_INVALID_ARG
    var r = utf8_validate(text, nbytes)
    var ok = Int32(0)
    if r == UTF8_OK:
        ok = Int32(1)
    out_ok.store[width=1](SIMD[DType.int32, 1](ok))
    if r == UTF8_OK:
        return SAGE_OK
    return SAGE_ERR_UTF8
