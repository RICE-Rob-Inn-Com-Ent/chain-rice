# Embedding — cosinus, norma L2, batch (wektor SIMD).
# TODO:
# [ ] implement token embedding lookup:
# [ ]     vocab_size, embed_dim as runtime parameters — not hardcoded
# [ ] implement positional encoding: sinusoidal + learned variants
# [ ] implement embedding normalization: L2 norm via SIMD
# [ ] implement batched embedding for multiple sequences
# [ ] integrate with tokenize.mojo for end-to-end pipeline

alias F32x8 = SIMD[DType.float32, 8]


fn l2_norm_f32x8(v: F32x8) -> Float32:
    return (v * v).reduce_add().sqrt()


fn cosine_f32x8(a: F32x8, b: F32x8) -> Float32:
    var dp = (a * b).reduce_add()
    var na = (a * a).reduce_add().sqrt()
    var nb = (b * b).reduce_add().sqrt()
    return dp / (na * nb)
