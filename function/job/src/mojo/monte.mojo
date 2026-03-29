# Monte Carlo — LCG 64-bit (deterministyczny PRNG; JAX/PRNG w Pythonie pozostaje źródłem głównym).
# TODO:
# [ ] implement Monte Carlo simulation engine:
# [ ]     n_samples as runtime parameter from RICE_MONTE_N_SAMPLES
# [ ] implement parallel random number generation via SIMD
# [ ] implement importance sampling
# [ ] implement variance reduction: antithetic variates, control variates

fn lcg_u64(state: UInt64) -> UInt64:
    """LCG (Numerical Recipes styl)."""
    return state * 6364136223846793005 + 1442695040888963407


fn u01_from_u64(x: UInt64) -> Float32:
    """[0, 1) z górnych bitów."""
    var top = UInt32((x >> 32) & 0xFFFFFFFF)
    return Float32(top) / Float32(4294967296.0)
