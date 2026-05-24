# SIMD — native-width vectors (AVX-2 / AVX-512 / NEON), FMA, reductions, math, RiceArray load/store.
# Matches Python bridge dtypes: Float32, Float64 only for vectorized float paths.
# Legacy F32x8 / I32x8 aliases remain for kernels that still assume 8-wide f32.

from math import exp, log, rsqrt, sqrt
from memory.unsafe_pointer import UnsafePointer
from sys.info import simd_width_of


# === Host-native lane counts (AVX2: 8×f32 / 4×f64; AVX-512: 16×f32 / 8×f64; NEON: 4×f32, etc.) ===


@always_inline
fn simdwidthof[dtype: DType]() -> Int:
    """Return hardware SIMD lanes for ``dtype`` (SAGE name; wraps ``simd_width_of``)."""
    return simd_width_of[dtype]()


alias NATIVE_F32_LANES: Int = simd_width_of[DType.float32]()
alias NATIVE_F64_LANES: Int = simd_width_of[DType.float64]()

alias F32Vec = SIMD[DType.float32, NATIVE_F32_LANES]
alias F64Vec = SIMD[DType.float64, NATIVE_F64_LANES]

# --- Legacy 8-lane f32 (existing embed / conv / polars / __init__ re-exports) ----------------
alias F32x8 = SIMD[DType.float32, 8]
alias I32x8 = SIMD[DType.int32, 8]


# === Core arithmetic (branch-free, in-register) =============================================


@always_inline
fn v_add[dtype: DType, width: Int](a: SIMD[dtype, width], b: SIMD[dtype, width]) -> SIMD[dtype, width]:
    return a + b


@always_inline
fn v_sub[dtype: DType, width: Int](a: SIMD[dtype, width], b: SIMD[dtype, width]) -> SIMD[dtype, width]:
    return a - b


@always_inline
fn v_mul[dtype: DType, width: Int](a: SIMD[dtype, width], b: SIMD[dtype, width]) -> SIMD[dtype, width]:
    return a * b


@always_inline
fn v_div[dtype: DType, width: Int](a: SIMD[dtype, width], b: SIMD[dtype, width]) -> SIMD[dtype, width]:
    return a / b


@always_inline
fn v_fma[dtype: DType, width: Int](
    a: SIMD[dtype, width], b: SIMD[dtype, width], c: SIMD[dtype, width]
) -> SIMD[dtype, width]:
    """Fused multiply-add: (a * b) + c in one contractible FMA sequence."""
    return a.fma(b, c)


# === Reductions =============================================================================


@always_inline
fn v_sum[width: Int](vector: SIMD[DType.float32, width]) -> Float32:
    return vector.reduce_add()


@always_inline
fn v_sum[width: Int](vector: SIMD[DType.float64, width]) -> Float64:
    return vector.reduce_add()


@always_inline
fn v_max[width: Int](vector: SIMD[DType.float32, width]) -> Float32:
    return vector.reduce_max()


@always_inline
fn v_max[width: Int](vector: SIMD[DType.float64, width]) -> Float64:
    return vector.reduce_max()


@always_inline
fn v_min[width: Int](vector: SIMD[DType.float32, width]) -> Float32:
    return vector.reduce_min()


@always_inline
fn v_min[width: Int](vector: SIMD[DType.float64, width]) -> Float64:
    return vector.reduce_min()


# === Transcendentals (vectorized libm / LLVM) ================================================


@always_inline
fn v_exp[dtype: DType, width: Int](x: SIMD[dtype, width]) -> SIMD[dtype, width]:
    return exp[dtype, width](x)


@always_inline
fn v_log[dtype: DType, width: Int](x: SIMD[dtype, width]) -> SIMD[dtype, width]:
    return log[dtype, width](x)


@always_inline
fn v_sqrt[dtype: DType, width: Int](x: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """IEEE-style elementwise ``sqrt`` (lowers to sqrt + rsqrt micro-ops per target)."""
    return sqrt[dtype, width](x)


@always_inline
fn v_rsqrt[dtype: DType, width: Int](x: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """Elementwise ``1/sqrt(x)`` — prefer for norms / cosine prior to multiply."""
    return rsqrt[dtype, width](x)


@always_inline
fn v_sqrt_via_rsqrt[dtype: DType, width: Int](x: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """``sqrt(x)`` via one Newton refinement on ``rsqrt`` (fast when ``rsqrt`` is native)."""
    var r0 = rsqrt[dtype, width](x)
    var r1 = r0 * (SIMD[dtype, width](1.5) - SIMD[dtype, width](0.5) * x * r0 * r0)
    return x * r1


# === Branchless selection ===================================================================


@always_inline
fn v_select[dtype: DType, width: Int](
    mask: SIMD[DType.bool, width], a: SIMD[dtype, width], b: SIMD[dtype, width]
) -> SIMD[dtype, width]:
    """Per-lane ``mask ? a : b`` (``True`` → ``a``, ``False`` → ``b``)."""
    return mask.select(a, b)


# === Memory ↔ registers (RiceArray / raw C buffers) ========================================


@always_inline
fn load[width: Int](p: UnsafePointer[Scalar[DType.float32]]) -> SIMD[DType.float32, width]:
    """Load ``width`` consecutive ``float32`` from element offset ``0``."""
    return p.load[width=width]()


@always_inline
fn load[width: Int](p: UnsafePointer[Scalar[DType.float64]]) -> SIMD[DType.float64, width]:
    """Load ``width`` consecutive ``float64`` from element offset ``0``."""
    return p.load[width=width]()


@always_inline
fn store[width: Int](p: UnsafePointer[Scalar[DType.float32]], v: SIMD[DType.float32, width]):
    """Store ``v`` at element offset ``0`` (``RiceArray`` / C buffer head)."""
    p.store[width=width](v)


@always_inline
fn store[width: Int](p: UnsafePointer[Scalar[DType.float64]], v: SIMD[DType.float64, width]):
    """Store ``v`` at element offset ``0``."""
    p.store[width=width](v)


@always_inline
fn load_offset[width: Int](
    p: UnsafePointer[Scalar[DType.float32]], offset_elems: Int
) -> SIMD[DType.float32, width]:
    return p.load[width=width](offset_elems)


@always_inline
fn load_offset[width: Int](
    p: UnsafePointer[Scalar[DType.float64]], offset_elems: Int
) -> SIMD[DType.float64, width]:
    return p.load[width=width](offset_elems)


@always_inline
fn store_offset[width: Int](
    p: UnsafePointer[Scalar[DType.float32]], offset_elems: Int, v: SIMD[DType.float32, width]
):
    p.store[width=width](offset_elems, v)


@always_inline
fn store_offset[width: Int](
    p: UnsafePointer[Scalar[DType.float64]], offset_elems: Int, v: SIMD[DType.float64, width]
):
    p.store[width=width](offset_elems, v)


# === Native-width convenience wrappers =======================================================


@always_inline
fn v_add_f32n(a: F32Vec, b: F32Vec) -> F32Vec:
    return v_add[DType.float32, NATIVE_F32_LANES](a, b)


@always_inline
fn v_add_f64n(a: F64Vec, b: F64Vec) -> F64Vec:
    return v_add[DType.float64, NATIVE_F64_LANES](a, b)


@always_inline
fn load_native_f32(p: UnsafePointer[Scalar[DType.float32]]) -> F32Vec:
    return load[NATIVE_F32_LANES](p)


@always_inline
fn load_native_f64(p: UnsafePointer[Scalar[DType.float64]]) -> F64Vec:
    return load[NATIVE_F64_LANES](p)


@always_inline
fn store_native_f32(p: UnsafePointer[Scalar[DType.float32]], v: F32Vec):
    store[NATIVE_F32_LANES](p, v)


@always_inline
fn store_native_f64(p: UnsafePointer[Scalar[DType.float64]], v: F64Vec):
    store[NATIVE_F64_LANES](p, v)


# === Legacy 8-wide kernels (unchanged ABI for existing modules) =============================


@always_inline
fn dot_f32x8(a: F32x8, b: F32x8) -> Float32:
    return (a * b).reduce_add()


@always_inline
fn fma_f32x8(a: F32x8, b: F32x8, c: F32x8) -> F32x8:
    return a.fma(b, c)


@always_inline
fn broadcast_f32x8(v: Float32) -> F32x8:
    return F32x8(v)


@always_inline
fn dot_i32x8(a: I32x8, b: I32x8) -> Int32:
    return (a * b).reduce_add()
