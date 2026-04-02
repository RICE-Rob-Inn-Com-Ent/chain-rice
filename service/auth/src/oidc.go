package auth

// TODO:
// [ ] implement OIDC discovery:
//     NewProvider(ctx, issuerURL string) (*oidc.Provider, error)
//     issuerURL from RICE_AUTH_OIDC_ISSUER env var
// [ ] implement ID token verification:
//     Verify(ctx, rawIDToken string) (*oidc.IDToken, error)
//     clientID from RICE_AUTH_OIDC_CLIENT_ID env var
// [ ] implement claims extraction:
//     ExtractClaims(idToken *oidc.IDToken) (Claims, error)
//     maps OIDC claims → rice Claims struct

import (
	"context"

	"github.com/coreos/go-oidc/v3/oidc"
	"golang.org/x/oauth2"
)

// OIDCProvider wraps discovery and ID token verification.
type OIDCProvider struct {
	Provider *oidc.Provider
	Verifier *oidc.IDTokenVerifier
}

// NewOIDCProvider performs OIDC discovery and builds an ID token verifier.
func NewOIDCProvider(ctx context.Context, issuerURL, clientID string) (*OIDCProvider, error) {
	p, err := oidc.NewProvider(ctx, issuerURL)
	if err != nil {
		return nil, err
	}
	verifier := p.Verifier(&oidc.Config{ClientID: clientID})
	return &OIDCProvider{Provider: p, Verifier: verifier}, nil
}

// OAuth2Config returns an oauth2.Config for the provider's auth and token endpoints.
func (p *OIDCProvider) OAuth2Config(clientID, clientSecret, redirectURL string, scopes []string) *oauth2.Config {
	return &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,
		Endpoint:     p.Provider.Endpoint(),
		Scopes:       scopes,
	}
}

// VerifyIDToken validates the OIDC id_token and returns claims.
func (p *OIDCProvider) VerifyIDToken(ctx context.Context, rawIDToken string) (*oidc.IDToken, error) {
	return p.Verifier.Verify(ctx, rawIDToken)
}
