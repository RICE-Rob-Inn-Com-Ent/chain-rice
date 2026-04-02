package database

// TODO:
// [ ] implement Valkey client via go-redis:
//     NewCache(ctx) (*redis.Client, error)
//     reads VALKEY_URL from env
//     PoolSize from RICE_VALKEY_POOL_SIZE env var (default: 10)
//     DialTimeout from RICE_VALKEY_DIAL_TIMEOUT_S
// [ ] implement cache operations:
//     Get(ctx, key string) (string, error)
//     Set(ctx, key, value string, ttl time.Duration) error
//     Del(ctx, keys ...string) error
//     TTL from RICE_CACHE_DEFAULT_TTL_S env var
// [ ] implement cache key namespacing:
//     Key(namespace, id string) string
//     namespace: rice:{env}:{service}:{entity}:{id}
//     never hardcode key patterns

import (
	"context"
	"errors"
	"time"

	"github.com/redis/go-redis/v9"
)

// Cache wraps Valkey / Redis (go-redis) for CRUD, TTL, pipelines, Lua.
type Cache struct {
	Client *redis.Client
}

// NewCache returns a redis client from a standard URL (redis:// or rediss://).
func NewCache(addr string, password string, db int) *Cache {
	return &Cache{
		Client: redis.NewClient(&redis.Options{
			Addr:     addr,
			Password: password,
			DB:       db,
		}),
	}
}

// Get returns a string value or redis.Nil if missing.
func (c *Cache) Get(ctx context.Context, key string) (string, error) {
	if c == nil || c.Client == nil {
		return "", errors.New("database: nil cache")
	}
	return c.Client.Get(ctx, key).Result()
}

// Set sets key with optional TTL.
func (c *Cache) Set(ctx context.Context, key string, value any, ttl time.Duration) error {
	if c == nil || c.Client == nil {
		return errors.New("database: nil cache")
	}
	return c.Client.Set(ctx, key, value, ttl).Err()
}

// Del removes keys.
func (c *Cache) Del(ctx context.Context, keys ...string) error {
	if c == nil || c.Client == nil {
		return errors.New("database: nil cache")
	}
	return c.Client.Del(ctx, keys...).Err()
}

// Pipeline starts a pipeline for batching commands.
func (c *Cache) Pipeline() redis.Pipeliner {
	if c == nil || c.Client == nil {
		return nil
	}
	return c.Client.Pipeline()
}

// Eval runs a Lua script (atomic server-side).
func (c *Cache) Eval(ctx context.Context, script string, keys []string, args ...any) *redis.Cmd {
	if c == nil || c.Client == nil {
		return nil
	}
	return c.Client.Eval(ctx, script, keys, args...)
}
