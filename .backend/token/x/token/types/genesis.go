package types

import "fmt"

// DefaultGenesis returns the default genesis state
func DefaultGenesis() *GenesisState {
	return &GenesisState{
		Params:   DefaultParams(),
		TokenMap: []Token{}}
}

// Validate performs basic genesis state validation returning an error upon any
// failure.
func (gs GenesisState) Validate() error {
	tokenIndexMap := make(map[string]struct{})

	for _, elem := range gs.TokenMap {
		index := fmt.Sprint(elem.Denom)
		if _, ok := tokenIndexMap[index]; ok {
			return fmt.Errorf("duplicated index for token")
		}
		tokenIndexMap[index] = struct{}{}
	}

	return gs.Params.Validate()
}
