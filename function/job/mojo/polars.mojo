# Columnar kernels — DataFrame views (RiceArray / bridge), SIMD filter masks, aggregations, parallel groupby, hash join, lazy hints.
# Layout: **column-major** ``Float32`` ``data[col * nrows + row]`` for SIMD down columns; optional ``Int64`` key column; masks ``UInt8`` 0/1.

from algorithm import parallelize
from math import max, min, sqrt
from memory.unsafe_pointer import UnsafePointer
from .simd import NATIVE_F32_LANES, v_max, v_min, v_select, v_sum

alias W: Int = NATIVE_F32_LANES
alias F32Ptr = UnsafePointer[Scalar[DType.float32]]
alias I64Ptr = UnsafePointer[Scalar[DType.int64]]
alias U8Ptr = UnsafePointer[Scalar[DType.uint8]]
alias I32Ptr = UnsafePointer[Scalar[DType.int32]]

alias F32x8 = SIMD[DType.float32, 8]

alias POLAR_CMP_EQ: Int = 0
alias POLAR_CMP_NE: Int = 1
alias POLAR_CMP_LT: Int = 2
alias POLAR_CMP_LE: Int = 3
alias POLAR_CMP_GT: Int = 4
alias POLAR_CMP_GE: Int = 5

alias LAZY_NOP: Int = 0
alias LAZY_FILTER_F32: Int = 1
alias LAZY_GROUPBY: Int = 2
alias LAZY_JOIN: Int = 3


# === Legacy 8-wide (unchanged ABI) =============================================================


fn rolling_sum_f32x8(v: F32x8) -> Float32:
    return v.reduce_add()


fn mean_f32x8(v: F32x8) -> Float32:
    return v.reduce_add() / 8.0


# === DataFrame (column-major f32 + optional i64 key, zero-copy slice) =========================


@register_passable("trivial")
struct DataFrame:
    """Column-major ``f32`` block ``[ncols][nrows]`` + optional aligned ``i64`` key column (length ``nrows``).

    ``row0 .. row0+row_count`` is the active slice (zero-copy: adjust fields, same ``data`` pointer).
    """
    var data: F32Ptr
    var keys: I64Ptr
    var has_keys: Bool
    var nrows: Int
    var ncols: Int
    var row0: Int
    var row_count: Int


@register_passable("trivial")
struct LazyOp:
    var opcode: UInt32
    var col: Int32
    var aux_i32: Int32
    var aux_f32: Float32


alias LazyOpPtr = UnsafePointer[LazyOp]


@register_passable("trivial")
struct LazyPlan:
    """Fixed-capacity op buffer (bridge / host fills before ``lazy_materialize_hint``)."""
    var ops: LazyOpPtr
    var cap: Int
    var len: Int


fn df_slice(df: DataFrame, row0: Int, n: Int) -> DataFrame:
    """Zero-copy view: same ``data``/``keys``, narrowed ``row0`` and ``row_count`` (clamped)."""
    var r0 = df.row0 + row0
    var rc = n
    if r0 < df.row0:
        r0 = df.row0
    if rc > df.row_count - (r0 - df.row0):
        rc = df.row_count - (r0 - df.row0)
    if rc < 0:
        rc = 0
    return DataFrame {
        data: df.data,
        keys: df.keys,
        has_keys: df.has_keys,
        nrows: df.nrows,
        ncols: df.ncols,
        row0: r0,
        row_count: rc,
    }


fn df_col_ptr(df: DataFrame, col: Int) -> F32Ptr:
    """Start of column ``col`` within the full allocation (caller indexes ``row0..``)."""
    return df.data + col * df.nrows + df.row0


# === SIMD branchless compare → mask bytes ======================================================


@always_inline
fn _cmp_mask_f32(a: SIMD[DType.float32, W], v: SIMD[DType.float32, W], cmp: Int) -> SIMD[DType.bool, W]:
    if cmp == POLAR_CMP_EQ:
        return a == v
    if cmp == POLAR_CMP_NE:
        return a != v
    if cmp == POLAR_CMP_LT:
        return a < v
    if cmp == POLAR_CMP_LE:
        return a <= v
    if cmp == POLAR_CMP_GT:
        return a > v
    return a >= v


fn filter_f32_column_mask(
    df: DataFrame,
    col: Int,
    cmp: Int,
    value: Float32,
    out_mask: U8Ptr,
):
    """Write ``out_mask[r] in {0,1}`` for ``row r`` in the active slice (branchless SIMD lanes)."""
    if col < 0 or col >= df.ncols or df.row_count <= 0:
        return
    var base = df.data + col * df.nrows + df.row0
    var vv = SIMD[DType.float32, W](value)
    var r: Int = 0
    while r + W <= df.row_count:
        var a = (base + r).load[width=W]()
        var m = _cmp_mask_f32(a, vv, cmp)
        var one = SIMD[DType.uint8, W](1)
        var zero = SIMD[DType.uint8, W](0)
        var b = v_select[DType.uint8, W](m, one, zero)
        (out_mask + r).store[width=W](b)
        r += W
    while r < df.row_count:
        var a = (base + r).load[width=1]()
        var m = _cmp_mask_f32(a, SIMD[DType.float32, 1](value), cmp)
        var b = v_select[DType.uint8, 1](m, SIMD[DType.uint8, 1](1), SIMD[DType.uint8, 1](0))
        (out_mask + r).store[width=1](b)
        r += 1


@always_inline
fn filter_column(
    df: DataFrame,
    col: Int,
    condition: Int,
    value: Float32,
    out_mask: U8Ptr,
):
    """Alias for ``filter_f32_column_mask`` (column, compare-op, value → row bitmask)."""
    filter_f32_column_mask(df, col, condition, value, out_mask)


# === Aggregations on one f32 column (active slice) =============================================


fn col_sum_f32(df: DataFrame, col: Int) -> Float32:
    var p = df_col_ptr(df, col)
    var s = Float32(0.0)
    var i: Int = 0
    while i + W <= df.row_count:
        s += v_sum((p + i).load[width=W]())
        i += W
    while i < df.row_count:
        s += (p + i).load[width=1]().reduce_add()
        i += 1
    return s


fn col_mean_f32(df: DataFrame, col: Int) -> Float32:
    if df.row_count <= 0:
        return 0.0
    return col_sum_f32(df, col) / Float32(df.row_count)


fn col_min_f32(df: DataFrame, col: Int) -> Float32:
    var p = df_col_ptr(df, col)
    var m = Float32(3.4028235e38)
    var i: Int = 0
    while i + W <= df.row_count:
        m = min(m, v_min((p + i).load[width=W]()))
        i += W
    while i < df.row_count:
        m = min(m, (p + i).load[width=1]().reduce_min())
        i += 1
    return m


fn col_max_f32(df: DataFrame, col: Int) -> Float32:
    var p = df_col_ptr(df, col)
    var m = Float32(-3.4028235e38)
    var i: Int = 0
    while i + W <= df.row_count:
        m = max(m, v_max((p + i).load[width=W]()))
        i += W
    while i < df.row_count:
        m = max(m, (p + i).load[width=1]().reduce_max())
        i += 1
    return m


fn col_std_f32(df: DataFrame, col: Int) -> Float32:
    if df.row_count <= 1:
        return 0.0
    var mu = col_mean_f32(df, col)
    var acc = Float32(0.0)
    var p = df_col_ptr(df, col)
    var mv = SIMD[DType.float32, W](mu)
    var i: Int = 0
    while i + W <= df.row_count:
        var d = (p + i).load[width=W]() - mv
        acc += v_sum(d * d)
        i += W
    while i < df.row_count:
        var t = (p + i).load[width=1]().reduce_add() - mu
        acc += t * t
        i += 1
    return sqrt(acc / Float32(df.row_count - 1))


# === Parallel groupby (key in [kmin, kmax], segmented partial counts → merge) ================


fn groupby_count_i64_range_parallel(
    keys: I64Ptr,
    n: Int,
    kmin: Int64,
    kmax: Int64,
    out_counts: I64Ptr,
    work_partial: I64Ptr,
    buckets: Int,
    workers: Int,
):
    """Count keys per integer bucket ``key - kmin``; ``out_counts`` length ``buckets``.

    ``work_partial`` length ``workers * buckets`` (row-major worker-major); merged into ``out_counts``.
    """
    if buckets <= 0 or n <= 0:
        return
    var wn = workers
    if wn < 1:
        wn = 1
    if wn > n:
        wn = n
    var i: Int = 0
    while i < wn * buckets:
        (work_partial + i).store[width=1](SIMD[DType.int64, 1](0))
        i += 1

    def job(wid: Int):
        var r = wid
        while r < n:
            var k = (keys + r).load[width=1]()[0]
            var bi = Int(k - kmin)
            if bi < 0:
                bi = 0
            if bi >= buckets:
                bi = buckets - 1
            var slot = wid * buckets + bi
            var cur = (work_partial + slot).load[width=1]()[0]
            (work_partial + slot).store[width=1](SIMD[DType.int64, 1](cur + 1))
            r += wn

    parallelize[job](wn, wn)

    for b in range(buckets):
        var s = Int64(0)
        var w: Int = 0
        while w < wn:
            s += (work_partial + w * buckets + b).load[width=1]()[0]
            w += 1
        (out_counts + b).store[width=1](SIMD[DType.int64, 1](s))


fn groupby_sum_f32_bucket_parallel(
    df: DataFrame,
    value_col: Int,
    kmin: Int64,
    kmax: Int64,
    out_sum: F32Ptr,
    work_partial: F32Ptr,
    buckets: Int,
    workers: Int,
):
    """Sum ``value_col`` grouped by ``df.keys[row]`` in ``[kmin,kmax]`` (requires ``has_keys``)."""
    if not df.has_keys or value_col < 0 or value_col >= df.ncols or buckets <= 0 or df.row_count <= 0:
        return
    var wn = workers
    if wn < 1:
        wn = 1
    if wn > df.row_count:
        wn = df.row_count
    var i: Int = 0
    while i < wn * buckets:
        (work_partial + i).store[width=1](SIMD[DType.float32, 1](0.0))
        i += 1
    var vals = df_col_ptr(df, value_col)

    def job(wid: Int):
        var r = wid
        while r < df.row_count:
            var k = (df.keys + df.row0 + r).load[width=1]()[0]
            var bi = Int(k - kmin)
            if bi < 0:
                bi = 0
            if bi >= buckets:
                bi = buckets - 1
            var slot = wid * buckets + bi
            var v = (vals + r).load[width=1]()[0]
            var cur = (work_partial + slot).load[width=1]()[0]
            (work_partial + slot).store[width=1](SIMD[DType.float32, 1](cur + v))
            r += wn

    parallelize[job](wn, wn)

    for b in range(buckets):
        var s = Float32(0.0)
        var w: Int = 0
        while w < wn:
            s += (work_partial + w * buckets + b).load[width=1]()[0]
            w += 1
        (out_sum + b).store[width=1](SIMD[DType.float32, 1](s))


# === Hash join (right small: build table, left probe) =========================================


@always_inline
fn _hj_hash(k: Int64, buckets: Int) -> Int:
    return Int((UInt64(k) * UInt64(1315423911)) % UInt64(buckets))


fn hash_join_count_i64(
    left_keys: I64Ptr,
    left_n: Int,
    right_keys: I64Ptr,
    right_n: Int,
    table_keys: I64Ptr,
    table_row: I32Ptr,
    buckets: Int,
    out_hits: I32Ptr,
):
    """Single-match build/probe: ``table_*`` length ``buckets`` (open addr, ``EMPTY = MIN``). ``out_hits[i]`` = right row or ``-1``."""

    var EMPTY = Int64(-9223372036854775808)
    var b: Int = 0
    while b < buckets:
        (table_keys + b).store[width=1](SIMD[DType.int64, 1](EMPTY))
        (table_row + b).store[width=1](SIMD[DType.int32, 1](-1))
        b += 1
    var j: Int = 0
    while j < right_n:
        var k = (right_keys + j).load[width=1]()[0]
        var h0 = _hj_hash(k, buckets)
        var t: Int = 0
        while t < buckets:
            var slot = (h0 + t) % buckets
            if (table_keys + slot).load[width=1]()[0] == EMPTY:
                (table_keys + slot).store[width=1](SIMD[DType.int64, 1](k))
                (table_row + slot).store[width=1](SIMD[DType.int32, 1](Int32(j)))
                break
            t += 1
        j += 1
    var i: Int = 0
    while i < left_n:
        var lk = (left_keys + i).load[width=1]()[0]
        var h0 = _hj_hash(lk, buckets)
        var t: Int = 0
        var found = Int32(-1)
        while t < buckets:
            var slot = (h0 + t) % buckets
            if (table_keys + slot).load[width=1]()[0] == EMPTY:
                break
            if (table_keys + slot).load[width=1]()[0] == lk:
                found = (table_row + slot).load[width=1]()[0]
                break
            t += 1
        (out_hits + i).store[width=1](SIMD[DType.int32, 1](found))
        i += 1


# === Lazy plan (execution hints for bridge) ====================================================


fn lazy_plan_init(inout plan: LazyPlan):
    plan.len = 0


fn lazy_plan_push_filter(inout plan: LazyPlan, col: Int, cmp: Int, value: Float32) -> Bool:
    if plan.len >= plan.cap:
        return False
    var op = LazyOp {
        opcode: UInt32(LAZY_FILTER_F32),
        col: Int32(col),
        aux_i32: Int32(cmp),
        aux_f32: value,
    }
    (plan.ops + plan.len).store[width=1](op)
    plan.len += 1
    return True


fn lazy_materialize_hint(plan: LazyPlan, df: DataFrame) -> Int:
    """Return suggested output rows after filters (conservative: min slice size if unknown)."""
    _ = plan
    return df.row_count


# === Bridge CSV / Parquet (host loads mmap → RiceArray) =======================================


fn bridge_register_csv_layout(
    path_utf8: U8Ptr,
    path_len: Int,
    out_ncols: I32Ptr,
    out_nrows: I32Ptr,
) -> Int:
    """Stub ABI: bridge fills ``out_ncols`` / ``out_nrows`` after parsing header; returns ``0`` on success."""
    _ = path_utf8
    _ = path_len
    (out_ncols + 0).store[width=1](SIMD[DType.int32, 1](0))
    (out_nrows + 0).store[width=1](SIMD[DType.int32, 1](0))
    return 0


fn bridge_register_parquet_layout(
    path_utf8: U8Ptr,
    path_len: Int,
    out_ncols: I32Ptr,
    out_nrows: I32Ptr,
) -> Int:
    """Stub ABI for Parquet footer / schema probe (filled by ``bridge.py``)."""
    _ = path_utf8
    _ = path_len
    (out_ncols + 0).store[width=1](SIMD[DType.int32, 1](0))
    (out_nrows + 0).store[width=1](SIMD[DType.int32, 1](0))
    return 0
