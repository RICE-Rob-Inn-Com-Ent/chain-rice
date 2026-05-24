package token

import (
	"fmt"

	"cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// Params governs x/token chain-wide rules. Persisted via collections ([State].Params), not read here.
type Params struct {
	MintDenom      string   `json:"mint_denom" yaml:"mint_denom"`
	MintingEnabled bool     `json:"minting_enabled" yaml:"minting_enabled"`
	MaxSupply      math.Int `json:"max_supply" yaml:"max_supply"`
}

// DefaultParams returns SMITH defaults (micro-denom urice, minting on, capped supply in base units).
func DefaultParams() Params {
	return Params{
		MintDenom:      "urice",
		MintingEnabled: true,
		MaxSupply:      math.NewInt(21_000_000_000000), // 21e6 full RICE at 10^6 units per coin
	}
}

// Validate checks denom and supply caps.
func (p Params) Validate() error {
	if err := sdk.ValidateDenom(p.MintDenom); err != nil {
		return fmt.Errorf("mint_denom: %w", err)
	}
	if p.MaxSupply.IsNil() || p.MaxSupply.IsNegative() || p.MaxSupply.IsZero() {
		return fmt.Errorf("max_supply must be positive")
	}
	return nil
}
