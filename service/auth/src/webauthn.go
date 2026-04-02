package auth

// TODO:
// [ ] implement WebAuthn registration:
//     BeginRegistration(ctx, user User) (options, sessionData, error)
//     FinishRegistration(ctx, user, sessionData, response) (credential, error)
//     relying party ID from RICE_AUTH_RP_ID env var
//     relying party origin from RICE_AUTH_RP_ORIGIN env var
// [ ] implement WebAuthn authentication:
//     BeginLogin(ctx, user User) (options, sessionData, error)
//     FinishLogin(ctx, user, sessionData, response) error
// [ ] implement credential storage:
//     credentials stored in YugabyteDB via database/
//     never stored in Valkey — must be durable

import (
	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
)

// WebAuthn constructors and type aliases for registration / login ceremonies.

// NewWebAuthn creates the library facade from RP configuration.
func NewWebAuthn(cfg *webauthn.Config) (*webauthn.WebAuthn, error) {
	return webauthn.New(cfg)
}

// Re-export commonly used types for credential stores and handlers.
type (
	WebAuthnConfig = webauthn.Config
	SessionData      = webauthn.SessionData
	Credential       = webauthn.Credential
)

// UserVerificationDiscouraged is a convenience constant.
var UserVerificationDiscouraged = protocol.VerificationDiscouraged
