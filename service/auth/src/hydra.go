package auth

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	hydra "github.com/ory/hydra-client-go"
)

// Hydra wraps the Ory Hydra admin API for consent completion and token introspection.
type Hydra struct {
	Client *hydra.APIClient
}

// NewHydra returns a [Hydra] using [NewHydraClient].
func NewHydra(adminURL string, httpClient *http.Client) *Hydra {
	return &Hydra{Client: NewHydraClient(adminURL, httpClient)}
}

// NewHydraClient builds the Ory Hydra OpenAPI client (OAuth2/OIDC server admin/public base URL).
func NewHydraClient(publicURL string, httpClient *http.Client) *hydra.APIClient {
	cfg := hydra.NewConfiguration()
	cfg.Servers = hydra.ServerConfigurations{{URL: publicURL}}
	if httpClient != nil {
		cfg.HTTPClient = httpClient
	}
	return hydra.NewAPIClient(cfg)
}

// AcceptConsentRequest loads the consent challenge, grants the requested scopes and audiences, and completes the flow.
// Callers redirect the user to [hydra.CompletedRequest.RedirectTo].
func (h *Hydra) AcceptConsentRequest(ctx *kit.Context, challenge string) (*hydra.CompletedRequest, *kit.Error) {
	if h == nil || h.Client == nil {
		return nil, hydraKitErr(ctx, kit.Internal("auth.hydra: nil client"))
	}
	if strings.TrimSpace(challenge) == "" {
		return nil, hydraKitErr(ctx, kit.BadRequest("auth.hydra: empty consent challenge"))
	}
	gctx := hydraGoCtx(ctx)
	consent, resp, err := h.Client.AdminApi.GetConsentRequest(gctx).ConsentChallenge(challenge).Execute()
	if err != nil {
		return nil, hydraOryErr(ctx, "auth.hydra", resp, err)
	}
	if consent == nil {
		return nil, hydraKitErr(ctx, kit.Internal("auth.hydra: empty consent request"))
	}
	accept := hydra.NewAcceptConsentRequest()
	scopes := append([]string(nil), consent.GetRequestedScope()...)
	aud := append([]string(nil), consent.GetRequestedAccessTokenAudience()...)
	accept.SetGrantScope(scopes)
	accept.SetGrantAccessTokenAudience(aud)
	done, resp2, err2 := h.Client.AdminApi.AcceptConsentRequest(gctx).
		ConsentChallenge(challenge).
		AcceptConsentRequest(*accept).
		Execute()
	if err2 != nil {
		return nil, hydraOryErr(ctx, "auth.hydra", resp2, err2)
	}
	return done, nil
}

// IntrospectToken calls Hydra's RFC 7662 introspection endpoint. A token is valid when result.Active is true.
func (h *Hydra) IntrospectToken(ctx *kit.Context, token string) (*hydra.OAuth2TokenIntrospection, *kit.Error) {
	if h == nil || h.Client == nil {
		return nil, hydraKitErr(ctx, kit.Internal("auth.hydra: nil client"))
	}
	if strings.TrimSpace(token) == "" {
		return nil, hydraKitErr(ctx, kit.BadRequest("auth.hydra: empty token"))
	}
	gctx := hydraGoCtx(ctx)
	info, resp, err := h.Client.AdminApi.IntrospectOAuth2Token(gctx).Token(token).Execute()
	if err != nil {
		return nil, hydraOryErr(ctx, "auth.hydra", resp, err)
	}
	return info, nil
}

func hydraGoCtx(ctx *kit.Context) context.Context {
	if ctx == nil {
		return context.Background()
	}
	return ctx.ToContext()
}

func hydraKitErr(ctx *kit.Context, e *kit.Error) *kit.Error {
	if e == nil {
		return nil
	}
	if ctx == nil {
		return e
	}
	return e.WithTraceFromContext(ctx.ToContext())
}

func hydraOryErr(ctx *kit.Context, svc string, resp *http.Response, err error) *kit.Error {
	gctx := hydraGoCtx(ctx)
	msg := svc
	if err != nil {
		msg = fmt.Sprintf("%s: %v", svc, err)
	} else if resp != nil {
		msg = fmt.Sprintf("%s: %s", svc, resp.Status)
	}
	var ke *kit.Error
	switch {
	case resp != nil && resp.StatusCode == http.StatusUnauthorized:
		ke = kit.Unauthorized(msg)
	case resp != nil && resp.StatusCode == http.StatusBadRequest:
		ke = kit.BadRequest(msg)
	case resp != nil && resp.StatusCode == http.StatusNotFound:
		ke = kit.NotFound(msg)
	default:
		ke = kit.Internal(msg)
	}
	return ke.WithTraceFromContext(gctx)
}
