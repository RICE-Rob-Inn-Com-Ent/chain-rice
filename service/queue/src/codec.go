package queue

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/klauspost/compress/s2"
	commonpb "go.temporal.io/api/common/v1"
	"go.temporal.io/sdk/converter"
	"google.golang.org/protobuf/proto"
)

// Cross-language JSON wire (Go, Rust serde, Mojo):
//   - Use [SmithRFC3339Time] for instants; encoding/json emits RFC3339 / RFC3339Nano.
//   - Use [uuid.UUID] or [SmithUUID] for IDs; JSON is lowercase hex with hyphens (8-4-4-4-12).

// SmithRFC3339Time is serialized as RFC3339Nano-compatible strings, matching Rust chrono/serde and typical Mojo JSON parsers.
type SmithRFC3339Time = time.Time

// SmithUUID is a UUID in canonical string form for JSON interop.
type SmithUUID = uuid.UUID

const (
	// DefaultSmithCompressMinBytes is the minimum uncompressed payload size before S2 compression is considered.
	DefaultSmithCompressMinBytes = 1024

	metadataEncodingS2 = "binary/smith-s2"

	// NATS wire: single flag byte + body. Proto and JSON paths share framing for the multi-language bus.
	natsWireJSONRaw  byte = 0x00 // body is UTF-8 JSON
	natsWireJSONS2   byte = 0x01 // body is S2-compressed JSON
	natsWireProtoRaw byte = 0x02 // body is protobuf wire (for *proto.Message targets on decode)
	natsWireProtoS2  byte = 0x03 // S2-compressed protobuf wire
)

var bufferPool = sync.Pool{
	New: func() any {
		return new(bytes.Buffer)
	},
}

func getBuffer() *bytes.Buffer {
	return bufferPool.Get().(*bytes.Buffer)
}

func putBuffer(b *bytes.Buffer) {
	b.Reset()
	bufferPool.Put(b)
}

// smithJSONPayloadConverter is the last-chance converter: JSON with pooled encoding, encoding name json/plain for Temporal interop.
type smithJSONPayloadConverter struct{}

func (smithJSONPayloadConverter) Encoding() string {
	return converter.MetadataEncodingJSON
}

func (smithJSONPayloadConverter) ToPayload(value interface{}) (*commonpb.Payload, error) {
	data, err := marshalJSONInteroperable(value)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", converter.ErrUnableToEncode, err)
	}
	return &commonpb.Payload{
		Metadata: map[string][]byte{converter.MetadataEncoding: []byte(converter.MetadataEncodingJSON)},
		Data:     data,
	}, nil
}

func (smithJSONPayloadConverter) FromPayload(payload *commonpb.Payload, valuePtr interface{}) error {
	err := json.Unmarshal(payload.GetData(), valuePtr)
	if err != nil {
		return fmt.Errorf("%w: %v", converter.ErrUnableToDecode, err)
	}
	return nil
}

func (smithJSONPayloadConverter) ToString(payload *commonpb.Payload) string {
	return string(payload.GetData())
}

func marshalJSONInteroperable(v interface{}) ([]byte, error) {
	if v == nil {
		return []byte("null"), nil
	}
	buf := getBuffer()
	defer putBuffer(buf)
	buf.Reset()
	enc := json.NewEncoder(buf)
	enc.SetEscapeHTML(false)
	if err := enc.Encode(v); err != nil {
		return nil, err
	}
	b := buf.Bytes()
	if len(b) > 0 && b[len(b)-1] == '\n' {
		b = b[:len(b)-1]
	}
	out := make([]byte, len(b))
	copy(out, b)
	return out, nil
}

// smithS2PayloadCodec wraps already-encoded Temporal payloads with S2 when beneficial (same pattern as [converter.NewZlibCodec]).
type smithS2PayloadCodec struct {
	minBytes int
}

// NewSmithS2PayloadCodec returns a [converter.PayloadCodec] using S2 compression (klauspost/compress).
// Payloads smaller than minBytes are not compressed. Pass <= 0 for [DefaultSmithCompressMinBytes].
func NewSmithS2PayloadCodec(minBytes int) converter.PayloadCodec {
	if minBytes <= 0 {
		minBytes = DefaultSmithCompressMinBytes
	}
	return &smithS2PayloadCodec{minBytes: minBytes}
}

func (c *smithS2PayloadCodec) Encode(payloads []*commonpb.Payload) ([]*commonpb.Payload, error) {
	result := make([]*commonpb.Payload, len(payloads))
	for i, p := range payloads {
		raw, err := proto.Marshal(p)
		if err != nil {
			return payloads, err
		}
		if len(raw) < c.minBytes {
			result[i] = p
			continue
		}
		enc := s2.Encode(nil, raw)
		if len(enc) >= len(raw) {
			result[i] = p
			continue
		}
		result[i] = &commonpb.Payload{
			Metadata: map[string][]byte{converter.MetadataEncoding: []byte(metadataEncodingS2)},
			Data:     enc,
		}
	}
	return result, nil
}

func (*smithS2PayloadCodec) Decode(payloads []*commonpb.Payload) ([]*commonpb.Payload, error) {
	result := make([]*commonpb.Payload, len(payloads))
	for i, p := range payloads {
		if string(p.Metadata[converter.MetadataEncoding]) != metadataEncodingS2 {
			result[i] = p
			continue
		}
		b, err := s2.Decode(nil, p.Data)
		if err != nil {
			return payloads, err
		}
		result[i] = &commonpb.Payload{}
		if err := proto.Unmarshal(b, result[i]); err != nil {
			return payloads, err
		}
	}
	return result, nil
}

// NewSmithDataConverter builds the SMITH Temporal [converter.DataConverter]:
// nil → raw bytes → binary protobuf ([proto.Message] / gogo) → JSON (interop), then optional S2 wrapping of the payload blob.
func NewSmithDataConverter() converter.DataConverter {
	return NewSmithDataConverterWithOptions(SmithDataConverterOptions{})
}

// SmithDataConverterOptions configures [NewSmithDataConverterWithOptions].
type SmithDataConverterOptions struct {
	// CompressMinBytes is the minimum inner payload size (raw protobuf-encoded Payload) before S2 is attempted.
	CompressMinBytes int
}

// NewSmithDataConverterWithOptions is like [NewSmithDataConverter] with options.
func NewSmithDataConverterWithOptions(opts SmithDataConverterOptions) converter.DataConverter {
	minB := opts.CompressMinBytes
	if minB == 0 {
		minB = DefaultSmithCompressMinBytes
	}
	inner := converter.NewCompositeDataConverter(
		converter.NewNilPayloadConverter(),
		converter.NewByteSlicePayloadConverter(),
		converter.NewProtoPayloadConverter(),
		smithJSONPayloadConverter{},
	)
	return converter.NewCodecDataConverter(inner, NewSmithS2PayloadCodec(minB))
}

// Codec is the SMITH wire facade: Temporal payloads use [Codec.TemporalDataConverter]; NATS/KV use [Marshal] / [Unmarshal] with the same JSON/proto semantics.
type Codec struct {
	dc converter.DataConverter
}

// NewCodec returns a codec whose Temporal converter is [NewSmithDataConverter].
func NewCodec() *Codec {
	return &Codec{dc: NewSmithDataConverter()}
}

// TemporalDataConverter returns the [converter.DataConverter] passed to Temporal client and worker construction.
func (c *Codec) TemporalDataConverter() converter.DataConverter {
	if c == nil || c.dc == nil {
		return NewSmithDataConverter()
	}
	return c.dc
}

// Marshal encodes v for NATS (and KV) with the same JSON/proto rules and optional S2 compression as large JSON/proto blobs.
func Marshal(v any) ([]byte, error) {
	if v == nil {
		return []byte{natsWireJSONRaw, 'n', 'u', 'l', 'l'}, nil
	}
	if msg, ok := v.(proto.Message); ok {
		return marshalNATSProto(msg, DefaultSmithCompressMinBytes)
	}
	raw, err := marshalJSONInteroperable(v)
	if err != nil {
		return nil, fmt.Errorf("queue.codec: marshal json: %w", err)
	}
	return frameNATSJSON(raw, DefaultSmithCompressMinBytes)
}

// Unmarshal decodes NATS/KV bytes from [Marshal] into v (JSON) or *proto.Message (protobuf path).
func Unmarshal(data []byte, v any) error {
	if v == nil {
		return fmt.Errorf("queue.codec: nil destination")
	}
	if len(data) == 0 {
		return errors.New("queue.codec: empty input")
	}
	// Backward compatibility: bare JSON from older helpers.
	if data[0] != natsWireJSONRaw && data[0] != natsWireJSONS2 && data[0] != natsWireProtoRaw && data[0] != natsWireProtoS2 {
		return json.Unmarshal(data, v)
	}
	flag := data[0]
	body := data[1:]
	switch flag {
	case natsWireJSONRaw:
		return json.Unmarshal(body, v)
	case natsWireJSONS2:
		b, err := s2.Decode(nil, body)
		if err != nil {
			return fmt.Errorf("queue.codec: s2 decode json: %w", err)
		}
		return json.Unmarshal(b, v)
	case natsWireProtoRaw:
		return unmarshalNATSToProto(body, v)
	case natsWireProtoS2:
		b, err := s2.Decode(nil, body)
		if err != nil {
			return fmt.Errorf("queue.codec: s2 decode proto: %w", err)
		}
		return unmarshalNATSToProto(b, v)
	default:
		return fmt.Errorf("queue.codec: unknown wire flag 0x%02x", flag)
	}
}

func unmarshalNATSToProto(body []byte, v any) error {
	pm, ok := v.(proto.Message)
	if !ok {
		return fmt.Errorf("queue.codec: proto wire requires proto.Message destination, got %T", v)
	}
	if err := proto.Unmarshal(body, pm); err != nil {
		return fmt.Errorf("queue.codec: proto unmarshal: %w", err)
	}
	return nil
}

func marshalNATSProto(msg proto.Message, minCompress int) ([]byte, error) {
	raw, err := proto.Marshal(msg)
	if err != nil {
		return nil, err
	}
	if len(raw) >= minCompress {
		enc := s2.Encode(nil, raw)
		if len(enc) < len(raw) {
			out := make([]byte, 1+len(enc))
			out[0] = natsWireProtoS2
			copy(out[1:], enc)
			return out, nil
		}
	}
	out := make([]byte, 1+len(raw))
	out[0] = natsWireProtoRaw
	copy(out[1:], raw)
	return out, nil
}

func frameNATSJSON(raw []byte, minCompress int) ([]byte, error) {
	if len(raw) >= minCompress {
		enc := s2.Encode(nil, raw)
		if len(enc) < len(raw) {
			out := make([]byte, 1+len(enc))
			out[0] = natsWireJSONS2
			copy(out[1:], enc)
			return out, nil
		}
	}
	out := make([]byte, 1+len(raw))
	out[0] = natsWireJSONRaw
	copy(out[1:], raw)
	return out, nil
}

// MarshalKV encodes v for NATS KV using [Marshal].
func MarshalKV(v any) ([]byte, error) {
	return Marshal(v)
}

// UnmarshalKV decodes NATS KV bytes using [Unmarshal].
func UnmarshalKV(data []byte, v any) error {
	return Unmarshal(data, v)
}
