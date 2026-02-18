package secrets

import (
	"context"
	"errors"
	"fmt"
	"time"

	vault "github.com/hashicorp/vault/api"
	"go.uber.org/zap"
)

// VaultClient wraps HashiCorp Vault client
type VaultClient struct {
	client *vault.Client
	logger *zap.SugaredLogger
}

// NewVaultClient creates a new Vault client
func NewVaultClient(addr, token string) (*VaultClient, error) {
	config := vault.DefaultConfig()
	config.Address = addr
	config.Timeout = 10 * time.Second

	client, err := vault.NewClient(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create vault client: %w", err)
	}

	if token != "" {
		client.SetToken(token)
	}

	return &VaultClient{
		client: client,
	}, nil
}

// ReadSecret reads a secret from Vault
func (c *VaultClient) ReadSecret(ctx context.Context, path string) (string, error) {
	secret, err := c.client.Logical().ReadWithContext(ctx, path)
	if err != nil {
		return "", fmt.Errorf("failed to read secret: %w", err)
	}

	if secret == nil || secret.Data == nil {
		return "", errors.New("secret not found")
	}

	// Extract the value (assuming it's stored under "value" key)
	value, ok := secret.Data["value"].(string)
	if !ok {
		// Try to get the first value if "value" key doesn't exist
		for _, v := range secret.Data {
			if str, ok := v.(string); ok {
				return str, nil
			}
		}
		return "", errors.New("secret value not found or invalid type")
	}

	return value, nil
}

// WriteSecret writes a secret to Vault
func (c *VaultClient) WriteSecret(ctx context.Context, path string, value string) error {
	data := map[string]interface{}{
		"value": value,
	}

	_, err := c.client.Logical().WriteWithContext(ctx, path, data)
	if err != nil {
		return fmt.Errorf("failed to write secret: %w", err)
	}

	return nil
}

// DeleteSecret deletes a secret from Vault
func (c *VaultClient) DeleteSecret(ctx context.Context, path string) error {
	_, err := c.client.Logical().DeleteWithContext(ctx, path)
	if err != nil {
		return fmt.Errorf("failed to delete secret: %w", err)
	}

	return nil
}
