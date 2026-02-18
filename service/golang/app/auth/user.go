package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
)

// User represents a user in the system
type User struct {
	ID        string    `json:"id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	Password  string    `json:"-"` // Never serialize password
	Roles     []string  `json:"roles"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// UserRepository defines the interface for user storage
type UserRepository interface {
	Create(ctx context.Context, user *User) error
	FindByID(ctx context.Context, id string) (*User, error)
	FindByEmail(ctx context.Context, email string) (*User, error)
	Update(ctx context.Context, user *User) error
	Delete(ctx context.Context, id string) error
}

// UserService handles user operations
type UserService struct {
	repo   UserRepository
	logger *zap.SugaredLogger
}

// NewUserService creates a new user service
func NewUserService(repo UserRepository, logger *zap.SugaredLogger) *UserService {
	if logger == nil {
		zapLogger, _ := zap.NewProduction()
		logger = zapLogger.Sugar()
	}

	return &UserService{
		repo:   repo,
		logger: logger,
	}
}

// CreateUser creates a new user
func (s *UserService) CreateUser(ctx context.Context, email, name, password string) (*User, error) {
	if email == "" {
		return nil, errors.New("email is required")
	}
	if password == "" {
		return nil, errors.New("password is required")
	}

	// Check if user already exists
	existing, _ := s.repo.FindByEmail(ctx, email)
	if existing != nil {
		return nil, errors.New("user with this email already exists")
	}

	// Hash password (in production, use bcrypt or argon2)
	hashedPassword, err := hashPassword(password)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	user := &User{
		ID:        uuid.New().String(),
		Email:     email,
		Name:      name,
		Password:  hashedPassword,
		Roles:     []string{"user"},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := s.repo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Clear password before returning
	user.Password = ""
	return user, nil
}

// AuthenticateUser authenticates a user with email and password
func (s *UserService) AuthenticateUser(ctx context.Context, email, password string) (*User, error) {
	if email == "" || password == "" {
		return nil, errors.New("email and password are required")
	}

	user, err := s.repo.FindByEmail(ctx, email)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	if !checkPasswordHash(password, user.Password) {
		return nil, errors.New("invalid credentials")
	}

	// Clear password before returning
	user.Password = ""
	return user, nil
}

// GetUser retrieves a user by ID
func (s *UserService) GetUser(ctx context.Context, id string) (*User, error) {
	if id == "" {
		return nil, errors.New("user ID is required")
	}

	user, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}

	// Clear password before returning
	user.Password = ""
	return user, nil
}

// UpdateUser updates user information
func (s *UserService) UpdateUser(ctx context.Context, user *User) error {
	if user.ID == "" {
		return errors.New("user ID is required")
	}

	user.UpdatedAt = time.Now()
	return s.repo.Update(ctx, user)
}

// DeleteUser deletes a user
func (s *UserService) DeleteUser(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("user ID is required")
	}

	return s.repo.Delete(ctx, id)
}
