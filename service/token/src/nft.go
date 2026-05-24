package token

import (
	errorsmod "cosmossdk.io/errors"
	nft "cosmossdk.io/x/nft"

	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

// NFTIntegration documents wiring [cosmossdk.io/x/nft] for unique assets alongside fungible x/token.
// Mint/transfer/burn of NFTs are handled by the nft module; this file only provides naming helpers.
type NFTIntegration struct{}

// TokenLinkedNFTClassPrefix scopes NFT class IDs that BARD may treat as “token-adjacent” collections.
const TokenLinkedNFTClassPrefix = "rice/token/"

// ProposeNFTClassID returns a class id string suitable for [nft.Class.Id].
func ProposeNFTClassID(scope string) string {
	return TokenLinkedNFTClassPrefix + scope
}

// TokenNFTRecord is a placeholder descriptor for AI / generative assets before on-chain class creation.
type TokenNFTRecord struct {
	ClassID string `json:"class_id"`
	ID      string `json:"id"`
	URI     string `json:"uri,omitempty"`
	URIHash string `json:"uri_hash,omitempty"`
}

// ValidateTokenNFTRecord checks minimal fields; full id rules are enforced by x/nft on MsgSend/Mint.
func ValidateTokenNFTRecord(r TokenNFTRecord) error {
	if r.ClassID == "" || r.ID == "" {
		return errorsmod.Wrap(sdkerrors.ErrInvalidRequest, "class_id and id required")
	}
	return nil
}

// NFTClassMetadataHint returns optional metadata JSON URI for a new class (x/nft MsgCreateClass).
func NFTClassMetadataHint(name, symbol, description string) *nft.Class {
	return &nft.Class{
		Id:          "",
		Name:        name,
		Symbol:      symbol,
		Description: description,
		Uri:         "",
		UriHash:     "",
	}
}
