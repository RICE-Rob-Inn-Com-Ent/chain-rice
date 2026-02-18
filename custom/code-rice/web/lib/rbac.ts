/**
 * Role-Based Access Control (RBAC) for Code-Rice
 * 
 * Role Hierarchy: OWN > ADM > MGR > DEV
 * 
 * Resources and Actions:
 * - users: read, write, delete
 * - projects: read, write, delete
 * - modules: read, write, delete
 * - infrastructure: read, write, deploy
 * - settings: read, write
 * - reports: read, generate
 * - genes: read, write, delete
 */

import { getRoleFromId } from "./user-id-generator";

export type Role = "owner" | "admin" | "manager" | "developer" | "user";

export type Resource = 
  | "users" 
  | "projects" 
  | "modules" 
  | "infrastructure" 
  | "settings" 
  | "reports"
  | "genes"
  | "deployments";

export type Action = "read" | "write" | "delete" | "deploy" | "generate";

// Role hierarchy: higher number = more permissions
const ROLE_HIERARCHY: Record<Role, number> = {
  owner: 4,
  admin: 3,
  manager: 2,
  developer: 1,
  user: 0,
};

// Permission matrix: role -> resource -> actions
const PERMISSIONS: Record<Role, Partial<Record<Resource, Action[]>>> = {
  owner: {
    users: ["read", "write", "delete"],
    projects: ["read", "write", "delete"],
    modules: ["read", "write", "delete"],
    infrastructure: ["read", "write", "deploy"],
    settings: ["read", "write"],
    reports: ["read", "generate"],
    genes: ["read", "write", "delete"],
    deployments: ["read", "write", "delete"],
  },
  admin: {
    users: ["read", "write"],
    projects: ["read", "write", "delete"],
    modules: ["read", "write", "delete"],
    infrastructure: ["read", "write", "deploy"],
    settings: ["read", "write"],
    reports: ["read", "generate"],
    genes: ["read", "write", "delete"],
    deployments: ["read", "write"],
  },
  manager: {
    projects: ["read", "write"],
    modules: ["read", "write"],
    infrastructure: ["read"],
    reports: ["read", "generate"],
    genes: ["read", "write"],
    deployments: ["read"],
  },
  developer: {
    projects: ["read"],
    modules: ["read", "write"],
    infrastructure: ["read"],
    genes: ["read", "write"],
    deployments: ["read"],
  },
  user: {
    modules: ["read"],
  },
};

/**
 * Get role from user ID or role string
 */
export function getRole(userIdOrRole: string): Role {
  // If it's already a role, return it
  if (["owner", "admin", "manager", "developer", "user"].includes(userIdOrRole.toLowerCase())) {
    return userIdOrRole.toLowerCase() as Role;
  }
  
  // Otherwise, extract from ID
  const roleFromId = getRoleFromId(userIdOrRole);
  if (!roleFromId) {
    return "user";
  }
  
  // Map role names to Role type
  const roleMap: Record<string, Role> = {
    owner: "owner",
    admin: "admin",
    administrator: "admin",
    manager: "manager",
    developer: "developer",
    dev: "developer",
    user: "user",
  };
  
  return roleMap[roleFromId.toLowerCase()] || "user";
}

/**
 * Check if a role has permission for a resource and action
 */
export function hasPermission(
  userIdOrRole: string,
  resource: Resource,
  action: Action
): boolean {
  const role = getRole(userIdOrRole);
  const rolePermissions = PERMISSIONS[role];
  
  if (!rolePermissions) {
    return false;
  }
  
  const resourcePermissions = rolePermissions[resource];
  if (!resourcePermissions) {
    return false;
  }
  
  return resourcePermissions.includes(action);
}

/**
 * Check if role1 has higher or equal hierarchy than role2
 */
export function hasHigherOrEqualRole(role1: Role, role2: Role): boolean {
  return ROLE_HIERARCHY[role1] >= ROLE_HIERARCHY[role2];
}

/**
 * Check if a user can access a resource (at least read permission)
 */
export function canAccess(userIdOrRole: string, resource: Resource): boolean {
  return hasPermission(userIdOrRole, resource, "read");
}

/**
 * Get all resources a role can access
 */
export function getAccessibleResources(userIdOrRole: string): Resource[] {
  const role = getRole(userIdOrRole);
  const rolePermissions = PERMISSIONS[role];
  
  if (!rolePermissions) {
    return [];
  }
  
  return Object.keys(rolePermissions) as Resource[];
}

/**
 * Check if user is owner
 */
export function isOwner(userIdOrRole: string): boolean {
  return getRole(userIdOrRole) === "owner";
}

/**
 * Check if user is admin or owner
 */
export function isAdminOrOwner(userIdOrRole: string): boolean {
  const role = getRole(userIdOrRole);
  return role === "admin" || role === "owner";
}

/**
 * Check if user is developer or higher
 */
export function isDeveloperOrHigher(userIdOrRole: string): boolean {
  const role = getRole(userIdOrRole);
  return ROLE_HIERARCHY[role] >= ROLE_HIERARCHY.developer;
}


