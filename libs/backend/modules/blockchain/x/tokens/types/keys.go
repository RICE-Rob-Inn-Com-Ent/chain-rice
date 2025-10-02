package types

const (
	// ModuleName defines the module name
	ModuleName = "tokens"

	// StoreKey defines the primary module store key
	StoreKey = ModuleName

	// RouterKey is the message route for slashing
	RouterKey = ModuleName

	// QuerierRoute defines the module's query routing key
	QuerierRoute = ModuleName

	// MemStoreKey defines the in-memory store key
	MemStoreKey = "mem_tokens"
)

var (
	ParamsKey               = []byte("p_tokens")
	TokenKeyPrefix          = []byte("token/")
	TokenTransferKeyPrefix  = []byte("transfer/")
	TokenBalanceKeyPrefix   = []byte("balance/")
	TokenApprovalKeyPrefix  = []byte("approval/")
	TokenCountKey           = []byte("token_count")
)

func KeyPrefix(p string) []byte {
	return []byte(p)
}

// GetTokenKey returns the store key to retrieve a Token from the index fields
func GetTokenKey(id string) []byte {
	return append(TokenKeyPrefix, []byte(id)...)
}

// GetTokenTransferKey returns the store key to retrieve a TokenTransfer from the index fields
func GetTokenTransferKey(id string) []byte {
	return append(TokenTransferKeyPrefix, []byte(id)...)
}

// GetTokenBalanceKey returns the store key to retrieve a TokenBalance from the index fields
func GetTokenBalanceKey(tokenId, address string) []byte {
	return append(append(TokenBalanceKeyPrefix, []byte(tokenId)...), []byte(address)...)
}

// GetTokenApprovalKey returns the store key to retrieve a TokenApproval from the index fields
func GetTokenApprovalKey(tokenId, owner, spender string) []byte {
	return append(append(append(TokenApprovalKeyPrefix, []byte(tokenId)...), []byte(owner)...), []byte(spender)...)
}
