# FFT — DFT 4-punktowe dla sygnału rzeczywistego (analitycznie); okno Hanning n=4.
# TODO:
# [ ] implement Cooley-Tukey FFT — radix-2 DIT
# [ ] implement SIMD-accelerated butterfly operations
# [ ] implement real FFT (rfft) — exploit conjugate symmetry
# [ ] implement batched FFT across multiple signals
# [ ] benchmark vs scipy.fft baseline

alias F32x4 = SIMD[DType.float32, 4]
alias F32x8 = SIMD[DType.float32, 8]


fn dft4_real_f32(x: F32x4) -> F32x8:
    """DFT rzeczywiste N=4 → 4 binów zespolonych (Re, Im) × 4."""
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
    """Okno Hanning dla 4 próbek (przybliżenie)."""
    return F32x4(0.0, 0.5, 1.0, 0.5)


fn ifft4_real_energy_placeholder(spectrum: F32x8) -> F32x4:
    """Placeholder IFFT — zwraca sumę modułów binów jako skalar per ćwiartka (stub)."""
    var e0 = spectrum[0] * spectrum[0] + spectrum[1] * spectrum[1]
    var e1 = spectrum[2] * spectrum[2] + spectrum[3] * spectrum[3]
    var e2 = spectrum[4] * spectrum[4] + spectrum[5] * spectrum[5]
    var e3 = spectrum[6] * spectrum[6] + spectrum[7] * spectrum[7]
    return F32x4(e0, e1, e2, e3)
