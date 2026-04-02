package auth

// TODO:
// [ ] implement SPIFFE/SPIRE workload identity:
//     NewSpiffeClient(ctx) (*spiffe.X509Source, error)
//     reads RICE_SPIFFE_AGENT_SOCKET from env
// [ ] implement mTLS:
//     TLSConfig(ctx, source *spiffe.X509Source) (*tls.Config, error)
//     mutual TLS between rice services
//     SVID rotation handled automatically by SPIRE agent
// [ ] implement SVID validation:
//     ValidateSVID(ctx, svid string) error
//     validates SPIFFE ID against trust domain
//     trust domain from RICE_SPIFFE_TRUST_DOMAIN env var

import (
	"context"
	"crypto/tls"

	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

// NewX509Source returns an X.509 source backed by the SPIFFE workload API (for SVID fetch and bundle).
func NewX509Source(ctx context.Context, opts ...workloadapi.X509SourceOption) (*workloadapi.X509Source, error) {
	return workloadapi.NewX509Source(ctx, opts...)
}

// MTLSClientConfig returns a tls.Config for SPIFFE mTLS (workload to workload).
// The caller must Close the X509Source when the TLS config is no longer needed.
func MTLSClientConfig(ctx context.Context) (*tls.Config, *workloadapi.X509Source, error) {
	source, err := workloadapi.NewX509Source(ctx)
	if err != nil {
		return nil, nil, err
	}
	cfg := tlsconfig.MTLSClientConfig(source, source, tlsconfig.AuthorizeAny())
	return cfg, source, nil
}

// MTLSServerConfig returns a tls.Config for an SPIFFE-authenticated server.
// The caller must Close the X509Source when the TLS config is no longer needed.
func MTLSServerConfig(ctx context.Context) (*tls.Config, *workloadapi.X509Source, error) {
	source, err := workloadapi.NewX509Source(ctx)
	if err != nil {
		return nil, nil, err
	}
	cfg := tlsconfig.MTLSServerConfig(source, source, tlsconfig.AuthorizeAny())
	return cfg, source, nil
}

// MTLSClientTLSConfigFromSource builds a client tls.Config from an existing source (long-lived).
func MTLSClientTLSConfigFromSource(source *workloadapi.X509Source) *tls.Config {
	return tlsconfig.MTLSClientConfig(source, source, tlsconfig.AuthorizeAny())
}

// MTLSServerTLSConfigFromSource builds a server tls.Config from an existing source.
func MTLSServerTLSConfigFromSource(source *workloadapi.X509Source) *tls.Config {
	return tlsconfig.MTLSServerConfig(source, source, tlsconfig.AuthorizeAny())
}
