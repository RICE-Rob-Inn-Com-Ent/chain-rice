# Polars / ramki — suma krocząca na wektorze 8×f32 (stub kerneli agregacji dla `job/frame.py`).
# TODO:
# [ ] implement Mojo-accelerated Polars expression plugins:
# [ ]     custom UDF callable from Polars via FFI bridge
# [ ] implement columnar operations matching Polars dtype system
# [ ] implement Arrow-compatible memory layout for zero-copy exchange

alias F32x8 = SIMD[DType.float32, 8]


fn rolling_sum_f32x8(v: F32x8) -> Float32:
    """Suma wszystkich 8 elementów (agregacja w jednym rejestrze SIMD)."""
    return v.reduce_add()


fn mean_f32x8(v: F32x8) -> Float32:
    return v.reduce_add() / 8.0
