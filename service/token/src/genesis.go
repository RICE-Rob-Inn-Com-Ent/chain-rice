package token

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"

	"cosmossdk.io/math"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// GenesisBalance assigns base units at chain genesis (amount is a non-negative integer string).
type GenesisBalance struct {
	Address string `json:"address" yaml:"address"`
	Amount  string `json:"amount" yaml:"amount"`
}

// GenesisAuthzGrant is one persisted token authz row at chain genesis.
type GenesisAuthzGrant struct {
	Grantee          string `json:"grantee" yaml:"grantee"`
	Granter          string `json:"granter" yaml:"granter"`
	Kind             uint64 `json:"kind" yaml:"kind"`
	ExpirationHeight int64  `json:"expiration_height" yaml:"expiration_height"`
	RemainingLimit   string `json:"remaining_limit,omitempty" yaml:"remaining_limit,omitempty"`
}

// GenesisState is the exportable genesis payload for x/token (JSON for genesis file / export).
type GenesisState struct {
	Params      Params              `json:"params" yaml:"params"`
	TotalSupply string              `json:"total_supply" yaml:"total_supply"`
	Balances    []GenesisBalance    `json:"balances" yaml:"balances"`
	CircuitHalt bool                `json:"circuit_halt,omitempty" yaml:"circuit_halt,omitempty"`
	AuthzGrants []GenesisAuthzGrant `json:"authz_grants,omitempty" yaml:"authz_grants,omitempty"`
}

// DefaultGenesisAdminAddress is a deterministic SMITH devnet treasury key (replace for production).
func DefaultGenesisAdminAddress() sdk.AccAddress {
	return sdk.AccAddress{
		'S', 'M', 'I', 'T', 'H', '_', 'G', 'E', 'N', 'E', 'S', 'I', 'S', '_', 'T', 'R', 'E', 'A', 'S', 1,
	}
}

// DefaultGenesis seeds params plus the full default max supply on the genesis admin.
func DefaultGenesis() GenesisState {
	params := DefaultParams()
	supply := params.MaxSupply.String()
	return GenesisState{
		Params:      params,
		TotalSupply: supply,
		Balances: []GenesisBalance{
			{
				Address: DefaultGenesisAdminAddress().String(),
				Amount:  supply,
			},
		},
	}
}

// ValidateGenesis checks addresses, amounts, and that total_supply equals the sum of balances.
func ValidateGenesis(gs GenesisState) error {
	if err := gs.Params.Validate(); err != nil {
		return fmt.Errorf("params: %w", err)
	}

	total, ok := math.NewIntFromString(strings.TrimSpace(gs.TotalSupply))
	if !ok {
		return fmt.Errorf("total_supply: invalid integer")
	}
	if total.IsNil() || total.IsNegative() || !total.IsUint64() {
		return fmt.Errorf("total_supply: must be non-negative and fit in uint64")
	}
	totalU := total.Uint64()

	sum, err := sumGenesisBalances(gs.Balances)
	if err != nil {
		return err
	}
	if sum != totalU {
		return fmt.Errorf("total_supply %d does not match sum of balances %d", totalU, sum)
	}
	if total.GT(gs.Params.MaxSupply) {
		return fmt.Errorf("total_supply %s exceeds params.max_supply %s", total.String(), gs.Params.MaxSupply.String())
	}
	for i, g := range gs.AuthzGrants {
		if err := validateGenesisAuthzGrant(i, g); err != nil {
			return err
		}
	}
	return nil
}

func validateGenesisAuthzGrant(i int, g GenesisAuthzGrant) error {
	ge := strings.TrimSpace(g.Grantee)
	gr := strings.TrimSpace(g.Granter)
	if ge == "" || gr == "" {
		return fmt.Errorf("authz_grants[%d]: grantee or granter empty", i)
	}
	if _, err := sdk.AccAddressFromBech32(ge); err != nil {
		return fmt.Errorf("authz_grants[%d]: grantee: %w", i, err)
	}
	if _, err := sdk.AccAddressFromBech32(gr); err != nil {
		return fmt.Errorf("authz_grants[%d]: granter: %w", i, err)
	}
	if g.Kind != uint64(AuthzKindMint) && g.Kind != uint64(AuthzKindBurn) {
		return fmt.Errorf("authz_grants[%d]: kind must be %d (mint) or %d (burn)", i, AuthzKindMint, AuthzKindBurn)
	}
	lim := strings.TrimSpace(g.RemainingLimit)
	if lim != "" {
		if _, err := parseGenesisAmount(lim); err != nil {
			return fmt.Errorf("authz_grants[%d]: remaining_limit: %w", i, err)
		}
	}
	return nil
}

func sumGenesisBalances(balances []GenesisBalance) (uint64, error) {
	seen := make(map[string]struct{}, len(balances))
	var sum uint64
	for i, b := range balances {
		addr := strings.TrimSpace(b.Address)
		if addr == "" {
			return 0, fmt.Errorf("balances[%d]: empty address", i)
		}
		if _, err := sdk.AccAddressFromBech32(addr); err != nil {
			return 0, fmt.Errorf("balances[%d]: address: %w", i, err)
		}
		if _, dup := seen[addr]; dup {
			return 0, fmt.Errorf("balances[%d]: duplicate address %s", i, addr)
		}
		seen[addr] = struct{}{}

		amt, err := parseGenesisAmount(b.Amount)
		if err != nil {
			return 0, fmt.Errorf("balances[%d]: %w", i, err)
		}
		var errAdd error
		sum, errAdd = addUint64Genesis(sum, amt)
		if errAdd != nil {
			return 0, errAdd
		}
	}
	return sum, nil
}

func parseGenesisAmount(s string) (uint64, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, fmt.Errorf("empty amount")
	}
	i, ok := math.NewIntFromString(s)
	if !ok {
		return 0, fmt.Errorf("invalid amount")
	}
	if i.IsNil() || i.IsNegative() || !i.IsUint64() {
		return 0, fmt.Errorf("amount must be non-negative and fit in uint64")
	}
	return i.Uint64(), nil
}

func addUint64Genesis(a, b uint64) (uint64, error) {
	if b != 0 && a > ^uint64(0)-b {
		return 0, fmt.Errorf("genesis balances overflow uint64")
	}
	return a + b, nil
}

// InitGenesis loads params, balances (via Mint), authz grants, and circuit halt from validated genesis JSON.
func InitGenesis(ctx sdk.Context, k Keeper, data json.RawMessage) error {
	var gs GenesisState
	if err := json.Unmarshal(data, &gs); err != nil {
		return fmt.Errorf("token genesis json: %w", err)
	}
	if err := ValidateGenesis(gs); err != nil {
		return err
	}

	goCtx := ctx.Context()
	if err := k.SetParams(goCtx, gs.Params); err != nil {
		return fmt.Errorf("token genesis params: %w", err)
	}
	for i, b := range gs.Balances {
		addr, err := sdk.AccAddressFromBech32(strings.TrimSpace(b.Address))
		if err != nil {
			return fmt.Errorf("balances[%d]: %w", i, err)
		}
		amt, ok := math.NewIntFromString(strings.TrimSpace(b.Amount))
		if !ok {
			return fmt.Errorf("balances[%d]: invalid amount", i)
		}
		if amt.IsNil() || amt.IsZero() {
			continue
		}
		if err := k.Mint(goCtx, addr, amt); err != nil {
			return fmt.Errorf("balances[%d] mint: %w", i, err)
		}
	}

	sup, err := k.TotalSupply(goCtx)
	if err != nil {
		return err
	}
	expected, ok := math.NewIntFromString(strings.TrimSpace(gs.TotalSupply))
	if !ok {
		return fmt.Errorf("total_supply: invalid")
	}
	if !sup.Equal(expected) {
		return fmt.Errorf("after init, total supply %s != genesis total_supply %s", sup.String(), expected.String())
	}
	return nil
}

// ExportGenesis serializes current balances, supply, params, circuit flag, and authz grants for backup / fork exports.
func ExportGenesis(ctx sdk.Context, k Keeper) (json.RawMessage, error) {
	goCtx := ctx.Context()

	sup, err := k.TotalSupply(goCtx)
	if err != nil {
		return nil, err
	}
	if !sup.IsUint64() {
		return nil, fmt.Errorf("export: total supply does not fit uint64")
	}

	params, err := k.GetParams(goCtx)
	if err != nil {
		return nil, err
	}
	if sup.GT(params.MaxSupply) {
		params.MaxSupply = sup
	}

	var balances []GenesisBalance
	if err := k.IterateBalances(goCtx, func(addr sdk.AccAddress, v math.Int) (bool, error) {
		if v.IsNil() || v.IsZero() {
			return false, nil
		}
		if !v.IsUint64() {
			return true, fmt.Errorf("export: balance for %s does not fit uint64", addr.String())
		}
		balances = append(balances, GenesisBalance{
			Address: addr.String(),
			Amount:  v.String(),
		})
		return false, nil
	}); err != nil {
		return nil, err
	}

	sort.Slice(balances, func(i, j int) bool {
		return balances[i].Address < balances[j].Address
	})

	circuitHalt, err := k.IsCircuitHaltEngaged(goCtx)
	if err != nil {
		return nil, err
	}

	var authz []GenesisAuthzGrant
	if err := k.IterateAuthzGrants(goCtx, func(grantee, granter sdk.AccAddress, kind AuthzKind, g AuthzGrant) (bool, error) {
		authz = append(authz, GenesisAuthzGrant{
			Grantee:          grantee.String(),
			Granter:          granter.String(),
			Kind:             uint64(kind),
			ExpirationHeight: g.ExpirationHeight,
			RemainingLimit:   g.RemainingLimit,
		})
		return false, nil
	}); err != nil {
		return nil, err
	}
	sort.Slice(authz, func(i, j int) bool {
		if authz[i].Grantee != authz[j].Grantee {
			return authz[i].Grantee < authz[j].Grantee
		}
		if authz[i].Granter != authz[j].Granter {
			return authz[i].Granter < authz[j].Granter
		}
		return authz[i].Kind < authz[j].Kind
	})

	gs := GenesisState{
		Params:      params,
		TotalSupply: sup.String(),
		Balances:    balances,
		CircuitHalt: circuitHalt,
		AuthzGrants: authz,
	}
	if err := ValidateGenesis(gs); err != nil {
		return nil, fmt.Errorf("export validation: %w", err)
	}
	return json.Marshal(gs)
}
