# Tokenizacja — padding do wielokrotności (stub BPE; pełne BPE w Pythonie `agent/context.py`).
# TODO:
# [ ] implement BPE tokenizer in Mojo:
# [ ]     vocab file path passed as parameter — not hardcoded
# [ ] implement parallel tokenization via parallelize()
# [ ] implement special token handling: PAD, UNK, BOS, EOS
# [ ]     token IDs from config — not hardcoded
# [ ] implement detokenization (inverse mapping)

fn bpe_pad_to_multiple(seq_len: Int, pad_to: Int) -> Int:
    if pad_to <= 0:
        return seq_len
    var r = seq_len % pad_to
    if r == 0:
        return seq_len
    return seq_len + (pad_to - r)


fn vocab_lookup_bounded(token_id: UInt32, vocab_size: UInt32) -> UInt32:
    if vocab_size == 0:
        return 0
    return token_id % vocab_size
