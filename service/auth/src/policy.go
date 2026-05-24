package auth

import (
	"strings"
	"sync"
)

// Role is a coarse SMITH RBAC label attached to a user (Kratos identity id or internal subject).
type Role string

const (
	RoleOwner   Role = "Owner"
	RoleAdmin   Role = "Admin"
	RoleService Role = "Service"
	RoleUser    Role = "User"
)

// Policy holds per-user roles and answers [Policy.Can] for action/resource tuples such as Read + SAGE_Logs.
type Policy struct {
	mu       sync.RWMutex
	userRole map[string]Role
}

// NewPolicy builds an empty in-memory policy map.
func NewPolicy() *Policy {
	return &Policy{userRole: make(map[string]Role)}
}

// SetRole assigns role r to userID (typically a Kratos identity id).
func (p *Policy) SetRole(userID string, r Role) {
	if p == nil {
		return
	}
	uid := strings.TrimSpace(userID)
	if uid == "" {
		return
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.userRole == nil {
		p.userRole = make(map[string]Role)
	}
	p.userRole[uid] = r
}

// RoleOf returns the role for userID and false when unset.
func (p *Policy) RoleOf(userID string) (Role, bool) {
	if p == nil {
		return "", false
	}
	p.mu.RLock()
	defer p.mu.RUnlock()
	r, ok := p.userRole[strings.TrimSpace(userID)]
	return r, ok
}

// Can reports whether userID may perform action on resource (case-insensitive action; resource is opaque string).
// Example: Can("123", "Read", "Resource:SAGE_Logs") with role Service → true for read on SAGE logs.
func (p *Policy) Can(userID, action, resource string) bool {
	if p == nil {
		return false
	}
	uid := strings.TrimSpace(userID)
	if uid == "" {
		return false
	}
	p.mu.RLock()
	r, ok := p.userRole[uid]
	p.mu.RUnlock()
	if !ok {
		return false
	}
	return roleAllows(r, uid, normAction(action), strings.TrimSpace(resource))
}

func normAction(action string) string {
	return strings.ToLower(strings.TrimSpace(action))
}

func normResource(resource string) string {
	return strings.ToLower(strings.TrimSpace(resource))
}

func roleAllows(role Role, userID, action, resource string) bool {
	res := normResource(resource)
	switch role {
	case RoleOwner:
		return true
	case RoleAdmin:
		switch action {
		case "read", "write", "delete", "list", "patch", "create":
			return true
		default:
			return false
		}
	case RoleService:
		switch action {
		case "read", "list":
			if strings.Contains(res, "sage_logs") || strings.Contains(res, "sage-logs") {
				return true
			}
			return strings.HasPrefix(res, "internal:") || strings.HasPrefix(res, "service:")
		case "write", "patch":
			return strings.HasPrefix(res, "internal:") || strings.HasPrefix(res, "service:")
		default:
			return false
		}
	case RoleUser:
		switch action {
		case "read", "list":
			return userOwnsResource(userID, res)
		default:
			return false
		}
	default:
		return false
	}
}

func userOwnsResource(userID, res string) bool {
	if userID == "" {
		return false
	}
	u := strings.ToLower(userID)
	if strings.Contains(res, "user:"+u+":") {
		return true
	}
	if strings.Contains(res, "user:"+userID+":") {
		return true
	}
	if strings.HasSuffix(res, ":self") && strings.Contains(res, u) {
		return true
	}
	return false
}
