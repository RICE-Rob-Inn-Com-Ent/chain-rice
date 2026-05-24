# Monte Carlo — SIMD-friendly PRNG, GBM paths, Box–Muller, VaR / summaries (CLERK / .rice).
# Parallel batches use `algorithm.parallelize` (SAGE parallel_for); one xorshift128+ stream per worker.
# Bridge: `UnsafePointer[Scalar[DType.float32]]` for path buffers; `MonteSummary` is a compact stats bundle.

from algorithm import parallelize
from math import cos, sin
from memory.unsafe_pointer import UnsafePointer
from sys.info import num_physical_cores

from .simd import NATIVE_F32_LANES, v_exp, v_log, v_sqrt

alias W: Int = NATIVE_F32_LANES
alias F32Ptr = UnsafePointer[Scalar[DType.float32]]
alias F32x1 = SIMD[DType.float32, 1]
alias TWO_PI: Float32 = 6.283185307179586
alias EPS_U01: Float32 = 1.1920929e-7


# === Legacy LCG (deterministic; `__init__.mojo`) ==============================================


fn lcg_u64(state: UInt64) -> UInt64:
    """LCG (Numerical Recipes style)."""
    return state * 6364136223846793005 + 1442695040888963407


fn u01_from_u64(x: UInt64) -> Float32:
    """``[0, 1)`` from upper 32 bits."""
    var top = UInt32((x >> 32) & 0xFFFFFFFF)
    return Float32(top) / Float32(4294967296.0)


# === Xorshift128+ (per-worker stream; uniforms packed into SIMD registers) ==================


@register_passable("trivial")
struct Xor128p:
    var s0: UInt64
    var s1: UInt64


alias Xor128pPtr = UnsafePointer[Xor128p]


@always_inline
fn xor128p_next(inout st: Xor128p) -> UInt64:
    var x = st.s0
    var y = st.s1
    st.s0 = y
    x = x ^ (x << 23)
    st.s1 = x ^ y ^ (x >> 17) ^ (y >> 26)
    return st.s1 + y


@always_inline
fn u01_from_xor128p(inout st: Xor128p) -> Float32:
    var v = xor128p_next(st)
    return Float32(UInt32(v >> 32)) / Float32(4294967296.0)


@always_inline
fn rng_uniform_simd(inout st: Xor128p) -> SIMD[DType.float32, W]:
    """Draw ``W`` consecutive ``U(0,1)`` values into one SIMD register (no heap staging)."""
    var u = SIMD[DType.float32, W]()
    for lane in range(W):
        u[lane] = u01_from_xor128p(st)
    return u


fn xor128p_seed(inout st: Xor128p, seed: UInt64):
    """SplitMix64-style expansion of a 64-bit seed into full 128-bit state."""
    var z = seed + 0x9E3779B97F4A7C15
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB
    st.s0 = z ^ (z >> 31)
    z = st.s0 + 0x9E3779B97F4A7C15
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB
    st.s1 = z ^ (z >> 31)


fn monte_init_worker_rng(worker_rng: Xor128pPtr, workers: Int, base_seed: UInt64):
    """Seed ``workers`` independent streams (call with ``num_physical_cores()`` before ``simulate_gbm``)."""
    for i in range(workers):
        var st = Xor128p(0, 0)
        var s = base_seed ^ (UInt64(i) * 0xD6E8FEB866932FE5)
        xor128p_seed(st, s)
        worker_rng[i] = st


# === Box–Muller (scalar + SIMD) ===============================================================


@always_inline
fn box_muller_pair(inout st: Xor128p) -> SIMD[DType.float32, 2]:
    """Two independent standard normals from two uniforms (scalar stream)."""
    var u1 = u01_from_xor128p(st)
    var u2 = u01_from_xor128p(st)
    u1 = u1 if u1 > EPS_U01 else EPS_U01
    var r = v_sqrt[DType.float32, 1](F32x1(-2.0) * v_log[DType.float32, 1](F32x1(u1)))[0]
    var th = TWO_PI * u2
    return SIMD[DType.float32, 2](r * cos(th), r * sin(th))


@always_inline
fn box_muller_z0(inout st: Xor128p) -> Float32:
    """One standard normal (uses two uniforms internally)."""
    var p = box_muller_pair(st)
    return p[0]


@always_inline
fn box_muller_vec_z0(u1: SIMD[DType.float32, W], u2: SIMD[DType.float32, W]) -> SIMD[DType.float32, W]:
    """Vectorized Box–Muller ``z0``; ``u1,u2`` are independent ``U(0,1)`` SIMD registers."""
    var clamped = u1
    for lane in range(W):
        var x = clamped[lane]
        clamped[lane] = x if x > EPS_U01 else EPS_U01
    var r = v_sqrt[DType.float32, W](-2.0 * v_log[DType.float32, W](clamped))
    var th = TWO_PI * u2
    return r * cos[DType.float32, W](th)


# === GBM simulation =========================================================================


@always_inline
fn _gbm_step_scalar(inout st: Xor128p, S: Float32, drift: Float32, vol: Float32) -> Float32:
    """``S * exp(drift + vol * Z)`` with ``Z ~ N(0,1)``; uses ``v_exp`` (simd)."""
    var z = box_muller_z0(st)
    var inc = drift + vol * z
    return S * v_exp[DType.float32, 1](F32x1(inc))[0]


fn simulate_gbm(
    start_price: Float32,
    mu: Float32,
    sigma: Float32,
    dt: Float32,
    steps: Int,
    paths: Int,
    out_final: F32Ptr,
    worker_rng: Xor128pPtr,
):
    """Terminal prices under GBM: ``dS = mu S dt + sigma S dW`` (exact step on log-price).

    ``worker_rng`` must hold at least ``num_physical_cores()`` entries, pre-seeded (see ``monte_init_worker_rng``).
    Uses ``v_sqrt`` on ``dt`` and ``v_exp`` on the log-increment each step.
    """
    if paths <= 0 or steps <= 0:
        return
    var workers = num_physical_cores()
    if workers < 1:
        workers = 1

    var drift = (mu - Float32(0.5) * sigma * sigma) * dt
    var sqrt_dt = v_sqrt[DType.float32, 1](F32x1(dt))[0]
    var vol = sigma * sqrt_dt

    def path_worker(bid: Int):
        var st = worker_rng[bid]
        var p = bid
        while p < paths:
            var S = start_price
            for _t in range(steps):
                S = _gbm_step_scalar(st, S, drift, vol)
            out_final[p] = S
            p += workers
        worker_rng[bid] = st

    parallelize[path_worker](workers, workers)


fn simulate_gbm_barrier(
    start_price: Float32,
    mu: Float32,
    sigma: Float32,
    dt: Float32,
    steps: Int,
    paths: Int,
    barrier: Float32,
    out_final: F32Ptr,
    worker_rng: Xor128pPtr,
):
    """GBM with early exit once ``S <= barrier`` (down-and-out style path truncation)."""
    if paths <= 0 or steps <= 0:
        return
    var workers = num_physical_cores()
    if workers < 1:
        workers = 1

    var drift = (mu - Float32(0.5) * sigma * sigma) * dt
    var sqrt_dt = v_sqrt[DType.float32, 1](F32x1(dt))[0]
    var vol = sigma * sqrt_dt

    def path_worker_b(bid: Int):
        var st = worker_rng[bid]
        var p = bid
        while p < paths:
            var S = start_price
            for _t in range(steps):
                if S <= barrier:
                    break
                S = _gbm_step_scalar(st, S, drift, vol)
            out_final[p] = S
            p += workers
        worker_rng[bid] = st

    parallelize[path_worker_b](workers, workers)


# === Reductions & VaR ========================================================================


@register_passable("trivial")
struct MonteSummary:
    var mean: Float32
    var variance: Float32
    var std_dev: Float32
    var var95: Float32
    var var99: Float32


alias MonteSummaryPtr = UnsafePointer[MonteSummary]


fn mean_f32_buffer(x: F32Ptr, n: Int) -> Float32:
    var s = Float32(0.0)
    var i: Int = 0
    while i + W <= n:
        s += (x + i).load[width=W]().reduce_add()
        i += W
    while i < n:
        s += (x + i).load[width=1]().reduce_add()
        i += 1
    return s / Float32(n)


fn variance_f32_buffer(x: F32Ptr, n: Int, mean: Float32) -> Float32:
    if n <= 1:
        return 0.0
    var acc = Float32(0.0)
    var mv = SIMD[DType.float32, W](mean)
    var i: Int = 0
    while i + W <= n:
        var v = (x + i).load[width=W]()
        var d = v - mv
        acc += (d * d).reduce_add()
        i += W
    while i < n:
        var t = (x + i).load[width=1]().reduce_add() - mean
        acc += t * t
        i += 1
    return acc / Float32(n - 1)


fn standard_deviation_f32_buffer(x: F32Ptr, n: Int, mean: Float32) -> Float32:
    return v_sqrt[DType.float32, 1](F32x1(variance_f32_buffer(x, n, mean)))[0]


fn losses_from_prices(start_price: Float32, prices: F32Ptr, losses: F32Ptr, n: Int):
    """``losses[i] = max(0, start_price - prices[i])`` (long exposure drawdown)."""
    var i: Int = 0
    var s = SIMD[DType.float32, W](start_price)
    while i + W <= n:
        var p = (prices + i).load[width=W]()
        var ell = s - p
        var zero = SIMD[DType.float32, W](0.0)
        var mask = ell > zero
        (losses + i).store[width=W](mask.select(ell, zero))
        i += W
    while i < n:
        var pi = (prices + i).load[width=1]().reduce_add()
        var loss = start_price - pi
        if loss < 0.0:
            loss = 0.0
        (losses + i).store[width=1](SIMD[DType.float32, 1](loss))
        i += 1


fn sort_descending_inplace(a: F32Ptr, n: Int):
    """Insertion sort descending (suitable for modest ``n`` VaR / what-if)."""
    for i in range(1, n):
        var key = (a + i).load[width=1]()[0]
        var j = i - 1
        while j >= 0 and (a + j).load[width=1]()[0] < key:
            (a + j + 1).store[width=1]((a + j).load[width=1]())
            j -= 1
        (a + j + 1).store[width=1](F32x1(key))


fn calculate_var(losses: F32Ptr, sort_scratch: F32Ptr, n: Int, confidence: Float32) -> Float32:
    """Historical VaR on non-negative **losses**: ``confidence`` ``0.95`` → ~5% right-tail loss."""
    if n <= 0:
        return 0.0
    for i in range(n):
        (sort_scratch + i).store[width=1]((losses + i).load[width=1]())
    sort_descending_inplace(sort_scratch, n)
    var tail = Float32(1.0) - confidence
    if tail < 0.0:
        tail = 0.0
    if tail > 1.0:
        tail = 1.0
    var idx = Int(Float32(n - 1) * tail)
    if idx < 0:
        idx = 0
    if idx >= n:
        idx = n - 1
    return (sort_scratch + idx).load[width=1]()[0]


fn monte_summarize_paths(
    prices: F32Ptr,
    n: Int,
    start_price: Float32,
    losses_scratch: F32Ptr,
    var_sort_scratch: F32Ptr,
    out: MonteSummaryPtr,
):
    """Mean / variance / std on ``prices``; VaR 95/99 from drawdown losses (two scratch buffers)."""
    var m = mean_f32_buffer(prices, n)
    var v = variance_f32_buffer(prices, n, m)
    var sd = v_sqrt[DType.float32, 1](F32x1(v))[0]
    losses_from_prices(start_price, prices, losses_scratch, n)
    var v95 = calculate_var(losses_scratch, var_sort_scratch, n, Float32(0.95))
    var v99 = calculate_var(losses_scratch, var_sort_scratch, n, Float32(0.99))
    out[] = MonteSummary {
        mean: m,
        variance: v,
        std_dev: sd,
        var95: v95,
        var99: v99,
    }
