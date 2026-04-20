# Konwolucja 1D — jądro 3-tap, tryb „same” na 8 próbkach (stub dla `job/signal.py` / symulacji).
# TODO:
# [ ] implement 1D convolution via SIMD
# [ ] implement 2D convolution with im2col optimization
# [ ] implement depthwise separable convolution
# [ ] implement dilated convolution — dilation factor as parameter

alias F32x8 = SIMD[DType.float32, 8]


fn conv1d_same_f32x8_k3(x: F32x8, k0: Float32, k1: Float32, k2: Float32) -> F32x8:
    """Splot z paddingiem brzegowym (powielenie skrajnych próbek)."""
    var o0 = k0 * x[0] + k1 * x[0] + k2 * x[1]
    var o1 = k0 * x[0] + k1 * x[1] + k2 * x[2]
    var o2 = k0 * x[1] + k1 * x[2] + k2 * x[3]
    var o3 = k0 * x[2] + k1 * x[3] + k2 * x[4]
    var o4 = k0 * x[3] + k1 * x[4] + k2 * x[5]
    var o5 = k0 * x[4] + k1 * x[5] + k2 * x[6]
    var o6 = k0 * x[5] + k1 * x[6] + k2 * x[7]
    var o7 = k0 * x[6] + k1 * x[7] + k2 * x[7]
    return F32x8(o0, o1, o2, o3, o4, o5, o6, o7)
