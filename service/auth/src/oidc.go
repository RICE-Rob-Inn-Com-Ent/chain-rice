package auth

import (
	"context"
	"fmt"
	"net/http"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/coreos/go-oidc/v3/oidc"
	"golang.org/x/oauth2"
)

// Identity is SMITH's normalized user record produced from OIDC ID tokens or UserInfo.
type Identity struct {
	Subject string `json:"sub"`
	Email   string `json:"email"`
	Picture string `json:"picture"`
}

// OIDCUserClaims holds common OIDC profile claims unmarshaled from an ID token payload.
type OIDCUserClaims struct {
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Picture       string `json:"picture"`
	Name          string `json:"name"`
}

// OIDCProvider wraps OpenID Connect discovery and ID token verification.
type OIDCProvider struct {
	Provider *oidc.Provider
	Verifier *oidc.IDTokenVerifier
}

// NewOIDCProvider loads provider metadata from issuerURL (well-known discovery) and builds an ID token verifier.
func NewOIDCProvider(ctx context.Context, issuerURL, clientID string) (*OIDCProvider, error) {
	p, err := oidc.NewProvider(ctx, issuerURL)
	if err != nil {
		return nil, err
	}
	verifier := p.Verifier(&oidc.Config{ClientID: clientID})
	return &OIDCProvider{Provider: p, Verifier: verifier}, nil
}

// NewOIDCProviderWithHTTP is like [NewOIDCProvider] but uses the given HTTP client for discovery and JWKS fetches.
func NewOIDCProviderWithHTTP(ctx context.Context, hc *http.Client, issuerURL, clientID string) (*OIDCProvider, error) {
	if hc != nil {
		ctx = oidc.ClientContext(ctx, hc)
	}
	return NewOIDCProvider(ctx, issuerURL, clientID)
}

// OAuth2Config returns an [oauth2.Config] using endpoints from discovery.
func (p *OIDCProvider) OAuth2Config(clientID, clientSecret, redirectURL string, scopes []string) *oauth2.Config {
	return &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,
		Endpoint:     p.Provider.Endpoint(),
		Scopes:       scopes,
	}
}

// VerifyIDToken validates the OIDC id_token JWT and returns the parsed token.
func (p *OIDCProvider) VerifyIDToken(ctx context.Context, rawIDToken string) (*oidc.IDToken, error) {
	return p.Verifier.Verify(ctx, rawIDToken)
}

// IdentityFromIDToken maps a verified ID token (sub + standard claims) to [Identity].
func IdentityFromIDToken(idTok *oidc.IDToken) (Identity, error) {
	if idTok == nil {
		return Identity{}, fmt.Errorf("auth.oidc: nil id token")
	}
	var c OIDCUserClaims
	if err := idTok.Claims(&c); err != nil {
		return Identity{}, err
	}
	return Identity{
		Subject: idTok.Subject,
		Email:   c.Email,
		Picture: c.Picture,
	}, nil
}

// IdentityFromUserInfo maps the OIDC UserInfo response to [Identity] (picture read from raw claims when present).
func IdentityFromUserInfo(ui *oidc.UserInfo) (Identity, error) {
	if ui == nil {
		return Identity{}, fmt.Errorf("auth.oidc: nil userinfo")
	}
	var extra struct {
		Picture string `json:"picture"`
	}
	_ = ui.Claims(&extra)
	return Identity{
		Subject: ui.Subject,
		Email:   ui.Email,
		Picture: extra.Picture,
	}, nil
}

// OIDCClient bundles discovery-backed verification with an OAuth2 config for the same issuer.
type OIDCClient struct {
	OIDC   *OIDCProvider
	OAuth2 *oauth2.Config
}

// NewOIDCClient runs OIDC discovery and builds an OAuth2 config. Pass hc for a custom HTTP client (tracing, timeouts).
// Scopes should include oidc.ScopeOpenID ("openid") so the token response includes an id_token; add "email" / "profile" for those claims.
func NewOIDCClient(ctx context.Context, issuerURL, clientID, clientSecret, redirectURL string, scopes []string, hc *http.Client) (*OIDCClient, error) {
	op, err := NewOIDCProviderWithHTTP(ctx, hc, issuerURL, clientID)
	if err != nil {
		return nil, err
	}
	cfg := op.OAuth2Config(clientID, clientSecret, redirectURL, scopes)
	return &OIDCClient{OIDC: op, OAuth2: cfg}, nil
}

func oidcKitErr(ctx *kit.Context, e *kit.Error) *kit.Error {
	if e == nil {
		return nil
	}
	if ctx == nil {
		return e
	}
	return e.WithTraceFromContext(ctx.ToContext())
}
