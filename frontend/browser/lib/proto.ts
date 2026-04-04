// TODO:
// [ ] protobuf browser: gen/ types; serialize/deserialize for Connect — https://protobuf.dev/reference/javascript/javascript-generated/
// [ ] proto → zod for forms; camelCase mapping — https://zod.dev/
// [ ] helpers: isProtoMessage; protoToJSON — https://connectrpc.com/docs/web/using-clients
//
import { create, fromBinary, fromJson, toBinary, toJson } from "@bufbuild/protobuf";
import type { GenMessage } from "@bufbuild/protobuf/codegenv2";
import type { JsonValue, Message, MessageShape } from "@bufbuild/protobuf";

/**
 * Protobuf helpers for generated `gen/` schemas.
 */
export function toJSON<T extends GenMessage<Message>>(schema: T, message: MessageShape<T>): unknown {
	return toJson(schema, message);
}

export function fromJSON<T extends GenMessage<Message>>(schema: T, json: unknown): MessageShape<T> {
	return fromJson(schema, json as JsonValue) as MessageShape<T>;
}

export function toBinaryBuf<T extends GenMessage<Message>>(schema: T, message: MessageShape<T>): Uint8Array {
	return toBinary(schema, message);
}

export function fromBinaryBuf<T extends GenMessage<Message>>(schema: T, bytes: Uint8Array): MessageShape<T> {
	return fromBinary(schema, bytes) as MessageShape<T>;
}

export function cloneMessage<T extends GenMessage<Message>>(schema: T, message: MessageShape<T>): MessageShape<T> {
	const json = toJson(schema, message);
	return fromJson(schema, json as JsonValue) as MessageShape<T>;
}

export function createEmpty<T extends GenMessage<Message>>(schema: T): MessageShape<T> {
	return create(schema) as MessageShape<T>;
}

export function isJsonCompatible<T extends GenMessage<Message>>(schema: T, value: unknown): value is Record<string, unknown> {
	if (value === null || typeof value !== "object") return false;
	try {
		fromJson(schema, value as JsonValue);
		return true;
	} catch {
		return false;
	}
}
