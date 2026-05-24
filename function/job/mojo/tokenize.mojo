# Tokenization — UTF-8 validate (SIMD ASCII fast path), clean_text, hash-table BPE merges, parallel paragraphs.
# Zero-copy: all I/O is ``UnsafePointer`` / ``RiceArray`` views; bridge builds ``merge_*`` open-hash tables (50k+ merges).

from algorithm import parallelize
from memory.unsafe_pointer import UnsafePointer
from sys.info import num_physical_cores

from .simd import NATIVE_F32_LANES

alias W8: Int = NATIVE_F32_LANES
alias U8Ptr = UnsafePointer[Scalar[DType.uint8]]
alias I32Ptr = UnsafePointer[Scalar[DType.int32]]
alias U32Ptr = UnsafePointer[Scalar[DType.uint32]]
alias U64Ptr = UnsafePointer[Scalar[DType.uint64]]

alias UTF8_OK: Int = 0
alias UTF8_ERR: Int = -1

alias BPE_EMPTY_KEY: UInt64 = 0xFFFFFFFFFFFFFFFF


# === Legacy (unchanged ABI) ====================================================================


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


# === UTF-8 ===================================================================================


@always_inline
fn _utf8_continuation(b: UInt8) -> Bool:
    return (b & 0xC0) == 0x80


fn utf8_validate_scalar(text: U8Ptr, nbytes: Int) -> Int:
    """Return ``UTF8_OK`` or ``UTF8_ERR`` if bytes are not valid UTF-8."""
    var i: Int = 0
    while i < nbytes:
        var c0 = (text + i).load[width=1]()[0]
        if (c0 & 0x80) == 0:
            i += 1
            continue
        if (c0 & 0xE0) == 0xC0:
            if i + 1 >= nbytes:
                return UTF8_ERR
            if not _utf8_continuation((text + i + 1).load[width=1]()[0]):
                return UTF8_ERR
            var v = UInt32(c0 & 0x1F) << 6 | UInt32((text + i + 1).load[width=1]()[0] & 0x3F)
            if v < 0x80:
                return UTF8_ERR
            i += 2
            continue
        if (c0 & 0xF0) == 0xE0:
            if i + 2 >= nbytes:
                return UTF8_ERR
            if not _utf8_continuation((text + i + 1).load[width=1]()[0]):
                return UTF8_ERR
            if not _utf8_continuation((text + i + 2).load[width=1]()[0]):
                return UTF8_ERR
            var v = (
                UInt32(c0 & 0x0F) << 12
                | UInt32((text + i + 1).load[width=1]()[0] & 0x3F) << 6
                | UInt32((text + i + 2).load[width=1]()[0] & 0x3F)
            )
            if v < 0x800 or (v >= 0xD800 and v <= 0xDFFF):
                return UTF8_ERR
            i += 3
            continue
        if (c0 & 0xF8) == 0xF0:
            if i + 3 >= nbytes:
                return UTF8_ERR
            if not _utf8_continuation((text + i + 1).load[width=1]()[0]):
                return UTF8_ERR
            if not _utf8_continuation((text + i + 2).load[width=1]()[0]):
                return UTF8_ERR
            if not _utf8_continuation((text + i + 3).load[width=1]()[0]):
                return UTF8_ERR
            var v = (
                UInt32(c0 & 0x07) << 18
                | UInt32((text + i + 1).load[width=1]()[0] & 0x3F) << 12
                | UInt32((text + i + 2).load[width=1]()[0] & 0x3F) << 6
                | UInt32((text + i + 3).load[width=1]()[0] & 0x3F)
            )
            if v < 0x10000 or v > 0x10FFFF:
                return UTF8_ERR
            i += 4
            continue
        return UTF8_ERR
    return UTF8_OK


fn utf8_validate_simd_ascii_run(text: U8Ptr, nbytes: Int) -> Bool:
    """True iff every byte has high bit clear (ASCII-only buffer); SIMD chunk scan."""
    var i: Int = 0
    while i + W8 <= nbytes:
        var v = (text + i).load[width=W8]()
        var zero = SIMD[DType.uint8, W8](0)
        var hi = SIMD[DType.uint8, W8](0x80)
        var m = (v & hi) != zero
        var any_hi = False
        for lane in range(W8):
            if m[lane]:
                any_hi = True
                break
        if any_hi:
            return False
        i += W8
    while i < nbytes:
        if ((text + i).load[width=1]()[0] & UInt8(0x80)) != 0:
            return False
        i += 1
    return True


fn utf8_validate(text: U8Ptr, nbytes: Int) -> Int:
    """Validate UTF-8: fast ASCII SIMD path, else scalar full check."""
    if nbytes < 0:
        return UTF8_ERR
    if nbytes == 0:
        return UTF8_OK
    if utf8_validate_simd_ascii_run(text, nbytes):
        return UTF8_OK
    return utf8_validate_scalar(text, nbytes)


# === clean_text ===============================================================================


fn clean_text(out: U8Ptr, text: U8Ptr, text_len: Int) -> Int:
    """Copy ``text`` to ``out`` stripping HTML-like ``<...>`` spans and collapsing ASCII whitespace to ``0x20``.

    Returns output length (``out`` must hold at least ``text_len`` bytes).
    """
    var o: Int = 0
    var i: Int = 0
    var in_tag = False
    var last_space = False
    while i < text_len:
        var b = (text + i).load[width=1]()[0]
        i += 1
        if in_tag:
            if b == UInt8(62):
                in_tag = False
            continue
        if b == UInt8(60):
            in_tag = True
            continue
        var is_ws = b == UInt8(32) or b == UInt8(9) or b == UInt8(10) or b == UInt8(13)
        if is_ws:
            if not last_space:
                (out + o).store[width=1](SIMD[DType.uint8, 1](UInt8(32)))
                o += 1
                last_space = True
            continue
        last_space = False
        (out + o).store[width=1](SIMD[DType.uint8, 1](b))
        o += 1
    return o


# === BPE hash merge (bridge-filled open table) =================================================


@always_inline
fn _pair_key(a: UInt32, b: UInt32) -> UInt64:
    return (UInt64(a) << 32) | UInt64(b)


@always_inline
fn _pair_slot(want: UInt64, bucket_count: Int, keys: U64Ptr) -> Int:
    """Linear probe for ``want``; returns slot index or ``-1`` if empty miss."""
    if bucket_count <= 0:
        return -1
    var h0 = Int(want % UInt64(Int(bucket_count)))
    var t: Int = 0
    while t < bucket_count:
        var slot = (h0 + t) % bucket_count
        var k = (keys + slot).load[width=1]()[0]
        if k == BPE_EMPTY_KEY:
            return -1
        if k == want:
            return slot
        t += 1
    return -1


fn bpe_merge_one_pass(
    ids: U32Ptr,
    inout length: Int,
    bucket_count: Int,
    merge_keys: U64Ptr,
    merge_ranks: I32Ptr,
    merge_new_id: U32Ptr,
) -> Bool:
    """Single left-to-right merge pass using **minimum rank** adjacent pair (classic BPE order).

    Returns ``True`` if a merge was applied. Tables must align: ``merge_keys[slot]`` matches pair.
    """
    if length < 2:
        return False
    var best_r = Int32(2147483647)
    var best_i = -1
    var best_new = UInt32(0)
    var i: Int = 0
    while i < length - 1:
        var a = (ids + i).load[width=1]()[0]
        var b = (ids + i + 1).load[width=1]()[0]
        var want = _pair_key(a, b)
        var slot = _pair_slot(want, bucket_count, merge_keys)
        if slot < 0:
            i += 1
            continue
        var r = (merge_ranks + slot).load[width=1]()[0]
        if r < 0:
            i += 1
            continue
        if (r < best_r) or (r == best_r and best_i >= 0 and i < best_i):
            best_r = r
            best_i = i
            best_new = (merge_new_id + slot).load[width=1]()[0]
        i += 1
    if best_i < 0:
        return False
    (ids + best_i).store[width=1](SIMD[DType.uint32, 1](best_new))
    var j = best_i + 1
    while j < length - 1:
        (ids + j).store[width=1]((ids + j + 1).load[width=1]())
        j += 1
    length -= 1
    return True


fn bpe_reduce_ids(
    ids: U32Ptr,
    inout length: Int,
    bucket_count: Int,
    merge_keys: U64Ptr,
    merge_ranks: I32Ptr,
    merge_new_id: U32Ptr,
    max_passes: Int,
):
    """Apply ``bpe_merge_one_pass`` until quiescent or ``max_passes`` reached."""
    var p: Int = 0
    while p < max_passes:
        if not bpe_merge_one_pass(ids, length, bucket_count, merge_keys, merge_ranks, merge_new_id):
            break
        p += 1


@always_inline
fn _simd_eq_adjacent_ids(ids: U32Ptr, _len: Int, pos: Int, _w: Int) -> SIMD[DType.bool, W8]:
    """Lane ``ℓ`` is ``True`` iff ``ids[pos+ℓ] == ids[pos+ℓ+1]`` (for diagnostics / repeat-token SIMD)."""
    var a = (ids + pos).load[width=W8]()
    var b = (ids + pos + 1).load[width=W8]()
    return a == b


fn encode_utf8_bpe(
    text: U8Ptr,
    text_len: Int,
    out_ids: U32Ptr,
    out_cap: Int,
    work_ids: U32Ptr,
    work_cap: Int,
    bucket_count: Int,
    merge_keys: U64Ptr,
    merge_ranks: I32Ptr,
    merge_new_id: U32Ptr,
    byte_to_id: U32Ptr,
    unk_id: UInt32,
    bos_id: UInt32,
    eos_id: UInt32,
    add_bos: Bool,
    add_eos: Bool,
    require_valid_utf8: Bool,
) -> Int:
    """Byte-level BPE: UTF-8 bytes → ``byte_to_id`` → merges → ``out_ids``. Returns token count or ``-1``.

    ``work_cap >= text_len``. ``out_cap >=`` final tokens + optional BOS/EOS. Merge tables from bridge (RiceArray).
    """
    if text_len < 0 or work_cap < text_len or out_cap < 0:
        return -1
    if require_valid_utf8 and utf8_validate(text, text_len) != UTF8_OK:
        return -1
    var n = text_len
    if n > work_cap:
        return -1
    var i: Int = 0
    while i < n:
        var b = UInt32((text + i).load[width=1]()[0])
        if Int(b) < 256:
            var tid = (byte_to_id + Int(b)).load[width=1]()[0]
            (work_ids + i).store[width=1](SIMD[DType.uint32, 1](tid))
        else:
            (work_ids + i).store[width=1](SIMD[DType.uint32, 1](unk_id))
        i += 1
    var length = n
    var max_passes = n * 2
    bpe_reduce_ids(work_ids, length, bucket_count, merge_keys, merge_ranks, merge_new_id, max_passes)
    var need = length + (1 if add_bos else 0) + (1 if add_eos else 0)
    if need > out_cap:
        return -1
    var o: Int = 0
    if add_bos:
        (out_ids + o).store[width=1](SIMD[DType.uint32, 1](bos_id))
        o += 1
    i = 0
    while i < length:
        (out_ids + o + i).store[width=1]((work_ids + i).load[width=1]())
        i += 1
    o += length
    if add_eos:
        (out_ids + o).store[width=1](SIMD[DType.uint32, 1](eos_id))
        o += 1
    return o


# === Paragraph offsets (bridge can precompute) ================================================


fn paragraph_offsets_from_newlines(body: U8Ptr, nbytes: Int, out_off: I32Ptr, max_slots: Int) -> Int:
    """``out_off[p]`` = byte start of paragraph ``p``; ``out_off[npara]=nbytes``. Split on ``\\n``.

    Returns ``npara`` (``>= 1`` if ``nbytes>0``). Needs ``max_slots >= npara + 1``.
    """
    if max_slots < 2 or nbytes < 0:
        return 0
    (out_off + 0).store[width=1](SIMD[DType.int32, 1](0))
    var idx: Int = 1
    var i: Int = 0
    while i < nbytes:
        if (body + i).load[width=1]()[0] == UInt8(10):
            if idx >= max_slots - 1:
                break
            (out_off + idx).store[width=1](SIMD[DType.int32, 1](Int32(i + 1)))
            idx += 1
        i += 1
    if idx < max_slots:
        (out_off + idx).store[width=1](SIMD[DType.int32, 1](Int32(nbytes)))
    else:
        (out_off + max_slots - 1).store[width=1](SIMD[DType.int32, 1](Int32(nbytes)))
        idx = max_slots - 1
    return idx


# === Parallel paragraphs =====================================================================


fn encode_paragraphs_parallel(
    body: U8Ptr,
    para_off: I32Ptr,
    npara: Int,
    max_tokens_per_para: Int,
    out_block: U32Ptr,
    out_counts: I32Ptr,
    work_scratch: U32Ptr,
    scratch_stride: Int,
    bucket_count: Int,
    merge_keys: U64Ptr,
    merge_ranks: I32Ptr,
    merge_new_id: U32Ptr,
    byte_to_id: U32Ptr,
    unk_id: UInt32,
    bos_id: UInt32,
    eos_id: UInt32,
    add_bos: Bool,
    add_eos: Bool,
):
    """Encode each paragraph slice ``body[para_off[p]:para_off[p+1])`` into ``out_block + p*max_tokens_per_para``.

    ``work_scratch + p*scratch_stride`` must hold at least paragraph byte-length ``UInt32``s. ``out_counts[p]`` set to token count.
    """
    if npara <= 0 or max_tokens_per_para <= 0:
        return
    var workers = num_physical_cores()
    if workers < 1:
        workers = 1
    if workers > npara:
        workers = npara

    def job(pid: Int):
        var p = pid
        while p < npara:
            var a = Int((para_off + p).load[width=1]()[0])
            var b = Int((para_off + p + 1).load[width=1]()[0])
            if b < a:
                b = a
            var plen = b - a
            var w = work_scratch + p * scratch_stride
            var out_row = out_block + p * max_tokens_per_para
            var c = encode_utf8_bpe(
                body + a,
                plen,
                out_row,
                max_tokens_per_para,
                w,
                scratch_stride,
                bucket_count,
                merge_keys,
                merge_ranks,
                merge_new_id,
                byte_to_id,
                unk_id,
                bos_id,
                eos_id,
                add_bos,
                add_eos,
                False,
            )
            if c < 0:
                (out_counts + p).store[width=1](SIMD[DType.int32, 1](0))
            else:
                (out_counts + p).store[width=1](SIMD[DType.int32, 1](Int32(c)))
            p += workers

    parallelize[job](workers, workers)
