package token

import (
	cmttypes "github.com/cometbft/cometbft/types"
)

// TokenHoldingsDoNotAffectValidatorPower documents the default .rice policy: native x/token
// balances are not mapped into CometBFT voting power. Validator weights come from staking
// (bonded stake), not from urice holdings.
const TokenHoldingsDoNotAffectValidatorPower = true

// ConsensusParamsView is a thin holder for CometBFT consensus parameters (block size, evidence, etc.).
// Full wiring reads/writes via BaseApp / sdk.ConsensusParamsKeeper in the complete app.
type ConsensusParamsView struct {
	Params cmttypes.ConsensusParams
}

// ValidatorPower is a snapshot-friendly view of voting power (ABCI validator updates use int64).
type ValidatorPower struct {
	Address []byte
	Power   int64
}

// ABCIPlusPlusHooks documents optional integration points for ABCI++ (PrepareProposal, ProcessProposal,
// ExtendVote, VerifyVoteExtension). x/token does not require custom proposal logic unless governance
// adds token-weighted criteria; keep hooks no-op unless the app registers a wrapper.
//
// Reference: https://docs.cometbft.com/v0.38/spec/abci/abci++_methods
type ABCIPlusPlusHooks struct {
	// PrepareProposalFilter optionally rejects token-related txs under circuit halt (app-level).
	PrepareProposalFilter string
	// ProcessProposalValidateTokenState set to true if the app validates token invariants in ProcessProposal.
	ProcessProposalValidateTokenState bool
}

// TokenPowerFromHoldings returns zero: token balances must not alter validator power unless the app
// implements an explicit governance-approved mapping (not default on .rice).
func TokenPowerFromHoldings(_ string) int64 {
	return 0
}
