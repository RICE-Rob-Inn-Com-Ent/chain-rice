# Radix-2 Cooley–Tukey FFT / IFFT (power-of-two), 2D FFT, Hann/Hamming windows, spectrogram power.
# Complex layout: `Complex32` (re, im); buffers are `UnsafePointer[Complex32]` — interleaved pairs
# match `float32` pairs in `bridge.py` / `RiceArray` (zero-copy as `reinterpret_cast` on host).

from algorithm import parallelize
from math import cos, sin
from memory.unsafe_pointer import UnsafePointer
from sys.info import num_physical_cores

from .simd import F32x4, F32x8, NATIVE_F32_LANES, v_mul

alias W: Int = NATIVE_F32_LANES
alias F32Ptr = UnsafePointer[Scalar[DType.float32]]

alias TWO_PI: Float32 = 6.283185307179586


# === Complex ================================================================================


@register_passable("trivial")
struct Complex32:
    var re: Float32
    var im: Float32


alias Complex32Ptr = UnsafePointer[Complex32]


@always_inline
fn cconj(c: Complex32) -> Complex32:
    return Complex32 {re: c.re, im: -c.im}


@always_inline
fn cadd(a: Complex32, b: Complex32) -> Complex32:
    return Complex32 {re: a.re + b.re, im: a.im + b.im}


@always_inline
fn csub(a: Complex32, b: Complex32) -> Complex32:
    return Complex32 {re: a.re - b.re, im: a.im - b.im}


@always_inline
fn cmul(a: Complex32, b: Complex32) -> Complex32:
    return Complex32 {
        re: a.re * b.re - a.im * b.im,
        im: a.re * b.im + a.im * b.re,
    }


@always_inline
fn cadd_simd[lanes: Int](
    re_a: SIMD[DType.float32, lanes],
    im_a: SIMD[DType.float32, lanes],
    re_b: SIMD[DType.float32, lanes],
    im_b: SIMD[DType.float32, lanes],
) -> (SIMD[DType.float32, lanes], SIMD[DType.float32, lanes]):
    return (re_a + re_b, im_a + im_b)


@always_inline
fn cmul_simd[lanes: Int](
    re_a: SIMD[DType.float32, lanes],
    im_a: SIMD[DType.float32, lanes],
    re_b: SIMD[DType.float32, lanes],
    im_b: SIMD[DType.float32, lanes],
) -> (SIMD[DType.float32, lanes], SIMD[DType.float32, lanes]):
    return (
        re_a * re_b - im_a * im_b,
        re_a * im_b + im_a * re_b,
    )


# === Power-of-two & bit reversal ==============================================================


@always_inline
fn is_power_of_two(n: Int) -> Bool:
    return n > 0 and ((n & (n - 1)) == 0)


@always_inline
fn log2_int(n: Int) -> Int:
    var b: Int = 0
    var t = n
    while t > 1:
        t >>= 1
        b += 1
    return b


@always_inline
fn reverse_bits(x: Int, bits: Int) -> Int:
    var r: Int = 0
    var v = x
    for _ in range(bits):
        r = (r << 1) | (v & 1)
        v >>= 1
    return r


fn bit_reverse_permute(data: Complex32Ptr, n: Int, bits: Int):
    for j in range(n):
        var r = reverse_bits(j, bits)
        if j < r:
            var tmp = data[j]
            data[j] = data[r]
            data[r] = tmp


# === Twiddle tables (pre-compute for hot FFT paths) =========================================


fn fft_prepare_twiddles_forward(lut: Complex32Ptr, n: Int):
    """Fill ``lut[k] = exp(-2π i k / n)`` for ``k = 0 .. n-1`` (``n`` power of two)."""
    var nf = Float32(n)
    for k in range(n):
        var ang = -TWO_PI * Float32(k) / nf
        lut[k] = Complex32 {re: cos(ang), im: sin(ang)}


fn fft_prepare_twiddles_inverse(lut: Complex32Ptr, n: Int):
    """Fill ``lut[k] = exp(+2π i k / n)`` (conjugate of forward roots)."""
    var nf = Float32(n)
    for k in range(n):
        var ang = TWO_PI * Float32(k) / nf
        lut[k] = Complex32 {re: cos(ang), im: sin(ang)}


# === Radix-2 Cooley–Tukey DIT (in-place) =====================================================


fn fft_dit_inplace(data: Complex32Ptr, n: Int, lut: Complex32Ptr):
    """In-place DIT FFT; ``lut`` from ``fft_prepare_twiddles_forward``."""
    var bits = log2_int(n)
    bit_reverse_permute(data, n, bits)
    var m: Int = 2
    while m <= n:
        var half = m >> 1
        for k in range(0, n, m):
            for j in range(half):
                var idx = k + j
                var idx2 = k + j + half
                var widx = (j * n) // m
                var w = lut[widx]
                var u = data[idx]
                var v = cmul(w, data[idx2])
                data[idx] = cadd(u, v)
                data[idx2] = csub(u, v)
        m <<= 1


fn fft_1d(data: Complex32Ptr, n: Int, lut: Complex32Ptr):
    """Forward FFT in-place; ``n`` power of two; ``lut`` length ``n`` (forward twiddles)."""
    if not is_power_of_two(n):
        return
    fft_dit_inplace(data, n, lut)


fn ifft_1d(data: Complex32Ptr, n: Int, lut_inv: Complex32Ptr):
    """Inverse FFT in-place; ``lut_inv`` from ``fft_prepare_twiddles_inverse``; scales ``1/n``."""
    if not is_power_of_two(n):
        return
    fft_dit_inplace(data, n, lut_inv)
    var invn = Float32(1.0) / Float32(n)
    for i in range(n):
        var c = data[i]
        data[i] = Complex32 {re: c.re * invn, im: c.im * invn}


# === 2D FFT (row-major ``rows × cols`` complex) ==============================================


fn fft_2d(
    data: Complex32Ptr,
    rows: Int,
    cols: Int,
    lut_cols: Complex32Ptr,
    lut_rows: Complex32Ptr,
    row_tmp: Complex32Ptr,
):
    """Row-wise then column-wise FFT in-place. ``lut_cols`` length ``cols``, ``lut_rows`` length ``rows``."""
    if not is_power_of_two(rows) or not is_power_of_two(cols):
        return
    var workers = num_physical_cores()
    if workers < 1:
        workers = 1

    def row_job(r: Int):
        fft_1d(data + r * cols, cols, lut_cols)

    parallelize[row_job](rows, workers)

    for c in range(cols):
        for r in range(rows):
            row_tmp[r] = data[r * cols + c]
        fft_1d(row_tmp, rows, lut_rows)
        for r in range(rows):
            data[r * cols + c] = row_tmp[r]


# === Windows (real-valued, bridge-compatible `F32Ptr`) =======================================


@always_inline
fn _hann_coeff(n: Int, i: Int) -> Float32:
    if n <= 1:
        return 1.0
    var x = TWO_PI * Float32(i) / Float32(n - 1)
    return Float32(0.5) * (Float32(1.0) - cos(x))


@always_inline
fn _hamming_coeff(n: Int, i: Int) -> Float32:
    if n <= 1:
        return 1.0
    var x = TWO_PI * Float32(i) / Float32(n - 1)
    return Float32(0.54) - Float32(0.46) * cos(x)


fn apply_hann_window(x: F32Ptr, n: Int):
    var i: Int = 0
    while i + W <= n:
        var w = SIMD[DType.float32, W]()
        for lane in range(W):
            w[lane] = _hann_coeff(n, i + lane)
        var v = (x + i).load[width=W]()
        (x + i).store[width=W](v_mul[DType.float32, W](v, w))
        i += W
    while i < n:
        var w1 = _hann_coeff(n, i)
        var v1 = (x + i).load[width=1]()
        (x + i).store[width=1](v_mul[DType.float32, 1](v1, SIMD[DType.float32, 1](w1)))
        i += 1


fn apply_hamming_window(x: F32Ptr, n: Int):
    var i: Int = 0
    while i + W <= n:
        var w = SIMD[DType.float32, W]()
        for lane in range(W):
            w[lane] = _hamming_coeff(n, i + lane)
        var v = (x + i).load[width=W]()
        (x + i).store[width=W](v_mul[DType.float32, W](v, w))
        i += W
    while i < n:
        var w1 = _hamming_coeff(n, i)
        var v1 = (x + i).load[width=1]()
        (x + i).store[width=1](v_mul[DType.float32, 1](v1, SIMD[DType.float32, 1](w1)))
        i += 1


# === Spectrogram (|FFT|²) ====================================================================


fn spectrogram_mag2(src: Complex32Ptr, dst: F32Ptr, n: Int):
    """``dst[i] = re² + im²`` for each bin (vectorized where possible)."""
    var i: Int = 0
    while i + W <= n:
        var res = SIMD[DType.float32, W]()
        var ims = SIMD[DType.float32, W]()
        for lane in range(W):
            var c = src[i + lane]
            res[lane] = c.re
            ims[lane] = c.im
        var mag2 = res * res + ims * ims
        (dst + i).store[width=W](mag2)
        i += W
    while i < n:
        var c = src[i]
        var m2 = c.re * c.re + c.im * c.im
        (dst + i).store[width=1](SIMD[DType.float32, 1](m2))
        i += 1


# === Legacy N=4 real DFT + stubs (`__init__.mojo`) ============================================


fn dft4_real_f32(x: F32x4) -> F32x8:
    """Real DFT N=4 → eight floats (Re, Im) × four bins."""
    var x0 = x[0]
    var x1 = x[1]
    var x2 = x[2]
    var x3 = x[3]
    var r0 = x0 + x1 + x2 + x3
    var i0 = Float32(0.0)
    var r1 = x0 - x2
    var i1 = x3 - x1
    var r2 = x0 - x1 + x2 - x3
    var i2 = Float32(0.0)
    var r3 = x0 - x2
    var i3 = x1 - x3
    return F32x8(r0, i0, r1, i1, r2, i2, r3, i3)


fn hann_window_4() -> F32x4:
    """Four-sample Hann approximation (legacy)."""
    return F32x4(0.0, 0.5, 1.0, 0.5)


fn ifft4_real_energy_placeholder(spectrum: F32x8) -> F32x4:
    """Per-bin energy proxy from packed spectrum (legacy stub)."""
    var e0 = spectrum[0] * spectrum[0] + spectrum[1] * spectrum[1]
    var e1 = spectrum[2] * spectrum[2] + spectrum[3] * spectrum[3]
    var e2 = spectrum[4] * spectrum[4] + spectrum[5] * spectrum[5]
    var e3 = spectrum[6] * spectrum[6] + spectrum[7] * spectrum[7]
    return F32x4(e0, e1, e2, e3)
