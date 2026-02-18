package secrets

import (
	"context"
	"fmt"
	"os"
	"sync"

	"go.uber.org/zap"
)

// SecretManager handles secret management
type SecretManager interface {
	GetSecret(ctx context.Context, key string) (string, error)
	SetSecret(ctx context.Context, key, value string) error
	DeleteSecret(ctx context.Context, key string) error
}

// InMemorySecretManager is a simple in-memory secret manager (for development)
type InMemorySecretManager struct {
	secrets map[string]string
	mu      sync.RWMutex
	logger  *zap.SugaredLogger
}

// NewInMemorySecretManager creates a new in-memory secret manager
func NewInMemorySecretManager(logger *zap.SugaredLogger) *InMemorySecretManager {
	return &InMemorySecretManager{
		secrets: make(map[string]string),
		logger:  logger,
	}
}

// GetSecret retrieves a secret
func (m *InMemorySecretManager) GetSecret(ctx context.Context, key string) (string, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	value, ok := m.secrets[key]
	if !ok {
		// Fallback to environment variable
		if envValue := os.Getenv(key); envValue != "" {
			return envValue, nil
		}
		return "", fmt.Errorf("secret %s not found", key)
	}

	return value, nil
}

// SetSecret sets a secret
func (m *InMemorySecretManager) SetSecret(ctx context.Context, key, value string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.secrets[key] = value
	return nil
}

// DeleteSecret deletes a secret
func (m *InMemorySecretManager) DeleteSecret(ctx context.Context, key string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	delete(m.secrets, key)
	return nil
}

// VaultSecretManager is a HashiCorp Vault-based secret manager
type VaultSecretManager struct {
	client *VaultClient
	logger *zap.SugaredLogger
}

// NewVaultSecretManager creates a new Vault secret manager
func NewVaultSecretManager(vaultAddr, vaultToken string, logger *zap.SugaredLogger) (*VaultSecretManager, error) {
	client, err := NewVaultClient(vaultAddr, vaultToken)
	if err != nil {
		return nil, fmt.Errorf("failed to create vault client: %w", err)
	}

	return &VaultSecretManager{
		client: client,
		logger: logger,
	}, nil
}

// GetSecret retrieves a secret from Vault
func (m *VaultSecretManager) GetSecret(ctx context.Context, key string) (string, error) {
	// Try Vault first
	value, err := m.client.ReadSecret(ctx, key)
	if err == nil {
		return value, nil
	}

	// Fallback to environment variable
	if envValue := os.Getenv(key); envValue != "" {
		return envValue, nil
	}

	return "", fmt.Errorf("secret %s not found: %w", key, err)
}

// SetSecret sets a secret in Vault
func (m *VaultSecretManager) SetSecret(ctx context.Context, key, value string) error {
	return m.client.WriteSecret(ctx, key, value)
}

// DeleteSecret deletes a secret from Vault
func (m *VaultSecretManager) DeleteSecret(ctx context.Context, key string) error {
	return m.client.DeleteSecret(ctx, key)
}

// GetSecretManager returns the appropriate secret manager based on configuration
func GetSecretManager(logger *zap.SugaredLogger) SecretManager {
	vaultAddr := os.Getenv("VAULT_ADDR")
	vaultToken := os.Getenv("VAULT_TOKEN")

	if vaultAddr != "" && vaultToken != "" {
		manager, err := NewVaultSecretManager(vaultAddr, vaultToken, logger)
		if err != nil {
			logger.Warnf("Failed to initialize Vault secret manager, falling back to in-memory: %v", err)
			return NewInMemorySecretManager(logger)
		}
		return manager
	}

	// Default to in-memory for development
	return NewInMemorySecretManager(logger)
}
