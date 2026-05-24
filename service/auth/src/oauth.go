package auth

import (
	"context"
	"fmt"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"golang.org/x/oauth2"
)

// OAuthSession is the SMITH session after a successful external OIDC/OAuth2 authorization code exchange.
type OAuthSession struct {
	Identity Identity
	Token    *oauth2.Token
}

// ExchangeCode swaps an authorization code for tokens, verifies the ID token when present, and maps claims to [Identity].
// Pass PKCE [oauth2.VerifierOption] from [NewPKCEPair] when the auth request used PKCE.
func (c *OIDCClient) ExchangeCode(ctx *kit.Context, code string, opts ...oauth2.AuthCodeOption) (*OAuthSession, *kit.Error) {
	if c == nil || c.OAuth2 == nil || c.OIDC == nil {
		return nil, oidcKitErr(ctx, kit.Internal("auth.oauth: nil OIDC client"))
	}
	if strings.TrimSpace(code) == "" {
		return nil, oidcKitErr(ctx, kit.BadRequest("auth.oauth: empty code"))
	}
	gctx := context.Background()
	if ctx != nil {
		gctx = ctx.ToContext()
	}
	tok, err := c.OAuth2.Exchange(gctx, code, opts...)
	if err != nil {
		return nil, oidcKitErr(ctx, kit.BadRequest("auth.oauth: token exchange failed: "+err.Error()))
	}
	id, kerr := c.identityFromTokenExchange(gctx, tok)
	if kerr != nil {
		return nil, oidcKitErr(ctx, kerr)
	}
	return &OAuthSession{Identity: id, Token: tok}, nil
}

func (c *OIDCClient) identityFromTokenExchange(gctx context.Context, tok *oauth2.Token) (Identity, *kit.Error) {
	raw, ok := idTokenStringFromToken(tok)
	if ok && raw != "" {
		idTok, err := c.OIDC.VerifyIDToken(gctx, raw)
		if err != nil {
			return Identity{}, kit.BadRequest("auth.oauth: id_token verify: " + err.Error())
		}
		if idTok.AccessTokenHash != "" && tok.AccessToken != "" {
			if err := idTok.VerifyAccessToken(tok.AccessToken); err != nil {
				return Identity{}, kit.Unauthorized("auth.oauth: " + err.Error())
			}
		}
		id, err := IdentityFromIDToken(idTok)
		if err != nil {
			return Identity{}, kit.Internal("auth.oauth: id_token claims: " + err.Error())
		}
		return id, nil
	}
	ui, err := c.OIDC.Provider.UserInfo(gctx, oauth2.StaticTokenSource(tok))
	if err != nil {
		return Identity{}, kit.BadRequest("auth.oauth: missing id_token and userinfo failed: " + err.Error())
	}
	id, err := IdentityFromUserInfo(ui)
	if err != nil {
		return Identity{}, kit.Internal("auth.oauth: userinfo claims: " + err.Error())
	}
	return id, nil
}

func idTokenStringFromToken(tok *oauth2.Token) (string, bool) {
	if tok == nil {
		return "", false
	}
	switch v := tok.Extra("id_token").(type) {
	case string:
		s := strings.TrimSpace(v)
		return s, s != ""
	case []byte:
		s := strings.TrimSpace(string(v))
		return s, s != ""
	default:
		if v == nil {
			return "", false
		}
		s := strings.TrimSpace(fmt.Sprint(v))
		return s, s != ""
	}
}

// PKCEPair holds verifier and AuthCodeURL / Exchange options.
type PKCEPair struct {
	Verifier     string
	ChallengeOpt oauth2.AuthCodeOption
	VerifierOpt  oauth2.AuthCodeOption
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
