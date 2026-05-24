package database

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"runtime"
	"strings"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	lru "github.com/hashicorp/golang-lru/v2"
	"github.com/redis/go-redis/v9"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	"golang.org/x/sync/singleflight"
	grpcCodes "google.golang.org/grpc/codes"
)

const (
	cacheTracerName   = "rice/database/cache"
	metadataKeyPrefix = "smith:meta:"
	defaultL1Size     = 8192
	redisOpAttr       = "db.redis.operation"
	redisKeyAttr      = "db.redis.key"
	cacheLevelAttr    = "cache.level"
	cacheHitAttr      = "cache.hit"
)

// l1Entry is a JSON payload and optional local expiry aligned with Redis TTL.
type l1Entry struct {
	b      []byte
	expiry time.Time // zero means no TTL (evicted by LRU only)
}

// Cache is a hybrid L1 (in-process LRU) + L2 (Redis) JSON cache.
// go-redis maintains its connection pool and retries; L1 is invalidated on Delete,
// Increment, and successful Set. Optional CLIENT TRACKING ON NOLOOP is enabled
// on connect when the server supports it (best-effort; failures are ignored).
type Cache struct {
	Client *redis.Client
	l1     *lru.Cache[string, *l1Entry]
	sf     singleflight.Group
}

var cacheTracer = otel.Tracer(cacheTracerName)

// NewCache builds a Redis v9 client with tuned pool/timeouts and an L1 LRU.
func NewCache(addr, password string, db int) *Cache {
	n := runtime.GOMAXPROCS(0)
	if n < 1 {
		n = 1
	}
	poolSize := n * 16
	if poolSize < 32 {
		poolSize = 32
	}
	if poolSize > 256 {
		poolSize = 256
	}
	minIdle := n * 2
	if minIdle < 4 {
		minIdle = 4
	}
	if minIdle > 32 {
		minIdle = 32
	}

	rdb := redis.NewClient(&redis.Options{
		Addr:                  addr,
		Password:              password,
		DB:                    db,
		PoolSize:              poolSize,
		MinIdleConns:          minIdle,
		PoolTimeout:           8 * time.Second,
		DialTimeout:           5 * time.Second,
		ReadTimeout:           3 * time.Second,
		WriteTimeout:          3 * time.Second,
		MaxRetries:            3,
		MinRetryBackoff:       8 * time.Millisecond,
		MaxRetryBackoff:       512 * time.Millisecond,
		ContextTimeoutEnabled: true,
		OnConnect: func(ctx context.Context, cn *redis.Conn) error {
			// Client-side tracking (invalidation channel); ignore if unsupported.
			cmd := redis.NewStatusCmd(ctx, "CLIENT", "TRACKING", "ON", "NOLOOP")
			_ = cn.Process(ctx, cmd)
			_ = cmd.Err()
			return nil
		},
	})

	l1, err := lru.NewWithEvict[string, *l1Entry](defaultL1Size, nil)
	if err != nil {
		l1, _ = lru.NewWithEvict[string, *l1Entry](1024, nil)
	}
	return &Cache{Client: rdb, l1: l1}
}

func cacheCtx(kctx *kit.Context) context.Context {
	if kctx == nil {
		return context.Background()
	}
	return kctx
}

func (c *Cache) nilCheck() error {
	if c == nil || c.Client == nil {
		return errors.New("database: nil cache")
	}
	return nil
}

func cacheWrapRedis(op string, err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, redis.Nil) {
		return kit.Err.NotFound("cache: key not found")
	}
	return kit.New("DATABASE_CACHE_FAILED", err.Error(), http.StatusInternalServerError, grpcCodes.Internal).
		Wrap(err, op)
}

func isNotFound(err error) bool {
	var ke *kit.Error
	return errors.As(err, &ke) && ke != nil && ke.Code == "NOT_FOUND"
}

func (e *l1Entry) expired() bool {
	return !e.expiry.IsZero() && time.Now().After(e.expiry)
}

func l1Deadline(ttl time.Duration) time.Time {
	if ttl <= 0 {
		return time.Time{}
	}
	return time.Now().Add(ttl)
}

func redisSpan(ctx context.Context, op, key string) (context.Context, trace.Span) {
	ctx, span := cacheTracer.Start(ctx, "redis."+strings.ToUpper(op))
	span.SetAttributes(
		attribute.String(redisOpAttr, op),
		attribute.String(redisKeyAttr, key),
		attribute.String(cacheLevelAttr, "L2"),
	)
	return ctx, span
}

func endSpan(span trace.Span, err error) {
	if span == nil {
		return
	}
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
	}
	span.End()
}

// redisTTL runs TTL with an OTel span (separate round-trip after GET backfill).
func (c *Cache) redisTTL(ctx context.Context, key string) time.Duration {
	ctx2, span := redisSpan(ctx, "TTL", key)
	d, err := c.Client.TTL(ctx2, key).Result()
	endSpan(span, err)
	if err != nil {
		return -1
	}
	return d
}

// Get reads JSON from L1 then Redis; on L2 hit backfills L1. Missing keys return [kit.Err.NotFound].
func (c *Cache) Get(kctx *kit.Context, key string, dest any) error {
	if err := c.nilCheck(); err != nil {
		return err
	}
	if dest == nil {
		return kit.Internal("cache.Get: nil destination")
	}
	ctx := cacheCtx(kctx)

	if c.l1 != nil {
		if ent, ok := c.l1.Get(key); ok && ent != nil && !ent.expired() {
			_, span := cacheTracer.Start(ctx, "cache.Get")
			span.SetAttributes(
				attribute.String(cacheLevelAttr, "L1"),
				attribute.Bool(cacheHitAttr, true),
			)
			if err := json.Unmarshal(ent.b, dest); err != nil {
				endSpan(span, err)
				return kit.New("DATABASE_CACHE_FAILED", "cache: corrupt L1 JSON", http.StatusInternalServerError, grpcCodes.Internal).
					Wrap(err, "json.Unmarshal")
			}
			span.End()
			return nil
		}
	}

	ctx2, span := redisSpan(ctx, "GET", key)
	val, err := c.Client.Get(ctx2, key).Result()
	if err == nil {
		span.SetAttributes(attribute.Bool(cacheHitAttr, true))
	} else {
		span.SetAttributes(attribute.Bool(cacheHitAttr, false))
	}
	endSpan(span, err)

	if err != nil {
		if errors.Is(err, redis.Nil) {
			_, s := cacheTracer.Start(ctx, "cache.Get")
			s.SetAttributes(attribute.String(cacheLevelAttr, "L2"), attribute.Bool(cacheHitAttr, false))
			s.End()
			return kit.Err.NotFound("cache: key not found")
		}
		return cacheWrapRedis("redis.GET", err)
	}

	_, hitSpan := cacheTracer.Start(ctx, "cache.Get")
	hitSpan.SetAttributes(attribute.String(cacheLevelAttr, "L2"), attribute.Bool(cacheHitAttr, true))
	hitSpan.End()

	b := append([]byte(nil), val...)
	if err := json.Unmarshal(b, dest); err != nil {
		return kit.New("DATABASE_CACHE_FAILED", "cache: invalid JSON in Redis", http.StatusInternalServerError, grpcCodes.Internal).
			Wrap(err, "json.Unmarshal")
	}
	if c.l1 != nil {
		ttl := c.redisTTL(ctx, key)
		var exp time.Time
		if ttl > 0 {
			exp = time.Now().Add(ttl)
		}
		_ = c.l1.Add(key, &l1Entry{b: b, expiry: exp})
	}
	return nil
}

// Set writes JSON to L1 and Redis together.
func (c *Cache) Set(kctx *kit.Context, key string, value any, ttl time.Duration) error {
	if err := c.nilCheck(); err != nil {
		return err
	}
	b, err := kit.ToBytes(value)
	if err != nil {
		return err
	}
	ctx := cacheCtx(kctx)
	ctx2, span := redisSpan(ctx, "SET", key)
	rerr := c.Client.Set(ctx2, key, b, ttl).Err()
	endSpan(span, rerr)
	if rerr != nil {
		return cacheWrapRedis("redis.SET", rerr)
	}
	if c.l1 != nil {
		_ = c.l1.Add(key, &l1Entry{b: append([]byte(nil), b...), expiry: l1Deadline(ttl)})
	}
	return nil
}

// Delete removes keys from L1 and Redis.
func (c *Cache) Delete(kctx *kit.Context, keys ...string) error {
	if err := c.nilCheck(); err != nil {
		return err
	}
	if len(keys) == 0 {
		return nil
	}
	ctx := cacheCtx(kctx)
	if c.l1 != nil {
		for _, k := range keys {
			c.l1.Remove(k)
		}
	}
	ctx2, span := redisSpan(ctx, "DEL", strings.Join(keys, ","))
	rerr := c.Client.Del(ctx2, keys...).Err()
	endSpan(span, rerr)
	if rerr != nil {
		return cacheWrapRedis("redis.DEL", rerr)
	}
	return nil
}

// Increment runs Redis INCR and drops any L1 entry for the key (atomic on server).
func (c *Cache) Increment(kctx *kit.Context, key string) (int64, error) {
	if err := c.nilCheck(); err != nil {
		return 0, err
	}
	ctx := cacheCtx(kctx)
	if c.l1 != nil {
		c.l1.Remove(key)
	}
	ctx2, span := redisSpan(ctx, "INCR", key)
	n, err := c.Client.Incr(ctx2, key).Result()
	endSpan(span, err)
	if err != nil {
		return 0, cacheWrapRedis("redis.INCR", err)
	}
	return n, nil
}

// Fetch is get-or-set: on miss runs generator once per key (singleflight), stores at ttl, fills dest.
func (c *Cache) Fetch(kctx *kit.Context, key string, ttl time.Duration, dest any, generator func() (any, error)) error {
	if err := c.nilCheck(); err != nil {
		return err
	}
	if dest == nil {
		return kit.Internal("cache.Fetch: nil destination")
	}
	if getErr := c.Get(kctx, key, dest); getErr == nil {
		return nil
	} else if !isNotFound(getErr) {
		return getErr
	}
	v, err, _ := c.sf.Do(key, func() (any, error) {
		val, gerr := generator()
		if gerr != nil {
			return nil, gerr
		}
		if serr := c.Set(kctx, key, val, ttl); serr != nil {
			return nil, serr
		}
		return val, nil
	})
	if err != nil {
		return err
	}
	b, err := kit.ToBytes(v)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(b, dest); err != nil {
		return kit.New("DATABASE_CACHE_FAILED", "cache.Fetch: decode generated value", http.StatusInternalServerError, grpcCodes.Internal).
			Wrap(err, "json.Unmarshal")
	}
	return nil
}

// SetMetadata stores file-style metadata as JSON (via [kit.ToBytes]) under a reserved key namespace.
func (c *Cache) SetMetadata(kctx *kit.Context, key string, meta map[string]any, ttl time.Duration) error {
	if meta == nil {
		return kit.BadRequest("cache.SetMetadata: nil metadata map")
	}
	return c.Set(kctx, metadataRedisKey(key), meta, ttl)
}

// GetMetadata loads metadata written with [Cache.SetMetadata] into dest (JSON decode).
func (c *Cache) GetMetadata(kctx *kit.Context, key string, dest any) error {
	return c.Get(kctx, metadataRedisKey(key), dest)
}

func metadataRedisKey(key string) string {
	return metadataKeyPrefix + key
}

// GetString returns the raw Redis payload for key from L1/L2 without JSON decoding.
// Prefer [Cache.Get] with a typed destination for JSON values.
func (c *Cache) GetString(ctx context.Context, key string) (string, error) {
	kctx := kit.FromContext(ctx)
	b, err := c.getBytes(kctx, key)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

// SetContext calls [Cache.Set] with [kit.FromContext](ctx).
func (c *Cache) SetContext(ctx context.Context, key string, value any, ttl time.Duration) error {
	return c.Set(kit.FromContext(ctx), key, value, ttl)
}

func (c *Cache) getBytes(kctx *kit.Context, key string) ([]byte, error) {
	if err := c.nilCheck(); err != nil {
		return nil, err
	}
	ctx := cacheCtx(kctx)

	if c.l1 != nil {
		if ent, ok := c.l1.Get(key); ok && ent != nil && !ent.expired() {
			return append([]byte(nil), ent.b...), nil
		}
	}
	ctx2, span := redisSpan(ctx, "GET", key)
	val, err := c.Client.Get(ctx2, key).Result()
	if err == nil {
		span.SetAttributes(attribute.Bool(cacheHitAttr, true))
	} else {
		span.SetAttributes(attribute.Bool(cacheHitAttr, false))
	}
	endSpan(span, err)
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, kit.Err.NotFound("cache: key not found")
		}
		return nil, cacheWrapRedis("redis.GET", err)
	}
	b := []byte(val)
	if c.l1 != nil {
		ttl := c.redisTTL(ctx, key)
		var exp time.Time
		if ttl > 0 {
			exp = time.Now().Add(ttl)
		}
		_ = c.l1.Add(key, &l1Entry{b: append([]byte(nil), b...), expiry: exp})
	}
	return b, nil
}

// Del removes keys using [kit.FromContext](ctx).
func (c *Cache) Del(ctx context.Context, keys ...string) error {
	return c.Delete(kit.FromContext(ctx), keys...)
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
