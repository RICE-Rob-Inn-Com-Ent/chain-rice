package auth

// TODO:
// [ ] implement OAuth2 authorization code flow:
//     AuthURL(state, scopes string) string
//     Exchange(ctx, code string) (*oauth2.Token, error)
//     state from RICE_AUTH_OAUTH_STATE env var
// [ ] implement token refresh:
//     Refresh(ctx, token *oauth2.Token) (*oauth2.Token, error)
//     store tokens in Valkey with TTL
// [ ] implement OAuth2 providers:
//     provider config from RICE_AUTH_OAUTH_* env vars
//     never hardcode client_id, client_secret — SOPS only

import (
	"context"

	"golang.org/x/oauth2"
)

// OAuth2 client helpers (authorization code + PKCE).

// PKCEPair holds verifier and AuthCodeURL / Exchange options.
type PKCEPair struct {
	Verifier       string
	ChallengeOpt   oauth2.AuthCodeOption
	VerifierOpt    oauth2.AuthCodeOption
}

// NewPKCEPair generates a new RFC 7636 PKCE verifier and S256 challenge options.
func NewPKCEPair() PKCEPair {
	v := oauth2.GenerateVerifier()
	return PKCEPair{
		Verifier:     v,
		ChallengeOpt: oauth2.S256ChallengeOption(v),
		VerifierOpt:  oauth2.VerifierOption(v),
	}
}

// ExchangeAuthCode exchanges an authorization code for tokens (pass VerifierOpt from PKCEPair).
func ExchangeAuthCode(ctx context.Context, cfg *oauth2.Config, code string, opts ...oauth2.AuthCodeOption) (*oauth2.Token, error) {
	return cfg.Exchange(ctx, code, opts...)
}

// RefreshToken obtains a new access token from a refresh token.
func RefreshToken(ctx context.Context, cfg *oauth2.Config, refreshToken string) (*oauth2.Token, error) {
	ts := cfg.TokenSource(ctx, &oauth2.Token{RefreshToken: refreshToken})
	return ts.Token()
}
