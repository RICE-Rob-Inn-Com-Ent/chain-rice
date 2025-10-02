package keeper

import (
	"encoding/json"
	"fmt"

	"github.com/cosmos/cosmos-sdk/codec"
	storetypes "cosmossdk.io/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"cosmossdk.io/math"
	"cosmossdk.io/log"

	"github.com/rice-dev/backend/blockchain/x/tokens/types"
)

type (
	Keeper struct {
		cdc      codec.BinaryCodec
		storeKey storetypes.StoreKey
		memKey   storetypes.StoreKey

		// the address capable of executing a MsgUpdateParams message. Typically, this
		// should be the x/gov module account.
		authority string

		// other keepers
		accountKeeper types.AccountKeeper
		bankKeeper    types.BankKeeper
	}
)

func NewKeeper(
	cdc codec.BinaryCodec,
	storeKey,
	memKey storetypes.StoreKey,
	authority string,

	// other keepers
	accountKeeper types.AccountKeeper,
	bankKeeper types.BankKeeper,
) *Keeper {
	return &Keeper{
		cdc:      cdc,
		storeKey: storeKey,
		memKey:   memKey,

		authority: authority,

		// other keepers
		accountKeeper: accountKeeper,
		bankKeeper:    bankKeeper,
	}
}

// GetAuthority returns the module's authority.
func (k Keeper) GetAuthority() string {
	return k.authority
}

// Logger returns a module-specific logger.
func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", "x/"+types.ModuleName)
}

// CreateToken creates a new token
func (k Keeper) CreateToken(ctx sdk.Context, token types.Token) error {
	store := ctx.KVStore(k.storeKey)
	
	// Check if token already exists
	if store.Has(types.GetTokenKey(token.Id)) {
		return types.ErrTokenAlreadyExists
	}
	
	// Set token in store
	tokenBytes, err := json.Marshal(&token)
	if err != nil {
		return err
	}
	store.Set(types.GetTokenKey(token.Id), tokenBytes)
	
	// Update token count
	count := k.GetTokenCount(ctx)
	count++
	k.SetTokenCount(ctx, count)
	
	return nil
}

// GetToken retrieves a token by ID
func (k Keeper) GetToken(ctx sdk.Context, id string) (types.Token, bool) {
	store := ctx.KVStore(k.storeKey)
	
	tokenBytes := store.Get(types.GetTokenKey(id))
	if tokenBytes == nil {
		return types.Token{}, false
	}
	
	var token types.Token
	err := json.Unmarshal(tokenBytes, &token)
	if err != nil {
		return types.Token{}, false
	}
	return token, true
}

// GetAllTokens returns all tokens
func (k Keeper) GetAllTokens(ctx sdk.Context) []types.Token {
	store := ctx.KVStore(k.storeKey)
	iterator := store.Iterator(types.TokenKeyPrefix, storetypes.PrefixEndBytes(types.TokenKeyPrefix))
	defer iterator.Close()
	
	var tokens []types.Token
	for ; iterator.Valid(); iterator.Next() {
		var token types.Token
		err := json.Unmarshal(iterator.Value(), &token)
		if err != nil {
			continue
		}
		tokens = append(tokens, token)
	}
	
	return tokens
}

// UpdateToken updates an existing token
func (k Keeper) UpdateToken(ctx sdk.Context, token types.Token) error {
	store := ctx.KVStore(k.storeKey)
	
	// Check if token exists
	if !store.Has(types.GetTokenKey(token.Id)) {
		return types.ErrTokenNotFound
	}
	
	// Update token in store
	tokenBytes, err := json.Marshal(&token)
	if err != nil {
		return err
	}
	store.Set(types.GetTokenKey(token.Id), tokenBytes)
	
	return nil
}

// DeleteToken deletes a token
func (k Keeper) DeleteToken(ctx sdk.Context, id string) error {
	store := ctx.KVStore(k.storeKey)
	
	// Check if token exists
	if !store.Has(types.GetTokenKey(id)) {
		return types.ErrTokenNotFound
	}
	
	// Delete token from store
	store.Delete(types.GetTokenKey(id))
	
	// Update token count
	count := k.GetTokenCount(ctx)
	if count > 0 {
		count--
		k.SetTokenCount(ctx, count)
	}
	
	return nil
}

// GetTokenCount returns the current token count
func (k Keeper) GetTokenCount(ctx sdk.Context) uint64 {
	store := ctx.KVStore(k.storeKey)
	
	countBytes := store.Get(types.TokenCountKey)
	if countBytes == nil {
		return 0
	}
	
	return sdk.BigEndianToUint64(countBytes)
}

// SetTokenCount sets the token count
func (k Keeper) SetTokenCount(ctx sdk.Context, count uint64) {
	store := ctx.KVStore(k.storeKey)
	
	countBytes := sdk.Uint64ToBigEndian(count)
	store.Set(types.TokenCountKey, countBytes)
}

// TransferToken transfers tokens from one address to another
func (k Keeper) TransferToken(ctx sdk.Context, tokenId, from, to string, amount math.Int) error {
	// Check if token exists
	_, exists := k.GetToken(ctx, tokenId)
	if !exists {
		return types.ErrTokenNotFound
	}
	
	// Get sender balance
	senderBalance := k.GetTokenBalance(ctx, tokenId, from)
	if senderBalance.LT(amount) {
		return types.ErrInsufficientBalance
	}
	
	// Update sender balance
	newSenderBalance := senderBalance.Sub(amount)
	k.SetTokenBalance(ctx, tokenId, from, newSenderBalance)
	
	// Update recipient balance
	recipientBalance := k.GetTokenBalance(ctx, tokenId, to)
	newRecipientBalance := recipientBalance.Add(amount)
	k.SetTokenBalance(ctx, tokenId, to, newRecipientBalance)
	
	// Create transfer record
	transfer := types.TokenTransfer{
		Id:        fmt.Sprintf("%s-%d", tokenId, ctx.BlockHeight()),
		TokenId:   tokenId,
		Sender:    from,
		Recipient: to,
		Amount:    amount,
		Timestamp: ctx.BlockTime(),
	}
	
	// Store transfer record
	store := ctx.KVStore(k.storeKey)
	transferBytes, err := json.Marshal(&transfer)
	if err != nil {
		return err
	}
	store.Set(types.GetTokenTransferKey(transfer.Id), transferBytes)
	
	return nil
}

// GetTokenBalance returns the balance of a token for a specific address
func (k Keeper) GetTokenBalance(ctx sdk.Context, tokenId, address string) math.Int {
	store := ctx.KVStore(k.storeKey)
	
	balanceBytes := store.Get(types.GetTokenBalanceKey(tokenId, address))
	if balanceBytes == nil {
		return math.ZeroInt()
	}
	
	var balance math.Int
	err := json.Unmarshal(balanceBytes, &balance)
	if err != nil {
		return math.ZeroInt()
	}
	return balance
}

// SetTokenBalance sets the balance of a token for a specific address
func (k Keeper) SetTokenBalance(ctx sdk.Context, tokenId, address string, balance math.Int) {
	store := ctx.KVStore(k.storeKey)
	
	balanceBytes, err := json.Marshal(&balance)
	if err != nil {
		return
	}
	store.Set(types.GetTokenBalanceKey(tokenId, address), balanceBytes)
}

// GetAllTokenBalances returns all token balances
func (k Keeper) GetAllTokenBalances(ctx sdk.Context) []types.TokenBalance {
	store := ctx.KVStore(k.storeKey)
	iterator := store.Iterator(types.TokenBalanceKeyPrefix, storetypes.PrefixEndBytes(types.TokenBalanceKeyPrefix))
	defer iterator.Close()
	
	var balances []types.TokenBalance
	for ; iterator.Valid(); iterator.Next() {
		var balance math.Int
		err := json.Unmarshal(iterator.Value(), &balance)
		if err != nil {
			continue
		}
		
		// Parse key to extract token ID and address
		key := iterator.Key()
		tokenId := string(key[1:]) // Skip prefix byte
		address := string(key[1+len(tokenId):])
		
		balances = append(balances, types.TokenBalance{
			TokenId: tokenId,
			Address: address,
			Amount:  balance,
		})
	}
	
	return balances
}

// ApproveTokenApproval approves a spender to spend tokens on behalf of an owner
func (k Keeper) ApproveTokenApproval(ctx sdk.Context, tokenId, owner, spender string, amount math.Int) error {
	// Check if token exists
	_, exists := k.GetToken(ctx, tokenId)
	if !exists {
		return types.ErrTokenNotFound
	}
	
	// Create approval
	approval := types.TokenApproval{
		TokenId: tokenId,
		Owner:   owner,
		Spender: spender,
		Amount:  amount,
	}
	
	// Store approval
	store := ctx.KVStore(k.storeKey)
	approvalBytes, err := json.Marshal(&approval)
	if err != nil {
		return err
	}
	store.Set(types.GetTokenApprovalKey(tokenId, owner, spender), approvalBytes)
	
	return nil
}

// GetTokenApproval returns the approval amount for a spender
func (k Keeper) GetTokenApproval(ctx sdk.Context, tokenId, owner, spender string) math.Int {
	store := ctx.KVStore(k.storeKey)
	
	approvalBytes := store.Get(types.GetTokenApprovalKey(tokenId, owner, spender))
	if approvalBytes == nil {
		return math.ZeroInt()
	}
	
	var approval types.TokenApproval
	err := json.Unmarshal(approvalBytes, &approval)
	if err != nil {
		return math.ZeroInt()
	}
	return approval.Amount
}

// GetAllTokenApprovals returns all token approvals
func (k Keeper) GetAllTokenApprovals(ctx sdk.Context) []types.TokenApproval {
	store := ctx.KVStore(k.storeKey)
	iterator := store.Iterator(types.TokenApprovalKeyPrefix, storetypes.PrefixEndBytes(types.TokenApprovalKeyPrefix))
	defer iterator.Close()
	
	var approvals []types.TokenApproval
	for ; iterator.Valid(); iterator.Next() {
		var approval types.TokenApproval
		err := json.Unmarshal(iterator.Value(), &approval)
		if err != nil {
			continue
		}
		approvals = append(approvals, approval)
	}
	
	return approvals
}

// SpendFromApproval spends tokens from an approval
func (k Keeper) SpendFromApproval(ctx sdk.Context, tokenId, owner, spender string, amount math.Int) error {
	// Check approval amount
	approvalAmount := k.GetTokenApproval(ctx, tokenId, owner, spender)
	if approvalAmount.LT(amount) {
		return types.ErrInsufficientApproval
	}
	
	// Transfer tokens
	err := k.TransferToken(ctx, tokenId, owner, spender, amount)
	if err != nil {
		return err
	}
	
	// Update approval amount
	newApprovalAmount := approvalAmount.Sub(amount)
	if newApprovalAmount.IsZero() {
		// Remove approval if amount is zero
		store := ctx.KVStore(k.storeKey)
		store.Delete(types.GetTokenApprovalKey(tokenId, owner, spender))
	} else {
		// Update approval
		k.ApproveTokenApproval(ctx, tokenId, owner, spender, newApprovalAmount)
	}
	
	return nil
}

// GetAllTokenTransfers returns all token transfers
func (k Keeper) GetAllTokenTransfers(ctx sdk.Context) []types.TokenTransfer {
	store := ctx.KVStore(k.storeKey)
	iterator := store.Iterator(types.TokenTransferKeyPrefix, storetypes.PrefixEndBytes(types.TokenTransferKeyPrefix))
	defer iterator.Close()
	
	var transfers []types.TokenTransfer
	for ; iterator.Valid(); iterator.Next() {
		var transfer types.TokenTransfer
		err := json.Unmarshal(iterator.Value(), &transfer)
		if err != nil {
			continue
		}
		transfers = append(transfers, transfer)
	}
	
	return transfers
}
