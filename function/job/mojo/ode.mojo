# ODE — vectorized RK4 / Cash–Karp RK45, ensemble `parallelize`, RiceArray-friendly `F32Ptr` ABI.
# RHS is a **parameter** function `deriv(t, y, dy_out, dim, params)` (Mojo monomorphization; bridge wires models in Mojo).

from algorithm import parallelize
from math import exp, log, max, min
from memory.unsafe_pointer import UnsafePointer
from sys.info import num_physical_cores

from .simd import NATIVE_F32_LANES, v_fma

alias W: Int = NATIVE_F32_LANES
alias F32Ptr = UnsafePointer[Scalar[DType.float32]]

# User RHS: ``dy_out[i] = f_i(t, y, params)``; may ignore ``t`` / ``params`` for autonomous systems.
alias OdeRhs = fn (t: Float32, y: F32Ptr, dy_out: F32Ptr, dim: Int, params: F32Ptr) -> None


# === Legacy scalar exp (unchanged ABI) ========================================================


fn rk4_scalar_exp_step(y: Float32, dt: Float32) -> Float32:
    """One RK4 step for ``y' = y`` (historical test kernel)."""
    var k1 = y
    var k2 = y + 0.5 * dt * k1
    var k3 = y + 0.5 * dt * k2
    var k4 = y + dt * k3
    return y + (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)


fn euler_scalar_exp_step(y: Float32, dt: Float32) -> Float32:
    """Explicit Euler for ``y' = y`` (baseline)."""
    return y + dt * y


# === Work buffer sizes =========================================================================


@always_inline
fn rk4_work_elems(dim: Int) -> Int:
    """``rk4_step`` scratch: ``k1,k2,k3,k4,ytemp`` × ``dim``."""
    return 5 * dim


@always_inline
fn rk45_work_elems(dim: Int) -> Int:
    """Cash–Karp scratch: ``k1..k6`` and one staging vector."""
    return 7 * dim


# === Register-friendly SIMD axpy / copy ========================================================


@always_inline
fn _fma_y_plus_ax(dim: Int, y: F32Ptr, a: F32Ptr, scale: Float32, out_: F32Ptr):
    """``out_[i] = y[i] + scale * a[i]`` using ``v_fma`` on native SIMD chunks."""
    var sv = SIMD[DType.float32, W](scale)
    var i: Int = 0
    while i + W <= dim:
        var vy = (y + i).load[width=W]()
        var va = (a + i).load[width=W]()
        (out_ + i).store[width=W](v_fma[DType.float32, W](sv, va, vy))
        i += W
    while i < dim:
        var vy = (y + i).load[width=1]()
        var va = (a + i).load[width=1]()
        (out_ + i).store[width=1](v_fma[DType.float32, 1](SIMD[DType.float32, 1](scale), va, vy))
        i += 1


@always_inline
fn _fma_inplace_y_plus_ax(dim: Int, y: F32Ptr, a: F32Ptr, scale: Float32):
    """``y[i] += scale * a[i]`` (accumulate) via ``v_fma``."""
    var sv = SIMD[DType.float32, W](scale)
    var i: Int = 0
    while i + W <= dim:
        var vy = (y + i).load[width=W]()
        var va = (a + i).load[width=W]()
        (y + i).store[width=W](v_fma[DType.float32, W](sv, va, vy))
        i += W
    while i < dim:
        var vy = (y + i).load[width=1]()
        var va = (a + i).load[width=1]()
        (y + i).store[width=1](v_fma[DType.float32, 1](SIMD[DType.float32, 1](scale), va, vy))
        i += 1


@always_inline
fn _copy_vec(dim: Int, dst: F32Ptr, src: F32Ptr):
    var i: Int = 0
    while i + W <= dim:
        (dst + i).store[width=W]((src + i).load[width=W]())
        i += W
    while i < dim:
        (dst + i).store[width=1]((src + i).load[width=1]())
        i += 1


@always_inline
fn _yth_add_scaled_k(dim: Int, yt: F32Ptr, k: F32Ptr, scale: Float32):
    """``yt += scale * k`` (``v_fma``)."""
    _fma_inplace_y_plus_ax(dim, yt, k, scale)


# === RK4 vector step =========================================================================


fn rk4_step[
    deriv: OdeRhs,
](dim: Int, y: F32Ptr, t: Float32, dt: Float32, params: F32Ptr, work: F32Ptr):
    """In-place RK4 on ``y`` (length ``dim``). ``work`` length ``>= rk4_work_elems(dim)``.

    Layout: ``k1@+0``, ``k2@+dim``, ``k3@+2dim``, ``k4@+3dim``, ``yt@+4dim``.
    """
    var k1 = work
    var k2 = work + dim
    var k3 = work + 2 * dim
    var k4 = work + 3 * dim
    var yt = work + 4 * dim
    var half = Float32(0.5) * dt
    var full = dt

    deriv(t, y, k1, dim, params)
    _fma_y_plus_ax(dim, y, k1, half, yt)
    deriv(t + half, yt, k2, dim, params)
    _fma_y_plus_ax(dim, y, k2, half, yt)
    deriv(t + half, yt, k3, dim, params)
    _fma_y_plus_ax(dim, y, k3, full, yt)
    deriv(t + full, yt, k4, dim, params)

    var sixth = dt / Float32(6.0)
    var i: Int = 0
    var s2 = SIMD[DType.float32, W](Float32(2.0))
    var ss = SIMD[DType.float32, W](sixth)
    while i + W <= dim:
        var vy = (y + i).load[width=W]()
        var vk1 = (k1 + i).load[width=W]()
        var vk2 = (k2 + i).load[width=W]()
        var vk3 = (k3 + i).load[width=W]()
        var vk4 = (k4 + i).load[width=W]()
        var inc = vk1
        inc = v_fma[DType.float32, W](s2, vk2, inc)
        inc = v_fma[DType.float32, W](s2, vk3, inc)
        inc = inc + vk4
        (y + i).store[width=W](v_fma[DType.float32, W](ss, inc, vy))
        i += W
    while i < dim:
        var vy = (y + i).load[width=1]()
        var vk1 = (k1 + i).load[width=1]()
        var vk2 = (k2 + i).load[width=1]()
        var vk3 = (k3 + i).load[width=1]()
        var vk4 = (k4 + i).load[width=1]()
        var inc = vk1
        inc = v_fma[DType.float32, 1](SIMD[DType.float32, 1](2.0), vk2, inc)
        inc = v_fma[DType.float32, 1](SIMD[DType.float32, 1](2.0), vk3, inc)
        inc = inc + vk4
        (y + i).store[width=1](v_fma[DType.float32, 1](SIMD[DType.float32, 1](sixth), inc, vy))
        i += 1


# === integrate_to (fixed dt) ===================================================================


fn integrate_to[
    deriv: OdeRhs,
](dim: Int, y: F32Ptr, t_start: Float32, target_t: Float32, dt: Float32, params: F32Ptr, work: F32Ptr) -> Float32:
    """Advance ``t`` from ``t_start`` toward ``target_t`` with fixed base ``dt`` (last step shortened)."""
    var t = t_start
    if target_t <= t_start:
        return t_start
    while t < target_t:
        var h = dt
        var rem = target_t - t
        if h > rem:
            h = rem
        rk4_step[deriv](dim, y, t, h, params, work)
        t += h
    return t


# === Ensemble ================================================================================


fn simulate_ensemble[
    deriv: OdeRhs,
](
    dim: Int,
    num_systems: Int,
    state: F32Ptr,
    t0: Float32,
    target_t: Float32,
    dt: Float32,
    params: F32Ptr,
    param_stride: Int,
    work: F32Ptr,
    work_stride: Int,
):
    """Parallel integration: ``state[s*dim:(s+1)*dim]`` with ``params[s*param_stride:]``.

    ``work`` must hold ``num_systems * work_stride`` floats; use ``work_stride >= rk4_work_elems(dim)``.
    """
    if num_systems <= 0 or dim <= 0:
        return
    var workers = num_physical_cores()
    if workers < 1:
        workers = 1
    if workers > num_systems:
        workers = num_systems

    def job(sid: Int):
        var y = state + sid * dim
        var p = params + sid * param_stride
        var w = work + sid * work_stride
        _ = integrate_to[deriv](dim, y, t0, target_t, dt, p, w)

    parallelize[job](num_systems, workers)


# === Cash–Karp RK45 (embedded 4/5) ============================================================


@always_inline
fn _ck_time_nodes() -> SIMD[DType.float32, 6]:
    """``c`` for stages ``k1..k6`` (Cash–Karp)."""
    return SIMD[DType.float32, 6](
        0.0,
        Float32(1.0) / Float32(5.0),
        Float32(3.0) / Float32(10.0),
        Float32(3.0) / Float32(5.0),
        Float32(1.0),
        Float32(7.0) / Float32(8.0),
    )


fn _ck_build_stage_y(dim: Int, y: F32Ptr, h: Float32, work: F32Ptr, stage: Int, yt: F32Ptr):
    """``yt = y + h * sum_j a[stage][j] k_j``; ``stage`` in ``1..5`` (``k1`` at ``work+0``)."""
    var k0 = work
    if stage == 1:
        _fma_y_plus_ax(dim, y, k0, h * (Float32(1.0) / Float32(5.0)), yt)
        return
    var k1 = work + dim
    if stage == 2:
        _copy_vec(dim, yt, y)
        _yth_add_scaled_k(dim, yt, k0, h * (Float32(3.0) / Float32(40.0)))
        _yth_add_scaled_k(dim, yt, k1, h * (Float32(9.0) / Float32(40.0)))
        return
    var k2 = work + 2 * dim
    if stage == 3:
        _copy_vec(dim, yt, y)
        _yth_add_scaled_k(dim, yt, k0, h * (Float32(3.0) / Float32(10.0)))
        _yth_add_scaled_k(dim, yt, k1, h * (Float32(-9.0) / Float32(10.0)))
        _yth_add_scaled_k(dim, yt, k2, h * (Float32(6.0) / Float32(5.0)))
        return
    var k3 = work + 3 * dim
    if stage == 4:
        _copy_vec(dim, yt, y)
        _yth_add_scaled_k(dim, yt, k0, h * (Float32(-11.0) / Float32(54.0)))
        _yth_add_scaled_k(dim, yt, k1, h * (Float32(5.0) / Float32(2.0)))
        _yth_add_scaled_k(dim, yt, k2, h * (Float32(-70.0) / Float32(27.0)))
        _yth_add_scaled_k(dim, yt, k3, h * (Float32(35.0) / Float32(27.0)))
        return
    var k4 = work + 4 * dim
    _copy_vec(dim, yt, y)
    _yth_add_scaled_k(dim, yt, k0, h * (Float32(1631.0) / Float32(55296.0)))
    _yth_add_scaled_k(dim, yt, k1, h * (Float32(175.0) / Float32(512.0)))
    _yth_add_scaled_k(dim, yt, k2, h * (Float32(575.0) / Float32(13824.0)))
    _yth_add_scaled_k(dim, yt, k3, h * (Float32(44275.0) / Float32(110592.0)))
    _yth_add_scaled_k(dim, yt, k4, h * (Float32(253.0) / Float32(4096.0)))


fn _rk45_err_max_norm(dim: Int, work: F32Ptr, y0: F32Ptr, h: Float32, atol: Float32, rtol: Float32) -> Float32:
    """Scaled max-norm of ``h * sum ec_i k_i`` (Cash–Karp embedding)."""
    var k0 = work
    var k2 = work + 2 * dim
    var k3 = work + 3 * dim
    var k4 = work + 4 * dim
    var k5 = work + 5 * dim
    var ec0 = Float32(-0.0042937748)
    var ec2 = Float32(0.018668586)
    var ec3 = Float32(-0.034155027)
    var ec4 = Float32(-0.019321987)
    var ec5 = Float32(0.0391022)
    var emax = Float32(0.0)
    var i: Int = 0
    var hv = SIMD[DType.float32, W](h)
    while i + W <= dim:
        var e = (k0 + i).load[width=W]() * SIMD[DType.float32, W](ec0)
        e = v_fma[DType.float32, W]((k2 + i).load[width=W>(), SIMD[DType.float32, W](ec2), e)
        e = v_fma[DType.float32, W]((k3 + i).load[width=W>(), SIMD[DType.float32, W](ec3), e)
        e = v_fma[DType.float32, W]((k4 + i).load[width=W>(), SIMD[DType.float32, W](ec4), e)
        e = v_fma[DType.float32, W]((k5 + i).load[width=W>(), SIMD[DType.float32, W](ec5), e)
        e = hv * e
        var yabs = abs((y0 + i).load[width=W]())
        var sc = atol + rtol * yabs
        var ratio = abs(e) / max(sc, SIMD[DType.float32, W](1e-12))
        emax = max(emax, ratio.reduce_max())
        i += W
    while i < dim:
        var e = (k0 + i).load[width=1]() * SIMD[DType.float32, 1](ec0)
        e = v_fma[DType.float32, 1]((k2 + i).load[width=1>(), SIMD[DType.float32, 1](ec2), e)
        e = v_fma[DType.float32, 1]((k3 + i).load[width=1>(), SIMD[DType.float32, 1](ec3), e)
        e = v_fma[DType.float32, 1]((k4 + i).load[width=1>(), SIMD[DType.float32, 1](ec4), e)
        e = v_fma[DType.float32, 1]((k5 + i).load[width=1>(), SIMD[DType.float32, 1](ec5), e)
        e = SIMD[DType.float32, 1](h) * e
        var yabs = abs((y0 + i).load[width=1]())
        var sc = SIMD[DType.float32, 1](atol) + SIMD[DType.float32, 1](rtol) * yabs
        var ratio = abs(e) / max(sc, SIMD[DType.float32, 1](1e-12))
        emax = max(emax, ratio.reduce_max())
        i += 1
    return emax


fn rk45_cash_karp_step[
    deriv: OdeRhs,
](
    dim: Int,
    y: F32Ptr,
    t: Float32,
    inout dt: Float32,
    params: F32Ptr,
    work: F32Ptr,
    y_save: F32Ptr,
    atol: Float32,
    rtol: Float32,
) -> Bool:
    """One embedded Cash–Karp attempt: on **success** updates ``y`` (5th order) and suggests a new ``dt``.

    On **reject**, restores ``y`` from ``y_save``, shrinks ``dt``, returns ``False`` (caller retries the same ``t``).
    ``work`` length ``>= rk45_work_elems(dim)``; ``y_save`` length ``>= dim``.
    """
    _copy_vec(dim, y_save, y)
    var k1 = work
    var k2 = work + dim
    var k3 = work + 2 * dim
    var k4 = work + 3 * dim
    var k5 = work + 4 * dim
    var k6 = work + 5 * dim
    var yt = work + 6 * dim
    var h = dt
    var c = _ck_time_nodes()

    deriv(t, y, k1, dim, params)
    _ck_build_stage_y(dim, y, h, work, 1, yt)
    deriv(t + h * c[1], yt, k2, dim, params)
    _ck_build_stage_y(dim, y, h, work, 2, yt)
    deriv(t + h * c[2], yt, k3, dim, params)
    _ck_build_stage_y(dim, y, h, work, 3, yt)
    deriv(t + h * c[3], yt, k4, dim, params)
    _ck_build_stage_y(dim, y, h, work, 4, yt)
    deriv(t + h * c[4], yt, k5, dim, params)
    _ck_build_stage_y(dim, y, h, work, 5, yt)
    deriv(t + h * c[5], yt, k6, dim, params)

    var err = _rk45_err_max_norm(dim, work, y_save, h, atol, rtol)
    var safe = max(err, Float32(1e-12))
    var grow = Float32(0.95) * exp(log(safe) * Float32(-0.2))

    if err <= Float32(1.0):
        var b1 = Float32(37.0) / Float32(378.0)
        var b3 = Float32(250.0) / Float32(621.0)
        var b4 = Float32(125.0) / Float32(594.0)
        var b6 = Float32(512.0) / Float32(1771.0)
        _copy_vec(dim, y, y_save)
        _yth_add_scaled_k(dim, y, k1, h * b1)
        _yth_add_scaled_k(dim, y, k3, h * b3)
        _yth_add_scaled_k(dim, y, k4, h * b4)
        _yth_add_scaled_k(dim, y, k6, h * b6)
        dt = h * min(Float32(5.0), max(Float32(0.2), grow))
        dt = max(dt, Float32(1e-10))
        return True
    _copy_vec(dim, y, y_save)
    dt = h * max(Float32(0.1), min(Float32(0.5), grow))
    dt = max(dt, Float32(1e-10))
    return False


fn integrate_to_rk45[
    deriv: OdeRhs,
](
    dim: Int,
    y: F32Ptr,
    t_start: Float32,
    target_t: Float32,
    inout dt: Float32,
    params: F32Ptr,
    work: F32Ptr,
    y_save: F32Ptr,
    atol: Float32,
    rtol: Float32,
) -> Float32:
    """Adaptive integration to ``target_t`` using Cash–Karp steps (accept/reject loop)."""
    var t = t_start
    if target_t <= t_start:
        return t_start
    var guard: Int = 0
    while t < target_t:
        guard += 1
        if guard > 10000000:
            break
        var rem = target_t - t
        var hstep = min(dt, rem)
        dt = hstep
        if rk45_cash_karp_step[deriv](dim, y, t, dt, params, work, y_save, atol, rtol):
            t += hstep
    return t


# === Reference RHS: autonomous ``y' = y`` (decoupled lanes) =====================================


fn rhs_exp_autonomous(t: Float32, y: F32Ptr, dy_out: F32Ptr, dim: Int, params: F32Ptr):
    """``dy = y`` (ignores ``t``, ``params``); useful with ``rk4_step[rhs_exp_autonomous]``."""
    _ = t
    _ = params
    _copy_vec(dim, dy_out, y)
