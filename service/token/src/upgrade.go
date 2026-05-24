package token

import (
	errorsmod "cosmossdk.io/errors"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
	"github.com/cosmos/cosmos-sdk/types/module"
)

// ConsensusVersion is the x/token module store/schema version (increment on breaking state changes).
// Register a matching [module.Configurator.RegisterMigration] each time this value increases.
const ConsensusVersion = 1

// RegisterTokenStoreMigrations registers in-place store migrations for x/token.
// When bumping [ConsensusVersion], add a handler fromVersion == previous version (e.g. 1 -> 2 uses fromVersion 1).
func RegisterTokenStoreMigrations(cfg module.Configurator) error {
	// Example when moving to v2:
	// return cfg.RegisterMigration(ModuleName, 1, MigrateTokenV1ToV2)
	_ = cfg
	return nil
}

// OnUpgrade is an optional hook for [cosmossdk.io/x/upgrade] Plan handlers: param rewrites, one-off fixes,
// or emits after [module.RunMigrations] completes. Store shape changes belong in RegisterMigration handlers.
func OnUpgrade(ctx sdk.Context, k Keeper, fromConsensus, toConsensus uint64) error {
	if fromConsensus > toConsensus {
		return errorsmod.Wrap(sdkerrors.ErrInvalidRequest, "token: consensus downgrade not supported")
	}
	if toConsensus > ConsensusVersion {
		return errorsmod.Wrapf(sdkerrors.ErrInvalidVersion, "token: target version %d exceeds module consensus %d", toConsensus, ConsensusVersion)
	}
	_ = k
	_ = ctx
	// Future: switch toConsensus { case 2: ... }
	return nil
}

// MigrateTokenV1ToV2 is a placeholder no-op; replace with real store key / collections migration when [ConsensusVersion] becomes 2.
func MigrateTokenV1ToV2(_ sdk.Context) error {
	return nil
}
