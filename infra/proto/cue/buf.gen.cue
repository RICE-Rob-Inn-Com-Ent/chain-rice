# Buf codegen – TypeScript + Connect. Run from root: buf generate
# Output under node/src/gen (node package consumes generated code).
version: v2
plugins:
  - plugin: es
    out: node/src/gen
    opt: target=ts
  - plugin: connect-es
    out: node/src/gen
    opt: target=ts
