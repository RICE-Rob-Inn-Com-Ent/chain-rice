package database

// TODO:
// [ ] implement session store via Valkey:
//     NewSession(ctx, userID string) (sessionID string, error)
//     GetSession(ctx, sessionID string) (Session, error)
//     DeleteSession(ctx, sessionID string) error
// [ ] implement session TTL:
//     default TTL from RICE_SESSION_TTL_S env var
//     sliding window: extend TTL on every access
// [ ] implement session data:
//     Session struct: UserID, Roles, Claims, CreatedAt, ExpiresAt
//     serialized as JSON in Valkey — never store sensitive data

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// SessionStore is user session state in Valkey (opaque blobs; PASETO/JWT ids live as keys).
type SessionStore struct {
	Client *redis.Client
	Prefix string
}

// SessionData is an example payload; replace with proto/json from your auth contract.
type SessionData struct {
	UserID    string    `json:"user_id"`
	CreatedAt time.Time `json:"created_at"`
}

func sessionKey(prefix, sid string) string {
	return fmt.Sprintf("%s:session:%s", prefix, sid)
}

func blacklistKey(prefix, jti string) string {
	return fmt.Sprintf("%s:blacklist:%s", prefix, jti)
}

// CreateSession stores a session id → JSON blob with TTL.
func (s *SessionStore) CreateSession(ctx context.Context, ttl time.Duration, data SessionData) (sessionID string, err error) {
	if s == nil || s.Client == nil {
		return "", errors.New("database: nil session store")
	}
	sessionID = uuid.NewString()
	b, err := json.Marshal(data)
	if err != nil {
		return "", err
	}
	key := sessionKey(s.Prefix, sessionID)
	return sessionID, s.Client.Set(ctx, key, b, ttl).Err()
}

// GetSession loads session JSON.
func (s *SessionStore) GetSession(ctx context.Context, sessionID string) (*SessionData, error) {
	if s == nil || s.Client == nil {
		return nil, errors.New("database: nil session store")
	}
	key := sessionKey(s.Prefix, sessionID)
	b, err := s.Client.Get(ctx, key).Bytes()
	if err != nil {
		return nil, err
	}
	var out SessionData
	if err := json.Unmarshal(b, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

// DeleteSession removes a session.
func (s *SessionStore) DeleteSession(ctx context.Context, sessionID string) error {
	if s == nil || s.Client == nil {
		return errors.New("database: nil session store")
	}
	return s.Client.Del(ctx, sessionKey(s.Prefix, sessionID)).Err()
}

// BlacklistToken marks a token id (e.g. PASETO jti) as revoked until expiry.
func (s *SessionStore) BlacklistToken(ctx context.Context, jti string, ttl time.Duration) error {
	if s == nil || s.Client == nil {
		return errors.New("database: nil session store")
	}
	return s.Client.Set(ctx, blacklistKey(s.Prefix, jti), "1", ttl).Err()
}

// IsTokenBlacklisted returns true if jti is blocked.
func (s *SessionStore) IsTokenBlacklisted(ctx context.Context, jti string) (bool, error) {
	if s == nil || s.Client == nil {
		return false, errors.New("database: nil session store")
	}
	n, err := s.Client.Exists(ctx, blacklistKey(s.Prefix, jti)).Result()
	if err != nil {
		return false, err
	}
	return n > 0, nil
}
