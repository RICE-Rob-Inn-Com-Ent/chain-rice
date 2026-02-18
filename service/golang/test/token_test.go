package testutil

import (
	"context"
	"strconv"
	"testing"

	"cosmossdk.io/core/address"
	storetypes "cosmossdk.io/store/types"
	addresscodec "github.com/cosmos/cosmos-sdk/codec/address"
	"github.com/cosmos/cosmos-sdk/runtime"
	"github.com/cosmos/cosmos-sdk/testutil"
	sdk "github.com/cosmos/cosmos-sdk/types"
	moduletestutil "github.com/cosmos/cosmos-sdk/types/module/testutil"
	"github.com/cosmos/cosmos-sdk/types/query"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	apptoken "github.com/chainrice/rice/backend/app/token"
	"github.com/chainrice/rice/backend/module"
	"github.com/chainrice/rice/backend/module/token"
)

type fixture struct {
	ctx          context.Context
	keeper       token.TokenKeeper
	addressCodec address.Codec
}

func initFixture(t *testing.T) *fixture {
	t.Helper()

	encCfg := moduletestutil.MakeTestEncodingConfig(module.TokenAppModule{})
	addressCodec := addresscodec.NewBech32Codec(sdk.GetConfig().GetBech32AccountAddrPrefix())
	storeKey := storetypes.NewKVStoreKey(token.TokenStoreKey)

	storeService := runtime.NewKVStoreService(storeKey)
	ctx := testutil.DefaultContextWithDB(t, storeKey, storetypes.NewTransientStoreKey("transient_test")).Ctx

	authority := authtypes.NewModuleAddress(token.TokenGovModuleName)

	k := token.TokenNewKeeper(
		storeService,
		encCfg.Codec,
		addressCodec,
		authority,
	)

	// Initialize params
	if err := k.Params.Set(ctx, token.TokenDefaultParams()); err != nil {
		t.Fatalf("failed to set params: %v", err)
	}

	return &fixture{
		ctx:          ctx,
		keeper:       k,
		addressCodec: addressCodec,
	}
}

func createNToken(keeper token.TokenKeeper, ctx context.Context, n int) []apptoken.Token {
	items := make([]apptoken.Token, n)
	for i := range items {
		items[i].Denom = strconv.Itoa(i)
		items[i].Name = strconv.Itoa(i)
		items[i].Symbol = strconv.Itoa(i)
		items[i].Decimals = uint32(i)
		_ = keeper.Token.Set(ctx, items[i].Denom, items[i])
	}
	return items
}

func TestGenesis(t *testing.T) {
	params := token.TokenDefaultParams()
	genesisState := apptoken.GenesisState{
		Params:   params,
		TokenMap: []apptoken.Token{{Denom: "0"}, {Denom: "1"}}}

	f := initFixture(t)
	err := f.keeper.TokenInitGenesis(f.ctx, &genesisState)
	require.NoError(t, err)
	got, err := f.keeper.TokenExportGenesis(f.ctx)
	require.NoError(t, err)
	require.NotNil(t, got)

	require.EqualExportedValues(t, genesisState.Params, got.Params)
	require.EqualExportedValues(t, genesisState.TokenMap, got.TokenMap)
}

func TestMsgUpdateParams(t *testing.T) {
	f := initFixture(t)
	ms := token.TokenNewMsgServerImpl(f.keeper)

	params := token.TokenDefaultParams()
	require.NoError(t, f.keeper.Params.Set(f.ctx, params))

	authorityStr, err := f.addressCodec.BytesToString(f.keeper.GetAuthority())
	require.NoError(t, err)

	// default params
	testCases := []struct {
		name      string
		input     *apptoken.MsgUpdateParams
		expErr    bool
		expErrMsg string
	}{
		{
			name: "invalid authority",
			input: &apptoken.MsgUpdateParams{
				Authority: "invalid",
				Params:    &params,
			},
			expErr:    true,
			expErrMsg: "invalid authority",
		},
		{
			name: "send enabled param",
			input: &apptoken.MsgUpdateParams{
				Authority: authorityStr,
				Params:    &apptoken.Params{},
			},
			expErr: false,
		},
		{
			name: "all good",
			input: &apptoken.MsgUpdateParams{
				Authority: authorityStr,
				Params:    &params,
			},
			expErr: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := ms.UpdateParams(f.ctx, tc.input)

			if tc.expErr {
				require.Error(t, err)
				require.Contains(t, err.Error(), tc.expErrMsg)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestParamsQuery(t *testing.T) {
	f := initFixture(t)

	qs := token.TokenNewQueryServerImpl(f.keeper)
	params := token.TokenDefaultParams()
	require.NoError(t, f.keeper.Params.Set(f.ctx, params))

	response, err := qs.Params(f.ctx, &apptoken.QueryParamsRequest{})
	require.NoError(t, err)
	require.Equal(t, &apptoken.QueryParamsResponse{Params: &params}, response)
}

func TestTokenQuerySingle(t *testing.T) {
	f := initFixture(t)
	qs := token.TokenNewQueryServerImpl(f.keeper)
	msgs := createNToken(f.keeper, f.ctx, 2)
	tests := []struct {
		desc     string
		request  *apptoken.QueryGetTokenRequest
		response *apptoken.QueryGetTokenResponse
		err      error
	}{
		{
			desc: "First",
			request: &apptoken.QueryGetTokenRequest{
				Denom: msgs[0].Denom,
			},
			response: &apptoken.QueryGetTokenResponse{Token: msgs[0]},
		},
		{
			desc: "Second",
			request: &apptoken.QueryGetTokenRequest{
				Denom: msgs[1].Denom,
			},
			response: &apptoken.QueryGetTokenResponse{Token: msgs[1]},
		},
		{
			desc: "KeyNotFound",
			request: &apptoken.QueryGetTokenRequest{
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
	qs := token.TokenNewQueryServerImpl(f.keeper)
	msgs := createNToken(f.keeper, f.ctx, 5)

	request := func(next []byte, offset, limit uint64, total bool) *apptoken.QueryAllTokenRequest {
		return &apptoken.QueryAllTokenRequest{
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
