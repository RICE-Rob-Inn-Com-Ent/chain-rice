// Package auth implements SMITH application identity: PASETO sessions, OAuth2/OIDC, WebAuthn,
// Ory Kratos/Hydra clients, SPIFFE workload identity, BIP39 mnemonics, and Fiber middleware for
// multi-method authentication.
//
// Start here for the public surface, then open the file that matches your concern:
//
//   - PASETO issue/verify, API keys: paseto.go, crypto.go
//   - Fiber auth (bearer, cookie, API key): middleware.go — MultiAuthConfig, PasetoBearerConfig
//   - Ory: kratos.go (identity), hydra.go (OAuth2 server), session.go (Redis-backed session cache)
//   - OAuth2/OIDC clients: oauth.go, oidc.go
//   - WebAuthn: webauthn.go — SmithWebAuthn, NewRiceWebAuthnConfig
//   - SPIFFE: spiffe.go
//   - BIP39 mnemonics: bip39.go
//   - Post-quantum helpers: pqcrypto.go
//   - RBAC: policy.go
package auth
