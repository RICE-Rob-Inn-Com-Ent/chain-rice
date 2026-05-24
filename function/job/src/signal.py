"""DSP / spectral analysis — NumPy & SciPy core, optional Mojo kernels via :mod:`bridge`.

Hot paths use vectorized NumPy / SciPy. When ``RICE_MOJO_SIGNAL_*`` env flags are set and
matching symbols exist in the shared library, :func:`bridge.execute_kernel` runs in-place
on C-contiguous buffers (pinned via :func:`memory.anchor` inside the bridge).

Complex-valued work uses NumPy ``complex64`` / ``complex128``; :class:`array.RiceArray`
accepts ``complex64`` as input and returns arrays in the complex domain as ``ndarray``
unless the result dtype is allowed for :class:`array.RiceArray` (see ``as_rice``).
"""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import os
import time
from typing import Any, Literal, TypeVar, cast

import numpy as np
from loguru import logger
from numpy.typing import NDArray
from scipy import signal

from . import const

from .array import RiceArray

_ArrayT = TypeVar("_ArrayT", bound=np.generic)

# --- Optional Mojo symbol names (override via env) ---------------------------------
_MOJO_LIB = os.getenv("RICE_MOJO_SIGNAL_LIB", const.RICE_MOJO_ARRAY_LIB).strip() or const.RICE_MOJO_ARRAY_LIB
_MOJO_FFT_SYM = os.getenv("RICE_MOJO_SIGNAL_FFT_SYMBOL", "rice_signal_fft").strip() or "rice_signal_fft"
_MOJO_CONV_SYM = os.getenv("RICE_MOJO_SIGNAL_CONV_SYMBOL", "rice_signal_conv").strip() or "rice_signal_conv"


def _mojo_fft_enabled() -> bool:
    return os.getenv("RICE_MOJO_SIGNAL_FFT_ENABLE", "").strip().lower() in {"1", "true", "yes", "on"}


def _mojo_conv_enabled() -> bool:
    return os.getenv("RICE_MOJO_SIGNAL_CONV_ENABLE", "").strip().lower() in {"1", "true", "yes", "on"}


def _log_signal(
    name: str,
    t0: float,
    *,
    fs: float | None = None,
    shape: tuple[int, ...] | None = None,
    nbytes: int | None = None,
    backend: str = "numpy",
    extra: str = "",
) -> None:
    logger.info(
        "signal op={} wall_ms={:.2f} fs={} shape={} nbytes={} backend={} {}",
        name,
        (time.perf_counter() - t0) * 1000,
        fs,
        shape,
        nbytes,
        backend,
        extra,
    )


def _as_ndarray(data: NDArray[Any] | RiceArray) -> NDArray[Any]:
    if isinstance(data, RiceArray):  # type: ignore[arg-type]
        return data.data
    return np.asarray(data)


def _maybe_rice_array(
    arr: NDArray[_ArrayT],
    *,
    like: NDArray[Any] | RiceArray | None,
    as_rice: bool,
) -> NDArray[_ArrayT] | RiceArray:
    if not as_rice or like is None or not isinstance(like, RiceArray):  # type: ignore[arg-type]
        return arr
    try:
        return RiceArray(arr, copy=False)  # type: ignore[call-arg]
    except TypeError:
        return arr


def _try_mojo_inplace_1d_f32(x: NDArray[np.float32], symbol: str) -> bool:
    """Return True if a native in-place kernel ran successfully (buffer ABI: one f32 vector)."""
    if x.ndim != 1 or x.dtype != np.float32 or not x.flags.c_contiguous:
        return False
    try:
        from .bridge import KernelNotFoundError, execute_kernel, get_kernel
    except ImportError:  # pragma: no cover
        return False
    try:
        fn = get_kernel(_MOJO_LIB, symbol, n_buffers=1)
    except KernelNotFoundError:
        return False
    try:
        execute_kernel(fn, x)
    except Exception:
        logger.exception("signal Mojo kernel failed symbol={}", symbol)
        return False
    return True


# --- FFT / spectrum -----------------------------------------------------------------


def fft(
    data: NDArray[Any] | RiceArray,
    *,
    axes: tuple[int, ...] | None = None,
    norm: Literal["backward", "ortho", "forward"] | None = None,
    use_mojo: bool = False,
) -> NDArray[np.complexfloating]:
    """N-dimensional complex FFT (1D / 2D / batched via ``axes``).

    ``use_mojo``: when ``RICE_MOJO_SIGNAL_FFT_ENABLE`` is set, attempts an in-place kernel
    named ``RICE_MOJO_SIGNAL_FFT_SYMBOL`` (default ``rice_signal_fft``) on a **1-D**
    ``float32`` buffer via :func:`bridge.execute_kernel` (memory anchored in the bridge).
    Until the shared library exports a documented complex layout, the implementation
    **falls back to NumPy** after logging.
    """
    t0 = time.perf_counter()
    x = np.ascontiguousarray(_as_ndarray(data))
    if use_mojo and _mojo_fft_enabled() and x.ndim == 1 and x.dtype == np.float32:
        probe = np.ascontiguousarray(x, dtype=np.float32).copy()
        if _try_mojo_inplace_1d_f32(probe, _MOJO_FFT_SYM):
            logger.warning(
                "fft: Mojo kernel {} ran on a probe buffer; output layout not interpreted — using NumPy",
                _MOJO_FFT_SYM,
            )
    if axes is None:
        if x.ndim == 1:
            out = np.fft.fft(x, norm=norm)
        elif x.ndim == 2:
            out = np.fft.fft2(x, norm=norm)
        else:
            out = np.fft.fftn(x, norm=norm)
    else:
        out = np.fft.fftn(x, axes=axes, norm=norm)
    _log_signal("fft", t0, shape=x.shape, nbytes=x.nbytes, backend="numpy")
    return cast(NDArray[np.complexfloating], out)


def ifft(
    data: NDArray[Any] | RiceArray,
    *,
    axes: tuple[int, ...] | None = None,
    norm: Literal["backward", "ortho", "forward"] | None = None,
    use_mojo: bool = False,
) -> NDArray[np.complexfloating]:
    """Inverse FFT; ``use_mojo`` reserved (same env as :func:`fft`) — NumPy until ABI is fixed."""
    t0 = time.perf_counter()
    if use_mojo and _mojo_fft_enabled():
        logger.debug("ifft use_mojo=True — using NumPy until IFFT Mojo ABI is wired")
    x = np.ascontiguousarray(_as_ndarray(data), dtype=np.complex128)
    if axes is None:
        if x.ndim == 1:
            out = np.fft.ifft(x, norm=norm)
        elif x.ndim == 2:
            out = np.fft.ifft2(x, norm=norm)
        else:
            out = np.fft.ifftn(x, norm=norm)
    else:
        out = np.fft.ifftn(x, axes=axes, norm=norm)
    _log_signal("ifft", t0, shape=x.shape, nbytes=x.nbytes, backend="numpy")
    return cast(NDArray[np.complexfloating], out)


def power_spectrum(
    data: NDArray[Any] | RiceArray,
    *,
    axes: tuple[int, ...] | None = None,
    norm: Literal["backward", "ortho", "forward"] | None = None,
) -> NDArray[np.floating]:
    """``|FFT(x)|**2`` for energy / PSD-style spectral density (per-bin, uncalibrated)."""
    t0 = time.perf_counter()
    spec = fft(data, axes=axes, norm=norm)
    ps = (np.abs(spec) ** 2).astype(np.float64, copy=False)
    _log_signal("power_spectrum", t0, shape=ps.shape, nbytes=ps.nbytes, backend="numpy")
    return cast(NDArray[np.floating], ps)


# --- Convolution / correlation --------------------------------------------------------


def convolve(
    sig: NDArray[Any] | RiceArray,
    kernel: NDArray[Any] | RiceArray,
    mode: Literal["full", "valid", "same"] = "full",
    *,
    method: Literal["auto", "direct", "fft"] = "auto",
    use_mojo: bool = False,
) -> NDArray[Any]:
    """1D / 2D convolution (SciPy); optional Mojo for 1-D ``float32`` ``same`` (symbol ``RICE_MOJO_SIGNAL_CONV_SYMBOL``)."""
    t0 = time.perf_counter()
    a = np.ascontiguousarray(_as_ndarray(sig))
    v = np.ascontiguousarray(_as_ndarray(kernel))
    if (
        use_mojo
        and _mojo_conv_enabled()
        and mode == "same"
        and a.ndim == 1
        and v.ndim == 1
        and a.dtype == np.float32
        and v.dtype == np.float32
    ):
        try:
            from .bridge import KernelNotFoundError, execute_kernel, get_kernel

            fn = get_kernel(_MOJO_LIB, _MOJO_CONV_SYM, n_buffers=2)
            out = np.ascontiguousarray(a, dtype=np.float32).copy()
            vv = np.ascontiguousarray(v, dtype=np.float32)
            execute_kernel(fn, out, vv)
            _log_signal("convolve", t0, shape=out.shape, nbytes=out.nbytes, backend="mojo")
            return out
        except KernelNotFoundError:
            logger.debug("convolve: kernel {} not in {}", _MOJO_CONV_SYM, _MOJO_LIB)
        except Exception:
            logger.exception("convolve: Mojo path failed; using SciPy")
    out = signal.convolve(a, v, mode=mode, method=method)
    _log_signal("convolve", t0, shape=out.shape, nbytes=int(out.nbytes), backend="scipy")
    return out


def cross_correlate(
    a: NDArray[Any] | RiceArray,
    b: NDArray[Any] | RiceArray,
    mode: Literal["full", "valid", "same"] = "full",
    *,
    method: Literal["auto", "direct", "fft"] = "auto",
) -> NDArray[Any]:
    """Cross-correlation ``signal.correlate(a, b)`` (lag detection / template matching)."""
    t0 = time.perf_counter()
    aa = np.ascontiguousarray(_as_ndarray(a))
    bb = np.ascontiguousarray(_as_ndarray(b))
    out = signal.correlate(aa, bb, mode=mode, method=method)
    _log_signal("cross_correlate", t0, shape=out.shape, nbytes=int(out.nbytes), backend="scipy")
    return out


# --- IIR design skeletons -------------------------------------------------------------


def lowpass(
    cutoff_hz: float,
    fs: float,
    *,
    order: int = 4,
    analog: bool = False,
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    """Butterworth low-pass; returns ``(b, a)`` for :func:`apply_filter`."""
    nyq = 0.5 * fs
    wn = cutoff_hz / nyq
    return signal.butter(order, wn, btype="low", analog=analog)


def highpass(
    cutoff_hz: float,
    fs: float,
    *,
    order: int = 4,
    analog: bool = False,
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    """Butterworth high-pass ``(b, a)``."""
    nyq = 0.5 * fs
    wn = cutoff_hz / nyq
    return signal.butter(order, wn, btype="high", analog=analog)


def bandpass(
    low_hz: float,
    high_hz: float,
    fs: float,
    *,
    order: int = 4,
    analog: bool = False,
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    """Butterworth band-pass ``(b, a)``."""
    nyq = 0.5 * fs
    wn = (low_hz / nyq, high_hz / nyq)
    return signal.butter(order, wn, btype="band", analog=analog)


def apply_filter(
    data: NDArray[Any] | RiceArray,
    b: NDArray[np.floating],
    a: NDArray[np.floating],
    *,
    axis: int = -1,
    as_rice: bool = False,
) -> NDArray[Any] | RiceArray:
    """IIR/FIR along ``axis`` via ``lfilter`` (vectorized SciPy core)."""
    t0 = time.perf_counter()
    x = _as_ndarray(data)
    b = np.asarray(b, dtype=np.float64)
    a = np.asarray(a, dtype=np.float64)
    y = signal.lfilter(b, a, x, axis=axis)
    _log_signal("apply_filter", t0, shape=y.shape, nbytes=int(y.nbytes), backend="scipy")
    return _maybe_rice_array(y, like=data, as_rice=as_rice)


# --- Windows ------------------------------------------------------------------------


def apply_window(
    data: NDArray[Any] | RiceArray,
    window_type: Literal["hann", "hamming", "blackman"] = "hann",
    *,
    axis: int = -1,
    periodic: bool = True,
    as_rice: bool = False,
) -> NDArray[Any] | RiceArray:
    """Multiply ``data`` by a SciPy window along ``axis`` (spectral leakage control)."""
    t0 = time.perf_counter()
    x = np.ascontiguousarray(_as_ndarray(data))
    n = x.shape[axis]
    sym = not periodic
    win = signal.get_window(window_type, n, fftbins=periodic)
    shape = [1] * x.ndim
    shape[axis] = n
    w = win.reshape(shape)
    y = x * w
    _log_signal(
        "apply_window",
        t0,
        shape=y.shape,
        nbytes=int(y.nbytes),
        backend="scipy",
        extra=f"type={window_type!r}",
    )
    return _maybe_rice_array(y, like=data, as_rice=as_rice)


# --- STFT / resample -----------------------------------------------------------------


def stft(
    data: NDArray[Any] | RiceArray,
    fs: float,
    *,
    nperseg: int = 256,
    noverlap: int | None = None,
    nfft: int | None = None,
    boundary: str | None = "zeros",
    padded: bool = True,
    axis: int = -1,
) -> tuple[NDArray[np.floating], NDArray[np.floating], NDArray[np.complexfloating]]:
    """Short-time Fourier transform: ``f``, ``t``, complex STFT matrix."""
    t0 = time.perf_counter()
    x = np.ascontiguousarray(_as_ndarray(data))
    if noverlap is None:
        noverlap = nperseg // 2
    f, t, Zxx = signal.stft(
        x,
        fs,
        nperseg=nperseg,
        noverlap=noverlap,
        nfft=nfft,
        boundary=boundary,
        padded=padded,
        axis=axis,
    )
    _log_signal(
        "stft",
        t0,
        fs=fs,
        shape=Zxx.shape,
        nbytes=int(Zxx.nbytes),
        backend="scipy",
        extra=f"nperseg={nperseg}",
    )
    return f, t, Zxx


def resample(
    data: NDArray[Any] | RiceArray,
    target_rate: float,
    *,
    source_rate: float,
    axis: int = -1,
    as_rice: bool = False,
) -> NDArray[Any] | RiceArray:
    """Resample along ``axis`` to a new implicit sample rate using FFT-based ``signal.resample``.

    Output length is ``round(input_len * target_rate / source_rate)`` on that axis.
    """
    t0 = time.perf_counter()
    if source_rate <= 0 or target_rate <= 0:
        msg = "source_rate and target_rate must be positive"
        raise ValueError(msg)
    x = np.ascontiguousarray(_as_ndarray(data))
    axis = axis % x.ndim
    n_in = x.shape[axis]
    n_out = max(1, int(round(n_in * target_rate / source_rate)))
    y = signal.resample(x, n_out, axis=axis)
    _log_signal(
        "resample",
        t0,
        fs=target_rate,
        shape=y.shape,
        nbytes=int(y.nbytes),
        backend="scipy",
        extra=f"source_rate={source_rate}",
    )
    return _maybe_rice_array(y, like=data, as_rice=as_rice)


# --- Legacy / convenience (unchanged API surface) -------------------------------------


def butter_lowpass(
    cutoff_hz: float,
    fs: float,
    *,
    order: int = 4,
) -> tuple[NDArray[np.floating], NDArray[np.floating]]:
    """Butterworth low-pass coefficients ``(b, a)`` (alias of :func:`lowpass`)."""
    return lowpass(cutoff_hz, fs, order=order)


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
) -> tuple[NDArray[np.intp], dict[str, Any]]:
    return signal.find_peaks(x, height=height, distance=distance)


__all__ = [
    "apply_filter",
    "apply_window",
    "bandpass",
    "butter_lowpass",
    "convolve",
    "convolve_same",
    "cross_correlate",
    "fft",
    "fft_rfft",
    "filtfilt_zero_phase",
    "find_peaks_1d",
    "highpass",
    "ifft",
    "lowpass",
    "power_spectrum",
    "resample",
    "stft",
    "welch_psd",
]
