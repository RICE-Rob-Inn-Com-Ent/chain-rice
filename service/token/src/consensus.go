package token

// TODO:
// [ ] implement CometBFT consensus integration:
//     ProcessProposal: validates incoming block proposals
//     PrepareProposal: selects txs for next block
//     ExtendVote: adds vote extensions (chain-specific data)
// [ ] implement vote extension validation:
//     VerifyVoteExtension: validates extensions from other validators

import (
	cmttypes "github.com/cometbft/cometbft/types"
)

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
