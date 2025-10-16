package keeper

import (
	"context"

	"tokenchain/x/token/types"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func (q queryServer) TokenInfo(ctx context.Context, req *types.QueryTokenInfoRequest) (*types.QueryTokenInfoResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}

	// TODO: Process the query

	return &types.QueryTokenInfoResponse{}, nil
}
