package auth

// TODO:
// [ ] implement BIP39 mnemonic generation:
//     GenerateMnemonic(bitSize int) (string, error)
//     bitSize: 128|160|192|224|256 — from RICE_BIP39_BITS env var
// [ ] implement seed derivation:
//     MnemonicToSeed(mnemonic, passphrase string) ([]byte, error)
//     passphrase from SOPS — never hardcoded
// [ ] implement entropy validation:
//     ValidateMnemonic(mnemonic string) error
//     used before deriving Cosmos SDK wallet from seed

import (
	"github.com/tyler-smith/go-bip39"
)

// NewMnemonic generates a random BIP-39 mnemonic of the given word count (12, 15, 18, 21, 24).
func NewMnemonic(bitSize int) (string, error) {
	entropy, err := bip39.NewEntropy(bitSize)
	if err != nil {
		return "", err
	}
	return bip39.NewMnemonic(entropy)
}

// MnemonicToSeed derives a BIP-39 seed from mnemonic + optional passphrase.
func MnemonicToSeed(mnemonic, passphrase string) []byte {
	return bip39.NewSeed(mnemonic, passphrase)
}

// IsMnemonicValid checks the mnemonic checksum.
func IsMnemonicValid(mnemonic string) bool {
	return bip39.IsMnemonicValid(mnemonic)
}
