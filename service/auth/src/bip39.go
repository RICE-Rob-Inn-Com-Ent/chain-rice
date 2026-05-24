package auth

import (
	"fmt"
	"strings"

	"github.com/tyler-smith/go-bip39"
)

// Entropy size for a 24-word English BIP-39 mnemonic (256 bits + 8-bit checksum).
const entropyBits256 = 256

// GenerateMnemonic returns a new random BIP-39 mnemonic with 256-bit entropy (24 words).
func GenerateMnemonic() (string, error) {
	entropy, err := bip39.NewEntropy(entropyBits256)
	if err != nil {
		return "", err
	}
	mnemonic, err := bip39.NewMnemonic(entropy)
	clearBytes(entropy)
	if err != nil {
		return "", err
	}
	return mnemonic, nil
}

// MnemonicToSeed derives a 64-byte BIP-39 seed from mnemonic and optional passphrase ("25th word").
// The mnemonic must be valid (word list + checksum); otherwise an error is returned.
// Callers should zero the returned slice when finished with [ZeroBytes].
func MnemonicToSeed(mnemonic string, password string) ([]byte, error) {
	return bip39.NewSeedWithErrorChecking(strings.TrimSpace(mnemonic), password)
}

// ValidateMnemonic reports whether the phrase is a valid BIP-39 mnemonic for the active word list.
func ValidateMnemonic(mnemonic string) error {
	_, err := bip39.EntropyFromMnemonic(strings.TrimSpace(mnemonic))
	if err != nil {
		return fmt.Errorf("auth.bip39: %w", err)
	}
	return nil
}

// ZeroBytes overwrites b with zeros. Use for seeds and other sensitive byte slices when done.
func ZeroBytes(b []byte) {
	clearBytes(b)
}

func clearBytes(b []byte) {
	for i := range b {
		b[i] = 0
	}
}

// NewMnemonic generates a random BIP-39 mnemonic for bitSize in {128, 160, 192, 224, 256}
// (word counts 12, 15, 18, 21, 24). Prefer [GenerateMnemonic] for the standard 24-word phrase.
func NewMnemonic(bitSize int) (string, error) {
	entropy, err := bip39.NewEntropy(bitSize)
	if err != nil {
		return "", err
	}
	mnemonic, err := bip39.NewMnemonic(entropy)
	clearBytes(entropy)
	if err != nil {
		return "", err
	}
	return mnemonic, nil
}

// IsMnemonicValid checks the mnemonic checksum and word list membership.
func IsMnemonicValid(mnemonic string) bool {
	return bip39.IsMnemonicValid(strings.TrimSpace(mnemonic))
}
