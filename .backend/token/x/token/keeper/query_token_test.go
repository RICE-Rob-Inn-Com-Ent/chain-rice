package keeper_test

import (
	"context"
	"strconv"
	"testing"

	"github.com/cosmos/cosmos-sdk/types/query"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"tokenchain/x/token/keeper"
	"tokenchain/x/token/types"
)

func createNToken(keeper keeper.Keeper, ctx context.Context, n int) []types.Token {
	items := make([]types.Token, n)
	for i := range items {
		items[i].Denom = strconv.Itoa(i)
		items[i].Name = strconv.Itoa(i)
		items[i].Symbol = strconv.Itoa(i)
		items[i].Decimals = uint64(i)
		items[i].TotalSupply = uint64(i)
		items[i].Mintable = true
		_ = keeper.Token.Set(ctx, items[i].Denom, items[i])
	}
	return items
}

func TestTokenQuerySingle(t *testing.T) {
	f := initFixture(t)
	qs := keeper.NewQueryServerImpl(f.keeper)
	msgs := createNToken(f.keeper, f.ctx, 2)
	tests := []struct {
		desc     string
		request  *types.QueryGetTokenRequest
		response *types.QueryGetTokenResponse
		err      error
	}{
		{
			desc: "First",
			request: &types.QueryGetTokenRequest{
				Denom: msgs[0].Denom,
			},
			response: &types.QueryGetTokenResponse{Token: msgs[0]},
		},
		{
			desc: "Second",
			request: &types.QueryGetTokenRequest{
				Denom: msgs[1].Denom,
			},
			response: &types.QueryGetTokenResponse{Token: msgs[1]},
		},
		{
			desc: "KeyNotFound",
			request: &types.QueryGetTokenRequest{
				Denom: strconv.Itoa(100000),
			},
			err: status.Error(codes.NotFound, "not found"),
		},
		{
			desc: "InvalidRequest",
			err:  status.Error(codes.InvalidArgument, "invalid request"),
		},
	}
	for _, tc := range tests {
		t.Run(tc.desc, func(t *testing.T) {
			response, err := qs.GetToken(f.ctx, tc.request)
			if tc.err != nil {
				require.ErrorIs(t, err, tc.err)
			} else {
				require.NoError(t, err)
				require.EqualExportedValues(t, tc.response, response)
			}
		})
	}
}

func TestTokenQueryPaginated(t *testing.T) {
	f := initFixture(t)
	qs := keeper.NewQueryServerImpl(f.keeper)
	msgs := createNToken(f.keeper, f.ctx, 5)

	request := func(next []byte, offset, limit uint64, total bool) *types.QueryAllTokenRequest {
		return &types.QueryAllTokenRequest{
			Pagination: &query.PageRequest{
				Key:        next,
				Offset:     offset,
				Limit:      limit,
				CountTotal: total,
			},
		}
	}
	t.Run("ByOffset", func(t *testing.T) {
		step := 2
		for i := 0; i < len(msgs); i += step {
			resp, err := qs.ListToken(f.ctx, request(nil, uint64(i), uint64(step), false))
			require.NoError(t, err)
			require.LessOrEqual(t, len(resp.Token), step)
			require.Subset(t, msgs, resp.Token)
		}
	})
	t.Run("ByKey", func(t *testing.T) {
		step := 2
		var next []byte
		for i := 0; i < len(msgs); i += step {
			resp, err := qs.ListToken(f.ctx, request(next, 0, uint64(step), false))
			require.NoError(t, err)
			require.LessOrEqual(t, len(resp.Token), step)
			require.Subset(t, msgs, resp.Token)
			next = resp.Pagination.NextKey
		}
	})
	t.Run("Total", func(t *testing.T) {
		resp, err := qs.ListToken(f.ctx, request(nil, 0, 0, true))
		require.NoError(t, err)
		require.Equal(t, len(msgs), int(resp.Pagination.Total))
		require.EqualExportedValues(t, msgs, resp.Token)
	})
	t.Run("InvalidRequest", func(t *testing.T) {
		_, err := qs.ListToken(f.ctx, nil)
		require.ErrorIs(t, err, status.Error(codes.InvalidArgument, "invalid request"))
	})
}
