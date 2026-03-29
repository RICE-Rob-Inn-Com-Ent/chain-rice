# ODE — klasyczny RK4 dla skalara (model y' = y; rozszerz na wektor dla `simulation/physics.py`).
# TODO:
# [ ] implement RK4 ODE solver — vectorized via SIMD
# [ ] implement adaptive step size: RK45 (Dormand-Prince)
# [ ]     rtol, atol as parameters — not hardcoded
# [ ] implement stiff ODE solver: implicit Euler
# [ ] implement event detection: zero-crossing

fn rk4_scalar_exp_step(y: Float32, dt: Float32) -> Float32:
    """Jeden krok RK4 dla równania y' = y (test porównawczy z exp)."""
    var k1 = y
    var k2 = y + 0.5 * dt * k1
    var k3 = y + 0.5 * dt * k2
    var k4 = y + dt * k3
    return y + (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)


fn euler_scalar_exp_step(y: Float32, dt: Float32) -> Float32:
    """Euler jawny dla y' = y (baseline)."""
    return y + dt * y
