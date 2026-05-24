package web

// Secret and transport crypto: gocloud.dev KMS keepers plus post-quantum TLS (hybrid
// X25519MLKEM768) and optional ML-KEM-768 application-layer encapsulation.

import (
	"context"
	"crypto/mlkem"
	"crypto/tls"
	"errors"
	"net/http"

	"gocloud.dev/runtimevar"
	_ "gocloud.dev/runtimevar/awssecretsmanager"
	_ "gocloud.dev/runtimevar/filevar"
	"gocloud.dev/secrets"
	_ "gocloud.dev/secrets/awskms"
	_ "gocloud.dev/secrets/gcpkms"
	_ "gocloud.dev/secrets/localsecrets"
)

// OpenKeeper opens a KMS-backed keeper for Encrypt/Decrypt (not arbitrary secret fetch by name).
func OpenKeeper(ctx context.Context, urlstr string) (*secrets.Keeper, error) {
	return secrets.OpenKeeper(ctx, urlstr)
}

// Encrypt and Decrypt delegate to gocloud secrets.Keeper (envelope encryption with cloud KMS).
func Encrypt(ctx context.Context, k *secrets.Keeper, plaintext []byte) ([]byte, error) {
	if k == nil {
		return nil, errNilKeeper
	}
	return k.Encrypt(ctx, plaintext)
}

func Decrypt(ctx context.Context, k *secrets.Keeper, ciphertext []byte) ([]byte, error) {
	if k == nil {
		return nil, errNilKeeper
	}
	return k.Decrypt(ctx, ciphertext)
}

// OpenVariable watches runtime configuration (AWS Secrets Manager, files, etc.).
func OpenVariable(ctx context.Context, urlstr string) (*runtimevar.Variable, error) {
	return runtimevar.OpenVariable(ctx, urlstr)
}

// ApplyPQTLSConfig sets TLS 1.3+ minimum and hybrid post-quantum key exchange preferences
// (X25519MLKEM768 first) on cfg. It mutates cfg in place; do not call concurrently with handshakes
// using the same config. Pass a dedicated [*tls.Config] per server or transport.
func ApplyPQTLSConfig(cfg *tls.Config) {
	if cfg == nil {
		return
	}
	if cfg.MinVersion < tls.VersionTLS13 {
		cfg.MinVersion = tls.VersionTLS13
	}
	cfg.CurvePreferences = []tls.CurveID{
		tls.X25519MLKEM768,
		tls.X25519,
		tls.CurveP256,
		tls.CurveP384,
		tls.CurveP521,
	}
}

// NewPQTLSClientConfig returns a fresh client-side TLS config with [ApplyPQTLSConfig] applied.
func NewPQTLSClientConfig() *tls.Config {
	c := new(tls.Config)
	ApplyPQTLSConfig(c)
	return c
}

// NewPQHTTPTransport returns a clone of base (or a fresh transport) whose TLS client config
// enforces post-quantum TLS via [ApplyPQTLSConfig] for outgoing HTTPS/Connect/gRPC-over-HTTP requests.
func NewPQHTTPTransport(base *http.Transport) *http.Transport {
	var t *http.Transport
	if base != nil {
		t = base.Clone()
	} else {
		t = http.DefaultTransport.(*http.Transport).Clone()
	}
	if t.TLSClientConfig == nil {
		t.TLSClientConfig = NewPQTLSClientConfig()
	} else {
		ApplyPQTLSConfig(t.TLSClientConfig)
	}
	return t
}

// NewPQHTTPClient returns an [http.Client] suitable for Connect clients and other RPC over HTTPS,
// with post-quantum-capable TLS on the transport.
func NewPQHTTPClient() *http.Client {
	return &http.Client{Transport: NewPQHTTPTransport(nil)}
}

// PQGenerateMLKEM768 generates an ML-KEM-768 key pair (FIPS 203) for optional app-layer PQ wrapping.
func PQGenerateMLKEM768() (*mlkem.DecapsulationKey768, error) {
	return mlkem.GenerateKey768()
}

// PQMLKEM768Encapsulate derives a shared secret and ciphertext from a peer's encapsulation key bytes.
func PQMLKEM768Encapsulate(encapsulationKey []byte) (sharedSecret, ciphertext []byte, err error) {
	ek, err := mlkem.NewEncapsulationKey768(encapsulationKey)
	if err != nil {
		return nil, nil, err
	}
	sk, ct := ek.Encapsulate()
	return sk, ct, nil
}

// PQMLKEM768Decapsulate recovers the shared secret from ciphertext using the decapsulation key.
func PQMLKEM768Decapsulate(dk *mlkem.DecapsulationKey768, ciphertext []byte) ([]byte, error) {
	if dk == nil {
		return nil, errors.New("web: nil ML-KEM decapsulation key")
	}
	return dk.Decapsulate(ciphertext)
}

// PQMLKEM768EncapsulationKeyBytes returns the wire-format public key for dk.
func PQMLKEM768EncapsulationKeyBytes(dk *mlkem.DecapsulationKey768) ([]byte, error) {
	if dk == nil {
		return nil, errors.New("web: nil ML-KEM decapsulation key")
	}
	return dk.EncapsulationKey().Bytes(), nil
}
