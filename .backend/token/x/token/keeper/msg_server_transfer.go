package keeper

import (
	"context"

	"tokenchain/x/token/types"

	errorsmod "cosmossdk.io/errors"
)

func (k msgServer) Transfer(ctx context.Context, msg *types.MsgTransfer) (*types.MsgTransferResponse, error) {
	if _, err := k.addressCodec.StringToBytes(msg.Creator); err != nil {
		return nil, errorsmod.Wrap(err, "invalid authority address")
	}

	// TODO: Handle the message

	return &types.MsgTransferResponse{}, nil
}
