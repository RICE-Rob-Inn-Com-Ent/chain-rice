package auth

import (
	"context"
	"errors"
	"sync"
	"time"
)

// InMemoryUserRepository is an in-memory user repository (for development/testing)
type InMemoryUserRepository struct {
	users map[string]*User
	mu    sync.RWMutex
}

// NewInMemoryUserRepository creates a new in-memory user repository
func NewInMemoryUserRepository() *InMemoryUserRepository {
	return &InMemoryUserRepository{
		users: make(map[string]*User),
	}
}

// Create creates a new user
func (r *InMemoryUserRepository) Create(ctx context.Context, user *User) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Check if user already exists
	if _, exists := r.users[user.ID]; exists {
		return errors.New("user already exists")
	}

	// Check if email already exists
	for _, u := range r.users {
		if u.Email == user.Email {
			return errors.New("user with this email already exists")
		}
	}

	r.users[user.ID] = user
	return nil
}

// FindByID finds a user by ID
func (r *InMemoryUserRepository) FindByID(ctx context.Context, id string) (*User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	user, exists := r.users[id]
	if !exists {
		return nil, errors.New("user not found")
	}

	// Return a copy to prevent external modifications
	userCopy := *user
	return &userCopy, nil
}

// FindByEmail finds a user by email
func (r *InMemoryUserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, user := range r.users {
		if user.Email == email {
			// Return a copy to prevent external modifications
			userCopy := *user
			return &userCopy, nil
		}
	}

	return nil, errors.New("user not found")
}

// Update updates a user
func (r *InMemoryUserRepository) Update(ctx context.Context, user *User) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.users[user.ID]; !exists {
		return errors.New("user not found")
	}

	user.UpdatedAt = time.Now()
	r.users[user.ID] = user
	return nil
}

// Delete deletes a user
func (r *InMemoryUserRepository) Delete(ctx context.Context, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.users[id]; !exists {
		return errors.New("user not found")
	}

	delete(r.users, id)
	return nil
}
