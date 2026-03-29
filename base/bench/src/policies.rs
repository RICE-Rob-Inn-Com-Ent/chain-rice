//! Policy engine — CEL compile/eval and XML scan (`quick-xml`).
use criterion::{black_box, Criterion};
use rice_policies::engine::{compile, evaluate, root_context};
use rice_policies::legal::root_element_name;

// [ ] https://docs.rs/criterion/ — cel-interpreter, fefix, quick-xml
// [ ] cel_eval, fix_parse, xml_parse, audit_publish, rule_load

pub fn register(c: &mut Criterion) {
    let program = compile("true").expect("cel compile");
    let ctx = root_context();
    let xml = r#"<?xml version="1.0"?><ComplianceEnvelope><item/></ComplianceEnvelope>"#;

    let mut g = c.benchmark_group("policies");
    g.bench_function("cel_compile_literal", |b| {
        b.iter(|| compile(black_box("true")).unwrap())
    });
    g.bench_function("cel_eval_literal", |b| {
        b.iter(|| evaluate(black_box(&program), black_box(&ctx)).unwrap())
    });
    g.bench_function("xml_root_element_name", |b| {
        b.iter(|| root_element_name(black_box(xml)).unwrap())
    });
    g.finish();
}
