package auth

// TODO:
// [ ] implement Ory Hydra OAuth2 server integration:
//     NewHydraClient() *hydra.APIClient
//     reads RICE_ORY_HYDRA_URL from env
// [ ] implement consent flow:
//     GetConsentRequest(ctx, challenge string) (*hydra.ConsentRequest, error)
//     AcceptConsent(ctx, challenge string, scopes []string) (redirectURL, error)
//     RejectConsent(ctx, challenge string, reason string) (redirectURL, error)
// [ ] implement token introspection:
//     IntrospectToken(ctx, token string) (*hydra.IntrospectedOAuth2Token, error)
//     used by middleware to validate Bearer tokens

import (
	"net/http"

	hydra "github.com/ory/hydra-client-go"
)

// NewHydraClient builds the Ory Hydra OpenAPI client (OAuth2/OIDC server).
func NewHydraClient(publicURL string, httpClient *http.Client) *hydra.APIClient {
	cfg := hydra.NewConfiguration()
	cfg.Servers = hydra.ServerConfigurations{{URL: publicURL}}
	if httpClient != nil {
		cfg.HTTPClient = httpClient
	}
	return hydra.NewAPIClient(cfg)
}
