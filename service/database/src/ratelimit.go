package database

import (
	"context"
	"fmt"
	"strconv"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/redis/go-redis/v9"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

const (
	rateTracerName = "rice/database/ratelimit"

	// DefaultDBHeavyLimit / DefaultDBHeavyWindow throttle [RateLimiter.LimitDatabaseAccess] per service.
	// Tune via deployment config when this package exposes env hooks.
	DefaultDBHeavyLimit  = 200
	DefaultDBHeavyWindow = time.Second
)

var (
	rateTracer      = otel.Tracer(rateTracerName)
	rateLimitScript = redis.NewScript(`
-- Fixed window: INCR + PEXPIRE on first hit; deny when count exceeds limit (atomic).
local c = redis.call('INCR', KEYS[1])
if c == 1 then
  redis.call('PEXPIRE', KEYS[1], tonumber(ARGV[2]))
end
if c > tonumber(ARGV[1]) then
  return 0
end
return 1
`)
)

// RateLimiter is a distributed fixed-window counter backed by Redis (same client as [Cache]).
type RateLimiter struct {
	Client *redis.Client
	// Prefix namespaces keys, e.g. deployment or cell name (optional).
	Prefix string
}

// NewRateLimiter wraps a shared Redis client.
func NewRateLimiter(client *redis.Client) *RateLimiter {
	return &RateLimiter{Client: client}
}

// NewRateLimiterFromCache reuses [Cache.Client].
func NewRateLimiterFromCache(c *Cache) *RateLimiter {
	if c == nil {
		return &RateLimiter{}
	}
	return &RateLimiter{Client: c.Client}
}

func (r *RateLimiter) redisKey(key string) string {
	if r.Prefix != "" {
		return fmt.Sprintf("%s:ratelimit:%s", r.Prefix, key)
	}
	return "smith:ratelimit:" + key
}

// Allow reports whether one more action is allowed for key inside a fixed window of length window.
// limit is the maximum number of allowed actions per window (must be > 0 to enforce).
// Uses a single Lua script (EVALSHA) for INCR + PEXPIRE + compare — one round-trip after script load.
//
// Fail-open: on Redis errors or a nil client, the call returns (true, nil) and logs at error level
// so availability beats strict limiting.
func (r *RateLimiter) Allow(ctx *kit.Context, key string, limit int, window time.Duration) (bool, error) {
	std, span := rateTracer.Start(poolContext(ctx), "ratelimit.Allow")
	defer span.End()
	span.SetAttributes(
		attribute.String("ratelimit.key", key),
		attribute.Int("ratelimit.limit", limit),
		attribute.Int64("ratelimit.window_ms", window.Milliseconds()),
	)
	return r.evalAllow(std, span, key, limit, window)
}

// LimitDatabaseAccess applies a default per-service cap on database-heavy work (see [DefaultDBHeavyLimit]).
func (r *RateLimiter) LimitDatabaseAccess(ctx *kit.Context, serviceName string) (bool, error) {
	std, span := rateTracer.Start(poolContext(ctx), "ratelimit.LimitDatabaseAccess")
	defer span.End()
	span.SetAttributes(attribute.String("ratelimit.service", serviceName))
	key := fmt.Sprintf("dbHeavy:%s", serviceName)
	span.SetAttributes(
		attribute.String("ratelimit.key", key),
		attribute.Int("ratelimit.limit", DefaultDBHeavyLimit),
		attribute.Int64("ratelimit.window_ms", DefaultDBHeavyWindow.Milliseconds()),
	)
	return r.evalAllow(std, span, key, DefaultDBHeavyLimit, DefaultDBHeavyWindow)
}

func (r *RateLimiter) evalAllow(std context.Context, span trace.Span, key string, limit int, window time.Duration) (bool, error) {
	if limit <= 0 {
		span.SetAttributes(attribute.Bool("ratelimit.no_op", true))
		return true, nil
	}
	if window <= 0 {
		span.SetAttributes(attribute.Bool("ratelimit.no_op", true))
		return true, nil
	}

	if r == nil || r.Client == nil {
		span.SetAttributes(attribute.Bool("ratelimit.fail_open", true))
		kit.Logger().ErrorContext(std, "ratelimit: nil client, fail-open",
			"key", key, "limit", limit, "window", window.String())
		return true, nil
	}

	ms := window / time.Millisecond
	if ms < 1 {
		ms = 1
	}

	rkey := r.redisKey(key)
	span.SetAttributes(attribute.String("db.redis.key", rkey))

	v, err := rateLimitScript.Run(std, r.Client, []string{rkey},
		strconv.Itoa(limit), strconv.FormatInt(int64(ms), 10)).Int()
	if err != nil {
		span.RecordError(err)
		span.SetAttributes(attribute.Bool("ratelimit.fail_open", true))
		kit.Logger().ErrorContext(std, "ratelimit: CRITICAL redis error, fail-open (availability over strict limiting)",
			"key", key, "err", err)
		return true, nil
	}

	allowed := v == 1
	if !allowed {
		span.SetAttributes(attribute.Bool("ratelimit.blocked", true))
		kit.Logger().WarnContext(std, "ratelimit: blocked",
			"key", key, "limit", limit, "window", window.String())
	}
	return allowed, nil
}
