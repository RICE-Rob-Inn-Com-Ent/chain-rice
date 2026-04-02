package auth

// TODO:
// [ ] implement password hashing via argon2id:
//     HashPassword(password string) (string, error)
//     VerifyPassword(password, hash string) (bool, error)
//     time from RICE_CRYPTO_ARGON_TIME env var (default: 3)
//     memory from RICE_CRYPTO_ARGON_MEM env var (default: 64MB)
// [ ] implement ChaCha20-Poly1305 encryption:
//     Encrypt(key, plaintext []byte) (ciphertext []byte, error)
//     Decrypt(key, ciphertext []byte) (plaintext []byte, error)
//     key derived via Argon2id from SOPS secret
// [ ] implement bcrypt for legacy compat:
//     HashBcrypt(password string) (string, error)
//     cost from RICE_CRYPTO_BCRYPT_COST env var (default: 12)

import (
	"crypto/rand"
	"errors"
	"io"

	"golang.org/x/crypto/argon2"
	"golang.org/x/crypto/bcrypt"
	"golang.org/x/crypto/chacha20poly1305"
	"golang.org/x/crypto/hkdf"
	"golang.org/x/crypto/pbkdf2"
	"golang.org/x/crypto/sha3"

	"crypto/sha256"
)

// Password hashing and symmetric crypto primitives (golang.org/x/crypto).

const (
	Argon2Time    = 3
	Argon2Memory  = 64 * 1024
	Argon2Threads = 4
	Argon2KeyLen  = 32
)

// HashPasswordArgon2id derives a key from password + salt using Argon2id.
func HashPasswordArgon2id(password, salt []byte) []byte {
	return argon2.IDKey(password, salt, Argon2Time, Argon2Memory, Argon2Threads, Argon2KeyLen)
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
		return nil, errors.New("key must be 32 bytes")
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

// ChaCha20Poly1305Open decrypts output from ChaCha20Poly1305Seal.
func ChaCha20Poly1305Open(key, sealed, additionalData []byte) ([]byte, error) {
	if len(key) != chacha20poly1305.KeySize {
		return nil, errors.New("key must be 32 bytes")
	}
	aead, err := chacha20poly1305.New(key)
	if err != nil {
		return nil, err
	}
	if len(sealed) < aead.NonceSize() {
		return nil, errors.New("ciphertext too short")
	}
	nonce := sealed[:aead.NonceSize()]
	return aead.Open(nil, nonce, sealed[aead.NonceSize():], additionalData)
}

// DeriveHKDF expands key material using HKDF-SHA256.
func DeriveHKDF(ikm, salt, info []byte, length int) ([]byte, error) {
	if length <= 0 {
		return nil, errors.New("length must be positive")
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
