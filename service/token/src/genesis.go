package token

// TODO:
// [ ] implement InitGenesis:
//     sets initial balances from genesis state
//     validates genesis consistency via CLERK calc/
// [ ] implement ExportGenesis:
//     exports full module state for chain export/upgrade

import (
	"encoding/json"
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// GenesisState is the exportable genesis payload for x/token (replace with proto JSON or codec).
type GenesisState struct {
	// Params Params
}

// DefaultGenesis returns an empty valid genesis.
func DefaultGenesis() GenesisState {
	return GenesisState{}
}

// ValidateGenesis checks genesis invariants before chain start.
func ValidateGenesis(gs GenesisState) error {
	_ = gs
	return nil
}

// InitGenesis loads genesis into the keeper store.
func InitGenesis(ctx sdk.Context, k Keeper, data json.RawMessage) error {
	var gs GenesisState
	if err := json.Unmarshal(data, &gs); err != nil {
		return fmt.Errorf("token genesis json: %w", err)
	}
	if err := ValidateGenesis(gs); err != nil {
		return err
	}
	_ = ctx
	_ = k
	return nil
}

// ExportGenesis dumps module state for upgrades and state sync.
func ExportGenesis(ctx sdk.Context, k Keeper) (json.RawMessage, error) {
	_ = ctx
	_ = k
	bz, err := json.Marshal(DefaultGenesis())
	return bz, err
}
