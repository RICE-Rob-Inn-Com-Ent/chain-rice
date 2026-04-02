package auth

// TODO:
// [ ] implement Ory Kratos integration:
//     NewKratosClient() *kratos.APIClient
//     reads RICE_ORY_KRATOS_URL from env
// [ ] implement identity management:
//     GetIdentity(ctx, id string) (*kratos.Identity, error)
//     CreateIdentity(ctx, traits map) (*kratos.Identity, error)
//     UpdateIdentity(ctx, id string, traits map) error
//     DeleteIdentity(ctx, id string) error
// [ ] implement flow handling:
//     InitRegistrationFlow(ctx) (*kratos.RegistrationFlow, error)
//     InitLoginFlow(ctx) (*kratos.LoginFlow, error)
//     SubmitFlow(ctx, flowID string, body any) error

import (
	"net/http"

	kratos "github.com/ory/kratos-client-go"
)

// NewKratosClient builds the Ory Kratos OpenAPI client for public/admin flows.
func NewKratosClient(publicURL string, httpClient *http.Client) *kratos.APIClient {
	cfg := kratos.NewConfiguration()
	cfg.Servers = kratos.ServerConfigurations{{URL: publicURL}}
	if httpClient != nil {
		cfg.HTTPClient = httpClient
	}
	return kratos.NewAPIClient(cfg)
}
