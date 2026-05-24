package auth

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"strings"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	kratos "github.com/ory/kratos-client-go"
	"github.com/redis/go-redis/v9"
)

// DefaultSessionCacheTTL is used when [SessionManager.TTL] is zero.
const DefaultSessionCacheTTL = 45 * time.Second

// SessionManager keeps a hot copy of Kratos sessions in Redis (keyed by cookie digest) for low-latency reads.
type SessionManager struct {
	Kratos *Kratos
	RDB    *redis.Client

	// Prefix namespaces Redis keys (e.g. "auth:kratos:").
	Prefix string

	// TTL for cached session JSON; defaults to [DefaultSessionCacheTTL] when zero.
	TTL time.Duration
}

func (m *SessionManager) ttl() time.Duration {
	if m == nil || m.TTL <= 0 {
		return DefaultSessionCacheTTL
	}
	return m.TTL
}

func (m *SessionManager) prefix() string {
	if m == nil || strings.TrimSpace(m.Prefix) == "" {
		return "auth:kratos:"
	}
	return m.Prefix
}

func (m *SessionManager) cookieCacheKey(cookie string) string {
	sum := sha256.Sum256([]byte(cookie))
	return m.prefix() + "c:" + hex.EncodeToString(sum[:])
}

func (m *SessionManager) userIndexKey(identityID string) string {
	return m.prefix() + "user:" + identityID + ":keys"
}

// GetSession returns the Kratos session for the browser cookie, consulting Redis before calling Kratos.
func (m *SessionManager) GetSession(ctx *kit.Context, cookie string) (*kratos.Session, *kit.Error) {
	if m == nil || m.Kratos == nil {
		return nil, kratosKitErr(ctx, kit.Internal("auth.session: nil session manager or kratos client"))
	}
	if m.RDB == nil {
		return m.Kratos.GetSession(ctx, cookie)
	}
	gctx := kratosGoCtx(ctx)
	cacheKey := m.cookieCacheKey(cookie)
	if raw, err := m.RDB.Get(gctx, cacheKey).Result(); err == nil && raw != "" {
		var cached kratos.Session
		if json.Unmarshal([]byte(raw), &cached) == nil && strings.TrimSpace(cached.Id) != "" {
			return &cached, nil
		}
	} else if err != nil && err != redis.Nil {
		return nil, kratosKitErr(ctx, kit.Internal("auth.session: redis get: "+err.Error()))
	}
	sess, kerr := m.Kratos.GetSession(ctx, cookie)
	if kerr != nil {
		return nil, kerr
	}
	if err := m.writeSessionCache(gctx, cacheKey, sess); err != nil {
		return nil, kratosKitErr(ctx, kit.Internal("auth.session: redis set: "+err.Error()))
	}
	return sess, nil
}

func (m *SessionManager) writeSessionCache(gctx context.Context, cacheKey string, sess *kratos.Session) error {
	if sess == nil {
		return nil
	}
	payload, err := json.Marshal(sess)
	if err != nil {
		return err
	}
	pipe := m.RDB.TxPipeline()
	pipe.Set(gctx, cacheKey, payload, m.ttl())
	if sess.HasIdentity() {
		id := strings.TrimSpace(sess.GetIdentity().Id)
		if id != "" {
			pipe.SAdd(gctx, m.userIndexKey(id), cacheKey)
			pipe.Expire(gctx, m.userIndexKey(id), m.ttl()*4)
		}
	}
	_, err = pipe.Exec(gctx)
	return err
}

// RevokeSession deletes all active Kratos sessions for the identity userID and purges related Redis cache entries.
// userID must be the Kratos identity id (same value passed to [Kratos.UpdateIdentity]).
func (m *SessionManager) RevokeSession(ctx *kit.Context, userID string) *kit.Error {
	if strings.TrimSpace(userID) == "" {
		return kratosKitErr(ctx, kit.BadRequest("auth.session: empty user id"))
	}
	if m == nil || m.Kratos == nil || m.Kratos.Client == nil {
		return kratosKitErr(ctx, kit.Internal("auth.session: nil session manager or kratos client"))
	}
	gctx := kratosGoCtx(ctx)
	if m.RDB != nil {
		indexKey := m.userIndexKey(userID)
		keys, err := m.RDB.SMembers(gctx, indexKey).Result()
		if err != nil && err != redis.Nil {
			return kratosKitErr(ctx, kit.Internal("auth.session: redis smembers: "+err.Error()))
		}
		toDel := append([]string{indexKey}, keys...)
		if err := m.RDB.Del(gctx, toDel...).Err(); err != nil {
			return kratosKitErr(ctx, kit.Internal("auth.session: redis del: "+err.Error()))
		}
	}
	resp, err := m.Kratos.Client.IdentityAPI.DeleteIdentitySessions(gctx, userID).Execute()
	if err != nil {
		return kratosOryErr(ctx, "auth.session", resp, err)
	}
	return nil
}
