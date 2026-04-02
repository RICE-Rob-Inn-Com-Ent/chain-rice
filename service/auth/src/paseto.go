package auth

// TODO:
// [ ] implement PASETO v4 local token (symmetric):
//     IssueLocal(claims Claims) (string, error)
//     VerifyLocal(token string) (Claims, error)
//     key from RICE_AUTH_PASETO_SECRET_KEY_PATH via SOPS
// [ ] implement PASETO v4 public token (asymmetric):
//     IssuePublic(claims Claims) (string, error)
//     VerifyPublic(token string) (Claims, error)
//     private key from RICE_AUTH_PASETO_SECRET_KEY_PATH
//     public key from RICE_AUTH_PASETO_PUBLIC_KEY_PATH
// [ ] implement Claims struct:
//     Sub, Iss, Aud, Exp, Iat, Jti — standard
//     Role, Scope, ProjectID — rice-specific
//     all durations from RICE_AUTH_TOKEN_TTL_S env var
// [ ] implement token rotation:
//     RefreshToken(token string) (string, error)
//     max refresh count from RICE_AUTH_MAX_REFRESH env var

import (
	"time"

	"aidanwoods.dev/go-paseto"
)

// PASETO v4 helpers for session tokens (JWT replacement path).

// MintV4Public returns a signed public PASETO v4 string.
func MintV4Public(tok paseto.Token, secret paseto.V4AsymmetricSecretKey, implicit []byte) string {
	return tok.V4Sign(secret, implicit)
}

// MintV4Local returns an encrypted local PASETO v4 string.
func MintV4Local(tok paseto.Token, sym paseto.V4SymmetricKey, implicit []byte) string {
	return tok.V4Encrypt(sym, implicit)
}

// NewSessionToken builds a token with standard exp claim.
func NewSessionToken(ttl time.Duration) paseto.Token {
	tok := paseto.NewToken()
	tok.SetExpiration(time.Now().Add(ttl))
	return tok
}

// VerifyV4Public parses and verifies a public token.
func VerifyV4Public(p paseto.Parser, pub paseto.V4AsymmetricPublicKey, implicit []byte, tainted string) (*paseto.Token, error) {
	return p.ParseV4Public(pub, tainted, implicit)
}

// VerifyV4Local decrypts a local token.
func VerifyV4Local(p paseto.Parser, sym paseto.V4SymmetricKey, implicit []byte, tainted string) (*paseto.Token, error) {
	return p.ParseV4Local(sym, tainted, implicit)
}
