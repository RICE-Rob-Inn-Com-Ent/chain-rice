package token

import (
	context "context"
	grpc "google.golang.org/grpc"
)

// MsgServer is the server API for Msg service.
type MsgServer interface {
	CreateToken(context.Context, *MsgCreateToken) (*MsgCreateTokenResponse, error)
	Mint(context.Context, *MsgMint) (*MsgMintResponse, error)
	Burn(context.Context, *MsgBurn) (*MsgBurnResponse, error)
	Transfer(context.Context, *MsgTransfer) (*MsgTransferResponse, error)
	UpdateParams(context.Context, *MsgUpdateParams) (*MsgUpdateParamsResponse, error)
}

// MsgClient is the client API for Msg service.
type MsgClient interface {
	CreateToken(ctx context.Context, in *MsgCreateToken, opts ...grpc.CallOption) (*MsgCreateTokenResponse, error)
	Mint(ctx context.Context, in *MsgMint, opts ...grpc.CallOption) (*MsgMintResponse, error)
	Burn(ctx context.Context, in *MsgBurn, opts ...grpc.CallOption) (*MsgBurnResponse, error)
	Transfer(ctx context.Context, in *MsgTransfer, opts ...grpc.CallOption) (*MsgTransferResponse, error)
	UpdateParams(ctx context.Context, in *MsgUpdateParams, opts ...grpc.CallOption) (*MsgUpdateParamsResponse, error)
}

type msgClient struct {
	cc grpc.ClientConnInterface
}

func NewMsgClient(cc grpc.ClientConnInterface) MsgClient {
	return &msgClient{cc}
}

func (c *msgClient) CreateToken(ctx context.Context, in *MsgCreateToken, opts ...grpc.CallOption) (*MsgCreateTokenResponse, error) {
	out := new(MsgCreateTokenResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Msg/CreateToken", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *msgClient) Mint(ctx context.Context, in *MsgMint, opts ...grpc.CallOption) (*MsgMintResponse, error) {
	out := new(MsgMintResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Msg/Mint", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *msgClient) Burn(ctx context.Context, in *MsgBurn, opts ...grpc.CallOption) (*MsgBurnResponse, error) {
	out := new(MsgBurnResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Msg/Burn", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *msgClient) Transfer(ctx context.Context, in *MsgTransfer, opts ...grpc.CallOption) (*MsgTransferResponse, error) {
	out := new(MsgTransferResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Msg/Transfer", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *msgClient) UpdateParams(ctx context.Context, in *MsgUpdateParams, opts ...grpc.CallOption) (*MsgUpdateParamsResponse, error) {
	out := new(MsgUpdateParamsResponse)
	err := c.cc.Invoke(ctx, "/tokenchain.token.v1.Msg/UpdateParams", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// Msg_serviceDesc is the grpc.ServiceDesc for Msg service.
var Msg_serviceDesc = grpc.ServiceDesc{
	ServiceName: "tokenchain.token.v1.Msg",
	HandlerType: (*MsgServer)(nil),
	Methods:     []grpc.MethodDesc{},
	Streams:     []grpc.StreamDesc{},
	Metadata:    "tokenchain/token/v1/tx.proto",
}

// RegisterMsgServer registers the gRPC service
func RegisterMsgServer(s grpc.ServiceRegistrar, srv MsgServer) {
	s.RegisterService(&Msg_serviceDesc, srv)
}
