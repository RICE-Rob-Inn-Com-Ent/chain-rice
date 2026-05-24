package token

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"cosmossdk.io/collections"
	collcodec "cosmossdk.io/collections/codec"
	"cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// AuthzKind identifies which token action a grant authorizes.
type AuthzKind uint64

const (
	// AuthzKindMint authorizes the grantee to trigger minting up to optional limits.
	AuthzKindMint AuthzKind = 1
	// AuthzKindBurn authorizes the grantee to burn from their own balance within limits.
	AuthzKindBurn AuthzKind = 2
)

// AuthzGrant is stored per (grantee, granter, kind). RemainingLimit empty means unlimited amount.
// ExpirationHeight 0 means no block-height expiry.
type AuthzGrant struct {
	ExpirationHeight int64  `json:"expiration_height"`
	RemainingLimit   string `json:"remaining_limit"`
}

// AuthzGrantValueCodec is the collections codec for [AuthzGrant] (JSON).
func AuthzGrantValueCodec() collcodec.ValueCodec[AuthzGrant] {
	return authzGrantJSONCodec{}
}

type authzGrantJSONCodec struct{}

func (authzGrantJSONCodec) Encode(value AuthzGrant) ([]byte, error) {
	return json.Marshal(value)
}

func (authzGrantJSONCodec) Decode(b []byte) (AuthzGrant, error) {
	var g AuthzGrant
	if err := json.Unmarshal(b, &g); err != nil {
		return AuthzGrant{}, err
	}
	return g, nil
}

func (c authzGrantJSONCodec) EncodeJSON(value AuthzGrant) ([]byte, error) {
	return c.Encode(value)
}

func (c authzGrantJSONCodec) DecodeJSON(b []byte) (AuthzGrant, error) {
	return c.Decode(b)
}

func (authzGrantJSONCodec) Stringify(value AuthzGrant) string {
	b, err := json.Marshal(value)
	if err != nil {
		return fmt.Sprintf("token.AuthzGrant{exp:%d}", value.ExpirationHeight)
	}
	return string(b)
}

func (authzGrantJSONCodec) ValueType() string {
	return "token.AuthzGrant/json"
}

func authzGrantKey(grantee, granter sdk.AccAddress, kind AuthzKind) collections.Triple[sdk.AccAddress, sdk.AccAddress, uint64] {
	return collections.Join3(grantee, granter, uint64(kind))
}

// GrantActionAuthz records a grant from granter to grantee for the given kind and limits.
// remainingLimit nil means unlimited cumulative allowance; otherwise counts down on each consume.
func (k Keeper) GrantActionAuthz(ctx context.Context, granter, grantee sdk.AccAddress, kind AuthzKind, expirationHeight int64, remainingLimit *math.Int) error {
	if granter.Empty() || grantee.Empty() {
		return ErrInvalidAmount
	}
	if kind != AuthzKindMint && kind != AuthzKindBurn {
		return ErrInvalidAmount
	}
	g := AuthzGrant{ExpirationHeight: expirationHeight}
	if remainingLimit != nil {
		if remainingLimit.IsNil() || remainingLimit.IsNegative() {
			return ErrInvalidAmount
		}
		if remainingLimit.IsZero() {
			return ErrInvalidAmount
		}
		g.RemainingLimit = remainingLimit.String()
	}
	return k.ManagedState.AuthzGrants.Set(ctx, authzGrantKey(grantee, granter, kind), g)
}

// RevokeActionAuthz removes a grant.
func (k Keeper) RevokeActionAuthz(ctx context.Context, granter, grantee sdk.AccAddress, kind AuthzKind) error {
	if granter.Empty() || grantee.Empty() {
		return ErrInvalidAmount
	}
	return k.ManagedState.AuthzGrants.Remove(ctx, authzGrantKey(grantee, granter, kind))
}

// GetActionAuthz returns a stored grant if present.
func (k Keeper) GetActionAuthz(ctx context.Context, grantee, granter sdk.AccAddress, kind AuthzKind) (AuthzGrant, bool, error) {
	g, err := k.ManagedState.AuthzGrants.Get(ctx, authzGrantKey(grantee, granter, kind))
	if err != nil {
		if errors.Is(err, collections.ErrNotFound) {
			return AuthzGrant{}, false, nil
		}
		return AuthzGrant{}, false, err
	}
	return g, true, nil
}

// AuthzGrantValid reports whether a grant exists, is not expired at height, and has enough remaining (if capped).
func AuthzGrantValid(g AuthzGrant, height int64, need math.Int) bool {
	if g.ExpirationHeight > 0 && height > g.ExpirationHeight {
		return false
	}
	lim := strings.TrimSpace(g.RemainingLimit)
	if lim == "" {
		return true
	}
	rem, ok := math.NewIntFromString(lim)
	if !ok || rem.IsNil() || rem.IsNegative() {
		return false
	}
	return !rem.LT(need)
}

// IterateAuthzGrants walks all stored token authz grants. Return true from cb to stop.
func (k Keeper) IterateAuthzGrants(ctx context.Context, cb func(grantee, granter sdk.AccAddress, kind AuthzKind, g AuthzGrant) (stop bool, err error)) error {
	return k.ManagedState.AuthzGrants.Walk(ctx, nil, func(key collections.Triple[sdk.AccAddress, sdk.AccAddress, uint64], g AuthzGrant) (bool, error) {
		return cb(key.K1(), key.K2(), AuthzKind(key.K3()), g)
	})
}

// ConsumeActionAuthz applies a consumption of amount to the stored grant (decrements limit or deletes when exhausted).
func (k Keeper) ConsumeActionAuthz(ctx context.Context, grantee, granter sdk.AccAddress, kind AuthzKind, height int64, amount math.Int) error {
	if err := MustPositiveInt(amount); err != nil {
		return err
	}
	key := authzGrantKey(grantee, granter, kind)
	g, err := k.ManagedState.AuthzGrants.Get(ctx, key)
	if errors.Is(err, collections.ErrNotFound) {
		return ErrUnauthorized
	}
	if err != nil {
		return err
	}
	if !AuthzGrantValid(g, height, amount) {
		return ErrUnauthorized
	}
	lim := strings.TrimSpace(g.RemainingLimit)
	if lim == "" {
		return nil
	}
	rem, ok := math.NewIntFromString(lim)
	if !ok || rem.IsNil() {
		return ErrInvalidAmount
	}
	newRem, err := Subtract(rem, amount)
	if err != nil {
		return err
	}
	if newRem.IsZero() {
		return k.ManagedState.AuthzGrants.Remove(ctx, key)
	}
	g.RemainingLimit = newRem.String()
	return k.ManagedState.AuthzGrants.Set(ctx, key, g)
}
