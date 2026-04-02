package token

// TODO:
// [ ] implement IBC transfer module:
//     IBCModule implements porttypes.IBCModule
//     OnRecvPacket: receives cross-chain tokens
//     OnAcknowledgementPacket: handles send confirmation
//     OnTimeoutPacket: handles send timeout
// [ ] implement ICS-20 token transfer:
//     channel capabilities from RICE_TOKEN_IBC_* env vars

// IBCIntegration documents wiring for IBC (clients, connections, channels, packets).
// Import when aligned: ibckeeper "github.com/cosmos/ibc-go/v9/modules/core/keeper"
type IBCIntegration struct{}
