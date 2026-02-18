package token

import (
	context "context"
	grpc "google.golang.org/grpc"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/cosmos/cosmos-sdk/client"
)

// QueryServer is the server API for Query service.
type QueryServer interface {
	Params(context.Context, *QueryParamsRequest) (*QueryParamsResponse, error)
	GetToken(context.Context, *QueryGetTokenRequest) (*QueryGetTokenResponse, error)
	Token(context.Context, *QueryGetTokenRequest) (*QueryGetTokenResponse, error)
	ListToken(context.Context, *QueryAllTokenRequest) (*QueryAllTokenResponse, error)
	TokenAll(context.Context, *QueryAllTokenRequest) (*QueryAllTokenResponse, error)
	Balance(context.Context, *QueryBalanceRequest) (*QueryBalanceResponse, error)
	TokenInfo(context.Context, *QueryTokenInfoRequest) (*QueryTokenInfoResponse, error)
	ListTokens(context.Context, *QueryListTokensRequest) (*QueryListTokensResponse, error)
}

// QueryClient is the client API for Query service.
type QueryClient interface {
	Params(ctx context.Context, in *QueryParamsRequest, opts ...grpc.CallOption) (*QueryParamsResponse, error)
	GetToken(ctx context.Context, in *QueryGetTokenRequest, opts ...grpc.CallOption) (*QueryGetTokenResponse, error)
	Token(ctx context.Context, in *QueryGetTokenRequest, opts ...grpc.CallOption) (*QueryGetTokenResponse, error)
	ListToken(ctx context.Context, in *QueryAllTokenRequest, opts ...grpc.CallOption) (*QueryAllTokenResponse, error)
	TokenAll(ctx context.Context, in *QueryAllTokenRequest, opts ...grpc.CallOption) (*QueryAllTokenResponse, error)
	Balance(ctx context.Context, in *QueryBalanceRequest, opts ...grpc.CallOption) (*QueryBalanceResponse, error)
	TokenInfo(ctx context.Context, in *QueryTokenInfoRequest, opts ...grpc.CallOption) (*QueryTokenInfoResponse, error)
	ListTokens(ctx context.Context, in *QueryListTokensRequest, opts ...grpc.CallOption) (*QueryListTokensResponse, error)
}

type queryClient struct {
	cc grpc.ClientConnInterface
}

func NewQueryClient(cc grpc.ClientConnInterface) QueryClient {
	return &queryClient{cc}
}

func (c *queryClient) Params(ctx context.Context, in *QueryParamsRequest, opts ...grpc.CallOption) (*QueryParamsResponse, error) {
	out := new(QueryParamsResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Query/Params", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *queryClient) GetToken(ctx context.Context, in *QueryGetTokenRequest, opts ...grpc.CallOption) (*QueryGetTokenResponse, error) {
	out := new(QueryGetTokenResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Query/GetToken", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *queryClient) Token(ctx context.Context, in *QueryGetTokenRequest, opts ...grpc.CallOption) (*QueryGetTokenResponse, error) {
	return c.GetToken(ctx, in, opts...)
}

func (c *queryClient) ListToken(ctx context.Context, in *QueryAllTokenRequest, opts ...grpc.CallOption) (*QueryAllTokenResponse, error) {
	out := new(QueryAllTokenResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Query/ListToken", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *queryClient) TokenAll(ctx context.Context, in *QueryAllTokenRequest, opts ...grpc.CallOption) (*QueryAllTokenResponse, error) {
	return c.ListToken(ctx, in, opts...)
}

func (c *queryClient) Balance(ctx context.Context, in *QueryBalanceRequest, opts ...grpc.CallOption) (*QueryBalanceResponse, error) {
	out := new(QueryBalanceResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Query/Balance", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *queryClient) TokenInfo(ctx context.Context, in *QueryTokenInfoRequest, opts ...grpc.CallOption) (*QueryTokenInfoResponse, error) {
	out := new(QueryTokenInfoResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Query/TokenInfo", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *queryClient) ListTokens(ctx context.Context, in *QueryListTokensRequest, opts ...grpc.CallOption) (*QueryListTokensResponse, error) {
	out := new(QueryListTokensResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Query/ListTokens", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// Query_serviceDesc is the grpc.ServiceDesc for Query service.
var Query_serviceDesc = grpc.ServiceDesc{
	ServiceName: "tokenchain.token.v1.Query",
	HandlerType: (*QueryServer)(nil),
	Methods:     []grpc.MethodDesc{},
	Streams:     []grpc.StreamDesc{},
	Metadata:    "tokenchain/token/v1/query.proto",
}

// RegisterQueryServer registers the gRPC service
func RegisterQueryServer(s grpc.ServiceRegistrar, srv QueryServer) {
	s.RegisterService(&Query_serviceDesc, srv)
}

// RegisterQueryHandlerClient registers the gRPC Gateway handler
func RegisterQueryHandlerClient(ctx client.Context, mux *runtime.ServeMux, client QueryClient) error {
	// This is a stub - actual implementation would register HTTP handlers
	// For now, we'll just return nil as this is typically generated code
	return nil
}
