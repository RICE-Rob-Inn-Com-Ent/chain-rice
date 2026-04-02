package auth

// TODO:
// [ ] implement post-quantum key exchange via cloudflare/circl:
//     Kyber768 key encapsulation — NIST PQC standard
//     GenerateKyberKeyPair() (pub, priv []byte, error)
//     Encapsulate(pub []byte) (ciphertext, sharedSecret []byte, error)
//     Decapsulate(priv, ciphertext []byte) (sharedSecret []byte, error)
// [ ] implement post-quantum signatures:
//     Dilithium3 digital signatures
//     GenerateDilithiumKeyPair() (pub, priv []byte, error)
//     Sign(priv, msg []byte) (sig []byte, error)
//     Verify(pub, msg, sig []byte) error
// [ ] implement hybrid classical+PQ:
//     combine ed25519 + Kyber768 for transition period
//     RICE_AUTH_PQ_ENABLED=true activates PQ layer

import (
	"crypto/ecdh"
	"crypto/rand"
	"errors"
	"io"

	circlx25519 "github.com/cloudflare/circl/dh/x25519"
	"github.com/cloudflare/circl/kem/kyber/kyber768"
	"github.com/cloudflare/circl/sign/dilithium/mode3"
)

// Kyber768KeyPair generates a Kyber768 KEM keypair.
func Kyber768KeyPair(r io.Reader) (*kyber768.PublicKey, *kyber768.PrivateKey, error) {
	return kyber768.GenerateKeyPair(r)
}

// Kyber768Encapsulate runs encapsulation against a public key; fills ct and shared secret.
func Kyber768Encapsulate(pk *kyber768.PublicKey) (ct, ss []byte) {
	ct = make([]byte, kyber768.CiphertextSize)
	ss = make([]byte, kyber768.SharedKeySize)
	pk.EncapsulateTo(ct, ss, nil)
	return ct, ss
}

// Kyber768Decapsulate recovers the shared secret from ciphertext.
func Kyber768Decapsulate(sk *kyber768.PrivateKey, ct []byte) []byte {
	ss := make([]byte, kyber768.SharedKeySize)
	sk.DecapsulateTo(ss, ct)
	return ss
}

// Dilithium3GenerateKey generates a Dilithium3 signing keypair.
func Dilithium3GenerateKey(r io.Reader) (*mode3.PublicKey, *mode3.PrivateKey, error) {
	return mode3.GenerateKey(r)
}

// Dilithium3Sign signs msg and returns a detached signature.
func Dilithium3Sign(sk *mode3.PrivateKey, msg []byte) []byte {
	sig := make([]byte, mode3.SignatureSize)
	mode3.SignTo(sk, msg, sig)
	return sig
}

// Dilithium3Verify checks a Dilithium3 signature.
func Dilithium3Verify(pk *mode3.PublicKey, msg, sig []byte) bool {
	return mode3.Verify(pk, msg, sig)
}

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
