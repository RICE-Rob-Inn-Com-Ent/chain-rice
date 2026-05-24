package auth

import (
	"context"
	"crypto/ecdh"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	circlx25519 "github.com/cloudflare/circl/dh/x25519"
	"github.com/cloudflare/circl/kem/kyber/kyber768"
	"github.com/cloudflare/circl/sign/dilithium/mode3"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	"golang.org/x/crypto/chacha20poly1305"
)

const (
	// AlgKyber768 is the algorithm label for ML-KEM / Kyber768 public keys in [PQPublicKeyDoc].
	AlgKyber768 = "KYBER768"
	// AlgDilithium3 is the algorithm label for ML-DSA / Dilithium3 public keys in [PQPublicKeyDoc].
	AlgDilithium3 = "DILITHIUM3"
	// KeyEncodingBase64Std is standard Base64 (RFC 4648) for wire-safe public key bytes in JSON.
	KeyEncodingBase64Std = "base64"

	pqSealV1 byte = 0x01
)

var (
	hkdfPQSealInfo = []byte("rice.auth.pqseal.kyber768-chacha20poly1305.v1")
)

// PQPublicKeyDoc is a JSON-safe public key envelope for BARD and other SMITH services (no private material).
type PQPublicKeyDoc struct {
	Algorithm string `json:"alg"`
	Encoding  string `json:"enc"`
	PublicKey string `json:"pk"`
}

// pqGoContext returns a standard context for OTel; never logs key material.
func pqGoContext(ctx *kit.Context) context.Context {
	if ctx == nil {
		return context.Background()
	}
	return ctx.ToContext()
}

func pqSpan(ctx *kit.Context, name string, attrs ...attribute.KeyValue) (context.Context, trace.Span) {
	var opts []trace.SpanStartOption
	if len(attrs) > 0 {
		opts = append(opts, trace.WithAttributes(attrs...))
	}
	return otel.Tracer("rice/auth/pqcrypto").Start(pqGoContext(ctx), name, opts...)
}

// --- Kyber768 (KEM) — key generation & encapsulation ---

// GenerateKyber768KeyPair generates a Kyber768 keypair. Pass ctx for distributed trace correlation (optional).
func GenerateKyber768KeyPair(ctx *kit.Context, r io.Reader) (*kyber768.PublicKey, *kyber768.PrivateKey, error) {
	_, span := pqSpan(ctx, "auth.pq.kyber768.generate_keypair",
		attribute.String("algorithm", AlgKyber768),
	)
	defer span.End()
	pk, sk, err := kyber768.GenerateKeyPair(r)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, "generate_keypair")
		return nil, nil, err
	}
	span.SetStatus(codes.Ok, "")
	return pk, sk, nil
}

// Kyber768KeyPair is equivalent to [GenerateKyber768KeyPair] with no tracing context.
func Kyber768KeyPair(r io.Reader) (*kyber768.PublicKey, *kyber768.PrivateKey, error) {
	return GenerateKyber768KeyPair(nil, r)
}

// Kyber768EncapsulateContext encapsulates a shared secret to pk. Uses stack buffers for the KEM outputs, then copies.
func Kyber768EncapsulateContext(ctx *kit.Context, pk *kyber768.PublicKey) (ct, ss []byte) {
	_, span := pqSpan(ctx, "auth.pq.kyber768.encapsulate",
		attribute.String("algorithm", AlgKyber768),
	)
	defer span.End()
	if pk == nil {
		span.SetStatus(codes.Error, "nil_public_key")
		return nil, nil
	}
	var ctb [kyber768.CiphertextSize]byte
	var ssb [kyber768.SharedKeySize]byte
	pk.EncapsulateTo(ctb[:], ssb[:], nil)
	ct = make([]byte, kyber768.CiphertextSize)
	ss = make([]byte, kyber768.SharedKeySize)
	copy(ct, ctb[:])
	copy(ss, ssb[:])
	span.SetStatus(codes.Ok, "")
	return ct, ss
}

// Kyber768Encapsulate is [Kyber768EncapsulateContext] without tracing context.
func Kyber768Encapsulate(pk *kyber768.PublicKey) (ct, ss []byte) {
	return Kyber768EncapsulateContext(nil, pk)
}

// Kyber768DecapsulateContext recovers the shared secret using stack storage for the shared key.
func Kyber768DecapsulateContext(ctx *kit.Context, sk *kyber768.PrivateKey, ct []byte) ([]byte, error) {
	_, span := pqSpan(ctx, "auth.pq.kyber768.decapsulate",
		attribute.String("algorithm", AlgKyber768),
		attribute.Int("ciphertext.len", len(ct)),
	)
	defer span.End()
	if sk == nil {
		err := errors.New("auth.pq: nil private key")
		span.RecordError(err)
		span.SetStatus(codes.Error, "nil_private_key")
		return nil, err
	}
	if len(ct) != kyber768.CiphertextSize {
		err := errors.New("auth.pq: invalid kyber ciphertext size")
		span.RecordError(err)
		span.SetStatus(codes.Error, "ciphertext_size")
		return nil, err
	}
	var ssb [kyber768.SharedKeySize]byte
	sk.DecapsulateTo(ssb[:], ct)
	out := make([]byte, kyber768.SharedKeySize)
	copy(out, ssb[:])
	span.SetStatus(codes.Ok, "")
	return out, nil
}

// Kyber768Decapsulate recovers the shared secret (legacy API; invalid ciphertext length may yield undefined behavior from circl).
func Kyber768Decapsulate(sk *kyber768.PrivateKey, ct []byte) []byte {
	ss := make([]byte, kyber768.SharedKeySize)
	if sk == nil || len(ct) != kyber768.CiphertextSize {
		return ss
	}
	sk.DecapsulateTo(ss, ct)
	return ss
}

// --- Authenticated encryption: Kyber768 KEM + HKDF + ChaCha20-Poly1305 ---

// PQSealKyber768 seals plaintext for recipientPub: Kyber encapsulation, HKDF-derived AEAD key, ChaCha20-Poly1305.
// Wire format: version (1) || kyber_ciphertext || nonce||ciphertext (from [ChaCha20Poly1305Seal]).
func PQSealKyber768(ctx *kit.Context, recipientPub *kyber768.PublicKey, plaintext, aad []byte) ([]byte, error) {
	_, span := pqSpan(ctx, "auth.pq.kyber768.seal",
		attribute.Int("plaintext.len", len(plaintext)),
		attribute.Int("aad.len", len(aad)),
	)
	defer span.End()
	if recipientPub == nil {
		err := errors.New("auth.pq: nil recipient public key")
		span.RecordError(err)
		span.SetStatus(codes.Error, "nil_pubkey")
		return nil, err
	}

	var ct [kyber768.CiphertextSize]byte
	var ss [kyber768.SharedKeySize]byte
	recipientPub.EncapsulateTo(ct[:], ss[:], nil)

	key, err := DeriveHKDF(ss[:], nil, hkdfPQSealInfo, chacha20poly1305.KeySize)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, "hkdf")
		return nil, err
	}
	inner, err := ChaCha20Poly1305Seal(key, plaintext, aad)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, "aead_seal")
		return nil, err
	}

	outLen := 1 + len(ct) + len(inner)
	out := make([]byte, outLen)
	out[0] = pqSealV1
	copy(out[1:], ct[:])
	copy(out[1+len(ct):], inner)

	span.SetAttributes(attribute.Int("sealed.total_len", len(out)))
	span.SetStatus(codes.Ok, "")
	return out, nil
}

// PQOpenKyber768 opens a blob produced by [PQSealKyber768].
func PQOpenKyber768(ctx *kit.Context, recipientPriv *kyber768.PrivateKey, sealed, aad []byte) ([]byte, error) {
	_, span := pqSpan(ctx, "auth.pq.kyber768.open",
		attribute.Int("sealed.len", len(sealed)),
		attribute.Int("aad.len", len(aad)),
	)
	defer span.End()
	minLen := 1 + kyber768.CiphertextSize + chacha20poly1305.NonceSize + chacha20poly1305.Overhead
	if len(sealed) < minLen {
		err := errors.New("auth.pq: sealed blob too short")
		span.RecordError(err)
		span.SetStatus(codes.Error, "short_input")
		return nil, err
	}
	if sealed[0] != pqSealV1 {
		err := errors.New("auth.pq: unsupported seal version")
		span.RecordError(err)
		span.SetStatus(codes.Error, "version")
		return nil, err
	}
	if recipientPriv == nil {
		err := errors.New("auth.pq: nil recipient private key")
		span.RecordError(err)
		span.SetStatus(codes.Error, "nil_privkey")
		return nil, err
	}

	ct := sealed[1 : 1+kyber768.CiphertextSize]
	inner := sealed[1+kyber768.CiphertextSize:]

	var ss [kyber768.SharedKeySize]byte
	recipientPriv.DecapsulateTo(ss[:], ct)

	key, err := DeriveHKDF(ss[:], nil, hkdfPQSealInfo, chacha20poly1305.KeySize)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, "hkdf")
		return nil, err
	}
	plain, err := ChaCha20Poly1305Open(key, inner, aad)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, "aead_open")
		return nil, err
	}
	span.SetAttributes(attribute.Int("plaintext.len", len(plain)))
	span.SetStatus(codes.Ok, "")
	return plain, nil
}

// --- Dilithium3 (signatures) ---

// GenerateDilithium3KeyPair generates a Dilithium3 keypair with optional trace context.
func GenerateDilithium3KeyPair(ctx *kit.Context, r io.Reader) (*mode3.PublicKey, *mode3.PrivateKey, error) {
	_, span := pqSpan(ctx, "auth.pq.dilithium3.generate_keypair",
		attribute.String("algorithm", AlgDilithium3),
	)
	defer span.End()
	pk, sk, err := mode3.GenerateKey(r)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, "generate_keypair")
		return nil, nil, err
	}
	span.SetStatus(codes.Ok, "")
	return pk, sk, nil
}

// Dilithium3GenerateKey is [GenerateDilithium3KeyPair] without tracing context.
func Dilithium3GenerateKey(r io.Reader) (*mode3.PublicKey, *mode3.PrivateKey, error) {
	return GenerateDilithium3KeyPair(nil, r)
}

// Dilithium3SignContext signs msg with a pre-allocated signature buffer on the stack, then returns a copy.
func Dilithium3SignContext(ctx *kit.Context, sk *mode3.PrivateKey, msg []byte) ([]byte, error) {
	_, span := pqSpan(ctx, "auth.pq.dilithium3.sign",
		attribute.Int("msg.len", len(msg)),
	)
	defer span.End()
	if sk == nil {
		err := errors.New("auth.pq: nil signing key")
		span.RecordError(err)
		span.SetStatus(codes.Error, "nil_signing_key")
		return nil, err
	}
	var sig [mode3.SignatureSize]byte
	mode3.SignTo(sk, msg, sig[:])
	out := make([]byte, mode3.SignatureSize)
	copy(out, sig[:])
	span.SetStatus(codes.Ok, "")
	return out, nil
}

// Dilithium3Sign signs msg (legacy API; panics if sk is nil per [mode3.SignTo]).
func Dilithium3Sign(sk *mode3.PrivateKey, msg []byte) []byte {
	sig := make([]byte, mode3.SignatureSize)
	mode3.SignTo(sk, msg, sig)
	return sig
}

// Dilithium3VerifyContext verifies a Dilithium3 signature.
func Dilithium3VerifyContext(ctx *kit.Context, pk *mode3.PublicKey, msg, sig []byte) bool {
	_, span := pqSpan(ctx, "auth.pq.dilithium3.verify",
		attribute.Int("msg.len", len(msg)),
		attribute.Int("sig.len", len(sig)),
	)
	defer span.End()
	if pk == nil {
		span.SetStatus(codes.Error, "nil_public_key")
		return false
	}
	ok := mode3.Verify(pk, msg, sig)
	if !ok {
		span.SetStatus(codes.Error, "verify_failed")
		return false
	}
	span.SetStatus(codes.Ok, "")
	return true
}

// Dilithium3Verify is [Dilithium3VerifyContext] without tracing context.
func Dilithium3Verify(pk *mode3.PublicKey, msg, sig []byte) bool {
	return Dilithium3VerifyContext(nil, pk, msg, sig)
}

// --- Public key export / import (JSON for BARD & inter-service) ---

// Kyber768PublicKeyDoc builds a [PQPublicKeyDoc] from a Kyber768 public key (Base64-encoded raw pack).
func Kyber768PublicKeyDoc(pk *kyber768.PublicKey) (PQPublicKeyDoc, error) {
	if pk == nil {
		return PQPublicKeyDoc{}, errors.New("auth.pq: nil kyber public key")
	}
	raw, err := pk.MarshalBinary()
	if err != nil {
		return PQPublicKeyDoc{}, err
	}
	return PQPublicKeyDoc{
		Algorithm: AlgKyber768,
		Encoding:  KeyEncodingBase64Std,
		PublicKey: base64.StdEncoding.EncodeToString(raw),
	}, nil
}

// Dilithium3PublicKeyDoc builds a [PQPublicKeyDoc] from a Dilithium3 public key.
func Dilithium3PublicKeyDoc(pk *mode3.PublicKey) (PQPublicKeyDoc, error) {
	if pk == nil {
		return PQPublicKeyDoc{}, errors.New("auth.pq: nil dilithium public key")
	}
	return PQPublicKeyDoc{
		Algorithm: AlgDilithium3,
		Encoding:  KeyEncodingBase64Std,
		PublicKey: base64.StdEncoding.EncodeToString(pk.Bytes()),
	}, nil
}

// Kyber768PublicKeyFromDoc parses a Kyber768 public key from [PQPublicKeyDoc].
func Kyber768PublicKeyFromDoc(doc PQPublicKeyDoc) (*kyber768.PublicKey, error) {
	if !strings.EqualFold(doc.Algorithm, AlgKyber768) {
		return nil, errors.New("auth.pq: document is not Kyber768")
	}
	raw, err := base64.StdEncoding.DecodeString(doc.PublicKey)
	if err != nil {
		return nil, err
	}
	pub, err := kyber768.Scheme().UnmarshalBinaryPublicKey(raw)
	if err != nil {
		return nil, err
	}
	return pub.(*kyber768.PublicKey), nil
}

// Dilithium3PublicKeyFromDoc parses a Dilithium3 public key from [PQPublicKeyDoc].
func Dilithium3PublicKeyFromDoc(doc PQPublicKeyDoc) (*mode3.PublicKey, error) {
	if !strings.EqualFold(doc.Algorithm, AlgDilithium3) {
		return nil, errors.New("auth.pq: document is not Dilithium3")
	}
	raw, err := base64.StdEncoding.DecodeString(doc.PublicKey)
	if err != nil {
		return nil, err
	}
	var pk mode3.PublicKey
	if err := pk.UnmarshalBinary(raw); err != nil {
		return nil, err
	}
	return &pk, nil
}

// MarshalPQPublicKeyDoc serializes doc to JSON (UTF-8).
func MarshalPQPublicKeyDoc(doc PQPublicKeyDoc) ([]byte, error) {
	return json.Marshal(doc)
}

// UnmarshalPQPublicKeyDoc parses JSON into [PQPublicKeyDoc].
func UnmarshalPQPublicKeyDoc(b []byte) (PQPublicKeyDoc, error) {
	var doc PQPublicKeyDoc
	err := json.Unmarshal(b, &doc)
	return doc, err
}

// --- Classical / hybrid interop (non-PQ DH) ---

var errX25519LowOrder = errors.New("x25519: low-order public key")

// X25519SharedSecret performs X25519 (circl) Diffie-Hellman.
func X25519SharedSecret(ourSecret, theirPublic []byte) ([]byte, error) {
	if len(ourSecret) != circlx25519.Size || len(theirPublic) != circlx25519.Size {
		return nil, errors.New("x25519: keys must be 32 bytes")
	}
	var sec, pub, shared circlx25519.Key
	copy(sec[:], ourSecret)
	copy(pub[:], theirPublic)
	if !circlx25519.Shared(&shared, &sec, &pub) {
		return nil, errX25519LowOrder
	}
	out := make([]byte, circlx25519.Size)
	copy(out, shared[:])
	return out, nil
}

// P384ECDH performs a standard library ECDH on NIST P-384 (hybrid / non-PQ interop).
func P384ECDH(local *ecdh.PrivateKey, remote *ecdh.PublicKey) ([]byte, error) {
	return local.ECDH(remote)
}

// GenerateP384KeyPair creates an ECDH P-384 key pair.
func GenerateP384KeyPair() (*ecdh.PrivateKey, error) {
	return ecdh.P384().GenerateKey(rand.Reader)
}
