package token

import (
	cosmosbasev1beta1 "github.com/cosmos/cosmos-sdk/types"
	queryv1beta1 "github.com/cosmos/cosmos-sdk/types/query"
	_ "github.com/cosmos/gogoproto/gogoproto"
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
)

// Token represents a token in the system
type Token struct {
	Denom       string `protobuf:"bytes,1,opt,name=denom,proto3" json:"denom,omitempty"`
	Name        string `protobuf:"bytes,2,opt,name=name,proto3" json:"name,omitempty"`
	Symbol      string `protobuf:"bytes,3,opt,name=symbol,proto3" json:"symbol,omitempty"`
	Decimals    uint32 `protobuf:"varint,4,opt,name=decimals,proto3" json:"decimals,omitempty"`
	Description string `protobuf:"bytes,5,opt,name=description,proto3" json:"description,omitempty"`
	Uri         string `protobuf:"bytes,6,opt,name=uri,proto3" json:"uri,omitempty"`
	UriHash     string `protobuf:"bytes,7,opt,name=uri_hash,json=uriHash,proto3" json:"uri_hash,omitempty"`
}

// Params defines the parameters for the token module
type Params struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields
}

func (m *Params) Reset()         { *m = Params{} }
func (m *Params) String() string { return "Params" }
func (*Params) ProtoMessage()    {}
func (m *Params) Validate() error { return nil }

// GenesisState defines the token module's genesis state
type GenesisState struct {
	Params   Params  `protobuf:"bytes,1,opt,name=params,proto3" json:"params,omitempty"`
	TokenMap []Token `protobuf:"bytes,2,rep,name=token_map,json=tokenMap,proto3" json:"token_map,omitempty"`
}

func DefaultGenesis() *GenesisState {
	return &GenesisState{
		Params:   Params{},
		TokenMap: []Token{},
	}
}

func (m *GenesisState) Reset()         { *m = GenesisState{} }
func (m *GenesisState) String() string  { return "GenesisState" }
func (*GenesisState) ProtoMessage()    {}
func (m *GenesisState) Validate() error { return nil }

// Msg types
type MsgCreateToken struct {
	Creator     string `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	Denom       string `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
	Name        string `protobuf:"bytes,3,opt,name=name,proto3" json:"name,omitempty"`
	Symbol      string `protobuf:"bytes,4,opt,name=symbol,proto3" json:"symbol,omitempty"`
	Decimals    uint32 `protobuf:"varint,5,opt,name=decimals,proto3" json:"decimals,omitempty"`
	Description string `protobuf:"bytes,6,opt,name=description,proto3" json:"description,omitempty"`
	Uri         string `protobuf:"bytes,7,opt,name=uri,proto3" json:"uri,omitempty"`
	UriHash     string `protobuf:"bytes,8,opt,name=uri_hash,json=uriHash,proto3" json:"uri_hash,omitempty"`
}

type MsgCreateTokenResponse struct{}

type MsgMint struct {
	Creator   string                `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	Denom     string                `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
	Amount    cosmosbasev1beta1.Coin `protobuf:"bytes,3,opt,name=amount,proto3" json:"amount"`
	Recipient string                `protobuf:"bytes,4,opt,name=recipient,proto3" json:"recipient,omitempty"`
}

type MsgMintResponse struct{}

type MsgBurn struct {
	Creator string                `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	Denom   string                `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
	Amount  cosmosbasev1beta1.Coin `protobuf:"bytes,3,opt,name=amount,proto3" json:"amount"`
}

type MsgBurnResponse struct{}

type MsgTransfer struct {
	Creator string                `protobuf:"bytes,1,opt,name=creator,proto3" json:"creator,omitempty"`
	Denom   string                `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
	Amount  cosmosbasev1beta1.Coin `protobuf:"bytes,3,opt,name=amount,proto3" json:"amount"`
	From    string                `protobuf:"bytes,4,opt,name=from,proto3" json:"from,omitempty"`
	To      string                `protobuf:"bytes,5,opt,name=to,proto3" json:"to,omitempty"`
}

type MsgTransferResponse struct{}

type MsgUpdateParams struct {
	Authority string  `protobuf:"bytes,1,opt,name=authority,proto3" json:"authority,omitempty"`
	Params    *Params `protobuf:"bytes,2,opt,name=params,proto3" json:"params,omitempty"`
}

type MsgUpdateParamsResponse struct{}

// Query types
type QueryParamsRequest struct{}

type QueryParamsResponse struct {
	Params *Params `protobuf:"bytes,1,opt,name=params,proto3" json:"params,omitempty"`
}

type QueryGetTokenRequest struct {
	Denom string `protobuf:"bytes,1,opt,name=denom,proto3" json:"denom,omitempty"`
}

type QueryGetTokenResponse struct {
	Token Token `protobuf:"bytes,1,opt,name=token,proto3" json:"token,omitempty"`
}

type QueryAllTokenRequest struct {
	Pagination *queryv1beta1.PageRequest `protobuf:"bytes,1,opt,name=pagination,proto3" json:"pagination,omitempty"`
}

type QueryAllTokenResponse struct {
	Token      []Token                   `protobuf:"bytes,1,rep,name=token,proto3" json:"token,omitempty"`
	Pagination *queryv1beta1.PageResponse `protobuf:"bytes,2,opt,name=pagination,proto3" json:"pagination,omitempty"`
}

type QueryBalanceRequest struct {
	Address string `protobuf:"bytes,1,opt,name=address,proto3" json:"address,omitempty"`
	Denom   string `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
}

type QueryBalanceResponse struct {
	Balance cosmosbasev1beta1.Coin `protobuf:"bytes,1,opt,name=balance,proto3" json:"balance"`
}

type QueryTokenInfoRequest struct {
	Denom string `protobuf:"bytes,1,opt,name=denom,proto3" json:"denom,omitempty"`
}

type QueryTokenInfoResponse struct{}

type QueryListTokensRequest struct{}

type QueryListTokensResponse struct{}

// Proto methods (stubs)
func (m *Token) Reset()         { *m = Token{} }
func (m *Token) String() string { return "Token" }
func (*Token) ProtoMessage()    {}
func (m *Token) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgCreateToken) Reset()         { *m = MsgCreateToken{} }
func (m *MsgCreateToken) String() string { return "MsgCreateToken" }
func (*MsgCreateToken) ProtoMessage()    {}
func (m *MsgCreateToken) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgCreateTokenResponse) Reset()         { *m = MsgCreateTokenResponse{} }
func (m *MsgCreateTokenResponse) String() string { return "MsgCreateTokenResponse" }
func (*MsgCreateTokenResponse) ProtoMessage()    {}
func (m *MsgCreateTokenResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgMint) Reset()         { *m = MsgMint{} }
func (m *MsgMint) String() string { return "MsgMint" }
func (*MsgMint) ProtoMessage()    {}
func (m *MsgMint) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgMintResponse) Reset()         { *m = MsgMintResponse{} }
func (m *MsgMintResponse) String() string { return "MsgMintResponse" }
func (*MsgMintResponse) ProtoMessage()    {}
func (m *MsgMintResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgBurn) Reset()         { *m = MsgBurn{} }
func (m *MsgBurn) String() string { return "MsgBurn" }
func (*MsgBurn) ProtoMessage()    {}
func (m *MsgBurn) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgBurnResponse) Reset()         { *m = MsgBurnResponse{} }
func (m *MsgBurnResponse) String() string { return "MsgBurnResponse" }
func (*MsgBurnResponse) ProtoMessage()    {}
func (m *MsgBurnResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgTransfer) Reset()         { *m = MsgTransfer{} }
func (m *MsgTransfer) String() string { return "MsgTransfer" }
func (*MsgTransfer) ProtoMessage()    {}
func (m *MsgTransfer) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgTransferResponse) Reset()         { *m = MsgTransferResponse{} }
func (m *MsgTransferResponse) String() string { return "MsgTransferResponse" }
func (*MsgTransferResponse) ProtoMessage()    {}
func (m *MsgTransferResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgUpdateParams) Reset()         { *m = MsgUpdateParams{} }
func (m *MsgUpdateParams) String() string { return "MsgUpdateParams" }
func (*MsgUpdateParams) ProtoMessage()    {}
func (m *MsgUpdateParams) ProtoReflect() protoreflect.Message { return nil }

func (m *MsgUpdateParamsResponse) Reset()         { *m = MsgUpdateParamsResponse{} }
func (m *MsgUpdateParamsResponse) String() string { return "MsgUpdateParamsResponse" }
func (*MsgUpdateParamsResponse) ProtoMessage()    {}
func (m *MsgUpdateParamsResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryParamsRequest) Reset()         { *m = QueryParamsRequest{} }
func (m *QueryParamsRequest) String() string { return "QueryParamsRequest" }
func (*QueryParamsRequest) ProtoMessage()    {}
func (m *QueryParamsRequest) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryParamsResponse) Reset()         { *m = QueryParamsResponse{} }
func (m *QueryParamsResponse) String() string { return "QueryParamsResponse" }
func (*QueryParamsResponse) ProtoMessage()    {}
func (m *QueryParamsResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryGetTokenRequest) Reset()         { *m = QueryGetTokenRequest{} }
func (m *QueryGetTokenRequest) String() string { return "QueryGetTokenRequest" }
func (*QueryGetTokenRequest) ProtoMessage()    {}
func (m *QueryGetTokenRequest) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryGetTokenResponse) Reset()         { *m = QueryGetTokenResponse{} }
func (m *QueryGetTokenResponse) String() string { return "QueryGetTokenResponse" }
func (*QueryGetTokenResponse) ProtoMessage()    {}
func (m *QueryGetTokenResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryAllTokenRequest) Reset()         { *m = QueryAllTokenRequest{} }
func (m *QueryAllTokenRequest) String() string { return "QueryAllTokenRequest" }
func (*QueryAllTokenRequest) ProtoMessage()    {}
func (m *QueryAllTokenRequest) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryAllTokenResponse) Reset()         { *m = QueryAllTokenResponse{} }
func (m *QueryAllTokenResponse) String() string { return "QueryAllTokenResponse" }
func (*QueryAllTokenResponse) ProtoMessage()    {}
func (m *QueryAllTokenResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryBalanceRequest) Reset()         { *m = QueryBalanceRequest{} }
func (m *QueryBalanceRequest) String() string { return "QueryBalanceRequest" }
func (*QueryBalanceRequest) ProtoMessage()    {}
func (m *QueryBalanceRequest) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryBalanceResponse) Reset()         { *m = QueryBalanceResponse{} }
func (m *QueryBalanceResponse) String() string { return "QueryBalanceResponse" }
func (*QueryBalanceResponse) ProtoMessage()    {}
func (m *QueryBalanceResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryTokenInfoRequest) Reset()         { *m = QueryTokenInfoRequest{} }
func (m *QueryTokenInfoRequest) String() string { return "QueryTokenInfoRequest" }
func (*QueryTokenInfoRequest) ProtoMessage()    {}
func (m *QueryTokenInfoRequest) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryTokenInfoResponse) Reset()         { *m = QueryTokenInfoResponse{} }
func (m *QueryTokenInfoResponse) String() string { return "QueryTokenInfoResponse" }
func (*QueryTokenInfoResponse) ProtoMessage()    {}
func (m *QueryTokenInfoResponse) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryListTokensRequest) Reset()         { *m = QueryListTokensRequest{} }
func (m *QueryListTokensRequest) String() string { return "QueryListTokensRequest" }
func (*QueryListTokensRequest) ProtoMessage()    {}
func (m *QueryListTokensRequest) ProtoReflect() protoreflect.Message { return nil }

func (m *QueryListTokensResponse) Reset()         { *m = QueryListTokensResponse{} }
func (m *QueryListTokensResponse) String() string { return "QueryListTokensResponse" }
func (*QueryListTokensResponse) ProtoMessage()    {}
func (m *QueryListTokensResponse) ProtoReflect() protoreflect.Message { return nil }
