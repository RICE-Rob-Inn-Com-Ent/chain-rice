package auth

import (
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"go.uber.org/zap"
)

// JWTService handles JWT token operations
type JWTService struct {
	secretKey     []byte
	accessExpiry  time.Duration
	refreshExpiry time.Duration
	logger        *zap.SugaredLogger
}

// Claims represents JWT claims
type Claims struct {
	UserID    string   `json:"user_id"`
	Email     string   `json:"email"`
	Roles     []string `json:"roles"`
	TokenType string   `json:"token_type"` // "access" or "refresh"
	jwt.RegisteredClaims
}

// JWTConfig holds JWT configuration
type JWTConfig struct {
	SecretKey     string
	AccessExpiry  time.Duration
	RefreshExpiry time.Duration
	Logger        *zap.SugaredLogger
}

// NewJWTService creates a new JWT service
func NewJWTService(cfg JWTConfig) (*JWTService, error) {
	secretKey := cfg.SecretKey
	if secretKey == "" {
		secretKey = os.Getenv("JWT_SECRET_KEY")
		if secretKey == "" {
			return nil, errors.New("JWT secret key is required")
		}
	}

	if len(secretKey) < 32 {
		return nil, errors.New("JWT secret key must be at least 32 characters")
	}

	accessExpiry := cfg.AccessExpiry
	if accessExpiry == 0 {
		accessExpiry = 15 * time.Minute
	}

	refreshExpiry := cfg.RefreshExpiry
	if refreshExpiry == 0 {
		refreshExpiry = 7 * 24 * time.Hour // 7 days
	}

	logger := cfg.Logger
	if logger == nil {
		zapLogger, _ := zap.NewProduction()
		logger = zapLogger.Sugar()
	}

	return &JWTService{
		secretKey:     []byte(secretKey),
		accessExpiry:  accessExpiry,
		refreshExpiry: refreshExpiry,
		logger:        logger,
	}, nil
}

// GenerateAccessToken generates an access token
func (s *JWTService) GenerateAccessToken(userID, email string, roles []string) (string, error) {
	claims := &Claims{
		UserID:    userID,
		Email:     email,
		Roles:     roles,
		TokenType: "access",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.accessExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "rice-backend",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secretKey)
}

// GenerateRefreshToken generates a refresh token
func (s *JWTService) GenerateRefreshToken(userID, email string, roles []string) (string, error) {
	claims := &Claims{
		UserID:    userID,
		Email:     email,
		Roles:     roles,
		TokenType: "refresh",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.refreshExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "rice-backend",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secretKey)
}

// ValidateToken validates a JWT token and returns claims
func (s *JWTService) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.secretKey, nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	// Check if token is expired
	if claims.ExpiresAt != nil && time.Now().After(claims.ExpiresAt.Time) {
		return nil, errors.New("token is expired")
	}

	return claims, nil
}

// ValidateAccessToken validates an access token
func (s *JWTService) ValidateAccessToken(tokenString string) (*Claims, error) {
	claims, err := s.ValidateToken(tokenString)
	if err != nil {
		return nil, err
	}

	if claims.TokenType != "access" {
		return nil, errors.New("token is not an access token")
	}

	return claims, nil
}

// ValidateRefreshToken validates a refresh token
func (s *JWTService) ValidateRefreshToken(tokenString string) (*Claims, error) {
	claims, err := s.ValidateToken(tokenString)
	if err != nil {
		return nil, err
	}

	if claims.TokenType != "refresh" {
		return nil, errors.New("token is not a refresh token")
	}

	return claims, nil
}
