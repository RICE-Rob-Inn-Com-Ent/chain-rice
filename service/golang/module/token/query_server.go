package token

import (
	"context"
	"errors"

	"cosmossdk.io/collections"
	"cosmossdk.io/math"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/query"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/chainrice/rice/backend/app/token"
)

type tokenQueryServer struct {
	k TokenKeeper
}

var _ token.QueryServer = tokenQueryServer{}

// TokenNewQueryServerImpl returns an implementation of the QueryServer interface
func TokenNewQueryServerImpl(k TokenKeeper) token.QueryServer {
	return tokenQueryServer{k}
}

// Balance handles Balance query
func (q tokenQueryServer) Balance(ctx context.Context, req *token.QueryBalanceRequest) (*token.QueryBalanceResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	if req.Address == "" {
		return nil, status.Error(codes.InvalidArgument, "address is required")
	}
	if req.Denom == "" {
		return nil, status.Error(codes.InvalidArgument, "denom is required")
	}

	// Validate token exists
	_, err := q.k.Token.Get(ctx, req.Denom)
	if err != nil {
		if errors.Is(err, collections.ErrNotFound) {
			return nil, status.Error(codes.NotFound, "token not found")
		}
		return nil, status.Error(codes.Internal, "failed to get token")
	}

	// In a full implementation, this would query the bank module for balance
	// For now, return zero balance
	zeroBalance := sdk.NewCoin(req.Denom, math.ZeroInt())

	return &token.QueryBalanceResponse{
		Balance: zeroBalance,
	}, nil
}

// TokenInfo handles TokenInfo query
func (q tokenQueryServer) TokenInfo(ctx context.Context, req *token.QueryTokenInfoRequest) (*token.QueryTokenInfoResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	if req.Denom == "" {
		return nil, status.Error(codes.InvalidArgument, "denom is required")
	}

	// Get token
	_, err := q.k.Token.Get(ctx, req.Denom)
	if err != nil {
		if errors.Is(err, collections.ErrNotFound) {
			return nil, status.Error(codes.NotFound, "token not found")
		}
		return nil, status.Error(codes.Internal, "failed to get token")
	}

	// Return token info (QueryTokenInfoResponse would need to be defined in types)
	// For now, return empty response as the type is not fully defined
	return &token.QueryTokenInfoResponse{}, nil
}

// ListTokens handles ListTokens query
func (q tokenQueryServer) ListTokens(ctx context.Context, req *token.QueryListTokensRequest) (*token.QueryListTokensResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	// Use the same implementation as ListToken
	// Since QueryListTokensResponse is an empty struct, return empty response
	return &token.QueryListTokensResponse{}, nil
}

// TokenAll handles TokenAll query (alias for ListToken)
func (q tokenQueryServer) TokenAll(ctx context.Context, req *token.QueryAllTokenRequest) (*token.QueryAllTokenResponse, error) {
	return q.ListToken(ctx, req)
}

// ListToken handles ListToken query
func (q tokenQueryServer) ListToken(ctx context.Context, req *token.QueryAllTokenRequest) (*token.QueryAllTokenResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

		tokens, pageRes, err := query.CollectionPaginate(
		ctx,
		q.k.Token,
		req.Pagination,
		func(_ string, value token.Token) (token.Token, error) {
			return value, nil
		},
	)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	return &token.QueryAllTokenResponse{Token: tokens, Pagination: pageRes}, nil
}

// Token handles Token query (alias for GetToken)
func (q tokenQueryServer) Token(ctx context.Context, req *token.QueryGetTokenRequest) (*token.QueryGetTokenResponse, error) {
	return q.GetToken(ctx, req)
}

// GetToken handles GetToken query
func (q tokenQueryServer) GetToken(ctx context.Context, req *token.QueryGetTokenRequest) (*token.QueryGetTokenResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	val, err := q.k.Token.Get(ctx, req.Denom)
	if err != nil {
		if errors.Is(err, collections.ErrNotFound) {
			return nil, status.Error(codes.NotFound, "not found")
		}

		return nil, status.Error(codes.Internal, "internal error")
	}

	return &token.QueryGetTokenResponse{Token: val}, nil
}

// Params handles Params query
func (q tokenQueryServer) Params(ctx context.Context, req *token.QueryParamsRequest) (*token.QueryParamsResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	params, err := q.k.Params.Get(ctx)
	if err != nil && !errors.Is(err, collections.ErrNotFound) {
		return nil, status.Error(codes.Internal, "internal error")
	}

	return &token.QueryParamsResponse{Params: &params}, nil
}
