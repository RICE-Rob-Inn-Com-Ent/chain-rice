package types

// GetTokenRequest represents a request to get a token by ID
type GetTokenRequest struct {
	Id string `protobuf:"bytes,1,opt,name=id,proto3" json:"id,omitempty"`
}

// GetTokenResponse represents the response to getting a token
type GetTokenResponse struct {
	Token *Token `protobuf:"bytes,1,opt,name=token,proto3" json:"token,omitempty"`
}

// GetAllTokensRequest represents a request to get all tokens
type GetAllTokensRequest struct{}

// GetAllTokensResponse represents the response to getting all tokens
type GetAllTokensResponse struct {
	Tokens     []Token      `protobuf:"bytes,1,rep,name=tokens,proto3" json:"tokens"`
	Pagination *PageResponse `protobuf:"bytes,2,opt,name=pagination,proto3" json:"pagination,omitempty"`
}

// GetTokenBalanceRequest represents a request to get a token balance
type GetTokenBalanceRequest struct {
	TokenId string `protobuf:"bytes,1,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Address string `protobuf:"bytes,2,opt,name=address,proto3" json:"address,omitempty"`
}

// GetTokenBalanceResponse represents the response to getting a token balance
type GetTokenBalanceResponse struct {
	Balance *TokenBalance `protobuf:"bytes,1,opt,name=balance,proto3" json:"balance,omitempty"`
}

// GetAllTokenBalancesRequest represents a request to get all token balances
type GetAllTokenBalancesRequest struct{}

// GetAllTokenBalancesResponse represents the response to getting all token balances
type GetAllTokenBalancesResponse struct {
	Balances   []TokenBalance `protobuf:"bytes,1,rep,name=balances,proto3" json:"balances"`
	Pagination *PageResponse  `protobuf:"bytes,2,opt,name=pagination,proto3" json:"pagination,omitempty"`
}

// GetTokenApprovalRequest represents a request to get a token approval
type GetTokenApprovalRequest struct {
	TokenId string `protobuf:"bytes,1,opt,name=token_id,json=tokenId,proto3" json:"token_id,omitempty"`
	Owner   string `protobuf:"bytes,2,opt,name=owner,proto3" json:"owner,omitempty"`
	Spender string `protobuf:"bytes,3,opt,name=spender,proto3" json:"spender,omitempty"`
}

// GetTokenApprovalResponse represents the response to getting a token approval
type GetTokenApprovalResponse struct {
	Approval *TokenApproval `protobuf:"bytes,1,opt,name=approval,proto3" json:"approval,omitempty"`
}

// GetAllTokenApprovalsRequest represents a request to get all token approvals
type GetAllTokenApprovalsRequest struct{}

// GetAllTokenApprovalsResponse represents the response to getting all token approvals
type GetAllTokenApprovalsResponse struct {
	Approvals  []TokenApproval `protobuf:"bytes,1,rep,name=approvals,proto3" json:"approvals"`
	Pagination *PageResponse   `protobuf:"bytes,2,opt,name=pagination,proto3" json:"pagination,omitempty"`
}

// PageResponse represents pagination information
type PageResponse struct {
	Total uint64 `protobuf:"varint,1,opt,name=total,proto3" json:"total,omitempty"`
}

