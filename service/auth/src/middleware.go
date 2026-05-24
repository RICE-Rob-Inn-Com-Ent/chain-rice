package auth

import (
	"errors"
	"net/http"
	"strings"

	"aidanwoods.dev/go-paseto"
	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/gofiber/fiber/v2"
	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"google.golang.org/grpc/codes"
)

// Fiber Locals keys for downstream handlers (service/web).
const (
	LocalPasetoRaw   = "auth.paseto.raw"
	LocalPasetoToken = "auth.paseto.token"
	LocalRole        = "auth.role"
	LocalSPIFFEID    = "auth.spiffe.id"
	LocalAuthMethod  = "auth.method"
	LocalAPIKey      = "auth.api_key"
	ClaimRole        = "role"

	// AuthMethodPasetoBearer indicates the request was authenticated via Authorization: Bearer PASETO.
	AuthMethodPasetoBearer = "paseto_bearer"
	// AuthMethodPasetoCookie indicates the request was authenticated via a session cookie carrying PASETO.
	AuthMethodPasetoCookie = "paseto_cookie"
	// AuthMethodAPIKey indicates the request was authenticated via an API key header.
	AuthMethodAPIKey = "api_key"

	// HeaderAPIKey is the default header name for [MultiAuthConfig.APIKeyHeader].
	HeaderAPIKey = "X-API-Key"
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

func forbiddenErr(msg string) *kit.Error {
	return kit.New("FORBIDDEN", msg, http.StatusForbidden, codes.PermissionDenied)
}

func setPasetoLocals(c *fiber.Ctx, raw string, tok *paseto.Token, method string) {
	c.Locals(LocalPasetoRaw, raw)
	c.Locals(LocalPasetoToken, tok)
	c.Locals(LocalAuthMethod, method)
	if tok == nil {
		return
	}
	if role, err := tok.GetString(ClaimRole); err == nil && role != "" {
		c.Locals(LocalRole, role)
	}
}

// AuthRequired returns Fiber middleware that requires a valid v4.public PASETO in Authorization: Bearer.
func AuthRequired(p paseto.Parser, pub paseto.V4AsymmetricPublicKey, implicit []byte) fiber.Handler {
	return pasetoBearerV4Public(p, pub, implicit, true)
}

// AuthRequiredLocal returns Fiber middleware that requires a valid v4.local PASETO in Authorization: Bearer.
func AuthRequiredLocal(p paseto.Parser, sym paseto.V4SymmetricKey, implicit []byte) fiber.Handler {
	return pasetoBearerV4Local(p, sym, implicit, true)
}

// PasetoMiddlewareV4Public verifies a v4.public PASETO from the Bearer token.
func PasetoMiddlewareV4Public(p paseto.Parser, pub paseto.V4AsymmetricPublicKey, implicit []byte) fiber.Handler {
	return pasetoBearerV4Public(p, pub, implicit, false)
}

// PasetoMiddlewareV4Local decrypts a v4.local PASETO from the Bearer token.
func PasetoMiddlewareV4Local(p paseto.Parser, sym paseto.V4SymmetricKey, implicit []byte) fiber.Handler {
	return pasetoBearerV4Local(p, sym, implicit, false)
}

func pasetoBearerV4Public(p paseto.Parser, pub paseto.V4AsymmetricPublicKey, implicit []byte, kitErrors bool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		raw := BearerToken(c)
		if raw == "" {
			return pasetoMissing(kitErrors, c)
		}
		tok, err := p.ParseV4Public(pub, raw, implicit)
		if err != nil {
			return pasetoInvalid(kitErrors, c)
		}
		setPasetoLocals(c, raw, tok, AuthMethodPasetoBearer)
		return c.Next()
	}
}

func pasetoBearerV4Local(p paseto.Parser, sym paseto.V4SymmetricKey, implicit []byte, kitErrors bool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		raw := BearerToken(c)
		if raw == "" {
			return pasetoMissing(kitErrors, c)
		}
		tok, err := p.ParseV4Local(sym, raw, implicit)
		if err != nil {
			return pasetoInvalid(kitErrors, c)
		}
		setPasetoLocals(c, raw, tok, AuthMethodPasetoBearer)
		return c.Next()
	}
}

func pasetoMissing(kitErrors bool, c *fiber.Ctx) error {
	if kitErrors {
		return kit.Unauthorized("auth: missing bearer token").AsFiber(c)
	}
	return fiber.ErrUnauthorized
}

func pasetoInvalid(kitErrors bool, c *fiber.Ctx) error {
	if kitErrors {
		return kit.Unauthorized("auth: invalid or expired paseto token").AsFiber(c)
	}
	return fiber.ErrUnauthorized
}

// PasetoBearerConfig describes how to verify PASETO tokens for [MultiAuth].
// If Local is non-nil, v4.local is used; otherwise v4.public with Public.
type PasetoBearerConfig struct {
	Parser   paseto.Parser
	Implicit []byte
	Public   paseto.V4AsymmetricPublicKey
	Local    *paseto.V4SymmetricKey
}

func (pc *PasetoBearerConfig) verify(raw string) (*paseto.Token, error) {
	if pc.Local != nil {
		return pc.Parser.ParseV4Local(*pc.Local, raw, pc.Implicit)
	}
	return pc.Parser.ParseV4Public(pc.Public, raw, pc.Implicit)
}

// MultiAuthConfig enables multiple credential sources; the first match wins (cookie → bearer → API key).
type MultiAuthConfig struct {
	// Paseto, if non-nil, enables verification of PASETO from SessionCookie and/or Bearer (Bearer is always tried when Paseto is set).
	Paseto *PasetoBearerConfig

	// SessionCookie, if non-empty, is the cookie name whose value is verified as PASETO the same way as Bearer.
	SessionCookie string

	// APIKeyHeader is the header name for static API keys (default [HeaderAPIKey]).
	APIKeyHeader string

	// ValidAPIKeys, if non-empty, allows requests that present a key in ValidAPIKeys.
	ValidAPIKeys map[string]struct{}
}

// MultiAuth returns middleware that accepts any configured strategy.
func MultiAuth(cfg MultiAuthConfig) fiber.Handler {
	hdr := cfg.APIKeyHeader
	if hdr == "" {
		hdr = HeaderAPIKey
	}
	hasPaseto := cfg.Paseto != nil
	hasAPI := len(cfg.ValidAPIKeys) > 0
	if !hasPaseto && !hasAPI {
		return func(c *fiber.Ctx) error {
			return kit.Internal("auth.multi: set Paseto and/or ValidAPIKeys").AsFiber(c)
		}
	}

	return func(c *fiber.Ctx) error {
		if hasPaseto {
			if cfg.SessionCookie != "" {
				if v := strings.TrimSpace(c.Cookies(cfg.SessionCookie)); v != "" {
					if tok, err := cfg.Paseto.verify(v); err == nil {
						setPasetoLocals(c, v, tok, AuthMethodPasetoCookie)
						return c.Next()
					}
				}
			}
			if raw := BearerToken(c); raw != "" {
				if tok, err := cfg.Paseto.verify(raw); err == nil {
					setPasetoLocals(c, raw, tok, AuthMethodPasetoBearer)
					return c.Next()
				}
			}
		}
		if hasAPI {
			k := strings.TrimSpace(c.Get(hdr))
			if k != "" {
				if _, ok := cfg.ValidAPIKeys[k]; ok {
					c.Locals(LocalAPIKey, k)
					c.Locals(LocalAuthMethod, AuthMethodAPIKey)
					return c.Next()
				}
				return forbiddenErr("auth: invalid api key").AsFiber(c)
			}
		}
		return kit.Unauthorized("auth: no valid session, bearer token, or api key").AsFiber(c)
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

// InternalOnly requires an mTLS peer with a SPIFFE URI SAN. Optional authorize may return a *kit.Error
// (for example HTTP 403) to reject otherwise-valid SVIDs.
func InternalOnly(authorize func(spiffeID string) *kit.Error) fiber.Handler {
	return func(c *fiber.Ctx) error {
		raw, err := PeerSPIFFEID(c)
		if err != nil {
			return kit.Unauthorized("auth.spiffe: missing or invalid mTLS peer svid").AsFiber(c)
		}
		if _, err := spiffeid.FromString(raw); err != nil {
			return kit.Unauthorized("auth.spiffe: malformed spiffe id").AsFiber(c)
		}
		if authorize != nil {
			if ke := authorize(raw); ke != nil {
				return ke.AsFiber(c)
			}
		}
		c.Locals(LocalSPIFFEID, raw)
		return c.Next()
	}
}

// AllowedSPIFFEIDs returns an authorize function for [InternalOnly] that permits only the listed IDs (403 otherwise).
func AllowedSPIFFEIDs(allowed ...string) func(string) *kit.Error {
	m := make(map[string]struct{}, len(allowed))
	for _, id := range allowed {
		if id != "" {
			m[id] = struct{}{}
		}
	}
	return func(id string) *kit.Error {
		if _, ok := m[id]; !ok {
			return forbiddenErr("auth.spiffe: svid not in allow list")
		}
		return nil
	}
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

// SPIFFERequiredMiddleware requires an mTLS peer with a SPIFFE URI SAN (any valid ID).
func SPIFFERequiredMiddleware() fiber.Handler {
	return InternalOnly(nil)
}
