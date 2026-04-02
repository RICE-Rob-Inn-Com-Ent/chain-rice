package web

// TODO:
// [ ] implement gocloud.dev secrets:
//     NewSecrets(ctx) (*secrets.Keeper, error)
//     reads RICE_SECRETS_URL from env:
//     awskms://key-id → AWS KMS
//     gcpkms://project/location/keyring/key → GCP KMS
//     azurekeyvault://vault/key → Azure Key Vault
// [ ] implement secret operations:
//     Encrypt(ctx, plaintext []byte) ([]byte, error)
//     Decrypt(ctx, ciphertext []byte) ([]byte, error)
// [ ] implement secret rotation:
//     RotateKey(ctx) error — rotates encryption key
//     re-encrypts all secrets after rotation
//     triggered by rice audit → security step

import (
	"context"

	"gocloud.dev/runtimevar"
	"gocloud.dev/secrets"
	_ "gocloud.dev/runtimevar/awssecretsmanager"
	_ "gocloud.dev/runtimevar/filevar"
	_ "gocloud.dev/secrets/awskms"
	_ "gocloud.dev/secrets/gcpkms"
	_ "gocloud.dev/secrets/localsecrets"
)

// OpenKeeper opens a KMS-backed keeper for Encrypt/Decrypt (not arbitrary secret fetch by name).
func OpenKeeper(ctx context.Context, urlstr string) (*secrets.Keeper, error) {
	return secrets.OpenKeeper(ctx, urlstr)
}

// Encrypt and Decrypt delegate to gocloud secrets.Keeper (envelope encryption with cloud KMS).
func Encrypt(ctx context.Context, k *secrets.Keeper, plaintext []byte) ([]byte, error) {
	if k == nil {
		return nil, errNilKeeper
	}
	return k.Encrypt(ctx, plaintext)
}

func Decrypt(ctx context.Context, k *secrets.Keeper, ciphertext []byte) ([]byte, error) {
	if k == nil {
		return nil, errNilKeeper
	}
	return k.Decrypt(ctx, ciphertext)
}

// OpenVariable watches runtime configuration (AWS Secrets Manager, files, etc.).
func OpenVariable(ctx context.Context, urlstr string) (*runtimevar.Variable, error) {
	return runtimevar.OpenVariable(ctx, urlstr)
}
