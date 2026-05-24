package auth

// Passkey / WebAuthn ceremonies for .rice OS using github.com/go-webauthn/webauthn.
// Persist credentials via [WebAuthnStore] (e.g. Yugabyte); session/challenge state is caller-managed.

import (
	"encoding/hex"
	"errors"
	"log/slog"
	"net/http"
	"strings"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
)

// DefaultRPDisplayName is the default RP display name for SMITH WebAuthn.
const DefaultRPDisplayName = "SMITH OS"

// WebAuthnUser is the [webauthn.User] view used by registration and login (load credentials from [WebAuthnStore]).
type WebAuthnUser struct {
	ID          []byte
	Name        string
	DisplayName string
	Credentials []Credential
}

func (u *WebAuthnUser) WebAuthnID() []byte {
	if u == nil {
		return nil
	}
	return u.ID
}

func (u *WebAuthnUser) WebAuthnName() string {
	if u == nil {
		return ""
	}
	return u.Name
}

func (u *WebAuthnUser) WebAuthnDisplayName() string {
	if u == nil {
		return ""
	}
	if u.DisplayName != "" {
		return u.DisplayName
	}
	return u.Name
}

func (u *WebAuthnUser) WebAuthnCredentials() []webauthn.Credential {
	if u == nil {
		return nil
	}
	return u.Credentials
}

var _ webauthn.User = (*WebAuthnUser)(nil)

// WebAuthnStore persists WebAuthn credentials (durable store — not ephemeral cache).
type WebAuthnStore interface {
	SaveCredential(ctx *kit.Context, userID []byte, cred Credential) error
	LoadCredentials(ctx *kit.Context, userID []byte) ([]Credential, error)
}

// SmithWebAuthn wraps [webauthn.WebAuthn] with SMITH defaults and logging.
type SmithWebAuthn struct {
	wa *webauthn.WebAuthn
}

// NewRiceWebAuthnConfig builds RP config: display name defaults to [DefaultRPDisplayName].
// rpOrigins must include the full frontend origin(s) (e.g. https://app.example.com).
func NewRiceWebAuthnConfig(rpDisplayName, rpID string, rpOrigins []string) (*webauthn.Config, error) {
	rpID = strings.TrimSpace(rpID)
	if rpID == "" {
		return nil, errors.New("auth.webauthn: empty RPID")
	}
	if len(rpOrigins) == 0 {
		return nil, errors.New("auth.webauthn: at least one RP origin required")
	}
	dn := strings.TrimSpace(rpDisplayName)
	if dn == "" {
		dn = DefaultRPDisplayName
	}
	origins := make([]string, 0, len(rpOrigins))
	for _, o := range rpOrigins {
		o = strings.TrimSpace(o)
		if o != "" {
			origins = append(origins, o)
		}
	}
	if len(origins) == 0 {
		return nil, errors.New("auth.webauthn: no valid RP origins")
	}
	return &webauthn.Config{
		RPDisplayName: dn,
		RPID:          rpID,
		RPOrigins:     origins,
		AuthenticatorSelection: protocol.AuthenticatorSelection{
			UserVerification: protocol.VerificationPreferred,
		},
	}, nil
}

// NewWebAuthn creates the library facade from RP configuration.
func NewWebAuthn(cfg *webauthn.Config) (*webauthn.WebAuthn, error) {
	return webauthn.New(cfg)
}

// NewSmithWebAuthn returns a SMITH wrapper around a configured [webauthn.WebAuthn].
func NewSmithWebAuthn(wa *webauthn.WebAuthn) (*SmithWebAuthn, error) {
	if wa == nil {
		return nil, errors.New("auth.webauthn: nil WebAuthn")
	}
	return &SmithWebAuthn{wa: wa}, nil
}

// NewSmithWebAuthnFromConfig is [NewWebAuthn] + [NewSmithWebAuthn].
func NewSmithWebAuthnFromConfig(cfg *webauthn.Config) (*SmithWebAuthn, error) {
	wa, err := NewWebAuthn(cfg)
	if err != nil {
		return nil, err
	}
	return NewSmithWebAuthn(wa)
}

// WebAuthn returns the underlying SDK instance.
func (s *SmithWebAuthn) WebAuthn() *webauthn.WebAuthn {
	if s == nil {
		return nil
	}
	return s.wa
}

// BeginRegistration starts passkey registration for user.
func (s *SmithWebAuthn) BeginRegistration(user *WebAuthnUser, opts ...webauthn.RegistrationOption) (*protocol.CredentialCreation, *webauthn.SessionData, error) {
	if s == nil || s.wa == nil {
		return nil, nil, errors.New("auth.webauthn: nil service")
	}
	if user == nil {
		return nil, nil, errors.New("auth.webauthn: nil user")
	}
	return s.wa.BeginRegistration(user, opts...)
}

// FinishRegistration completes registration from the HTTP request body (POST JSON).
func (s *SmithWebAuthn) FinishRegistration(ctx *kit.Context, user *WebAuthnUser, session webauthn.SessionData, r *http.Request) (*webauthn.Credential, error) {
	if s == nil || s.wa == nil {
		return nil, errors.New("auth.webauthn: nil service")
	}
	if user == nil {
		return nil, errors.New("auth.webauthn: nil user")
	}
	if r == nil {
		return nil, errors.New("auth.webauthn: nil request")
	}
	cred, err := s.wa.FinishRegistration(user, session, r)
	if err != nil {
		return nil, err
	}
	logWebAuthnSuccess(ctx, "registration", user.WebAuthnID(), cred)
	return cred, nil
}

// FinishRegistrationWithBody completes registration from raw JSON ([protocol.ParseCredentialCreationResponseBytes]).
func (s *SmithWebAuthn) FinishRegistrationWithBody(ctx *kit.Context, user *WebAuthnUser, session webauthn.SessionData, responseBody []byte) (*webauthn.Credential, error) {
	if s == nil || s.wa == nil {
		return nil, errors.New("auth.webauthn: nil service")
	}
	if user == nil {
		return nil, errors.New("auth.webauthn: nil user")
	}
	parsed, err := protocol.ParseCredentialCreationResponseBytes(responseBody)
	if err != nil {
		return nil, err
	}
	cred, err := s.wa.CreateCredential(user, session, parsed)
	if err != nil {
		return nil, err
	}
	logWebAuthnSuccess(ctx, "registration", user.WebAuthnID(), cred)
	return cred, nil
}

// BeginLogin starts assertion for user (non-discoverable; user must have credentials).
func (s *SmithWebAuthn) BeginLogin(user *WebAuthnUser, opts ...webauthn.LoginOption) (*protocol.CredentialAssertion, *webauthn.SessionData, error) {
	if s == nil || s.wa == nil {
		return nil, nil, errors.New("auth.webauthn: nil service")
	}
	if user == nil {
		return nil, nil, errors.New("auth.webauthn: nil user")
	}
	return s.wa.BeginLogin(user, opts...)
}

// BeginDiscoverableLogin starts a client-side discoverable (passkey) login.
func (s *SmithWebAuthn) BeginDiscoverableLogin(opts ...webauthn.LoginOption) (*protocol.CredentialAssertion, *webauthn.SessionData, error) {
	if s == nil || s.wa == nil {
		return nil, nil, errors.New("auth.webauthn: nil service")
	}
	return s.wa.BeginDiscoverableLogin(opts...)
}

// FinishLogin completes login from the HTTP request body (POST JSON).
func (s *SmithWebAuthn) FinishLogin(ctx *kit.Context, user *WebAuthnUser, session webauthn.SessionData, r *http.Request) (*webauthn.Credential, error) {
	if s == nil || s.wa == nil {
		return nil, errors.New("auth.webauthn: nil service")
	}
	if user == nil {
		return nil, errors.New("auth.webauthn: nil user")
	}
	if r == nil {
		return nil, errors.New("auth.webauthn: nil request")
	}
	cred, err := s.wa.FinishLogin(user, session, r)
	if err != nil {
		return nil, err
	}
	logWebAuthnSuccess(ctx, "login", user.WebAuthnID(), cred)
	return cred, nil
}

// FinishLoginWithBody completes login from raw JSON ([protocol.ParseCredentialRequestResponseBytes]).
func (s *SmithWebAuthn) FinishLoginWithBody(ctx *kit.Context, user *WebAuthnUser, session webauthn.SessionData, responseBody []byte) (*webauthn.Credential, error) {
	if s == nil || s.wa == nil {
		return nil, errors.New("auth.webauthn: nil service")
	}
	if user == nil {
		return nil, errors.New("auth.webauthn: nil user")
	}
	parsed, err := protocol.ParseCredentialRequestResponseBytes(responseBody)
	if err != nil {
		return nil, err
	}
	cred, err := s.wa.ValidateLogin(user, session, parsed)
	if err != nil {
		return nil, err
	}
	logWebAuthnSuccess(ctx, "login", user.WebAuthnID(), cred)
	return cred, nil
}

// FinishRegistrationAndSave runs [SmithWebAuthn.FinishRegistrationWithBody] then [WebAuthnStore.SaveCredential].
func (s *SmithWebAuthn) FinishRegistrationAndSave(ctx *kit.Context, store WebAuthnStore, user *WebAuthnUser, session webauthn.SessionData, responseBody []byte) (*webauthn.Credential, error) {
	cred, err := s.FinishRegistrationWithBody(ctx, user, session, responseBody)
	if err != nil {
		return nil, err
	}
	if store != nil {
		if err := store.SaveCredential(ctx, user.WebAuthnID(), *cred); err != nil {
			return cred, err
		}
	}
	return cred, nil
}

func logWebAuthnSuccess(ctx *kit.Context, ceremony string, userHandle []byte, cred *webauthn.Credential) {
	lg := kit.Logger()
	args := []any{
		slog.String("auth.webauthn.ceremony", ceremony),
		slog.Int("auth.webauthn.user_handle_len", len(userHandle)),
	}
	if cred != nil && len(cred.ID) > 0 {
		args = append(args, slog.String("auth.webauthn.credential_id_prefix", credentialIDPrefix(cred.ID)))
	}
	if ctx != nil && ctx.TraceID.IsValid() {
		args = append(args, slog.String("trace_id", ctx.TraceID.String()))
	}
	lg.Info("auth.webauthn.success", args...)
}

func credentialIDPrefix(id []byte) string {
	const maxHex = 24
	h := hex.EncodeToString(id)
	if len(h) > maxHex {
		return h[:maxHex]
	}
	return h
}

// Re-export commonly used types for credential stores and handlers.
type (
	WebAuthnConfig = webauthn.Config
	SessionData    = webauthn.SessionData
	Credential     = webauthn.Credential
)

// UserVerificationDiscouraged is a convenience constant.
var UserVerificationDiscouraged = protocol.VerificationDiscouraged
