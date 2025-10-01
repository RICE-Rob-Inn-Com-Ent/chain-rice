package keeper

import (
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/rice-dev/backend/blockchain/x/tokens/types"
)

// InitGenesis initializes the capability module's state from a provided genesis
// state.
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
		k.SetTokenBalance(ctx, balance)
	}

	// Set all the token approvals
	for _, approval := range genState.TokenApprovals {
		k.SetTokenApproval(ctx, approval)
	}
}

// ExportGenesis returns the capability module's exported genesis.
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
	bz := k.cdc.MustMarshal(&params)
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
	k.cdc.MustUnmarshal(bz, &params)
	return params
}

// SetToken sets a token in the store
func (k Keeper) SetToken(ctx sdk.Context, token types.Token) {
	store := ctx.KVStore(k.storeKey)
	bz := k.cdc.MustMarshal(&token)
	store.Set(types.TokenKey(token.Id), bz)
}

// GetToken gets a token from the store
func (k Keeper) GetToken(ctx sdk.Context, tokenId string) (types.Token, bool) {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get(types.TokenKey(tokenId))
	if bz == nil {
		return types.Token{}, false
	}

	var token types.Token
	k.cdc.MustUnmarshal(bz, &token)
	return token, true
}

// GetAllTokens gets all tokens from the store
func (k Keeper) GetAllTokens(ctx sdk.Context) []types.Token {
	store := ctx.KVStore(k.storeKey)
	iterator := sdk.KVStorePrefixIterator(store, []byte("token/"))
	defer iterator.Close()

	var tokens []types.Token
	for ; iterator.Valid(); iterator.Next() {
		var token types.Token
		k.cdc.MustUnmarshal(iterator.Value(), &token)
		tokens = append(tokens, token)
	}

	return tokens
}

// SetTokenTransfer sets a token transfer in the store
func (k Keeper) SetTokenTransfer(ctx sdk.Context, transfer types.TokenTransfer) {
	store := ctx.KVStore(k.storeKey)
	bz := k.cdc.MustMarshal(&transfer)
	store.Set(types.TokenTransferKey(transfer.Id), bz)
}

// GetTokenTransfer gets a token transfer from the store
func (k Keeper) GetTokenTransfer(ctx sdk.Context, transferId string) (types.TokenTransfer, bool) {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get(types.TokenTransferKey(transferId))
	if bz == nil {
		return types.TokenTransfer{}, false
	}

	var transfer types.TokenTransfer
	k.cdc.MustUnmarshal(bz, &transfer)
	return transfer, true
}

// GetAllTokenTransfers gets all token transfers from the store
func (k Keeper) GetAllTokenTransfers(ctx sdk.Context) []types.TokenTransfer {
	store := ctx.KVStore(k.storeKey)
	iterator := sdk.KVStorePrefixIterator(store, []byte("transfer/"))
	defer iterator.Close()

	var transfers []types.TokenTransfer
	for ; iterator.Valid(); iterator.Next() {
		var transfer types.TokenTransfer
		k.cdc.MustUnmarshal(iterator.Value(), &transfer)
		transfers = append(transfers, transfer)
	}

	return transfers
}

// SetTokenBalance sets a token balance in the store
func (k Keeper) SetTokenBalance(ctx sdk.Context, balance types.TokenBalance) {
	store := ctx.KVStore(k.storeKey)
	bz := k.cdc.MustMarshal(&balance)
	store.Set(types.TokenBalanceKey(balance.Address, balance.TokenId), bz)
}

// GetTokenBalance gets a token balance from the store
func (k Keeper) GetTokenBalance(ctx sdk.Context, address, tokenId string) (types.TokenBalance, bool) {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get(types.TokenBalanceKey(address, tokenId))
	if bz == nil {
		return types.TokenBalance{}, false
	}

	var balance types.TokenBalance
	k.cdc.MustUnmarshal(bz, &balance)
	return balance, true
}

// GetAllTokenBalances gets all token balances from the store
func (k Keeper) GetAllTokenBalances(ctx sdk.Context) []types.TokenBalance {
	store := ctx.KVStore(k.storeKey)
	iterator := sdk.KVStorePrefixIterator(store, []byte("balance/"))
	defer iterator.Close()

	var balances []types.TokenBalance
	for ; iterator.Valid(); iterator.Next() {
		var balance types.TokenBalance
		k.cdc.MustUnmarshal(iterator.Value(), &balance)
		balances = append(balances, balance)
	}

	return balances
}

// SetTokenApproval sets a token approval in the store
func (k Keeper) SetTokenApproval(ctx sdk.Context, approval types.TokenApproval) {
	store := ctx.KVStore(k.storeKey)
	bz := k.cdc.MustMarshal(&approval)
	store.Set(types.TokenApprovalKey(approval.Owner, approval.Spender, approval.TokenId), bz)
}

// GetTokenApproval gets a token approval from the store
func (k Keeper) GetTokenApproval(ctx sdk.Context, owner, spender, tokenId string) (types.TokenApproval, bool) {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get(types.TokenApprovalKey(owner, spender, tokenId))
	if bz == nil {
		return types.TokenApproval{}, false
	}

	var approval types.TokenApproval
	k.cdc.MustUnmarshal(bz, &approval)
	return approval, true
}

// GetAllTokenApprovals gets all token approvals from the store
func (k Keeper) GetAllTokenApprovals(ctx sdk.Context) []types.TokenApproval {
	store := ctx.KVStore(k.storeKey)
	iterator := sdk.KVStorePrefixIterator(store, []byte("approval/"))
	defer iterator.Close()

	var approvals []types.TokenApproval
	for ; iterator.Valid(); iterator.Next() {
		var approval types.TokenApproval
		k.cdc.MustUnmarshal(iterator.Value(), &approval)
		approvals = append(approvals, approval)
	}

	return approvals
}
