package token

// TODO:
// [ ] implement QueryServer interface from gen/:
//     Balance(ctx, *QueryBalanceRequest) (*QueryBalanceResponse, error)
//     TotalSupply(ctx, *QueryTotalSupplyRequest) (*QueryTotalSupplyResponse, error)
//     Params(ctx, *QueryParamsRequest) (*QueryParamsResponse, error)
// [ ] implement pagination via cosmossdk.io/store:
//     collections.Paginate() for all list queries
//     page request from proto query — default size from RICE_TOKEN_PAGE_SIZE

import (
	"context"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/query"
)

// QueryServer implements gRPC Query for x/token (read path + pagination).
type QueryServer struct {
	keeper Keeper
}

// NewQueryServer constructs the query handler server.
func NewQueryServer(k Keeper) QueryServer {
	return QueryServer{keeper: k}
}

// ExamplePagedQuery shows PageRequest / PageResponse usage for list endpoints.
func (q QueryServer) ExamplePagedQuery(ctx context.Context, page *query.PageRequest) (*query.PageResponse, error) {
	_ = q
	_ = sdk.UnwrapSDKContext(ctx)
	if page == nil {
		page = &query.PageRequest{}
	}
	return &query.PageResponse{
		NextKey: nil,
		Total:   0,
	}, nil
}
