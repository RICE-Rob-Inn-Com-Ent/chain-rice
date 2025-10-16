package keeper

import (
	"context"

	"tokenchain/x/token/types"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func (q queryServer) ListTokens(ctx context.Context, req *types.QueryListTokensRequest) (*types.QueryListTokensResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	// TODO: Process the query

	return &types.QueryListTokensResponse{}, nil
}
