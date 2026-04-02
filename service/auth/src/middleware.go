package auth

// TODO:
// [ ] implement PASETO auth middleware for Fiber:
//     AuthMiddleware() fiber.Handler
//     extracts Bearer token from Authorization header
//     verifies PASETO → sets Claims in ctx
// [ ] implement PASETO auth interceptor for ConnectRPC:
//     AuthInterceptor() connect.UnaryInterceptorFunc
//     same logic as fiber middleware
// [ ] implement role-based access control:
//     RequireRole(roles ...string) fiber.Handler
//     checks Claims.Role against required roles
// [ ] implement scope-based access control:
//     RequireScope(scopes ...string) fiber.Handler
//     checks Claims.Scope against required scopes

import (
	"errors"
	"strings"

	"aidanwoods.dev/go-paseto"
	"github.com/gofiber/fiber/v2"
)

// Fiber Locals keys for downstream handlers (service/web).
const (
	LocalPasetoRaw   = "auth.paseto.raw"
	LocalPasetoToken = "auth.paseto.token"
	LocalRole        = "auth.role"
	LocalSPIFFEID    = "auth.spiffe.id"
	ClaimRole        = "role"
)

// BearerToken returns the token from Authorization: Bearer, or empty if missing.
func BearerToken(c *fiber.Ctx) string {
	h := strings.TrimSpace(c.Get("Authorization"))
	const prefix = "Bearer "
	if len(h) < len(prefix) || !strings.EqualFold(h[:len(prefix)], prefix) {
		return ""
	}
	return strings.TrimSpace(h[len(prefix):])
}

// PasetoMiddlewareV4Public verifies a v4.public PASETO from the Bearer token.
func PasetoMiddlewareV4Public(p paseto.Parser, pub paseto.V4AsymmetricPublicKey, implicit []byte) fiber.Handler {
	return func(c *fiber.Ctx) error {
		raw := BearerToken(c)
		if raw == "" {
			return fiber.ErrUnauthorized
		}
		tok, err := p.ParseV4Public(pub, raw, implicit)
		if err != nil {
			return fiber.ErrUnauthorized
		}
		c.Locals(LocalPasetoRaw, raw)
		c.Locals(LocalPasetoToken, tok)
		if role, err := tok.GetString(ClaimRole); err == nil && role != "" {
			c.Locals(LocalRole, role)
		}
		return c.Next()
	}
}

// PasetoMiddlewareV4Local decrypts a v4.local PASETO from the Bearer token.
func PasetoMiddlewareV4Local(p paseto.Parser, sym paseto.V4SymmetricKey, implicit []byte) fiber.Handler {
	return func(c *fiber.Ctx) error {
		raw := BearerToken(c)
		if raw == "" {
			return fiber.ErrUnauthorized
		}
		tok, err := p.ParseV4Local(sym, raw, implicit)
		if err != nil {
			return fiber.ErrUnauthorized
		}
		c.Locals(LocalPasetoRaw, raw)
		c.Locals(LocalPasetoToken, tok)
		if role, err := tok.GetString(ClaimRole); err == nil && role != "" {
			c.Locals(LocalRole, role)
		}
		return c.Next()
	}
}

// PeerSPIFFEID extracts the SPIFFE ID URI from the mTLS peer leaf certificate, if present.
func PeerSPIFFEID(c *fiber.Ctx) (string, error) {
	st := c.Context().TLSConnectionState()
	if st == nil || len(st.PeerCertificates) == 0 {
		return "", errors.New("auth: no tls peer certificate")
	}
	for _, u := range st.PeerCertificates[0].URIs {
		if u != nil && u.Scheme == "spiffe" {
			return u.String(), nil
		}
	}
	return "", errors.New("auth: no spiffe uri on peer cert")
}

// SPIFFEOptionalMiddleware attaches LocalSPIFFEID when the request has a valid peer SPIFFE ID.
func SPIFFEOptionalMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		if id, err := PeerSPIFFEID(c); err == nil {
			c.Locals(LocalSPIFFEID, id)
		}
		return c.Next()
	}
}

// SPIFFERequiredMiddleware requires an mTLS peer with a SPIFFE URI SAN.
func SPIFFERequiredMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		id, err := PeerSPIFFEID(c)
		if err != nil {
			return fiber.ErrUnauthorized
		}
		c.Locals(LocalSPIFFEID, id)
		return c.Next()
	}
}
