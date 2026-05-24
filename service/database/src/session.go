package database

import (
	"errors"
	"fmt"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	gojson "github.com/goccy/go-json"
	"github.com/redis/go-redis/v9"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

const (
	sessionTracerName = "rice/database/session"
	sessionKeyPrefix  = "rice:session:"
)

var sessionTracer = otel.Tracer(sessionTracerName)

// Session is persisted JSON in Redis (opaque to clients except fields you choose to return).
type Session struct {
	ID        kit.UUID       `json:"id"`
	UserID    kit.UUID       `json:"user_id"`
	Data      map[string]any `json:"data,omitempty"`
	CreatedAt time.Time      `json:"created_at"`
	ExpiresAt time.Time      `json:"expires_at"`
	// WindowMS is the sliding window length in milliseconds (written on create; used on [SessionManager.Get]).
	WindowMS int64 `json:"window_ms"`
}

// SessionManager stores opaque session blobs in Redis using the same client as [Cache].
type SessionManager struct {
	Client *redis.Client
	// Prefix is prepended before [sessionKeyPrefix] when non-empty (e.g. cell or env name).
	Prefix string
}

// NewSessionManager wraps a Redis client.
func NewSessionManager(client *redis.Client) *SessionManager {
	return &SessionManager{Client: client}
}

// NewSessionManagerFromCache reuses [Cache.Client].
func NewSessionManagerFromCache(c *Cache) *SessionManager {
	if c == nil {
		return &SessionManager{}
	}
	return &SessionManager{Client: c.Client}
}

func (m *SessionManager) redisKey(sessionID kit.UUID) string {
	s := sessionID.String()
	if m.Prefix != "" {
		return fmt.Sprintf("%s%s%s", m.Prefix, sessionKeyPrefix, s)
	}
	return sessionKeyPrefix + s
}

func (m *SessionManager) nilCheck() error {
	if m == nil || m.Client == nil {
		return errors.New("database: nil session manager")
	}
	return nil
}

// sessionJSON marshals with github.com/goccy/go-json (SMITH hot-path JSON; same stack as kit/Fiber).
func sessionJSONMarshal(v any) ([]byte, error) {
	return gojson.Marshal(v)
}

func sessionJSONUnmarshal(b []byte, v any) error {
	return gojson.Unmarshal(b, v)
}

// Create issues a new session id, stores JSON in Redis with TTL, and returns the session.
func (m *SessionManager) Create(ctx *kit.Context, userID kit.UUID, ttl time.Duration) (*Session, error) {
	if err := m.nilCheck(); err != nil {
		return nil, err
	}
	if ttl <= 0 {
		return nil, kit.BadRequest("session.Create: ttl must be positive")
	}
	std, span := sessionTracer.Start(poolContext(ctx), "session.login",
		trace.WithSpanKind(trace.SpanKindServer),
		trace.WithAttributes(attribute.String("session.op", "login")),
	)
	defer span.End()

	id, err := kit.ID.New()
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, err
	}
	now := time.Now().UTC()
	ms := ttl.Milliseconds()
	if ms < 1 {
		ms = 1
	}
	s := &Session{
		ID:        id,
		UserID:    userID,
		Data:      make(map[string]any),
		CreatedAt: now,
		ExpiresAt: now.Add(ttl),
		WindowMS:  ms,
	}

	b, err := sessionJSONMarshal(s)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, kit.Internal("session.Create: marshal").Wrap(err, "gojson.Marshal")
	}

	key := m.redisKey(id)
	if err := m.Client.Set(std, key, b, ttl).Err(); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, kit.Err.Internal("session: redis SET failed").Wrap(err, "redis.SET")
	}
	span.SetAttributes(attribute.String("session.id", id.String()), attribute.String("session.user_id", userID.String()))
	return s, nil
}

// Get loads a session, extends the Redis TTL by the original window (sliding expiration), and returns it.
// Missing or expired keys yield [kit.Err.Unauthenticated].
func (m *SessionManager) Get(ctx *kit.Context, sessionID kit.UUID) (*Session, error) {
	if err := m.nilCheck(); err != nil {
		return nil, err
	}
	std, span := sessionTracer.Start(poolContext(ctx), "session.refresh",
		trace.WithSpanKind(trace.SpanKindServer),
		trace.WithAttributes(
			attribute.String("session.op", "refresh"),
			attribute.String("session.id", sessionID.String()),
		),
	)
	defer span.End()

	key := m.redisKey(sessionID)
	b, err := m.Client.Get(std, key).Bytes()
	if err == redis.Nil {
		span.SetAttributes(attribute.Bool("session.missing", true))
		return nil, kit.Err.Unauthenticated("session: missing or expired")
	}
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, kit.Err.Internal("session: redis GET failed").Wrap(err, "redis.GET")
	}

	var s Session
	if err := sessionJSONUnmarshal(b, &s); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return nil, kit.Err.Internal("session: corrupt payload").Wrap(err, "gojson.Unmarshal")
	}
	win := time.Duration(s.WindowMS) * time.Millisecond
	if win <= 0 {
		win = time.Minute
	}
	if err := m.Client.Expire(std, key, win).Err(); err != nil {
		span.RecordError(err)
		// Non-fatal for read path; session still returned
		_ = err
	}
	s.ExpiresAt = time.Now().UTC().Add(win)
	return &s, nil
}

// Update merges one key into session Data atomically (optimistic lock via Redis WATCH).
func (m *SessionManager) Update(ctx *kit.Context, sessionID kit.UUID, key string, value any) error {
	if err := m.nilCheck(); err != nil {
		return err
	}
	if key == "" {
		return kit.BadRequest("session.Update: empty key")
	}
	std, span := sessionTracer.Start(poolContext(ctx), "session.update",
		trace.WithSpanKind(trace.SpanKindServer),
		trace.WithAttributes(
			attribute.String("session.op", "update"),
			attribute.String("session.id", sessionID.String()),
			attribute.String("session.data_key", key),
		),
	)
	defer span.End()

	rkey := m.redisKey(sessionID)
	const maxWatch = 8
	var lastErr error
	for attempt := 0; attempt < maxWatch; attempt++ {
		err := m.Client.Watch(std, func(tx *redis.Tx) error {
			b, err := tx.Get(std, rkey).Bytes()
			if err == redis.Nil {
				return kit.Err.Unauthenticated("session: missing or expired")
			}
			if err != nil {
				return kit.Err.Internal("session: redis GET failed").Wrap(err, "redis.GET")
			}
			var s Session
			if err := sessionJSONUnmarshal(b, &s); err != nil {
				return kit.Err.Internal("session: corrupt payload").Wrap(err, "gojson.Unmarshal")
			}
			if s.Data == nil {
				s.Data = make(map[string]any)
			}
			s.Data[key] = value
			out, err := sessionJSONMarshal(&s)
			if err != nil {
				return kit.Internal("session.Update: marshal").Wrap(err, "gojson.Marshal")
			}
			_, err = tx.TxPipelined(std, func(p redis.Pipeliner) error {
				return p.Set(std, rkey, out, redis.KeepTTL).Err()
			})
			return err
		}, rkey)
		if err == nil {
			return nil
		}
		if errors.Is(err, redis.TxFailedErr) {
			lastErr = err
			continue
		}
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return err
	}
	if lastErr != nil {
		span.RecordError(lastErr)
	}
	span.SetStatus(codes.Error, "watch retries exhausted")
	return kit.Err.Conflict("session: concurrent update conflict")
}

// Revoke deletes a session immediately.
func (m *SessionManager) Revoke(ctx *kit.Context, sessionID kit.UUID) error {
	if err := m.nilCheck(); err != nil {
		return err
	}
	std, span := sessionTracer.Start(poolContext(ctx), "session.logout",
		trace.WithSpanKind(trace.SpanKindServer),
		trace.WithAttributes(
			attribute.String("session.op", "logout"),
			attribute.String("session.id", sessionID.String()),
		),
	)
	defer span.End()

	if err := m.Client.Del(std, m.redisKey(sessionID)).Err(); err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
		return kit.Err.Internal("session: redis DEL failed").Wrap(err, "redis.DEL")
	}
	return nil
}
