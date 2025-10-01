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
	ParamsKey = []byte("p_tokens")
)

func KeyPrefix(p string) []byte {
	return []byte(p)
}

// TokenKey returns the store key to retrieve a Token from the index fields
func TokenKey(
	tokenId string,
) []byte {
	var key []byte

	tokenIdBytes := []byte(tokenId)
	key = append(key, tokenIdBytes...)
	key = append(key, []byte("/")...)

	return key
}

// TokenTransferKey returns the store key to retrieve a TokenTransfer from the index fields
func TokenTransferKey(
	transferId string,
) []byte {
	var key []byte

	transferIdBytes := []byte(transferId)
	key = append(key, transferIdBytes...)
	key = append(key, []byte("/")...)

	return key
}

// TokenBalanceKey returns the store key to retrieve a TokenBalance from the index fields
func TokenBalanceKey(
	address string,
	tokenId string,
) []byte {
	var key []byte

	addressBytes := []byte(address)
	key = append(key, addressBytes...)
	key = append(key, []byte("/")...)

	tokenIdBytes := []byte(tokenId)
	key = append(key, tokenIdBytes...)
	key = append(key, []byte("/")...)

	return key
}

// TokenApprovalKey returns the store key to retrieve a TokenApproval from the index fields
func TokenApprovalKey(
	owner string,
	spender string,
	tokenId string,
) []byte {
	var key []byte

	ownerBytes := []byte(owner)
	key = append(key, ownerBytes...)
	key = append(key, []byte("/")...)

	spenderBytes := []byte(spender)
	key = append(key, spenderBytes...)
	key = append(key, []byte("/")...)

	tokenIdBytes := []byte(tokenId)
	key = append(key, tokenIdBytes...)
	key = append(key, []byte("/")...)

	return key
}
