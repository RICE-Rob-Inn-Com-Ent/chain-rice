package token

import (
	"context"

	"github.com/chainrice/rice/backend/app/token"
)

// TokenInitGenesis initializes the module's state from a provided genesis state.
func (k TokenKeeper) TokenInitGenesis(ctx context.Context, genState *token.GenesisState) error {
	for _, elem := range genState.TokenMap {
		if err := k.Token.Set(ctx, elem.Denom, elem); err != nil {
			return err
		}
	}

	return k.Params.Set(ctx, genState.Params)
}

// TokenExportGenesis returns the module's exported genesis.
func (k TokenKeeper) TokenExportGenesis(ctx context.Context) (*token.GenesisState, error) {
	var err error

	genesis := token.DefaultGenesis()
	params, err := k.Params.Get(ctx)
	if err != nil {
		return nil, err
	}
	genesis.Params = params
	if err != nil {
		return nil, err
	}
	if err := k.Token.Walk(ctx, nil, func(_ string, val token.Token) (stop bool, err error) {
		genesis.TokenMap = append(genesis.TokenMap, val)
		return false, nil
	}); err != nil {
		return nil, err
	}

	return genesis, nil
}
