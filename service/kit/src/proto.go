package kit

// Protobuf helpers: timestamps, wire + JSON codecs, clone/merge, Any utilities.

import (
	"net/http"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/reflect/protoregistry"
	"google.golang.org/protobuf/types/known/anypb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// jsonMarshaler and jsonUnmarshaler back [ToJSON] / [FromJSON] (camelCase JSON names, stable for APIs).
var (
	jsonMarshaler = protojson.MarshalOptions{
		UseProtoNames:   false, // use JSON names from descriptors (typically camelCase)
		EmitUnpopulated: false,
		UseEnumNumbers:  false,
	}
	jsonUnmarshaler = protojson.UnmarshalOptions{
		DiscardUnknown: true,
	}
)

// ToProtoTime converts t to [timestamppb.Timestamp]. A zero [time.Time] returns nil (omit in proto3 JSON / optional fields).
func ToProtoTime(t time.Time) *timestamppb.Timestamp {
	if t.IsZero() {
		return nil
	}
	return timestamppb.New(t)
}

// FromProtoTime converts p to [time.Time]. A nil p returns the zero time.
func FromProtoTime(p *timestamppb.Timestamp) time.Time {
	if p == nil {
		return time.Time{}
	}
	return p.AsTime()
}

// Marshal encodes m with [proto.Marshal]. On failure returns a [*Error] (code PROTO_MARSHAL_FAILED, HTTP 500).
func Marshal(m proto.Message) ([]byte, error) {
	if m == nil {
		return nil, BadRequest("proto.Marshal: nil message")
	}
	b, err := proto.Marshal(m)
	if err != nil {
		return nil, New("PROTO_MARSHAL_FAILED", "protobuf wire marshal failed", http.StatusInternalServerError, codes.Internal).
			Wrap(err, "proto.Marshal")
	}
	return b, nil
}

// Unmarshal decodes wire data into m. On failure returns a [*Error] with code PROTO_UNMARSHAL_FAILED.
func Unmarshal(b []byte, m proto.Message) error {
	if m == nil {
		return BadRequest("proto.Unmarshal: nil message")
	}
	if err := proto.Unmarshal(b, m); err != nil {
		return New("PROTO_UNMARSHAL_FAILED", "protobuf wire unmarshal failed", http.StatusBadRequest, codes.InvalidArgument).
			WithDetails(map[string]any{"wire_bytes": len(b)}).
			Wrap(err, "proto.Unmarshal")
	}
	return nil
}

// ToJSON serializes m with [protojson] (JSON field names, enum strings). On failure returns PROTO_JSON_MARSHAL_FAILED.
func ToJSON(m proto.Message) (string, error) {
	if m == nil {
		return "", BadRequest("proto.ToJSON: nil message")
	}
	b, err := jsonMarshaler.Marshal(m)
	if err != nil {
		return "", New("PROTO_JSON_MARSHAL_FAILED", "protojson marshal failed", http.StatusInternalServerError, codes.Internal).
			Wrap(err, "protojson.Marshal")
	}
	return string(b), nil
}

// FromJSON parses JSON into m. On failure returns PROTO_JSON_UNMARSHAL_FAILED (HTTP 400).
func FromJSON(s string, m proto.Message) error {
	if m == nil {
		return BadRequest("proto.FromJSON: nil message")
	}
	if err := jsonUnmarshaler.Unmarshal([]byte(s), m); err != nil {
		return New("PROTO_JSON_UNMARSHAL_FAILED", "protojson unmarshal failed", http.StatusBadRequest, codes.InvalidArgument).
			Wrap(err, "protojson.Unmarshal")
	}
	return nil
}

// Clone returns a deep copy of m. A nil concrete message returns the zero value of T.
func Clone[T proto.Message](m T) T {
	if proto.Message(m) == nil {
		var z T
		return z
	}
	return proto.Clone(m).(T)
}

// Merge copies fields from src into dst ([proto.Merge]). Returns an error if dst or src is nil.
func Merge(dst, src proto.Message) error {
	if dst == nil {
		return BadRequest("proto.Merge: nil destination")
	}
	if src == nil {
		return BadRequest("proto.Merge: nil source")
	}
	proto.Merge(dst, src)
	return nil
}

// ProtoJSONMarshalOptions aliases [protojson.MarshalOptions] for custom call sites.
type ProtoJSONMarshalOptions = protojson.MarshalOptions

// ProtoJSONUnmarshalOptions aliases [protojson.UnmarshalOptions].
type ProtoJSONUnmarshalOptions = protojson.UnmarshalOptions

// DefaultProtoJSONMarshal returns options matching [ToJSON] (camelCase JSON names, no unpopulated emission).
func DefaultProtoJSONMarshal() ProtoJSONMarshalOptions {
	return jsonMarshaler
}

// DefaultProtoJSONUnmarshal returns options matching [FromJSON] (unknown fields discarded).
func DefaultProtoJSONUnmarshal() ProtoJSONUnmarshalOptions {
	return jsonUnmarshaler
}

// ProtoJSONMarshal serializes m with opts.
func ProtoJSONMarshal(m proto.Message, opts ProtoJSONMarshalOptions) ([]byte, error) {
	if m == nil {
		return nil, BadRequest("proto.ProtoJSONMarshal: nil message")
	}
	b, err := opts.Marshal(m)
	if err != nil {
		return nil, New("PROTO_JSON_MARSHAL_FAILED", "protojson marshal failed", http.StatusInternalServerError, codes.Internal).
			Wrap(err, "protojson.Marshal")
	}
	return b, nil
}

// ProtoJSONUnmarshal parses JSON into m with opts.
func ProtoJSONUnmarshal(b []byte, m proto.Message, opts ProtoJSONUnmarshalOptions) error {
	if m == nil {
		return BadRequest("proto.ProtoJSONUnmarshal: nil message")
	}
	if err := opts.Unmarshal(b, m); err != nil {
		return New("PROTO_JSON_UNMARSHAL_FAILED", "protojson unmarshal failed", http.StatusBadRequest, codes.InvalidArgument).
			Wrap(err, "protojson.Unmarshal")
	}
	return nil
}

// ProtoMarshal encodes m using the protobuf wire format ([Marshal]).
func ProtoMarshal(m proto.Message) ([]byte, error) {
	return Marshal(m)
}

// ProtoUnmarshal decodes wire data into m ([Unmarshal]).
func ProtoUnmarshal(b []byte, m proto.Message) error {
	return Unmarshal(b, m)
}

// ProtoClone is an alias for [Clone].
func ProtoClone[M proto.Message](m M) M {
	return Clone(m)
}

// FindMessageByName looks up a message descriptor in the global registry (e.g. "google.protobuf.Any").
func FindMessageByName(name protoreflect.FullName) (protoreflect.MessageType, error) {
	mt, err := protoregistry.GlobalTypes.FindMessageByName(name)
	if err != nil {
		return nil, Internal("proto.FindMessageByName").Wrap(err, string(name))
	}
	return mt, nil
}

// UnpackAnyTo decodes a [anypb.Any] into an existing concrete message.
func UnpackAnyTo(a *anypb.Any, msg proto.Message) error {
	if a == nil {
		return BadRequest("proto.UnpackAnyTo: nil Any")
	}
	if msg == nil {
		return BadRequest("proto.UnpackAnyTo: nil message")
	}
	if err := a.UnmarshalTo(msg); err != nil {
		return New("PROTO_UNMARSHAL_FAILED", "Any unpack failed", http.StatusBadRequest, codes.InvalidArgument).
			Wrap(err, "any.UnmarshalTo")
	}
	return nil
}
