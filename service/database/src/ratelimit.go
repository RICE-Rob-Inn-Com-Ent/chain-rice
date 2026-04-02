package database

// TODO:
// [ ] implement distributed rate limiting via Valkey:
//     Allow(ctx, key string, limit int, window time.Duration) (bool, error)
//     sliding window algorithm via Valkey sorted sets
// [ ] implement rate limit tiers:
//     per-IP, per-user, per-service rate limits
//     limits from RICE_RATE_LIMIT_* env vars — never hardcoded
// [ ] implement rate limit headers:
//     X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
//     added by bench/middleware.go

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// RateLimiter implements sliding-window and fixed-window counters in Valkey.
type RateLimiter struct {
	Client *redis.Client
	Prefix string
}

func rateKey(prefix, subject, window string) string {
	return fmt.Sprintf("%s:rl:%s:%s", prefix, subject, window)
}

// AllowSlidingWindow increments a key with TTL windowMs; returns false if count exceeds limit.
func (r *RateLimiter) AllowSlidingWindow(ctx context.Context, subject string, limit int64, window time.Duration) (bool, int64, error) {
	if r == nil || r.Client == nil {
		return false, 0, errors.New("database: nil rate limiter")
	}
	key := rateKey(r.Prefix, subject, "slide")
	pipe := r.Client.Pipeline()
	incr := pipe.Incr(ctx, key)
	pipe.Expire(ctx, key, window)
	if _, err := pipe.Exec(ctx); err != nil {
		return false, 0, err
	}
	n := incr.Val()
	if n > limit {
		return false, n, nil
	}
	return true, n, nil
}

// AllowTokenBucket is a simple refill using INCR + EXPIRE (approximation; tune for production).
func (r *RateLimiter) AllowTokenBucket(ctx context.Context, subject string, capacity int64, refillInterval time.Duration) (bool, error) {
	if r == nil || r.Client == nil {
		return false, errors.New("database: nil rate limiter")
	}
	key := rateKey(r.Prefix, subject, "bucket")
	n, err := r.Client.Incr(ctx, key).Result()
	if err != nil {
		return false, err
	}
	if n == 1 {
		_ = r.Client.Expire(ctx, key, refillInterval).Err()
	}
	if n > capacity {
		return false, nil
	}
	return true, nil
}
