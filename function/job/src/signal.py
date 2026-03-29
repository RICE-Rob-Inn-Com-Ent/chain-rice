"""SciPy — przetwarzanie sygnałów: filtry, FFT, splot, widmo."""

from __future__ import annotations

import numpy as np
from numpy.typing import NDArray
from scipy import signal

# TODO:
# [ ] implement FFT via scipy.fft:
# [ ]     fft, ifft, rfft, irfft — all with configurable window functions
# [ ]     window type from RICE_FFT_WINDOW env var (default: hann)
# [ ] implement filtering: butter, chebyshev, elliptic filters
# [ ]     filter type, order, cutoff from config — not hardcoded
# [ ] implement convolution: scipy.signal.convolve, fftconvolve
# [ ]     mode: full|valid|same from config
# [ ] implement spectrogram: scipy.signal.spectrogram
# [ ]     nperseg, noverlap from RICE_SPEC_* env vars
# [ ] implement peak detection: scipy.signal.find_peaks
# [ ]     prominence, width, height thresholds from config
# [ ] implement correlation: scipy.signal.correlate, coherence


def butter_lowpass(
    cutoff_hz: float,
    fs: float,
    *,
    order: int = 4,
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    """Projekt filtru Butterwortha (lowpass)."""
    nyq = 0.5 * fs
    wn = cutoff_hz / nyq
    return signal.butter(order, wn, btype="low", analog=False)


def filtfilt_zero_phase(
    b: NDArray[np.floating],
    a: NDArray[np.floating],
    x: NDArray[np.floating],
) -> NDArray[np.floating]:
    return signal.filtfilt(b, a, x)


def fft_rfft(x: NDArray[np.floating]) -> NDArray[np.complexfloating]:
    return np.fft.rfft(x)


def convolve_same(
    a: NDArray[np.floating],
    v: NDArray[np.floating],
) -> NDArray[np.floating]:
    return signal.convolve(a, v, mode="same")


def welch_psd(
    x: NDArray[np.floating],
    fs: float,
    *,
    nperseg: int | None = None,
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    return signal.welch(x, fs=fs, nperseg=nperseg)


def find_peaks_1d(
    x: NDArray[np.floating],
    *,
    height: float | None = None,
    distance: int | None = None,
) -> tuple[NDArray[np.intp], dict]:
    return signal.find_peaks(x, height=height, distance=distance)
