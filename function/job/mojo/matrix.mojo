# Row-major GEMM (tiled + parallel), transpose, Hadamard ops, Frobenius norm.
# Uses `simd.mojo` (`v_fma`, native SIMD width). Tiling keeps working sets in L1/L2.
# CPU tile scheduling uses Modular `parallelize` (SAGE “parallel_for” semantics).

from algorithm import parallelize
from memory.unsafe_pointer import UnsafePointer
from sys.info import num_physical_cores

from .simd import NATIVE_F32_LANES, v_fma

# --- Public pointer alias (row-major, stride = trailing dimension) ---------------------------
alias F32Ptr = UnsafePointer[Scalar[DType.float32]]

alias SMALL_MAT_THRESHOLD: Int = 64
alias W: Int = NATIVE_F32_LANES


# === Legacy 2×2 (SIMD register as row-major 2×2) ==============================================

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
    """LU for 2×2 (no pivot): eight values — L row-major, then U."""
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


# === Utilities ==============================================================================


@always_inline
fn _min(a: Int, b: Int) -> Int:
    return a if a < b else b


@always_inline
fn _max(a: Int, b: Int) -> Int:
    return a if a > b else b


@always_inline
fn _ceil_div(a: Int, b: Int) -> Int:
    return (a + b - 1) // b


fn memset_zero_f32(dst: F32Ptr, n: Int):
    """Zero ``n`` consecutive ``float32`` (vectorized prologue + tail)."""
    var i: Int = 0
    while i + W <= n:
        (dst + i).store[width=W](SIMD[DType.float32, W](0.0))
        i += W
    while i < n:
        (dst + i).store[width=1](SIMD[DType.float32, 1](0.0))
        i += 1


# === Column access (row-major): vertical gather with stride ``ld`` ===========================


@always_inline
fn load_col_f32[width: Int](src: F32Ptr, ld: Int, col: Int, row0: Int) -> SIMD[DType.float32, width]:
    """Load ``width`` elements of column ``col`` starting at row ``row0`` (row-major stride ``ld``)."""
    var out = SIMD[DType.float32, width]()
    for r in range(width):
        out[r] = src[(row0 + r) * ld + col]
    return out


# === Small-matrix path (no blocking; i–k–j + SIMD on ``N``) ==================================


fn matmul_small_f32(C: F32Ptr, A: F32Ptr, B: F32Ptr, M: Int, N: Int, K: Int):
    """``C[M×N] = A[M×K] @ B[K×N]`` (caller zeroes ``C``) when ``M,N,K < SMALL_MAT_THRESHOLD``."""
    for i in range(M):
        for k in range(K):
            var aik = A[i * K + k]
            var aikv = SIMD[DType.float32, W](aik)
            var j: Int = 0
            while j + W <= N:
                var b_row = B + k * N + j
                var c_row = C + i * N + j
                var bv = b_row.load[width=W]()
                var cv = c_row.load[width=W]()
                c_row.store[width=W](v_fma[DType.float32, W](aikv, bv, cv))
                j += W
            while j < N:
                var b_row_t = B + k * N + j
                var c_row_t = C + i * N + j
                var b1 = b_row_t.load[width=1]()
                var c1 = c_row_t.load[width=1]()
                c_row_t.store[width=1](v_fma[DType.float32, 1](SIMD[DType.float32, 1](aik), b1, c1))
                j += 1


# === Tiled micro-kernel (compile-time tile sizes) ============================================


fn _gemm_tile_ikj_f32[
    TILE_M: Int,
    TILE_N: Int,
    TILE_K: Int,
](
    C: F32Ptr,
    A: F32Ptr,
    B: F32Ptr,
    M: Int,
    N: Int,
    K: Int,
    ii: Int,
    jj: Int,
    kk: Int,
):
    """Accumulate one ``TILE_*`` block: ``C[ii:,jj:] += A[ii:,kk:] @ B[kk:,jj:]`` (clamped)."""
    var i_end = _min(ii + TILE_M, M)
    var j_end = _min(jj + TILE_N, N)
    var k_end = _min(kk + TILE_K, K)
    for i in range(ii, i_end):
        for k in range(kk, k_end):
            var aik = A[i * K + k]
            var aikv = SIMD[DType.float32, W](aik)
            var j: Int = jj
            while j + W <= j_end:
                var b_row = B + k * N + j
                var c_row = C + i * N + j
                var bv = b_row.load[width=W]()
                var cv = c_row.load[width=W]()
                c_row.store[width=W](v_fma[DType.float32, W](aikv, bv, cv))
                j += W
            while j < j_end:
                var b_row_t = B + k * N + j
                var c_row_t = C + i * N + j
                var b1 = b_row_t.load[width=1]()
                var c1 = c_row_t.load[width=1]()
                c_row_t.store[width=1](v_fma[DType.float32, 1](SIMD[DType.float32, 1](aik), b1, c1))
                j += 1


fn matmul_tiled_parallel_f32[
    TILE_M: Int,
    TILE_N: Int,
    TILE_K: Int,
](C: F32Ptr, A: F32Ptr, B: F32Ptr, M: Int, N: Int, K: Int):
    """Blocked GEMM; row-tile strips use ``parallelize`` (SAGE parallel_for over row tiles)."""
    var nti = _ceil_div(M, TILE_M)
    var ntj = _ceil_div(N, TILE_N)
    var ntk = _ceil_div(K, TILE_K)
    var workers = _max(1, num_physical_cores())

    def row_tile_strip(ti: Int):
        var ii = ti * TILE_M
        if ii >= M:
            return
        for tj in range(ntj):
            var jj = tj * TILE_N
            if jj >= N:
                continue
            for tk in range(ntk):
                var kk = tk * TILE_K
                _gemm_tile_ikj_f32[TILE_M, TILE_N, TILE_K](C, A, B, M, N, K, ii, jj, kk)

    parallelize[row_tile_strip](nti, workers)


# === Public GEMM =============================================================================


fn matmul(C: F32Ptr, A: F32Ptr, B: F32Ptr, M: Int, N: Int, K: Int):
    """Row-major ``C[M×N] = A[M×K] @ B[K×N]``. Zeros ``C`` then tiled or small fast path."""
    memset_zero_f32(C, M * N)
    if M < SMALL_MAT_THRESHOLD and N < SMALL_MAT_THRESHOLD and K < SMALL_MAT_THRESHOLD:
        matmul_small_f32(C, A, B, M, N, K)
    else:
        matmul_tiled_parallel_f32[32, 32, 32](C, A, B, M, N, K)


# === Transpose ===============================================================================


alias TRANSPOSE_BLOCK: Int = 32


fn transpose_out_f32(dst: F32Ptr, src: F32Ptr, rows: Int, cols: Int):
    """Out-of-place transpose: ``dst[cols×rows] = src[rows×cols]ᵀ``; blocked for L1/L2 locality."""
    for ii in range(0, rows, TRANSPOSE_BLOCK):
        var i_end = _min(ii + TRANSPOSE_BLOCK, rows)
        for jj in range(0, cols, TRANSPOSE_BLOCK):
            var j_end = _min(jj + TRANSPOSE_BLOCK, cols)
            for i in range(ii, i_end):
                for j in range(jj, j_end):
                    dst[j * rows + i] = src[i * cols + j]


fn transpose_inplace_square_f32(p: F32Ptr, n: Int):
    """In-place transpose for square ``n×n`` row-major matrix (swap across diagonal)."""
    for i in range(n):
        for j in range(i + 1, n):
            var a = p[i * n + j]
            var b = p[j * n + i]
            p[i * n + j] = b
            p[j * n + i] = a


# === Hadamard / element-wise =================================================================


fn mat_elem_add_f32(dst: F32Ptr, a: F32Ptr, b: F32Ptr, count: Int):
    var i: Int = 0
    while i + W <= count:
        var va = (a + i).load[width=W]()
        var vb = (b + i).load[width=W]()
        (dst + i).store[width=W](va + vb)
        i += W
    while i < count:
        var va1 = (a + i).load[width=1]()
        var vb1 = (b + i).load[width=1]()
        (dst + i).store[width=1](va1 + vb1)
        i += 1


fn mat_elem_sub_f32(dst: F32Ptr, a: F32Ptr, b: F32Ptr, count: Int):
    var i: Int = 0
    while i + W <= count:
        var va = (a + i).load[width=W]()
        var vb = (b + i).load[width=W]()
        (dst + i).store[width=W](va - vb)
        i += W
    while i < count:
        var va1 = (a + i).load[width=1]()
        var vb1 = (b + i).load[width=1]()
        (dst + i).store[width=1](va1 - vb1)
        i += 1


fn mat_elem_mul_f32(dst: F32Ptr, a: F32Ptr, b: F32Ptr, count: Int):
    var i: Int = 0
    while i + W <= count:
        var va = (a + i).load[width=W]()
        var vb = (b + i).load[width=W]()
        (dst + i).store[width=W](va * vb)
        i += W
    while i < count:
        var va1 = (a + i).load[width=1]()
        var vb1 = (b + i).load[width=1]()
        (dst + i).store[width=1](va1 * vb1)
        i += 1


# === Frobenius norm =========================================================================


fn matrix_norm_frobenius_f32(a: F32Ptr, rows: Int, cols: Int) -> Float32:
    """``sqrt(Σ a_ij²)`` over row-major ``rows×cols``."""
    var acc = Float32(0.0)
    var n = rows * cols
    var i: Int = 0
    while i + W <= n:
        var v = (a + i).load[width=W]()
        var sq = v * v
        acc += sq.reduce_add()
        i += W
    while i < n:
        var xv = (a + i).load[width=1]()
        var x = xv.reduce_add()
        acc += x * x
        i += 1
    return acc.sqrt()
