package keeper

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/rice-dev/backend/blockchain/x/tokens/types"
)

// GetTokenQuery retrieves a token by ID
func (k Keeper) GetTokenQuery(goCtx context.Context, req *types.GetTokenRequest) (*types.GetTokenResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	ctx := sdk.UnwrapSDKContext(goCtx)

	token, found := k.GetToken(ctx, req.Id)
	if !found {
		return nil, status.Error(codes.NotFound, "token not found")
	}

	return &types.GetTokenResponse{
		Token: &token,
	}, nil
}

// GetAllTokensQuery retrieves all tokens
func (k Keeper) GetAllTokensQuery(goCtx context.Context, req *types.GetAllTokensRequest) (*types.GetAllTokensResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	ctx := sdk.UnwrapSDKContext(goCtx)

	tokens := k.GetAllTokens(ctx)

	return &types.GetAllTokensResponse{
		Tokens: tokens,
		Pagination: &types.PageResponse{
			Total: uint64(len(tokens)),
		},
	}, nil
}

// GetTokenBalanceQuery retrieves the balance of a token for a specific address
func (k Keeper) GetTokenBalanceQuery(goCtx context.Context, req *types.GetTokenBalanceRequest) (*types.GetTokenBalanceResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	ctx := sdk.UnwrapSDKContext(goCtx)

	balance := k.GetTokenBalance(ctx, req.TokenId, req.Address)

	return &types.GetTokenBalanceResponse{
		Balance: &types.TokenBalance{
			TokenId: req.TokenId,
			Address: req.Address,
			Amount:  balance,
		},
	}, nil
}

// GetAllTokenBalancesQuery retrieves all token balances
func (k Keeper) GetAllTokenBalancesQuery(goCtx context.Context, req *types.GetAllTokenBalancesRequest) (*types.GetAllTokenBalancesResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	ctx := sdk.UnwrapSDKContext(goCtx)

	balances := k.GetAllTokenBalances(ctx)

	return &types.GetAllTokenBalancesResponse{
		Balances: balances,
		Pagination: &types.PageResponse{
			Total: uint64(len(balances)),
		},
	}, nil
}

// GetTokenApprovalQuery retrieves the approval amount for a spender
func (k Keeper) GetTokenApprovalQuery(goCtx context.Context, req *types.GetTokenApprovalRequest) (*types.GetTokenApprovalResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	ctx := sdk.UnwrapSDKContext(goCtx)

	approvalAmount := k.GetTokenApproval(ctx, req.TokenId, req.Owner, req.Spender)

	return &types.GetTokenApprovalResponse{
		Approval: &types.TokenApproval{
			TokenId: req.TokenId,
			Owner:   req.Owner,
			Spender: req.Spender,
			Amount:  approvalAmount,
		},
	}, nil
}

// GetAllTokenApprovalsQuery retrieves all token approvals
func (k Keeper) GetAllTokenApprovalsQuery(goCtx context.Context, req *types.GetAllTokenApprovalsRequest) (*types.GetAllTokenApprovalsResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	ctx := sdk.UnwrapSDKContext(goCtx)

	approvals := k.GetAllTokenApprovals(ctx)

	return &types.GetAllTokenApprovalsResponse{
		Approvals: approvals,
		Pagination: &types.PageResponse{
			Total: uint64(len(approvals)),
		},
	}, nil
}