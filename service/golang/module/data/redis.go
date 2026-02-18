package data

import (
	"context"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// RedisConfig holds Redis connection configuration
type RedisConfig struct {
	Host     string
	Port     int
	Password string
	DB       int
	PoolSize int
}

// RedisDefaultConfig returns default Redis configuration
func RedisDefaultConfig() RedisConfig {
	return RedisConfig{
		Host:     "localhost",
		Port:     6379,
		Password: "",
		DB:       0,
		PoolSize: 10,
	}
}

// RedisFromEnv creates config from environment variables
func RedisFromEnv() RedisConfig {
	config := RedisDefaultConfig()

	if redisURL := os.Getenv("REDIS_URL"); redisURL != "" {
		if parsed, err := redisParseRedisURL(redisURL); err == nil {
			config = parsed
		} else {
			log.Printf("Warning: Failed to parse REDIS_URL, using individual env vars: %v", err)
		}
	}

	if host := os.Getenv("REDIS_HOST"); host != "" {
		config.Host = host
	}
	if portStr := os.Getenv("REDIS_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err == nil {
			config.Port = port
		}
	}
	if password := os.Getenv("REDIS_PASSWORD"); password != "" {
		config.Password = password
	}
	if dbStr := os.Getenv("REDIS_DB"); dbStr != "" {
		if db, err := strconv.Atoi(dbStr); err == nil {
			config.DB = db
		}
	}
	if poolSizeStr := os.Getenv("REDIS_POOL_SIZE"); poolSizeStr != "" {
		if poolSize, err := strconv.Atoi(poolSizeStr); err == nil {
			config.PoolSize = poolSize
		}
	}

	return config
}

func redisParseRedisURL(urlStr string) (RedisConfig, error) {
	config := RedisDefaultConfig()

	if !strings.HasPrefix(urlStr, "redis://") {
		return config, fmt.Errorf("invalid Redis URL format, must start with redis://")
	}
	urlStr = urlStr[8:]

	var auth, hostPort, db string

	atIdx := strings.LastIndex(urlStr, "@")
	if atIdx != -1 {
		auth = urlStr[:atIdx]
		hostPort = urlStr[atIdx+1:]
		if strings.HasPrefix(auth, ":") {
			config.Password = auth[1:]
		} else if auth != "" {
			config.Password = auth
		}
	} else {
		hostPort = urlStr
	}

	slashIdx := strings.Index(hostPort, "/")
	if slashIdx != -1 {
		db = hostPort[slashIdx+1:]
		hostPort = hostPort[:slashIdx]
	}

	if db != "" {
		if dbNum, err := strconv.Atoi(db); err == nil {
			config.DB = dbNum
		}
	}

	colonIdx := strings.LastIndex(hostPort, ":")
	if colonIdx != -1 {
		config.Host = hostPort[:colonIdx]
		if port, err := strconv.Atoi(hostPort[colonIdx+1:]); err == nil {
			config.Port = port
		}
	} else {
		config.Host = hostPort
	}

	return config, nil
}

// RedisClient wraps the redis.Client with additional functionality
type RedisClient struct {
	*redis.Client
	config RedisConfig
}

// RedisNewConnection creates a new Redis connection
func RedisNewConnection(config RedisConfig) (*RedisClient, error) {
	if config.Host == "" {
		return nil, fmt.Errorf("Redis host cannot be empty")
	}

	if config.Port <= 0 || config.Port > 65535 {
		return nil, fmt.Errorf("Redis port must be between 1 and 65535, got %d", config.Port)
	}

	if config.DB < 0 {
		return nil, fmt.Errorf("Redis DB cannot be negative, got %d", config.DB)
	}

	if config.PoolSize <= 0 {
		config.PoolSize = 10 // Default pool size
	}

	client := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", config.Host, config.Port),
		Password: config.Password,
		DB:       config.DB,
		PoolSize: config.PoolSize,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		client.Close() // Clean up on failure
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	}

	log.Printf("Connected to Redis at %s:%d", config.Host, config.Port)

	return &RedisClient{
		Client: client,
		config: config,
	}, nil
}

// Close closes the Redis connection
func (c *RedisClient) Close() error {
	log.Println("Closing Redis connection")
	return c.Client.Close()
}

// HealthCheck performs a health check on Redis
func (c *RedisClient) HealthCheck(ctx context.Context) error {
	return c.Ping(ctx).Err()
}

// Session management helpers
const (
	RedisSessionPrefix       = "session:"
	RedisRefreshTokenPrefix  = "refresh:"
	RedisPasswordResetPrefix = "pwd_reset:"
	RedisMFAChallengePrefix  = "mfa_challenge:"
	RedisRateLimitPrefix     = "rate_limit:"
	RedisCachePrefix         = "cache:"
)

// SetSession stores a session with expiration
func (c *RedisClient) SetSession(ctx context.Context, token string, userID string, duration time.Duration) error {
	if ctx == nil {
		return fmt.Errorf("context cannot be nil")
	}

	if token == "" {
		return fmt.Errorf("token cannot be empty")
	}

	if userID == "" {
		return fmt.Errorf("user ID cannot be empty")
	}

	if duration <= 0 {
		return fmt.Errorf("duration must be positive")
	}

	if err := ctx.Err(); err != nil {
		return fmt.Errorf("context cancelled: %w", err)
	}

	key := RedisSessionPrefix + token
	return c.Set(ctx, key, userID, duration).Err()
}

// GetSession retrieves a session
func (c *RedisClient) GetSession(ctx context.Context, token string) (string, error) {
	key := RedisSessionPrefix + token
	return c.Get(ctx, key).Result()
}

// DeleteSession removes a session
func (c *RedisClient) DeleteSession(ctx context.Context, token string) error {
	key := RedisSessionPrefix + token
	return c.Del(ctx, key).Err()
}

// SetRefreshToken stores a refresh token
func (c *RedisClient) SetRefreshToken(ctx context.Context, token string, userID string, duration time.Duration) error {
	key := RedisRefreshTokenPrefix + token
	return c.Set(ctx, key, userID, duration).Err()
}

// GetRefreshToken retrieves a refresh token
func (c *RedisClient) GetRefreshToken(ctx context.Context, token string) (string, error) {
	key := RedisRefreshTokenPrefix + token
	return c.Get(ctx, key).Result()
}

// DeleteRefreshToken removes a refresh token
func (c *RedisClient) DeleteRefreshToken(ctx context.Context, token string) error {
	key := RedisRefreshTokenPrefix + token
	return c.Del(ctx, key).Err()
}

// SetPasswordResetToken stores a password reset token
func (c *RedisClient) SetPasswordResetToken(ctx context.Context, token string, userID string, duration time.Duration) error {
	key := RedisPasswordResetPrefix + token
	return c.Set(ctx, key, userID, duration).Err()
}

// GetPasswordResetToken retrieves a password reset token
func (c *RedisClient) GetPasswordResetToken(ctx context.Context, token string) (string, error) {
	key := RedisPasswordResetPrefix + token
	return c.Get(ctx, key).Result()
}

// SetMFAChallenge stores an MFA challenge
func (c *RedisClient) SetMFAChallenge(ctx context.Context, challengeID string, data string, duration time.Duration) error {
	key := RedisMFAChallengePrefix + challengeID
	return c.Set(ctx, key, data, duration).Err()
}

// GetMFAChallenge retrieves an MFA challenge
func (c *RedisClient) GetMFAChallenge(ctx context.Context, challengeID string) (string, error) {
	key := RedisMFAChallengePrefix + challengeID
	return c.Get(ctx, key).Result()
}

// DeleteMFAChallenge removes an MFA challenge
func (c *RedisClient) DeleteMFAChallenge(ctx context.Context, challengeID string) error {
	key := RedisMFAChallengePrefix + challengeID
	return c.Del(ctx, key).Err()
}

// CheckRateLimit checks and updates rate limit
func (c *RedisClient) CheckRateLimit(ctx context.Context, key string, limit int, window time.Duration) (bool, error) {
	if ctx == nil {
		return false, fmt.Errorf("context cannot be nil")
	}

	if key == "" {
		return false, fmt.Errorf("rate limit key cannot be empty")
	}

	if limit <= 0 {
		return false, fmt.Errorf("rate limit must be positive, got %d", limit)
	}

	if window <= 0 {
		return false, fmt.Errorf("rate limit window must be positive")
	}

	if err := ctx.Err(); err != nil {
		return false, fmt.Errorf("context cancelled: %w", err)
	}

	fullKey := RedisRateLimitPrefix + key
	count, err := c.Incr(ctx, fullKey).Result()
	if err != nil {
		return false, fmt.Errorf("failed to increment rate limit counter: %w", err)
	}

	if count == 1 {
		if err := c.Expire(ctx, fullKey, window).Err(); err != nil {
			return false, fmt.Errorf("failed to set rate limit expiration: %w", err)
		}
	}

	return count <= int64(limit), nil
}

// SetCache stores data in cache
func (c *RedisClient) SetCache(ctx context.Context, key string, value string, duration time.Duration) error {
	fullKey := RedisCachePrefix + key
	return c.Set(ctx, fullKey, value, duration).Err()
}

// GetCache retrieves data from cache
func (c *RedisClient) GetCache(ctx context.Context, key string) (string, error) {
	fullKey := RedisCachePrefix + key
	return c.Get(ctx, fullKey).Result()
}

// DeleteCache removes data from cache
func (c *RedisClient) DeleteCache(ctx context.Context, key string) error {
	fullKey := RedisCachePrefix + key
	return c.Del(ctx, fullKey).Err()
}

// InvalidateCachePattern deletes all keys matching a pattern
func (c *RedisClient) InvalidateCachePattern(ctx context.Context, pattern string) error {
	fullPattern := RedisCachePrefix + pattern
	iter := c.Scan(ctx, 0, fullPattern, 100).Iterator()
	keys := []string{}

	for iter.Next(ctx) {
		keys = append(keys, iter.Val())
	}

	if err := iter.Err(); err != nil {
		return err
	}

	if len(keys) > 0 {
		return c.Del(ctx, keys...).Err()
	}

	return nil
}

// GetConfig returns the connection configuration
func (c *RedisClient) GetConfig() RedisConfig {
	return c.config
}

// FlushDB flushes the current database
func (c *RedisClient) FlushDB(ctx context.Context) error {
	return c.Client.FlushDB(ctx).Err()
}

// RedisKeeper manages Redis connections and operations
type RedisKeeper struct {
	client *RedisClient
}

// RedisNewKeeper creates a new Redis keeper
func RedisNewKeeper(config RedisConfig) (*RedisKeeper, error) {
	client, err := RedisNewConnection(config)
	if err != nil {
		return nil, err
	}

	return &RedisKeeper{
		client: client,
	}, nil
}

// GetClient returns the underlying Redis client
func (k *RedisKeeper) GetClient() *RedisClient {
	return k.client
}

// HealthCheck performs a health check
func (k *RedisKeeper) HealthCheck(ctx context.Context) error {
	return k.client.HealthCheck(ctx)
}

// Close closes the connection
func (k *RedisKeeper) Close() error {
	log.Println("Closing Redis connection")
	return k.client.Close()
}
