package token

import (
	storetypes "cosmossdk.io/store/types"
)

// KV store keys for the token module and related persistence (IAVL commit multistore keys).
var (
	StoreKeyToken = storetypes.NewKVStoreKey("token")
	// MemStoreKeyToken optional in-memory store for transient state (e.g. iterators).
	MemStoreKeyToken = storetypes.NewMemoryStoreKey("mem_token")
)

// StoreKeys returns all KV keys registered with BaseApp for the token app slice.
func StoreKeys() map[string]*storetypes.KVStoreKey {
	return map[string]*storetypes.KVStoreKey{
		"token": StoreKeyToken,
	}
}
