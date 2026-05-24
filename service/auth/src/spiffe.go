package auth

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"net/http"
	"os"
	"sync"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/gofiber/fiber/v2"
	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/svid/x509svid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
	"google.golang.org/grpc/codes"
)

var (
	spiffeMu     sync.RWMutex
	globalX509   *workloadapi.X509Source
	spiffeSocket = defaultSpiffeSocket // overridden in tests
)

func defaultSpiffeSocket() string {
	if s := os.Getenv("SPIFFE_ENDPOINT_SOCKET"); s != "" {
		return s
	}
	return os.Getenv("RICE_SPIFFE_AGENT_SOCKET")
}

// InitSpiffe connects to the SPIRE Agent via the SPIFFE Workload API and
// keeps a process-wide [workloadapi.X509Source] for SVIDs and trust bundles.
// It is idempotent: subsequent calls return nil while a source is already open.
//
// Socket resolution: SPIFFE_ENDPOINT_SOCKET, then RICE_SPIFFE_AGENT_SOCKET.
// If both are empty, the go-spiffe default (SPIFFE_ENDPOINT_SOCKET in spec) applies.
func InitSpiffe(ctx *kit.Context) error {
	spiffeMu.Lock()
	defer spiffeMu.Unlock()
	if globalX509 != nil {
		return nil
	}

	base := context.Background()
	if ctx != nil {
		base = ctx
	}

	var opts []workloadapi.X509SourceOption
	if addr := spiffeSocket(); addr != "" {
		opts = append(opts, workloadapi.WithClientOptions(workloadapi.WithAddr(addr)))
	}

	src, err := workloadapi.NewX509Source(base, opts...)
	if err != nil {
		return err
	}
	globalX509 = src
	return nil
}

// CloseSpiffe closes the workload API source created by [InitSpiffe].
func CloseSpiffe() error {
	spiffeMu.Lock()
	defer spiffeMu.Unlock()
	if globalX509 == nil {
		return nil
	}
	err := globalX509.Close()
	globalX509 = nil
	return err
}

func x509SourceOrErr() (*workloadapi.X509Source, error) {
	spiffeMu.RLock()
	defer spiffeMu.RUnlock()
	if globalX509 == nil {
		return nil, errors.New("auth.spiffe: InitSpiffe not called or source closed")
	}
	return globalX509, nil
}

// GetX509SVID returns the workload X509-SVID from the source initialized by [InitSpiffe].
func GetX509SVID() (*x509svid.SVID, error) {
	src, err := x509SourceOrErr()
	if err != nil {
		return nil, err
	}
	return src.GetX509SVID()
}

// VerifyPeerX509SVID cryptographically verifies an mTLS peer chain against trust
// bundles received from the SPIRE Agent (same as the local workload's federation view).
func VerifyPeerX509SVID(peer []*x509.Certificate) (spiffeid.ID, [][]*x509.Certificate, error) {
	src, err := x509SourceOrErr()
	if err != nil {
		return spiffeid.ID{}, nil, err
	}
	return x509svid.Verify(peer, src)
}

// InternalOnlyVerified is like [InternalOnly] but verifies the peer presents a valid
// X509-SVID chain anchored in the local bundle source, not only a SPIFFE URI SAN.
func InternalOnlyVerified(authorize func(id spiffeid.ID) *kit.Error) fiber.Handler {
	return func(c *fiber.Ctx) error {
		st := c.Context().TLSConnectionState()
		if st == nil || len(st.PeerCertificates) == 0 {
			return kit.Unauthorized("auth.spiffe: missing or invalid mTLS peer chain").AsFiber(c)
		}
		id, _, err := VerifyPeerX509SVID(st.PeerCertificates)
		if err != nil {
			return kit.Unauthorized("auth.spiffe: peer svid verification failed").AsFiber(c)
		}
		if authorize != nil {
			if ke := authorize(id); ke != nil {
				return ke.AsFiber(c)
			}
		}
		c.Locals(LocalSPIFFEID, id.String())
		return c.Next()
	}
}

// AllowedPeerSPIFFEIDs returns an authorize function for [InternalOnlyVerified]
// that permits only the listed SPIFFE ID strings (403 otherwise).
func AllowedPeerSPIFFEIDs(allowed ...string) func(spiffeid.ID) *kit.Error {
	m := make(map[string]struct{}, len(allowed))
	for _, id := range allowed {
		if id != "" {
			m[id] = struct{}{}
		}
	}
	return func(id spiffeid.ID) *kit.Error {
		if _, ok := m[id.String()]; !ok {
			return kit.New("FORBIDDEN", "auth.spiffe: peer svid not in allow list", http.StatusForbidden, codes.PermissionDenied)
		}
		return nil
	}
}

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

// GlobalX509Source returns the source created by [InitSpiffe], or nil if uninitialized.
// Callers must not Close the returned source except via [CloseSpiffe].
func GlobalX509Source() *workloadapi.X509Source {
	spiffeMu.RLock()
	defer spiffeMu.RUnlock()
	return globalX509
}
