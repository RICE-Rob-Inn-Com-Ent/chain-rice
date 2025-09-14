## Protobuf Hello World

**Generate Code (using `protoc`)**

- Example (Go): `protoc --go_out=. --go-grpc_out=. hello.proto`
- Example (JS): `protoc --js_out=import_style=commonjs,binary:. hello.proto`

If using `buf`, see repo-level `buf.yaml` and run: `buf generate`.

Files in this example:

- `hello.proto`: Greeter (SayHello)
- `user.proto`: UserService (GetUser)
- `message.proto`: chat message with `MessageType`

See `ARCHITECTURE.md` for structure and extension ideas.


