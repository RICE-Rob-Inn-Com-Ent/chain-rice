package auth

// Password hashing (Argon2id), ChaCha20-Poly1305 for at-rest fields, and CSPRNG helpers.
// Context-aware APIs return [*kit.Error] with SMITH codes and optional trace correlation.

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"io"
	"net/http"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"golang.org/x/crypto/argon2"
	"golang.org/x/crypto/bcrypt"
	"golang.org/x/crypto/chacha20poly1305"
	"golang.org/x/crypto/hkdf"
	"golang.org/x/crypto/pbkdf2"
	"golang.org/x/crypto/sha3"
	"google.golang.org/grpc/codes"

	"crypto/sha256"
)

// Argon2id parameters for password hashing (time=1, memory=64MiB, 4 threads, 32-byte output).
const (
	Argon2Time    uint32 = 1
	Argon2Memory  uint32 = 64 * 1024 // KiB (1024 bytes each) ⇒ 64 MiB
	Argon2Threads uint8  = 4
	Argon2KeyLen  uint32 = 32
)

// DefaultPasswordSaltLen is the default salt size for [HashPassword].
const DefaultPasswordSaltLen = 16

// HashResult holds a password salt and Argon2id hash for storage (e.g. database columns).
type HashResult struct {
	Salt []byte
	Hash []byte
}

func cryptoErr(ctx *kit.Context, e *kit.Error) *kit.Error {
	if e == nil {
		return nil
	}
	if ctx == nil {
		return e
	}
	return e.WithTraceFromContext(ctx.ToContext())
}

// HashPassword hashes password with Argon2id and a fresh random salt ([DefaultPasswordSaltLen] bytes).
func HashPassword(ctx *kit.Context, password string) (HashResult, *kit.Error) {
	if password == "" {
		return HashResult{}, cryptoErr(ctx, kit.BadRequest("auth.crypto: empty password"))
	}
	salt, kerr := RandomBytes(ctx, DefaultPasswordSaltLen)
	if kerr != nil {
		return HashResult{}, kerr
	}
	hash := argon2.IDKey([]byte(password), salt, Argon2Time, Argon2Memory, Argon2Threads, Argon2KeyLen)
	return HashResult{Salt: salt, Hash: hash}, nil
}

// VerifyPassword checks password against a stored [HashResult] using constant-time comparison.
// Returns (false, nil) for a mismatch; only operational failures yield a non-nil [*kit.Error].
func VerifyPassword(ctx *kit.Context, password string, stored HashResult) (bool, *kit.Error) {
	if len(stored.Salt) == 0 || len(stored.Hash) == 0 {
		return false, cryptoErr(ctx, kit.BadRequest("auth.crypto: missing salt or hash"))
	}
	candidate := argon2.IDKey([]byte(password), stored.Salt, Argon2Time, Argon2Memory, Argon2Threads, Argon2KeyLen)
	if len(candidate) != len(stored.Hash) {
		return false, nil
	}
	if subtle.ConstantTimeCompare(candidate, stored.Hash) == 1 {
		return true, nil
	}
	return false, nil
}

// HashPasswordArgon2id derives a key from password + salt using Argon2id with [Argon2Time], [Argon2Memory], etc.
func HashPasswordArgon2id(password, salt []byte) []byte {
	return argon2.IDKey(password, salt, Argon2Time, Argon2Memory, Argon2Threads, Argon2KeyLen)
}

// EncryptSymmetric seals plaintext with ChaCha20-Poly1305 (random nonce prepended). key must be 32 bytes.
func EncryptSymmetric(ctx *kit.Context, key, plaintext, additionalData []byte) ([]byte, *kit.Error) {
	out, err := ChaCha20Poly1305Seal(key, plaintext, additionalData)
	if err != nil {
		return nil, cryptoErr(ctx, kit.New("AUTH_CRYPTO_ENCRYPT_FAILED", "auth.crypto: encrypt failed", http.StatusBadRequest, codes.InvalidArgument).Wrap(err, "ChaCha20Poly1305Seal"))
	}
	return out, nil
}

// DecryptSymmetric opens a blob from [EncryptSymmetric] or [ChaCha20Poly1305Seal].
func DecryptSymmetric(ctx *kit.Context, key, sealed, additionalData []byte) ([]byte, *kit.Error) {
	out, err := ChaCha20Poly1305Open(key, sealed, additionalData)
	if err != nil {
		return nil, cryptoErr(ctx, kit.New("AUTH_CRYPTO_DECRYPT_FAILED", "auth.crypto: decrypt failed", http.StatusBadRequest, codes.InvalidArgument).Wrap(err, "ChaCha20Poly1305Open"))
	}
	return out, nil
}

// RandomBytes returns n bytes from [crypto/rand].
func RandomBytes(ctx *kit.Context, n int) ([]byte, *kit.Error) {
	if n <= 0 {
		return nil, cryptoErr(ctx, kit.BadRequest("auth.crypto: random length must be positive"))
	}
	b := make([]byte, n)
	if _, err := io.ReadFull(rand.Reader, b); err != nil {
		return nil, cryptoErr(ctx, kit.New("AUTH_CRYPTO_RNG_FAILED", "auth.crypto: RNG read failed", http.StatusInternalServerError, codes.Internal).Wrap(err, "ReadFull"))
	}
	return b, nil
}

// RandomString returns a URL-safe unpadded Base64 string encoding n random bytes (entropy n bytes, string longer).
func RandomString(ctx *kit.Context, n int) (string, *kit.Error) {
	b, kerr := RandomBytes(ctx, n)
	if kerr != nil {
		return "", kerr
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

// RandomHex returns a lowercase hex string of n random bytes (length 2*n runes).
func RandomHex(ctx *kit.Context, n int) (string, *kit.Error) {
	b, kerr := RandomBytes(ctx, n)
	if kerr != nil {
		return "", kerr
	}
	return hex.EncodeToString(b), nil
}

// HashPasswordBcrypt hashes a password with bcrypt default cost.
func HashPasswordBcrypt(password []byte) ([]byte, error) {
	return bcrypt.GenerateFromPassword(password, bcrypt.DefaultCost)
}

// CompareBcrypt checks a bcrypt hash.
func CompareBcrypt(hashed, password []byte) error {
	return bcrypt.CompareHashAndPassword(hashed, password)
}

// ChaCha20Poly1305Seal encrypts plaintext with random nonce; nonce is prepended to output.
func ChaCha20Poly1305Seal(key, plaintext, additionalData []byte) ([]byte, error) {
	if len(key) != chacha20poly1305.KeySize {
		return nil, kit.BadRequest("auth.crypto: ChaCha20-Poly1305 key must be 32 bytes")
	}
	aead, err := chacha20poly1305.New(key)
	if err != nil {
		return nil, err
	}
	nonce := make([]byte, aead.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, err
	}
	out := aead.Seal(nonce, nonce, plaintext, additionalData)
	return out, nil
}

// ChaCha20Poly1305Open decrypts output from [ChaCha20Poly1305Seal].
func ChaCha20Poly1305Open(key, sealed, additionalData []byte) ([]byte, error) {
	if len(key) != chacha20poly1305.KeySize {
		return nil, kit.BadRequest("auth.crypto: ChaCha20-Poly1305 key must be 32 bytes")
	}
	aead, err := chacha20poly1305.New(key)
	if err != nil {
		return nil, err
	}
	if len(sealed) < aead.NonceSize() {
		return nil, kit.BadRequest("auth.crypto: ciphertext too short")
	}
	nonce := sealed[:aead.NonceSize()]
	return aead.Open(nil, nonce, sealed[aead.NonceSize():], additionalData)
}

// DeriveHKDF expands key material using HKDF-SHA256.
func DeriveHKDF(ikm, salt, info []byte, length int) ([]byte, error) {
	if length <= 0 {
		return nil, kit.BadRequest("auth.crypto: HKDF length must be positive")
	}
	r := hkdf.New(sha256.New, ikm, salt, info)
	out := make([]byte, length)
	if _, err := io.ReadFull(r, out); err != nil {
		return nil, err
	}
	return out, nil
}

// DerivePBKDF2 derives a key with PBKDF2-HMAC-SHA256.
func DerivePBKDF2(password, salt []byte, iter, keyLen int) []byte {
	return pbkdf2.Key(password, salt, iter, keyLen, sha256.New)
}

// SHA3Sum256 returns the SHA3-256 digest.
func SHA3Sum256(b []byte) []byte {
	h := sha3.New256()
	h.Write(b)
	return h.Sum(nil)
}
