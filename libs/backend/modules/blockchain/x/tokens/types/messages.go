package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"cosmossdk.io/math"
)

// MsgCreateToken represents a message to create a new token
type MsgCreateToken struct {
	Creator     string `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	Id          string `protobuf:"bytes,2,opt,name=id,proto3" json:"id,omitempty"`
	Denom       string `protobuf:"bytes,3,opt,name=denom,proto3" json:"denom,omitempty"`
	Supply      math.Int `protobuf:"bytes,4,opt,name=supply,proto3,customtype=cosmossdk.io/math.Int" json:"supply"`
	Mintable    bool   `protobuf:"varint,5,opt,name=mintable,proto3" json:"mintable,omitempty"`
	Burnable    bool   `protobuf:"varint,6,opt,name=burnable,proto3" json:"burnable,omitempty"`
	Description string `protobuf:"bytes,7,opt,name=description,proto3" json:"description,omitempty"`
}

// MsgCreateTokenResponse represents the response to creating a token
type MsgCreateTokenResponse struct {
	Id string `protobuf:"bytes,1,opt,name=id,proto3" json:"id,omitempty"`
}

// MsgUpdateToken represents a message to update an existing token
type MsgUpdateToken struct {
	Creator     string `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	Id          string `protobuf:"bytes,2,opt,name=id,proto3" json:"id,omitempty"`
	Denom       string `protobuf:"bytes,3,opt,name=denom,proto3" json:"denom,omitempty"`
	Supply      math.Int `protobuf:"bytes,4,opt,name=supply,proto3,customtype=cosmossdk.io/math.Int" json:"supply"`
	Mintable    bool   `protobuf:"varint,5,opt,name=mintable,proto3" json:"mintable,omitempty"`
	Burnable    bool   `protobuf:"varint,6,opt,name=burnable,proto3" json:"burnable,omitempty"`
	Description string `protobuf:"bytes,7,opt,name=description,proto3" json:"description,omitempty"`
}

// MsgUpdateTokenResponse represents the response to updating a token
type MsgUpdateTokenResponse struct{}

// MsgDeleteToken represents a message to delete a token
type MsgDeleteToken struct {
	Creator string `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	Id      string `protobuf:"bytes,2,opt,name=id,proto3" json:"id,omitempty"`
}

// MsgDeleteTokenResponse represents the response to deleting a token
type MsgDeleteTokenResponse struct{}

// MsgTransferToken represents a message to transfer tokens
type MsgTransferToken struct {
	Creator   string  `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	TokenId   string  `protobuf:"bytes,2,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Recipient string  `protobuf:"bytes,3,opt,name=recipient,proto3" json:"recipient,omitempty"`
	Amount    math.Int `protobuf:"bytes,4,opt,name=amount,proto3,customtype=cosmossdk.io/math.Int" json:"amount"`
}

// MsgTransferTokenResponse represents the response to transferring tokens
type MsgTransferTokenResponse struct{}

// MsgApproveToken represents a message to approve token spending
type MsgApproveToken struct {
	Owner   string  `protobuf:"bytes,1,opt,name=owner,proto3" json:"owner,omitempty"`
	Spender string  `protobuf:"bytes,2,opt,name=spender,proto3" json:"spender,omitempty"`
	TokenId string  `protobuf:"bytes,3,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Amount  math.Int `protobuf:"bytes,4,opt,name=amount,proto3,customtype=cosmossdk.io/math.Int" json:"amount"`
}

// MsgApproveTokenResponse represents the response to approving token spending
type MsgApproveTokenResponse struct{}

// GetSigners returns the signers for the message
func (m *MsgCreateToken) GetSigners() []sdk.AccAddress {
	creator, err := sdk.AccAddressFromBech32(m.Creator)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{creator}
}

// GetSigners returns the signers for the message
func (m *MsgUpdateToken) GetSigners() []sdk.AccAddress {
	creator, err := sdk.AccAddressFromBech32(m.Creator)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{creator}
}

// GetSigners returns the signers for the message
func (m *MsgDeleteToken) GetSigners() []sdk.AccAddress {
	creator, err := sdk.AccAddressFromBech32(m.Creator)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{creator}
}

// GetSigners returns the signers for the message
func (m *MsgTransferToken) GetSigners() []sdk.AccAddress {
	creator, err := sdk.AccAddressFromBech32(m.Creator)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{creator}
}

// GetSigners returns the signers for the message
func (m *MsgApproveToken) GetSigners() []sdk.AccAddress {
	owner, err := sdk.AccAddressFromBech32(m.Owner)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{owner}
}

// MsgMintToken represents a message to mint new tokens
type MsgMintToken struct {
	Creator string  `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	TokenId string  `protobuf:"bytes,2,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Amount  math.Int `protobuf:"bytes,3,opt,name=amount,proto3,customtype=cosmossdk.io/math.Int" json:"amount"`
}

// MsgMintTokenResponse represents the response to minting tokens
type MsgMintTokenResponse struct{}

// MsgBurnToken represents a message to burn tokens
type MsgBurnToken struct {
	Creator string  `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	TokenId string  `protobuf:"bytes,2,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Amount  math.Int `protobuf:"bytes,3,opt,name=amount,proto3,customtype=cosmossdk.io/math.Int" json:"amount"`
}

// MsgBurnTokenResponse represents the response to burning tokens
type MsgBurnTokenResponse struct{}

// GetSigners returns the signers for the message
func (m *MsgMintToken) GetSigners() []sdk.AccAddress {
	creator, err := sdk.AccAddressFromBech32(m.Creator)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{creator}
}

// GetSigners returns the signers for the message
func (m *MsgBurnToken) GetSigners() []sdk.AccAddress {
	creator, err := sdk.AccAddressFromBech32(m.Creator)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{creator}
}

// MsgTransferFromToken represents a message to transfer tokens from an approval
type MsgTransferFromToken struct {
	Owner   string  `protobuf:"bytes,1,opt,name=owner,proto3" json:"owner,omitempty"`
	Spender string  `protobuf:"bytes,2,opt,name=spender,proto3" json:"spender,omitempty"`
	TokenId string  `protobuf:"bytes,3,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Amount  math.Int `protobuf:"bytes,4,opt,name=amount,proto3,customtype=cosmossdk.io/math.Int" json:"amount"`
}

// MsgTransferFromTokenResponse represents the response to transferring tokens from an approval
type MsgTransferFromTokenResponse struct{}

// GetSigners returns the signers for the message
func (m *MsgTransferFromToken) GetSigners() []sdk.AccAddress {
	spender, err := sdk.AccAddressFromBech32(m.Spender)
	if err != nil {
		panic(err)
	}
	return []sdk.AccAddress{spender}
}
