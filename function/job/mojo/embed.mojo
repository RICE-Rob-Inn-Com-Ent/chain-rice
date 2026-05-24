# Embedding — SIMD dot / cosine / L2, Int8 & binary quantization, k-NN brute-force, PQ helpers.
# Buffers: ``UnsafePointer[Scalar[...]]`` (``RiceArray`` / ``bridge.py``). ``gemv_bias_f32`` loads row-major ``W``
# from checkpoints (BERT/CLIP-style). PQ expects ``dim == M * subdim`` and codebook layout ``[M*K][subdim]``.

from algorithm import parallelize
from math import abs, max, min
from memory.unsafe_pointer import UnsafePointer
from sys.info import num_physical_cores

from .simd import NATIVE_F32_LANES, v_fma, v_mul, v_sqrt, v_sub

alias W: Int = NATIVE_F32_LANES
alias F32Ptr = UnsafePointer[Scalar[DType.float32]]
alias I32Ptr = UnsafePointer[Scalar[DType.int32]]
alias I8Ptr = UnsafePointer[Scalar[DType.int8]]
alias U8Ptr = UnsafePointer[Scalar[DType.uint8]]

alias F32x8 = SIMD[DType.float32, 8]

alias EMBED_METRIC_DOT: Int = 0
alias EMBED_METRIC_COSINE: Int = 1
alias EMBED_METRIC_L2_SQ: Int = 2


# === Legacy 8-wide (unchanged ABI for ``__init__.mojo``) =======================================


fn l2_norm_f32x8(v: F32x8) -> Float32:
    return (v * v).reduce_add().sqrt()


fn cosine_f32x8(a: F32x8, b: F32x8) -> Float32:
    var dp = (a * b).reduce_add()
    var na = (a * a).reduce_add().sqrt()
    var nb = (b * b).reduce_add().sqrt()
    return dp / (na * nb)


# === Dot / norms (SIMD, ``v_fma`` accumulation) ================================================


@always_inline
fn dot_product_f32(v1: F32Ptr, v2: F32Ptr, dim: Int) -> Float32:
    """Inner product ``sum_i v1[i]*v2[i]`` (alias of FMA dot)."""
    return dot_product_f32_fma(v1, v2, dim)


@always_inline
fn dot_product_f32_fma(v1: F32Ptr, v2: F32Ptr, dim: Int) -> Float32:
    """Strict FMA dot: ``acc = sum(a*b)`` via ``v_fma(a, b, acc)`` chunks (width ``W``)."""
    var accv = SIMD[DType.float32, W](0.0)
    var i: Int = 0
    while i + W <= dim:
        var a = (v1 + i).load[width=W]()
        var b = (v2 + i).load[width=W]()
        accv = v_fma[DType.float32, W](a, b, accv)
        i += W
    var acc = accv.reduce_add()
    while i < dim:
        var a = (v1 + i).load[width=1]()
        var b = (v2 + i).load[width=1]()
        acc = v_fma[DType.float32, 1](a, b, SIMD[DType.float32, 1](acc)).reduce_add()
        i += 1
    return acc


@always_inline
fn norm_squared_f32_fma(v: F32Ptr, dim: Int) -> Float32:
    """``||v||^2`` with FMA accumulation."""
    var accv = SIMD[DType.float32, W](0.0)
    var i: Int = 0
    while i + W <= dim:
        var a = (v + i).load[width=W]()
        accv = v_fma[DType.float32, W](a, a, accv)
        i += W
    var acc = accv.reduce_add()
    while i < dim:
        var a = (v + i).load[width=1]()
        acc = v_fma[DType.float32, 1](a, a, SIMD[DType.float32, 1](acc)).reduce_add()
        i += 1
    return acc


@always_inline
fn euclidean_squared_f32(v1: F32Ptr, v2: F32Ptr, dim: Int) -> Float32:
    """``||v1-v2||^2`` using ``v_sub`` / ``v_mul`` (then horizontal sum)."""
    var accv = SIMD[DType.float32, W](0.0)
    var i: Int = 0
    while i + W <= dim:
        var a = (v1 + i).load[width=W]()
        var b = (v2 + i).load[width=W]()
        var d = v_sub[DType.float32, W](a, b)
        accv = accv + v_mul[DType.float32, W](d, d)
        i += W
    var acc = accv.reduce_add()
    while i < dim:
        var a = (v1 + i).load[width=1]()
        var b = (v2 + i).load[width=1]()
        var d = v_sub[DType.float32, 1](a, b)
        var p = v_mul[DType.float32, 1](d, d)
        acc += p.reduce_add()
        i += 1
    return acc


fn cosine_similarity(v1: F32Ptr, v2: F32Ptr, dim: Int) -> Float32:
    """Cosine in ``[-1,1]``; dot and norms via FMA, ``v_sqrt`` on scalar sums."""
    var dp = dot_product_f32_fma(v1, v2, dim)
    var n1 = norm_squared_f32_fma(v1, dim)
    var n2 = norm_squared_f32_fma(v2, dim)
    var d1 = v_sqrt[DType.float32, 1](SIMD[DType.float32, 1](max(n1, Float32(1e-12))))[0]
    var d2 = v_sqrt[DType.float32, 1](SIMD[DType.float32, 1](max(n2, Float32(1e-12))))[0]
    return dp / (d1 * d2)


fn euclidean_distance(v1: F32Ptr, v2: F32Ptr, dim: Int) -> Float32:
    """``||v1-v2||_2``."""
    var s = euclidean_squared_f32(v1, v2, dim)
    return v_sqrt[DType.float32, 1](SIMD[DType.float32, 1](max(s, Float32(0.0))))[0]


fn l2_normalize_f32_inplace(v: F32Ptr, dim: Int):
    """Divide ``v`` by ``||v||_2`` (in-place)."""
    var n2 = norm_squared_f32_fma(v, dim)
    var inv = Float32(1.0) / v_sqrt[DType.float32, 1](SIMD[DType.float32, 1](max(n2, Float32(1e-12))))[0]
    var i: Int = 0
    var sv = SIMD[DType.float32, W](inv)
    while i + W <= dim:
        (v + i).store[width=W]((v + i).load[width=W]() * sv)
        i += W
    while i < dim:
        (v + i).store[width=1]((v + i).load[width=1>() * SIMD[DType.float32, 1](inv))
        i += 1


# === Quantization =============================================================================


fn quantize_symmetric_i8(v: F32Ptr, dim: Int, out_i8: I8Ptr, scale_out: F32Ptr):
    """Symmetric int8: ``out ≈ round(v / scale)`` with ``scale = max|v|/127`` (``scale_out[0]``)."""
    var mabs = Float32(0.0)
    for i in range(dim):
        var t = abs((v + i).load[width=1]()[0])
        mabs = max(mabs, t)
    var scale = mabs / Float32(127.0)
    if scale < Float32(1e-12):
        scale = Float32(1e-12)
    scale_out[0] = scale
    var invs = Float32(1.0) / scale
    for i in range(dim):
        var x = (v + i).load[width=1]()[0] * invs
        var rnd = Float32(0.5) if x >= Float32(0.0) else Float32(-0.5)
        var qi = Int32(x + rnd)
        if qi < -128:
            qi = -128
        if qi > 127:
            qi = 127
        (out_i8 + i).store[width=1](SIMD[DType.int8, 1](Int8(Int(qi))))


fn dequantize_i8_to_f32(out_f32: F32Ptr, q: I8Ptr, dim: Int, scale: Float32):
    """``out_f32[i] = scale * float(q[i])``."""
    for i in range(dim):
        var iv = Int32(Int((q + i).load[width=1]()[0]))
        var fv = Float32(iv) * scale
        (out_f32 + i).store[width=1](SIMD[DType.float32, 1](fv))


fn pack_sign_binary_u8(v: F32Ptr, dim: Int, out_bytes: U8Ptr):
    """Pack sign bits ``(v[i]>=0)`` MSB-first, ``ceil(dim/8)`` bytes at ``out_bytes``."""
    var nbytes = (dim + 7) // 8
    var bi: Int = 0
    while bi < nbytes:
        var bytev: UInt8 = 0
        var bit: Int = 0
        while bit < 8:
            var idx = bi * 8 + bit
            if idx >= dim:
                break
            var s = (v + idx).load[width=1]()[0]
            if s >= Float32(0.0):
                var sh = 7 - bit
                bytev = UInt8(Int(bytev) | (1 << sh))
            bit += 1
        (out_bytes + bi).store[width=1](SIMD[DType.uint8, 1](bytev))
        bi += 1


@always_inline
fn _popcount_byte(x: UInt8) -> Int:
    var v = Int(x)
    var c = 0
    var b = 0
    while b < 8:
        c += (v >> b) & 1
        b += 1
    return c


fn hamming_distance_u8(a: U8Ptr, b: U8Ptr, num_bytes: Int) -> Int:
    """Popcount XOR between packed sign vectors."""
    var tot: Int = 0
    var i: Int = 0
    while i < num_bytes:
        var x = (a + i).load[width=1]()[0]
        var y = (b + i).load[width=1]()[0]
        tot += _popcount_byte(x ^ y)
        i += 1
    return tot


# === PQ (codebook + byte codes) ===============================================================


@always_inline
fn _pq_centroid_ptr(codebook: F32Ptr, M: Int, K: Int, subdim: Int, sub: Int, code: Int) -> F32Ptr:
    """Row ``(sub, code)`` in layout ``[M*K][subdim]`` row-major."""
    return codebook + (sub * K + code) * subdim


fn pq_codes_l2_squared(
    codebook: F32Ptr,
    M: Int,
    K: Int,
    subdim: Int,
    codes_a: U8Ptr,
    codes_b: U8Ptr,
) -> Float32:
    """Symmetric PQ surrogate: ``sum_m ||C_m[a_m] - C_m[b_m]||^2`` (ranking distance)."""
    var acc = Float32(0.0)
    for m in range(M):
        var ia = Int((codes_a + m).load[width=1]()[0])
        var ib = Int((codes_b + m).load[width=1]()[0])
        if ia < 0:
            ia = 0
        if ia >= K:
            ia = K - 1
        if ib < 0:
            ib = 0
        if ib >= K:
            ib = K - 1
        var pa = _pq_centroid_ptr(codebook, M, K, subdim, m, ia)
        var pb = _pq_centroid_ptr(codebook, M, K, subdim, m, ib)
        acc += euclidean_squared_f32(pa, pb, subdim)
    return acc


fn pq_query_residual_squared(
    query: F32Ptr,
    dim: Int,
    M: Int,
    K: Int,
    subdim: Int,
    codebook: F32Ptr,
    codes: U8Ptr,
) -> Float32:
    """Asymmetric PQ: ``sum_m ||q_subm - C_m[c_m]||^2`` (ADC-style residual energy)."""
    var acc = Float32(0.0)
    for m in range(M):
        var cid = Int((codes + m).load[width=1]()[0])
        if cid < 0:
            cid = 0
        if cid >= K:
            cid = K - 1
        var qsub = query + m * subdim
        var csub = _pq_centroid_ptr(codebook, M, K, subdim, m, cid)
        acc += euclidean_squared_f32(qsub, csub, subdim)
    return acc


# === k-NN brute-force =========================================================================


fn _score_row(
    query: F32Ptr,
    row: F32Ptr,
    dim: Int,
    metric: Int,
    query_norm_sq: Float32,
    row_norm_sq: Float32,
) -> Float32:
    if metric == EMBED_METRIC_DOT:
        return dot_product_f32_fma(query, row, dim)
    if metric == EMBED_METRIC_COSINE:
        var dp = dot_product_f32_fma(query, row, dim)
        var rn = max(row_norm_sq, Float32(1e-12))
        var qn = max(query_norm_sq, Float32(1e-12))
        var d1 = v_sqrt[DType.float32, 1](SIMD[DType.float32, 1](qn))[0]
        var d2 = v_sqrt[DType.float32, 1](SIMD[DType.float32, 1](rn))[0]
        return dp / (d1 * d2)
    var d2 = euclidean_squared_f32(query, row, dim)
    return -d2


fn find_top_k(
    query: F32Ptr,
    dim: Int,
    db: F32Ptr,
    num_vectors: Int,
    row_stride: Int,
    query_norm_sq: Float32,
    db_norm_sq: F32Ptr,
    k: Int,
    scores: F32Ptr,
    out_idx: I32Ptr,
    out_score: F32Ptr,
    metric: Int,
):
    """Brute-force k-NN: parallel score fill, then O(n·k) partial selection (higher score = better).

    ``scores`` length ``>= num_vectors``. For ``EMBED_METRIC_COSINE``, pass ``db_norm_sq[i]=||row_i||^2``;
    ``query_norm_sq = ||query||^2``. For ``EMBED_METRIC_L2_SQ`` / ``DOT``, ``db_norm_sq`` may be dummy (use query row).
    """
    if k <= 0 or num_vectors <= 0 or dim <= 0:
        return
    var kk = k
    if kk > num_vectors:
        kk = num_vectors
    var workers = num_physical_cores()
    if workers < 1:
        workers = 1
    if workers > num_vectors:
        workers = num_vectors

    def score_job(wid: Int):
        var i = wid
        while i < num_vectors:
            var row = db + i * row_stride
            var rns = query_norm_sq
            if metric != EMBED_METRIC_DOT:
                rns = (db_norm_sq + i).load[width=1]()[0]
            scores[i] = _score_row(query, row, dim, metric, query_norm_sq, rns)
            i += workers

    parallelize[score_job](workers, workers)

    for j in range(kk):
        var best_i = -1
        var best_s = Float32(-3.4e38)
        for i in range(num_vectors):
            var s = scores[i]
            if s > best_s:
                var taken = False
                var t: Int = 0
                while t < j:
                    if out_idx[t] == i:
                        taken = True
                        break
                    t += 1
                if not taken:
                    best_s = s
                    best_i = i
        if best_i >= 0:
            out_idx[j] = best_i
            out_score[j] = best_s


# === Linear layer (pretrained projection from ``bridge.py``) ==================================


fn gemv_bias_f32(
    out_dim: Int,
    in_dim: Int,
    W_row_major: F32Ptr,
    x: F32Ptr,
    bias: F32Ptr,
    y: F32Ptr,
    has_bias: Bool,
):
    """``y = W @ x + b`` with ``W`` row-major ``[out_dim][in_dim]`` (one embedding / logits row)."""
    for r in range(out_dim):
        var row = W_row_major + r * in_dim
        var acc = dot_product_f32_fma(row, x, in_dim)
        if has_bias:
            acc += (bias + r).load[width=1]()[0]
        (y + r).store[width=1](SIMD[DType.float32, 1](acc))
