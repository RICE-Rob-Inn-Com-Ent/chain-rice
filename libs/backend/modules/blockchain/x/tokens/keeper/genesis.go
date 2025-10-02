package keeper

import (
	"encoding/json"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"cosmossdk.io/math"

	"github.com/rice-dev/backend/blockchain/x/tokens/types"
)

// InitGenesis initializes the tokens module's genesis state
func InitGenesis(ctx sdk.Context, k Keeper, genState types.GenesisState) {
	// Set all the params
	k.SetParams(ctx, genState.Params)

	// Set all the tokens
	for _, token := range genState.Tokens {
		k.SetToken(ctx, token)
	}

	// Set all the token transfers
	for _, transfer := range genState.TokenTransfers {
		k.SetTokenTransfer(ctx, transfer)
	}

	// Set all the token balances
	for _, balance := range genState.TokenBalances {
		k.SetTokenBalance(ctx, balance.TokenId, balance.Address, balance.Amount)
	}

	// Set all the token approvals
	for _, approval := range genState.TokenApprovals {
		k.SetTokenApproval(ctx, approval.TokenId, approval.Owner, approval.Spender, approval.Amount)
	}
}

// ExportGenesis returns the tokens module's exported genesis
func ExportGenesis(ctx sdk.Context, k Keeper) *types.GenesisState {
	genesis := types.DefaultGenesis()
	genesis.Params = k.GetParams(ctx)

	// Get all tokens
	genesis.Tokens = k.GetAllTokens(ctx)

	// Get all token transfers
	genesis.TokenTransfers = k.GetAllTokenTransfers(ctx)

	// Get all token balances
	genesis.TokenBalances = k.GetAllTokenBalances(ctx)

	// Get all token approvals
	genesis.TokenApprovals = k.GetAllTokenApprovals(ctx)

	return genesis
}

// SetParams sets the params in the store
func (k Keeper) SetParams(ctx sdk.Context, params types.Params) {
	store := ctx.KVStore(k.storeKey)
	bz, err := json.Marshal(&params)
	if err != nil {
		return
	}
	store.Set(types.ParamsKey, bz)
}

// GetParams gets the params from the store
func (k Keeper) GetParams(ctx sdk.Context) types.Params {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get(types.ParamsKey)
	if bz == nil {
		return types.DefaultParams()
	}

	var params types.Params
	err := json.Unmarshal(bz, &params)
	if err != nil {
		return types.DefaultParams()
	}
	return params
}

// SetToken sets a token in the store
func (k Keeper) SetToken(ctx sdk.Context, token types.Token) {
	store := ctx.KVStore(k.storeKey)
	bz, err := json.Marshal(&token)
	if err != nil {
		return
	}
	store.Set(types.GetTokenKey(token.Id), bz)
}

// SetTokenTransfer sets a token transfer in the store
func (k Keeper) SetTokenTransfer(ctx sdk.Context, transfer types.TokenTransfer) {
	store := ctx.KVStore(k.storeKey)
	bz, err := json.Marshal(&transfer)
	if err != nil {
		return
	}
	store.Set(types.GetTokenTransferKey(transfer.Id), bz)
}

// SetTokenApproval sets a token approval in the store
func (k Keeper) SetTokenApproval(ctx sdk.Context, tokenId, owner, spender string, amount math.Int) {
	store := ctx.KVStore(k.storeKey)
	approval := types.TokenApproval{
		TokenId: tokenId,
		Owner:   owner,
		Spender: spender,
		Amount:  amount,
	}
	bz, err := json.Marshal(&approval)
	if err != nil {
		return
	}
	store.Set(types.GetTokenApprovalKey(tokenId, owner, spender), bz)
}