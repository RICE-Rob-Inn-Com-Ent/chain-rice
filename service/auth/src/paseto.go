package auth

import (
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"

	"aidanwoods.dev/go-paseto"
	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
)

// Well-known PASETO v4.local claim keys for SMITH session tokens.
const (
	ClaimTraceID = "trace_id"
	ClaimUserID  = "user_id"
)

const (
	envPasetoV4Key     = "RICE_AUTH_PASETO_V4_KEY"      // hex, 32-byte key
	envPasetoV4KeyPath = "RICE_AUTH_PASETO_V4_KEY_PATH" // file: hex or raw 32 bytes
	envPasetoImplicit  = "RICE_AUTH_PASETO_IMPLICIT"    // optional base64 implicit binding
)

var (
	pasetoMaterialOnce sync.Once
	pasetoMaterialErr  error
	pasetoSym          paseto.V4SymmetricKey
	pasetoImplicit     []byte
)

// PasetoKeyLoader is an optional hook to supply the v4.local key (exactly 32 bytes)
// and optional implicit bytes from a secret manager. When non-nil, it runs before
// environment-based loading on first use.
var PasetoKeyLoader func() (key []byte, implicit []byte, err error)

// SignToken builds a v4.local session token with standard time claims (iat, nbf, exp).
// Claims must include a subject: set ClaimUserID or JWT-style "sub" (sub is copied to user_id).
// For TraceID, set ClaimTraceID in claims or use [SignSessionToken].
func SignToken(claims map[string]any, duration time.Duration) (string, error) {
	if duration <= 0 {
		return "", errors.New("auth.paseto: duration must be positive")
	}
	key, implicit, err := sessionMaterial()
	if err != nil {
		return "", err
	}

	now := time.Now().UTC()
	payload := cloneClaims(claims)
	if err := normalizeSessionClaims(payload); err != nil {
		return "", err
	}
	if _, ok := payload[ClaimTraceID]; !ok {
		payload[ClaimTraceID] = ""
	}

	tok := paseto.NewToken()
	for k, v := range payload {
		if err := tok.Set(k, v); err != nil {
			return "", fmt.Errorf("auth.paseto: claim %q: %w", k, err)
		}
	}
	tok.SetIssuedAt(now)
	tok.SetNotBefore(now)
	tok.SetExpiration(now.Add(duration))

	return tok.V4Encrypt(key, implicit), nil
}

// SignSessionToken is like [SignToken] but fills ClaimTraceID from ctx when the span trace is valid.
func SignSessionToken(ctx *kit.Context, claims map[string]any, duration time.Duration) (string, error) {
	payload := cloneClaims(claims)
	if ctx != nil && ctx.TraceID.IsValid() {
		payload[ClaimTraceID] = ctx.TraceID.String()
	}
	return SignToken(payload, duration)
}

// VerifyToken decrypts a v4.local token and validates iat, nbf, and exp against the current time.
func VerifyToken(token string) (map[string]any, error) {
	key, implicit, err := sessionMaterial()
	if err != nil {
		return nil, err
	}
	p := paseto.MakeParser([]paseto.Rule{
		paseto.ValidAt(time.Now().UTC()),
	})
	tok, err := p.ParseV4Local(key, strings.TrimSpace(token), implicit)
	if err != nil {
		return nil, err
	}
	return tokenClaimsToAny(tok), nil
}

func sessionMaterial() (paseto.V4SymmetricKey, []byte, error) {
	pasetoMaterialOnce.Do(func() {
		var keyBytes, implicit []byte
		if PasetoKeyLoader != nil {
			keyBytes, implicit, pasetoMaterialErr = PasetoKeyLoader()
			if pasetoMaterialErr != nil {
				return
			}
			pasetoSym, pasetoMaterialErr = paseto.V4SymmetricKeyFromBytes(keyBytes)
			if pasetoMaterialErr != nil {
				return
			}
			pasetoImplicit = implicit
			return
		}
		keyBytes, pasetoMaterialErr = loadSymmetricKeyBytesFromEnv()
		if pasetoMaterialErr != nil {
			return
		}
		pasetoSym, pasetoMaterialErr = paseto.V4SymmetricKeyFromBytes(keyBytes)
		if pasetoMaterialErr != nil {
			return
		}
		pasetoImplicit, pasetoMaterialErr = loadImplicitFromEnv()
	})
	return pasetoSym, pasetoImplicit, pasetoMaterialErr
}

func loadSymmetricKeyBytesFromEnv() ([]byte, error) {
	if p := strings.TrimSpace(os.Getenv(envPasetoV4KeyPath)); p != "" {
		raw, err := os.ReadFile(p)
		if err != nil {
			return nil, fmt.Errorf("auth.paseto: read key file: %w", err)
		}
		return decodeKeyMaterial(strings.TrimSpace(string(raw)))
	}
	if s := strings.TrimSpace(os.Getenv(envPasetoV4Key)); s != "" {
		return decodeKeyMaterial(s)
	}
	return nil, fmt.Errorf("auth.paseto: set %s or %s (or PasetoKeyLoader)", envPasetoV4Key, envPasetoV4KeyPath)
}

func decodeKeyMaterial(s string) ([]byte, error) {
	if b, err := hex.DecodeString(s); err == nil && len(b) == 32 {
		return b, nil
	}
	if len(s) == 32 {
		return []byte(s), nil
	}
	if b, err := base64.StdEncoding.DecodeString(s); err == nil && len(b) == 32 {
		return b, nil
	}
	return nil, errors.New("auth.paseto: key must be 32 bytes (hex, raw, or base64)")
}

func loadImplicitFromEnv() ([]byte, error) {
	s := strings.TrimSpace(os.Getenv(envPasetoImplicit))
	if s == "" {
		return nil, nil
	}
	b, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		return nil, fmt.Errorf("auth.paseto: %s must be base64: %w", envPasetoImplicit, err)
	}
	return b, nil
}

func cloneClaims(in map[string]any) map[string]any {
	if len(in) == 0 {
		return make(map[string]any)
	}
	out := make(map[string]any, len(in)+4)
	for k, v := range in {
		out[k] = v
	}
	return out
}

func normalizeSessionClaims(c map[string]any) error {
	if uid, ok := c[ClaimUserID]; ok {
		if s, _ := uid.(string); strings.TrimSpace(s) != "" {
			return nil
		}
	}
	if sub, ok := c["sub"].(string); ok && strings.TrimSpace(sub) != "" {
		c[ClaimUserID] = strings.TrimSpace(sub)
		return nil
	}
	return errors.New("auth.paseto: claims must include user_id or sub")
}

func tokenClaimsToAny(tok *paseto.Token) map[string]any {
	raw := tok.Claims()
	out := make(map[string]any, len(raw))
	for k, v := range raw {
		out[k] = v
	}
	return out
}

// ResetPasetoSessionMaterialForTest clears cached key material (tests only).
func ResetPasetoSessionMaterialForTest() {
	pasetoMaterialOnce = sync.Once{}
	pasetoMaterialErr = nil
	pasetoSym = paseto.V4SymmetricKey{}
	pasetoImplicit = nil
}

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
