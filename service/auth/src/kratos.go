package auth

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	kratos "github.com/ory/kratos-client-go"
)

// Kratos wraps the Ory Kratos OpenAPI client for browser session checks and admin identity updates.
type Kratos struct {
	Client *kratos.APIClient
}

// NewKratos returns a [Kratos] using [NewKratosClient].
func NewKratos(publicURL string, httpClient *http.Client) *Kratos {
	return &Kratos{Client: NewKratosClient(publicURL, httpClient)}
}

// NewKratosClient builds the Ory Kratos OpenAPI client for public/admin flows.
func NewKratosClient(publicURL string, httpClient *http.Client) *kratos.APIClient {
	cfg := kratos.NewConfiguration()
	cfg.Servers = kratos.ServerConfigurations{{URL: publicURL}}
	if httpClient != nil {
		cfg.HTTPClient = httpClient
	}
	return kratos.NewAPIClient(cfg)
}

// GetSession resolves the active Kratos session using the forwarded browser Cookie header.
// When the cookie is missing or invalid, it returns [kit.Unauthorized].
func (k *Kratos) GetSession(ctx *kit.Context, cookie string) (*kratos.Session, *kit.Error) {
	if k == nil || k.Client == nil {
		return nil, kratosKitErr(ctx, kit.Internal("auth.kratos: nil client"))
	}
	gctx := kratosGoCtx(ctx)
	if strings.TrimSpace(cookie) == "" {
		return nil, kratosKitErr(ctx, kit.Unauthorized("auth.kratos: missing cookie"))
	}
	sess, resp, err := k.Client.FrontendAPI.ToSession(gctx).Cookie(cookie).Execute()
	if err != nil {
		if resp != nil && resp.StatusCode == http.StatusUnauthorized {
			return nil, kratosKitErr(ctx, kit.Unauthorized("auth.kratos: no valid session"))
		}
		return nil, kratosOryErr(ctx, "auth.kratos", resp, err)
	}
	if sess == nil {
		return nil, kratosKitErr(ctx, kit.Internal("auth.kratos: empty session"))
	}
	return sess, nil
}

// UpdateIdentity merges traits into the identity and mirrors name/email into metadata_public for SMITH consumers.
func (k *Kratos) UpdateIdentity(ctx *kit.Context, identityID string, traits map[string]any) *kit.Error {
	if k == nil || k.Client == nil {
		return kratosKitErr(ctx, kit.Internal("auth.kratos: nil client"))
	}
	if strings.TrimSpace(identityID) == "" {
		return kratosKitErr(ctx, kit.BadRequest("auth.kratos: empty identity id"))
	}
	gctx := kratosGoCtx(ctx)
	cur, resp, err := k.Client.IdentityAPI.GetIdentity(gctx, identityID).Execute()
	if err != nil {
		return kratosOryErr(ctx, "auth.kratos", resp, err)
	}
	if cur == nil {
		return kratosKitErr(ctx, kit.Internal("auth.kratos: empty identity"))
	}
	merged := mergeKratosTraits(cur.Traits, traits)
	state := "active"
	if cur.State != nil && strings.TrimSpace(*cur.State) != "" {
		state = *cur.State
	}
	body := kratos.NewUpdateIdentityBody(cur.SchemaId, state, merged)
	meta := mergeSmithMetadataPublic(cur.MetadataPublic, traits)
	if meta != nil {
		body.SetMetadataPublic(meta)
	}
	_, resp2, err2 := k.Client.IdentityAPI.UpdateIdentity(gctx, identityID).UpdateIdentityBody(*body).Execute()
	if err2 != nil {
		return kratosOryErr(ctx, "auth.kratos", resp2, err2)
	}
	return nil
}

func kratosGoCtx(ctx *kit.Context) context.Context {
	if ctx == nil {
		return context.Background()
	}
	return ctx.ToContext()
}

func kratosKitErr(ctx *kit.Context, e *kit.Error) *kit.Error {
	if e == nil {
		return nil
	}
	if ctx == nil {
		return e
	}
	return e.WithTraceFromContext(ctx.ToContext())
}

func kratosOryErr(ctx *kit.Context, svc string, resp *http.Response, err error) *kit.Error {
	gctx := kratosGoCtx(ctx)
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

func mergeKratosTraits(existing interface{}, patch map[string]any) map[string]interface{} {
	out := map[string]interface{}{}
	if m, ok := existing.(map[string]interface{}); ok {
		for k, v := range m {
			out[k] = v
		}
	}
	for k, v := range patch {
		out[k] = v
	}
	return out
}

func mergeSmithMetadataPublic(existing interface{}, traits map[string]any) map[string]interface{} {
	next := map[string]interface{}{}
	if m, ok := existing.(map[string]interface{}); ok {
		for k, v := range m {
			next[k] = v
		}
	}
	for _, key := range []string{"name", "email"} {
		if v, ok := traits[key]; ok {
			next[key] = v
		}
	}
	if len(next) == 0 {
		return nil
	}
	return next
}
