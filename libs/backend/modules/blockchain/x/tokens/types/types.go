package types

import (
	"time"

	"cosmossdk.io/math"
)

// GenesisState defines the tokens module's genesis state.
type GenesisState struct {
	Params         Params          `protobuf:"bytes,1,opt,name=params,proto3" json:"params"`
	Tokens         []Token         `protobuf:"bytes,2,rep,name=tokens,proto3" json:"tokens"`
	TokenTransfers []TokenTransfer `protobuf:"bytes,3,rep,name=token_transfers,json=tokenTransfers,proto3" json:"token_transfers"`
	TokenBalances []TokenBalance  `protobuf:"bytes,4,rep,name=token_balances,json=tokenBalances,proto3" json:"token_balances"`
	TokenApprovals []TokenApproval `protobuf:"bytes,5,rep,name=token_approvals,json=tokenApprovals,proto3" json:"token_approvals"`
}

// Token represents a fungible token.
type Token struct {
	Id          string         `protobuf:"bytes,1,opt,name=id,proto3" json:"id,omitempty"`
	Denom       string         `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
	Supply      math.Int       `protobuf:"bytes,3,opt,name=supply,proto3,customtype=cosmossdk.io/math.Int" json:"supply"`
	Creator     string         `protobuf:"bytes,4,opt,name=creator,proto3" json:"creator,omitempty"`
	Mintable    bool           `protobuf:"varint,5,opt,name=mintable,proto3" json:"mintable,omitempty"`
	Burnable    bool           `protobuf:"varint,6,opt,name=burnable,proto3" json:"burnable,omitempty"`
	Description string         `protobuf:"bytes,7,opt,name=description,proto3" json:"description,omitempty"`
	CreatedAt   time.Time      `protobuf:"bytes,8,opt,name=created_at,json=createdAt,proto3" json:"created_at"`
}

// TokenTransfer represents a transfer of tokens.
type TokenTransfer struct {
	Id        string    `protobuf:"bytes,1,opt,name=id,proto3" json:"id,omitempty"`
	TokenId   string    `protobuf:"bytes,2,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Sender    string    `protobuf:"bytes,3,opt,name=sender,proto3" json:"sender,omitempty"`
	Recipient string    `protobuf:"bytes,4,opt,name=recipient,proto3" json:"recipient,omitempty"`
	Amount    math.Int  `protobuf:"bytes,5,opt,name=amount,proto3,customtype=cosmossdk.io/math.Int" json:"amount"`
	Timestamp time.Time `protobuf:"bytes,6,opt,name=timestamp,proto3" json:"timestamp"`
}

// TokenBalance represents the balance of a token for a specific address.
type TokenBalance struct {
	TokenId string  `protobuf:"bytes,1,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Address string  `protobuf:"bytes,2,opt,name=address,proto3" json:"address,omitempty"`
	Amount  math.Int `protobuf:"bytes,3,opt,name=amount,proto3,customtype=cosmossdk.io/math.Int" json:"amount"`
}

// TokenApproval represents an approval for a spender to spend tokens on behalf of an owner.
type TokenApproval struct {
	TokenId string  `protobuf:"bytes,1,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Owner   string  `protobuf:"bytes,2,opt,name=owner,proto3" json:"owner,omitempty"`
	Spender string  `protobuf:"bytes,3,opt,name=spender,proto3" json:"spender,omitempty"`
	Amount  math.Int `protobuf:"bytes,4,opt,name=amount,proto3,customtype=cosmossdk.io/math.Int" json:"amount"`
}

// DefaultGenesis returns the default genesis state
func DefaultGenesis() *GenesisState {
	return &GenesisState{
		Params:         DefaultParams(),
		Tokens:         []Token{},
		TokenTransfers: []TokenTransfer{},
		TokenBalances:  []TokenBalance{},
		TokenApprovals: []TokenApproval{},
	}
}

// Validate validates the genesis state
func (gs GenesisState) Validate() error {
	// TODO: Add validation logic
	return nil
}
