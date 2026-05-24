"""Benchmarks for the ``helper`` package (convert, validate, schema)."""

from __future__ import annotations

import importlib
import json
from typing import Any

from ._resolve import helper_module
from ._timing import TimingSample, bench_call

_h = helper_module()
_schema = importlib.import_module(f"{_h.__name__}.schema")
Page = _schema.Page
SchemaBase = _schema.SchemaBase
parse_json = _h.parse_json
coerce_json = _h.coerce_json
validate_model_name = _h.validate_model_name
validate_slug = _h.validate_slug


class _BenchRow(SchemaBase):
    id: int
    name: str


_BenchPage = Page[_BenchRow]


def run_helper_benchmarks(*, repeat: int = 7, warmup: int = 2) -> list[TimingSample]:
    raw = json.dumps(
        {
            "items": [{"id": i, "name": f"row-{i}"} for i in range(500)],
            "offset": 0,
            "limit": 500,
            "has_next": False,
        },
    )
    payload: dict[str, Any] = {
        "items": [{"id": i, "name": f"row-{i}"} for i in range(500)],
        "offset": 0,
        "limit": 500,
        "has_next": False,
    }

    def parse_page() -> None:
        parse_json(_BenchPage, raw)

    def coerce() -> None:
        coerce_json(payload)

    def slug_loop() -> None:
        for i in range(200):
            validate_slug(f"bench-{i}-slug")

    def model_name_loop() -> None:
        for i in range(200):
            validate_model_name(f"org/model-{i}")

    return [
        bench_call("helper.parse_json(Page[Row])", parse_page, repeat=repeat, warmup=warmup),
        bench_call("helper.coerce_json(dict)", coerce, repeat=repeat, warmup=warmup),
        bench_call("helper.validate_slug x200", slug_loop, repeat=repeat, warmup=warmup),
        bench_call("helper.validate_model_name x200", model_name_loop, repeat=repeat, warmup=warmup),
    ]
