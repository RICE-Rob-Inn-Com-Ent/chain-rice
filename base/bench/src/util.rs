//! [`util::bytes`] + [`util::proto`] micro-workloads.

use criterion::{Criterion, black_box};

use crate::{BenchRow, smoke_ns};

pub fn smoke_rows() -> Vec<BenchRow> {
    let mut rows = Vec::new();
    let hex_in = "deadbeef";
    let ns_hex = smoke_ns(|| {
        let _ = black_box(util::bytes::decode_hex(hex_in));
    });
    rows.push(BenchRow {
        module: "util/bytes",
        scenario: "decode_hex",
        ns: ns_hex,
        notes: util::bytes::decode_hex(hex_in)
            .map(|v| format!("bytes={}", v.len()))
            .unwrap_or_else(|e| e.to_string()),
    });
    let ns_proto = smoke_ns(|| {
        let _ = black_box(util::proto::length_delimited_frame_byte_count(&[]));
    });
    rows.push(BenchRow {
        module: "util/proto",
        scenario: "length_delimited_frame_byte_count_empty",
        ns: ns_proto,
        notes: format!("{:?}", util::proto::length_delimited_frame_byte_count(&[])),
    });
    rows
}

pub fn register(c: &mut Criterion) {
    let mut g = c.benchmark_group("util");
    g.bench_function("decode_hex", |b| {
        b.iter(|| black_box(util::bytes::decode_hex(black_box("cafebabe")).unwrap()));
    });
    g.bench_function("proto_frame_empty", |b| {
        b.iter(|| black_box(util::proto::length_delimited_frame_byte_count(black_box(&[][..])).unwrap()));
    });
    g.finish();
}
