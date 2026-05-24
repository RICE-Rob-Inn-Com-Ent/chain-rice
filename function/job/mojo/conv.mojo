# 1D/2D convolution, depthwise + pointwise, pooling — SIMD FMA, tiling, parallel strips.
# Pointers: `UnsafePointer[Scalar[DType.float32]]` (same as `matrix.mojo` / `bridge.py`).
# Strip parallelism: `algorithm.parallelize` (SAGE “parallel_for” over rows / 1D offsets).

from algorithm import parallelize
from memory.unsafe_pointer import UnsafePointer
from sys.info import num_physical_cores

from .simd import F32x8, NATIVE_F32_LANES, v_fma, v_max, v_sum

alias F32Ptr = UnsafePointer[Scalar[DType.float32]]
alias W: Int = NATIVE_F32_LANES

alias CONV_PAD_ZERO: Int = 0
alias CONV_PAD_MIRROR: Int = 1

alias POOL_K2: Int = 2
alias POOL_K3: Int = 3

alias CONV2D_TILE: Int = 32


# === Legacy 8-lane 3-tap (`__init__.mojo`) ===================================================


fn conv1d_same_f32x8_k3(x: F32x8, k0: Float32, k1: Float32, k2: Float32) -> F32x8:
    """1D 3-tap “same” on an ``F32x8`` register (edge replicate)."""
    var o0 = k0 * x[0] + k1 * x[0] + k2 * x[1]
    var o1 = k0 * x[0] + k1 * x[1] + k2 * x[2]
    var o2 = k0 * x[1] + k1 * x[2] + k2 * x[3]
    var o3 = k0 * x[2] + k1 * x[3] + k2 * x[4]
    var o4 = k0 * x[3] + k1 * x[4] + k2 * x[5]
    var o5 = k0 * x[4] + k1 * x[5] + k2 * x[6]
    var o6 = k0 * x[5] + k1 * x[6] + k2 * x[7]
    var o7 = k0 * x[6] + k1 * x[7] + k2 * x[7]
    return F32x8(o0, o1, o2, o3, o4, o5, o6, o7)


# === Helpers ================================================================================


@always_inline
fn _min_i(a: Int, b: Int) -> Int:
    return a if a < b else b


@always_inline
fn _max_i(a: Int, b: Int) -> Int:
    return a if a > b else b


@always_inline
fn _ceil_div(a: Int, b: Int) -> Int:
    return (a + b - 1) // b


@always_inline
fn _mirror_idx(i: Int, n: Int) -> Int:
    if n <= 1:
        return 0
    var m = i % (2 * n - 2)
    if m < n:
        return m
    return 2 * n - 2 - m


@always_inline
fn _at1d(s: F32Ptr, n: Int, i: Int, boundary: Int) -> Float32:
    if boundary == CONV_PAD_MIRROR:
        return s[_mirror_idx(i, n)]
    if i < 0 or i >= n:
        return 0.0
    return s[i]


@always_inline
fn _at2d(im: F32Ptr, rows: Int, cols: Int, r: Int, c: Int, boundary: Int) -> Float32:
    if boundary == CONV_PAD_MIRROR:
        return im[_mirror_idx(r, rows) * cols + _mirror_idx(c, cols)]
    if r < 0 or r >= rows or c < 0 or c >= cols:
        return 0.0
    return im[r * cols + c]


@always_inline
fn _fma1(s: Float32, k: Float32, acc: SIMD[DType.float32, 1]) -> SIMD[DType.float32, 1]:
    return v_fma[DType.float32, 1](SIMD[DType.float32, 1](s), SIMD[DType.float32, 1](k), acc)


# === 1D convolution =========================================================================


fn conv1d(
    signal: F32Ptr,
    kernel: F32Ptr,
    output: F32Ptr,
    s_len: Int,
    k_len: Int,
    boundary: Int,
):
    """Valid conv: ``output[o] = Σ_t kernel[t] * sample(o+t)``, length ``s_len - k_len + 1``."""
    if k_len <= 0 or s_len < k_len:
        return
    var out_len = s_len - k_len + 1
    var workers = _max_i(1, num_physical_cores())

    def strip(worker_id: Int):
        var o = worker_id
        while o < out_len:
            var acc = SIMD[DType.float32, 1](0.0)
            if k_len == 3 and boundary == CONV_PAD_ZERO:
                acc = _fma1(
                    signal[o + 0], (kernel + 0).load[width=1]().reduce_add(), acc
                )
                acc = _fma1(
                    signal[o + 1], (kernel + 1).load[width=1]().reduce_add(), acc
                )
                acc = _fma1(
                    signal[o + 2], (kernel + 2).load[width=1]().reduce_add(), acc
                )
            elif k_len == 5 and boundary == CONV_PAD_ZERO:
                acc = _fma1(
                    signal[o + 0], (kernel + 0).load[width=1]().reduce_add(), acc
                )
                acc = _fma1(
                    signal[o + 1], (kernel + 1).load[width=1]().reduce_add(), acc
                )
                acc = _fma1(
                    signal[o + 2], (kernel + 2).load[width=1]().reduce_add(), acc
                )
                acc = _fma1(
                    signal[o + 3], (kernel + 3).load[width=1]().reduce_add(), acc
                )
                acc = _fma1(
                    signal[o + 4], (kernel + 4).load[width=1]().reduce_add(), acc
                )
            else:
                for t in range(k_len):
                    var sv = _at1d(signal, s_len, o + t, boundary)
                    var kv = (kernel + t).load[width=1]().reduce_add()
                    acc = _fma1(sv, kv, acc)
            output[o] = acc.reduce_add()
            o += workers

    parallelize[strip](workers, workers)


# === 2D convolution (tiled over output space) ================================================


@always_inline
fn _eff_ks(k_size: Int, dilation: Int) -> Int:
    return (k_size - 1) * dilation + 1


@always_inline
fn _conv2d_one(
    im: F32Ptr,
    rows: Int,
    cols: Int,
    or_: Int,
    oc: Int,
    kernel: F32Ptr,
    k_size: Int,
    stride: Int,
    dilation: Int,
    boundary: Int,
) -> Float32:
    var acc = SIMD[DType.float32, 1](0.0)
    var tap: Int = 0
    for kr in range(k_size):
        for kc in range(k_size):
            var rr = or_ * stride + kr * dilation
            var cc = oc * stride + kc * dilation
            var sv = _at2d(im, rows, cols, rr, cc, boundary)
            var kv = (kernel + tap).load[width=1]().reduce_add()
            acc = _fma1(sv, kv, acc)
            tap += 1
    return acc.reduce_add()


@always_inline
fn _conv2d_one_k3(
    im: F32Ptr,
    rows: Int,
    cols: Int,
    or_: Int,
    oc: Int,
    kernel: F32Ptr,
    stride: Int,
    dilation: Int,
    boundary: Int,
) -> Float32:
    """Fast path: 3×3, taps row-major in ``kernel``."""
    var acc = SIMD[DType.float32, 1](0.0)
    var tap: Int = 0
    for kr in range(3):
        for kc in range(3):
            var rr = or_ * stride + kr * dilation
            var cc = oc * stride + kc * dilation
            var sv = _at2d(im, rows, cols, rr, cc, boundary)
            var kv = (kernel + tap).load[width=1]().reduce_add()
            acc = _fma1(sv, kv, acc)
            tap += 1
    return acc.reduce_add()


@always_inline
fn _conv2d_one_k5(
    im: F32Ptr,
    rows: Int,
    cols: Int,
    or_: Int,
    oc: Int,
    kernel: F32Ptr,
    stride: Int,
    dilation: Int,
    boundary: Int,
) -> Float32:
    """Fast path: 5×5."""
    var acc = SIMD[DType.float32, 1](0.0)
    var tap: Int = 0
    for kr in range(5):
        for kc in range(5):
            var rr = or_ * stride + kr * dilation
            var cc = oc * stride + kc * dilation
            var sv = _at2d(im, rows, cols, rr, cc, boundary)
            var kv = (kernel + tap).load[width=1]().reduce_add()
            acc = _fma1(sv, kv, acc)
            tap += 1
    return acc.reduce_add()


fn conv2d(
    image: F32Ptr,
    kernel: F32Ptr,
    output: F32Ptr,
    rows: Int,
    cols: Int,
    k_size: Int,
    stride: Int,
    dilation: Int,
    boundary: Int,
):
    """2D valid conv, row-major. ``kernel`` length ``k_size*k_size`` (row-major taps)."""
    var ks = _eff_ks(k_size, dilation)
    if k_size <= 0 or stride <= 0 or dilation <= 0:
        return
    if rows < ks or cols < ks:
        return
    var out_r = (rows - ks) // stride + 1
    var out_c = (cols - ks) // stride + 1
    if out_r <= 0 or out_c <= 0:
        return
    var workers = _max_i(1, num_physical_cores())

    def strip_row(wid: Int):
        var br0 = wid * CONV2D_TILE
        while br0 < out_r:
            var br1 = _min_i(br0 + CONV2D_TILE, out_r)
            var bc0: Int = 0
            while bc0 < out_c:
                var bc1 = _min_i(bc0 + CONV2D_TILE, out_c)
                for or_ in range(br0, br1):
                    for oc in range(bc0, bc1):
                        var v: Float32
                        if k_size == 3:
                            v = _conv2d_one_k3(
                                image, rows, cols, or_, oc, kernel, stride, dilation, boundary
                            )
                        elif k_size == 5:
                            v = _conv2d_one_k5(
                                image, rows, cols, or_, oc, kernel, stride, dilation, boundary
                            )
                        else:
                            v = _conv2d_one(
                                image,
                                rows,
                                cols,
                                or_,
                                oc,
                                kernel,
                                k_size,
                                stride,
                                dilation,
                                boundary,
                            )
                        output[or_ * out_c + oc] = v
                bc0 += CONV2D_TILE
            br0 += workers * CONV2D_TILE

    parallelize[strip_row](workers, workers)


# === Depthwise + pointwise (single-channel + 1×1 mix) =======================================


fn depthwise_conv2d_f32(
    image: F32Ptr,
    dw_kernel: F32Ptr,
    tmp: F32Ptr,
    rows: Int,
    cols: Int,
    k_size: Int,
    stride: Int,
    dilation: Int,
    boundary: Int,
):
    """Depthwise spatial conv (one channel): writes ``tmp`` same layout as ``image`` (valid size)."""
    conv2d(image, dw_kernel, tmp, rows, cols, k_size, stride, dilation, boundary)


fn pointwise_1x1_f32(
    src: F32Ptr,
    dst: F32Ptr,
    weights: F32Ptr,
    n: Int,
):
    """``dst[i] = src[i] * weights[i]`` — length ``n`` (1×1 per spatial index)."""
    var i: Int = 0
    while i + W <= n:
        var a = (src + i).load[width=W]()
        var b = (weights + i).load[width=W]()
        (dst + i).store[width=W](a * b)
        i += W
    while i < n:
        var a1 = (src + i).load[width=1]().reduce_add()
        var b1 = (weights + i).load[width=1]().reduce_add()
        (dst + i).store[width=1](SIMD[DType.float32, 1](a1 * b1))
        i += 1


fn depthwise_separable_conv2d_f32(
    image: F32Ptr,
    dw_kernel: F32Ptr,
    pw_weights: F32Ptr,
    tmp: F32Ptr,
    out: F32Ptr,
    rows: Int,
    cols: Int,
    k_size: Int,
    stride: Int,
    dilation: Int,
    boundary: Int,
):
    """``out = PW( DW(image) )`` with intermediate in ``tmp`` (same shapes as ``conv2d`` output)."""
    var ks = _eff_ks(k_size, dilation)
    var out_r = (rows - ks) // stride + 1
    var out_c = (cols - ks) // stride + 1
    var n = out_r * out_c
    depthwise_conv2d_f32(
        image, dw_kernel, tmp, rows, cols, k_size, stride, dilation, boundary
    )
    pointwise_1x1_f32(tmp, out, pw_weights, n)


# === Pooling =================================================================================


@always_inline
fn _pool_out_dim(dim: Int, k: Int, stride: Int) -> Int:
    return (dim - k) // stride + 1


fn max_pool2d_k2_f32(
    src: F32Ptr, dst: F32Ptr, rows: Int, cols: Int, stride: Int, boundary: Int
):
    """2×2 max pool, ``stride`` on output grid; uses horizontal ``v_max`` on 2×2 SIMD bundle."""
    var or_ = _pool_out_dim(rows, POOL_K2, stride)
    var oc = _pool_out_dim(cols, POOL_K2, stride)
    for i in range(or_):
        for j in range(oc):
            var r0 = i * stride
            var c0 = j * stride
            var v00 = _at2d(src, rows, cols, r0 + 0, c0 + 0, boundary)
            var v01 = _at2d(src, rows, cols, r0 + 0, c0 + 1, boundary)
            var v10 = _at2d(src, rows, cols, r0 + 1, c0 + 0, boundary)
            var v11 = _at2d(src, rows, cols, r0 + 1, c0 + 1, boundary)
            var q = SIMD[DType.float32, 4](v00, v01, v10, v11)
            dst[i * oc + j] = v_max[4](q)


@always_inline
fn _max_f32(a: Float32, b: Float32) -> Float32:
    return a if a > b else b


fn max_pool2d_k3_f32(
    src: F32Ptr, dst: F32Ptr, rows: Int, cols: Int, stride: Int, boundary: Int
):
    """3×3 max pool; scalar scan (nine taps), branchless max via ``_max_f32``."""
    var or_ = _pool_out_dim(rows, POOL_K3, stride)
    var oc = _pool_out_dim(cols, POOL_K3, stride)
    for i in range(or_):
        for j in range(oc):
            var r0 = i * stride
            var c0 = j * stride
            var m: Float32 = _at2d(src, rows, cols, r0, c0, boundary)
            for dr in range(3):
                for dc in range(3):
                    var val = _at2d(src, rows, cols, r0 + dr, c0 + dc, boundary)
                    m = _max_f32(m, val)
            dst[i * oc + j] = m


fn avg_pool2d_k2_f32(
    src: F32Ptr, dst: F32Ptr, rows: Int, cols: Int, stride: Int, boundary: Int
):
    """2×2 average pool; ``v_sum`` on the 2×2 patch packed as ``SIMD[4]``."""
    var or_ = _pool_out_dim(rows, POOL_K2, stride)
    var oc = _pool_out_dim(cols, POOL_K2, stride)
    for i in range(or_):
        for j in range(oc):
            var r0 = i * stride
            var c0 = j * stride
            var v00 = _at2d(src, rows, cols, r0 + 0, c0 + 0, boundary)
            var v01 = _at2d(src, rows, cols, r0 + 0, c0 + 1, boundary)
            var v10 = _at2d(src, rows, cols, r0 + 1, c0 + 0, boundary)
            var v11 = _at2d(src, rows, cols, r0 + 1, c0 + 1, boundary)
            var q = SIMD[DType.float32, 4](v00, v01, v10, v11)
            dst[i * oc + j] = v_sum[4](q) * (1.0 / 4.0)


fn avg_pool2d_k3_f32(
    src: F32Ptr, dst: F32Ptr, rows: Int, cols: Int, stride: Int, boundary: Int
):
    """3×3 average pool; two ``v_sum`` passes (4 + 4) + tail scalar."""
    var or_ = _pool_out_dim(rows, POOL_K3, stride)
    var oc = _pool_out_dim(cols, POOL_K3, stride)
    for i in range(or_):
        for j in range(oc):
            var r0 = i * stride
            var c0 = j * stride
            var a0 = _at2d(src, rows, cols, r0 + 0, c0 + 0, boundary)
            var a1 = _at2d(src, rows, cols, r0 + 0, c0 + 1, boundary)
            var a2 = _at2d(src, rows, cols, r0 + 0, c0 + 2, boundary)
            var a3 = _at2d(src, rows, cols, r0 + 1, c0 + 0, boundary)
            var a4 = _at2d(src, rows, cols, r0 + 1, c0 + 1, boundary)
            var a5 = _at2d(src, rows, cols, r0 + 1, c0 + 2, boundary)
            var a6 = _at2d(src, rows, cols, r0 + 2, c0 + 0, boundary)
            var a7 = _at2d(src, rows, cols, r0 + 2, c0 + 1, boundary)
            var a8 = _at2d(src, rows, cols, r0 + 2, c0 + 2, boundary)
            var q0 = SIMD[DType.float32, 4](a0, a1, a2, a3)
            var q1 = SIMD[DType.float32, 4](a4, a5, a6, a7)
            var s = v_sum[4](q0) + v_sum[4](q1) + a8
            dst[i * oc + j] = s * (1.0 / 9.0)
