package kit

// TODO:
// [ ] implement protobuf encoding/decoding:
//     Encode(msg proto.Message) ([]byte, error)
//     Decode(b []byte, msg proto.Message) error
// [ ] implement protobuf JSON marshal:
//     MarshalJSON(msg proto.Message) ([]byte, error)
//     UnmarshalJSON(b []byte, msg proto.Message) error
//     uses protojson — handles well-known types correctly
// [ ] implement proto validation:
//     ValidateProto(msg proto.Message) error
//     validates required fields after Decode
// [ ] implement proto → map conversion for logging:
//     ToMap(msg proto.Message) map[string]any
//     used by zap logger to log proto without reflection

import (
	"fmt"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/reflect/protoregistry"
	"google.golang.org/protobuf/types/known/anypb"
)

// ProtoMarshal encodes m using the protobuf wire format.
func ProtoMarshal(m proto.Message) ([]byte, error) {
	return proto.Marshal(m)
}

// ProtoUnmarshal decodes wire data into m.
func ProtoUnmarshal(b []byte, m proto.Message) error {
	return proto.Unmarshal(b, m)
}

// ProtoClone returns a deep copy of m.
func ProtoClone[M proto.Message](m M) M {
	return proto.Clone(m).(M)
}

// ProtoMerge merges src into dst (dst must be non-nil).
func ProtoMerge(dst, src proto.Message) {
	proto.Merge(dst, src)
}

// ProtoJSONMarshalOptions configures JSON output for API boundaries.
type ProtoJSONMarshalOptions = protojson.MarshalOptions

// ProtoJSONUnmarshalOptions configures JSON parsing.
type ProtoJSONUnmarshalOptions = protojson.UnmarshalOptions

// DefaultProtoJSONMarshal emits protojson with stable, API-friendly defaults.
func DefaultProtoJSONMarshal() ProtoJSONMarshalOptions {
	return protojson.MarshalOptions{
		EmitUnpopulated: false,
		UseProtoNames:   true,
	}
}

// DefaultProtoJSONUnmarshal ignores unknown fields from clients.
func DefaultProtoJSONUnmarshal() ProtoJSONUnmarshalOptions {
	return protojson.UnmarshalOptions{DiscardUnknown: true}
}

// ProtoJSONMarshal serializes m to JSON using opts.
func ProtoJSONMarshal(m proto.Message, opts ProtoJSONMarshalOptions) ([]byte, error) {
	return opts.Marshal(m)
}

// ProtoJSONUnmarshal parses JSON into m using opts.
func ProtoJSONUnmarshal(b []byte, m proto.Message, opts ProtoJSONUnmarshalOptions) error {
	return opts.Unmarshal(b, m)
}

// FindMessageByName looks up a message descriptor in the global registry (e.g. "google.protobuf.Any").
func FindMessageByName(name protoreflect.FullName) (protoreflect.MessageType, error) {
	return protoregistry.GlobalTypes.FindMessageByName(name)
}

// UnpackAnyTo decodes a google.protobuf.Any into an existing concrete message.
func UnpackAnyTo(a *anypb.Any, msg proto.Message) error {
	if a == nil {
		return fmt.Errorf("kit: nil Any")
	}
	if msg == nil {
		return fmt.Errorf("kit: nil message")
	}
	return a.UnmarshalTo(msg)
}
