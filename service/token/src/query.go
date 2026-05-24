package token

import (
	"context"
	"sort"
	"strings"
	"time"

	errorsmod "cosmossdk.io/errors"
	"cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
)

// OTel tracer scope for x/token queries.
const queryOtelScope = "github.com/RICE-Rob-Inn-Com-Ent/rice/service/token/query"

// DefaultAllBalancesLimit caps entries per query for frontend-friendly responses.
const DefaultAllBalancesLimit uint64 = 256

// --- QueryBalance ---

// QueryBalanceRequest requests an account balance by bech32 address.
//
// proto: smith.token.v1.QueryBalanceRequest
// grpc-gateway: GET /smith/token/v1/balance/{address}
type QueryBalanceRequest struct {
	Address string `protobuf:"bytes,1,opt,name=address,proto3" json:"address,omitempty"`
}

func (m *QueryBalanceRequest) Reset()         { *m = QueryBalanceRequest{} }
func (m *QueryBalanceRequest) String() string { return m.Address }
func (*QueryBalanceRequest) ProtoMessage()    {}

// QueryBalanceResponse carries the balance as a decimal integer string.
//
// proto: smith.token.v1.QueryBalanceResponse
type QueryBalanceResponse struct {
	Amount string `protobuf:"bytes,1,opt,name=amount,proto3" json:"amount,omitempty"`
	Denom  string `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
}

func (m *QueryBalanceResponse) Reset()         { *m = QueryBalanceResponse{} }
func (m *QueryBalanceResponse) String() string { return m.Amount }
func (*QueryBalanceResponse) ProtoMessage()    {}

// --- QueryAllBalances ---

// QueryAllBalancesRequest lists non-zero balances up to Limit (grpc-gateway friendly).
//
// proto: smith.token.v1.QueryAllBalancesRequest
// grpc-gateway: GET /smith/token/v1/all_balances
type QueryAllBalancesRequest struct {
	Limit uint64 `protobuf:"varint,1,opt,name=limit,proto3" json:"limit,omitempty"`
}

func (m *QueryAllBalancesRequest) Reset()         { *m = QueryAllBalancesRequest{} }
func (m *QueryAllBalancesRequest) String() string { return "" }
func (*QueryAllBalancesRequest) ProtoMessage()    {}

// BalanceEntry is one address balance for REST/JSON clients.
type BalanceEntry struct {
	Address string `protobuf:"bytes,1,opt,name=address,proto3" json:"address,omitempty"`
	Amount  string `protobuf:"bytes,2,opt,name=amount,proto3" json:"amount,omitempty"`
}

// QueryAllBalancesResponse is optimized for fast pagination-free reads (bounded by Limit).
//
// proto: smith.token.v1.QueryAllBalancesResponse
type QueryAllBalancesResponse struct {
	Balances []BalanceEntry `protobuf:"bytes,1,rep,name=balances,proto3" json:"balances,omitempty"`
	Denom    string         `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
}

func (m *QueryAllBalancesResponse) Reset()         { *m = QueryAllBalancesResponse{} }
func (m *QueryAllBalancesResponse) String() string { return "" }
func (*QueryAllBalancesResponse) ProtoMessage()    {}

// --- QueryTotalSupply ---

// QueryTotalSupplyRequest requests aggregate supply for the primary mint denom.
//
// proto: smith.token.v1.QueryTotalSupplyRequest
// grpc-gateway: GET /smith/token/v1/total_supply
type QueryTotalSupplyRequest struct{}

func (m *QueryTotalSupplyRequest) Reset()         { *m = QueryTotalSupplyRequest{} }
func (m *QueryTotalSupplyRequest) String() string { return "" }
func (*QueryTotalSupplyRequest) ProtoMessage()    {}

// QueryTotalSupplyResponse carries total supply as a decimal integer string.
//
// proto: smith.token.v1.QueryTotalSupplyResponse
type QueryTotalSupplyResponse struct {
	Amount string `protobuf:"bytes,1,opt,name=amount,proto3" json:"amount,omitempty"`
	Denom  string `protobuf:"bytes,2,opt,name=denom,proto3" json:"denom,omitempty"`
}

func (m *QueryTotalSupplyResponse) Reset()         { *m = QueryTotalSupplyResponse{} }
func (m *QueryTotalSupplyResponse) String() string { return m.Amount }
func (*QueryTotalSupplyResponse) ProtoMessage()    {}

// --- QueryParams ---

// QueryParamsRequest requests x/token chain parameters.
//
// proto: smith.token.v1.QueryParamsRequest
// grpc-gateway: GET /smith/token/v1/params
type QueryParamsRequest struct{}

func (m *QueryParamsRequest) Reset()         { *m = QueryParamsRequest{} }
func (m *QueryParamsRequest) String() string { return "" }
func (*QueryParamsRequest) ProtoMessage()    {}

// QueryParamsResponse exposes params as strings for JSON clients.
//
// proto: smith.token.v1.QueryParamsResponse
type QueryParamsResponse struct {
	MintDenom      string `protobuf:"bytes,1,opt,name=mint_denom,json=mintDenom,proto3" json:"mint_denom,omitempty"`
	MintingEnabled bool   `protobuf:"varint,2,opt,name=minting_enabled,json=mintingEnabled,proto3" json:"minting_enabled,omitempty"`
	MaxSupply      string `protobuf:"bytes,3,opt,name=max_supply,json=maxSupply,proto3" json:"max_supply,omitempty"`
}

func (m *QueryParamsResponse) Reset()         { *m = QueryParamsResponse{} }
func (m *QueryParamsResponse) String() string { return m.MintDenom }
func (*QueryParamsResponse) ProtoMessage()    {}

// Querier performs state reads using the collections-backed [Keeper].
type Querier struct {
	Keeper Keeper
}

// Balance returns the balance for the requested address.
func (q Querier) Balance(ctx context.Context, req *QueryBalanceRequest) (*QueryBalanceResponse, error) {
	if req == nil {
		return nil, errorsmod.Wrap(sdkerrors.ErrInvalidRequest, "nil request")
	}
	addr := strings.TrimSpace(req.Address)
	if addr == "" {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "address empty")
	}
	acc, err := sdk.AccAddressFromBech32(addr)
	if err != nil {
		return nil, errorsmod.Wrap(ErrInvalidAmount, "address bech32")
	}
	bal, err := q.Keeper.GetBalance(ctx, acc)
	if err != nil {
		return nil, err
	}
	denom, err := q.Keeper.PrimaryMintDenom(ctx)
	if err != nil {
		return nil, err
	}
	return &QueryBalanceResponse{Amount: bal.String(), Denom: denom}, nil
}

// AllBalances returns up to Limit non-zero balances (sorted by address ascending).
func (q Querier) AllBalances(ctx context.Context, req *QueryAllBalancesRequest) (*QueryAllBalancesResponse, error) {
	limit := DefaultAllBalancesLimit
	if req != nil && req.Limit > 0 {
		limit = req.Limit
		if limit > 2048 {
			limit = 2048
		}
	}
	denom, err := q.Keeper.PrimaryMintDenom(ctx)
	if err != nil {
		return nil, err
	}
	var out []BalanceEntry
	var count uint64
	if err := q.Keeper.IterateBalances(ctx, func(addr sdk.AccAddress, v math.Int) (bool, error) {
		if v.IsNil() || v.IsZero() {
			return false, nil
		}
		out = append(out, BalanceEntry{Address: addr.String(), Amount: v.String()})
		count++
		if count >= limit {
			return true, nil
		}
		return false, nil
	}); err != nil {
		return nil, err
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Address < out[j].Address })
	return &QueryAllBalancesResponse{Balances: out, Denom: denom}, nil
}

// TotalSupply returns the module total supply for the primary denom.
func (q Querier) TotalSupply(ctx context.Context, _ *QueryTotalSupplyRequest) (*QueryTotalSupplyResponse, error) {
	sup, err := q.Keeper.TotalSupply(ctx)
	if err != nil {
		return nil, err
	}
	denom, err := q.Keeper.PrimaryMintDenom(ctx)
	if err != nil {
		return nil, err
	}
	return &QueryTotalSupplyResponse{Amount: sup.String(), Denom: denom}, nil
}

// Params returns stored module parameters.
func (q Querier) Params(ctx context.Context, _ *QueryParamsRequest) (*QueryParamsResponse, error) {
	p, err := q.Keeper.GetParams(ctx)
	if err != nil {
		return nil, err
	}
	return &QueryParamsResponse{
		MintDenom:      p.MintDenom,
		MintingEnabled: p.MintingEnabled,
		MaxSupply:      p.MaxSupply.String(),
	}, nil
}

// QueryServer serves gRPC Query for x/token (collections-backed reads).
type QueryServer struct {
	querier Querier
}

// NewQueryServer constructs the query handler server.
func NewQueryServer(k Keeper) QueryServer {
	return QueryServer{querier: Querier{Keeper: k}}
}

// QueryServerIface is the exported gRPC-style surface (implement with [QueryServer]).
type QueryServerIface interface {
	Balance(context.Context, *QueryBalanceRequest) (*QueryBalanceResponse, error)
	AllBalances(context.Context, *QueryAllBalancesRequest) (*QueryAllBalancesResponse, error)
	TotalSupply(context.Context, *QueryTotalSupplyRequest) (*QueryTotalSupplyResponse, error)
	Params(context.Context, *QueryParamsRequest) (*QueryParamsResponse, error)
}

var _ QueryServerIface = QueryServer{}

func (s QueryServer) Balance(ctx context.Context, req *QueryBalanceRequest) (*QueryBalanceResponse, error) {
	tr := otel.Tracer(queryOtelScope)
	ctx, span := tr.Start(ctx, "x/token.Query.Balance")
	defer span.End()
	start := time.Now()
	resp, err := s.querier.Balance(ctx, req)
	span.SetAttributes(attribute.Float64("token.query.latency_ms", float64(time.Since(start).Microseconds())/1000.0))
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, err
	}
	if req != nil {
		span.SetAttributes(attribute.String("token.address", strings.TrimSpace(req.Address)))
	}
	span.SetAttributes(attribute.String("token.balance", resp.Amount))
	span.SetStatus(codes.Ok, "")
	return resp, nil
}

func (s QueryServer) AllBalances(ctx context.Context, req *QueryAllBalancesRequest) (*QueryAllBalancesResponse, error) {
	tr := otel.Tracer(queryOtelScope)
	ctx, span := tr.Start(ctx, "x/token.Query.AllBalances")
	defer span.End()
	start := time.Now()
	resp, err := s.querier.AllBalances(ctx, req)
	span.SetAttributes(attribute.Float64("token.query.latency_ms", float64(time.Since(start).Microseconds())/1000.0))
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, err
	}
	span.SetAttributes(attribute.Int("token.balance_entries", len(resp.Balances)))
	span.SetStatus(codes.Ok, "")
	return resp, nil
}

func (s QueryServer) TotalSupply(ctx context.Context, req *QueryTotalSupplyRequest) (*QueryTotalSupplyResponse, error) {
	tr := otel.Tracer(queryOtelScope)
	ctx, span := tr.Start(ctx, "x/token.Query.TotalSupply")
	defer span.End()
	start := time.Now()
	resp, err := s.querier.TotalSupply(ctx, req)
	span.SetAttributes(attribute.Float64("token.query.latency_ms", float64(time.Since(start).Microseconds())/1000.0))
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, err
	}
	span.SetAttributes(attribute.String("token.total_supply", resp.Amount))
	span.SetStatus(codes.Ok, "")
	return resp, nil
}

func (s QueryServer) Params(ctx context.Context, req *QueryParamsRequest) (*QueryParamsResponse, error) {
	tr := otel.Tracer(queryOtelScope)
	ctx, span := tr.Start(ctx, "x/token.Query.Params")
	defer span.End()
	start := time.Now()
	resp, err := s.querier.Params(ctx, req)
	span.SetAttributes(attribute.Float64("token.query.latency_ms", float64(time.Since(start).Microseconds())/1000.0))
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, err
	}
	span.SetStatus(codes.Ok, "")
	return resp, nil
}
