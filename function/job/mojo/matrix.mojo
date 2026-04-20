# Macierze 2×2 (SIMD jako row-major) — mnożenie, transpozycja, wyznacznik, odwrotność, LU dla 2×2.
# TODO:
# [ ] implement tiled matrix multiplication:
# [ ]     tile_size as compile-time alias — tunable for L1/L2 cache
# [ ]     parallelize via Mojo parallelize() across rows
# [ ] implement BLAS-level 2/3 operations:
# [ ]     gemv (matrix-vector), gemm (matrix-matrix)
# [ ] implement in-place operations to avoid allocation
# [ ] implement strided memory access patterns for cache efficiency
# [ ] integrate with MAX Engine Tensor for GPU dispatch

alias F32x4 = SIMD[DType.float32, 4]


fn matmul_2x2_f32(a: F32x4, b: F32x4) -> F32x4:
    var a00 = a[0]
    var a01 = a[1]
    var a10 = a[2]
    var a11 = a[3]
    var b00 = b[0]
    var b01 = b[1]
    var b10 = b[2]
    var b11 = b[3]
    var c00 = a00 * b00 + a01 * b10
    var c01 = a00 * b01 + a01 * b11
    var c10 = a10 * b00 + a11 * b10
    var c11 = a10 * b01 + a11 * b11
    return F32x4(c00, c01, c10, c11)


fn transpose_2x2_f32(a: F32x4) -> F32x4:
    return F32x4(a[0], a[2], a[1], a[3])


fn det_2x2_f32(a: F32x4) -> Float32:
    return a[0] * a[3] - a[1] * a[2]


fn inverse_2x2_f32(a: F32x4) -> F32x4:
    var d = det_2x2_f32(a)
    var inv = 1.0 / d
    return F32x4(a[3] * inv, -a[1] * inv, -a[2] * inv, a[0] * inv)


fn lu_decompose_2x2_f32(a: F32x4) -> SIMD[DType.float32, 8]:
    """LU dla 2×2 (bez pivotingu): zwraca 8 wartości — L (row-major), potem U."""
    var a00 = a[0]
    var a01 = a[1]
    var a10 = a[2]
    var a11 = a[3]
    var l10 = a10 / a00
    var u00 = a00
    var u01 = a01
    var u11 = a11 - l10 * a01
    return SIMD[DType.float32, 8](
        1.0,
        0.0,
        l10,
        1.0,
        u00,
        u01,
        0.0,
        u11,
    )
