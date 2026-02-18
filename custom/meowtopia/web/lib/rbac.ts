/**
 * Role-Based Access Control (RBAC) for Meowtopia
 * 
 * Role Hierarchy: OWN > ADM > MGR > VOL > USR
 * 
 * Resources and Actions:
 * - products: read, write, delete
 * - orders: read, write, delete, cancel, refund
 * - customers: read, write, delete
 * - inventory: read, write
 * - settings: read, write
 * - reports: read, generate
 * - blog: read, write, delete, publish
 */

import { getRoleFromId } from "./user-id-generator";

export type Role = "OWNER" | "ADMIN" | "MANAGER" | "VOLUNTEER" | "CUSTOMER" | "ARTIST";

export type Resource = 
  | "products" 
  | "orders" 
  | "customers" 
  | "inventory" 
  | "settings" 
  | "reports"
  | "blog"
  | "foundations"
  | "loyalty";

export type Action = "read" | "write" | "delete" | "cancel" | "refund" | "publish" | "generate";

// Role hierarchy: higher number = more permissions
const ROLE_HIERARCHY: Record<Role, number> = {
  OWNER: 6,
  ADMIN: 5,
  MANAGER: 4,
  ARTIST: 3,
  VOLUNTEER: 2,
  CUSTOMER: 1,
};

// Permission matrix: role -> resource -> actions
const PERMISSIONS: Record<Role, Partial<Record<Resource, Action[]>>> = {
  OWNER: {
    products: ["read", "write", "delete"],
    orders: ["read", "write", "delete", "cancel", "refund"],
    customers: ["read", "write", "delete"],
    inventory: ["read", "write"],
    settings: ["read", "write"],
    reports: ["read", "generate"],
    blog: ["read", "write", "delete", "publish"],
    foundations: ["read", "write", "delete"],
    loyalty: ["read", "write", "delete"],
  },
  ADMIN: {
    products: ["read", "write", "delete"],
    orders: ["read", "write", "cancel", "refund"],
    customers: ["read", "write"],
    inventory: ["read", "write"],
    settings: ["read", "write"],
    reports: ["read", "generate"],
    blog: ["read", "write", "publish"],
    foundations: ["read", "write"],
    loyalty: ["read", "write"],
  },
  MANAGER: {
    products: ["read", "write"],
    orders: ["read", "write", "cancel"],
    customers: ["read"],
    inventory: ["read", "write"],
    reports: ["read"],
    blog: ["read", "write"],
    foundations: ["read"],
    loyalty: ["read", "write"],
  },
  VOLUNTEER: {
    products: ["read"],
    orders: ["read"],
    blog: ["read"],
    foundations: ["read"],
  },
  CUSTOMER: {
    products: ["read"],
    orders: ["read"],
    blog: ["read"],
  },
  ARTIST: {
    products: ["read", "write"],
    blog: ["read", "write"],
  },
};

/**
 * Get role from user ID or role string
 */
export function getRole(userIdOrRole: string): Role {
  // If it's already a role, return it
  const upperRole = userIdOrRole.toUpperCase();
  if (["OWNER", "ADMIN", "MANAGER", "VOLUNTEER", "CUSTOMER", "ARTIST", "SUPERADMIN"].includes(upperRole)) {
    // Map SUPERADMIN to OWNER
    if (upperRole === "SUPERADMIN") return "OWNER";
    return upperRole as Role;
  }
  
  // Otherwise, extract from ID
  const roleFromId = getRoleFromId(userIdOrRole);
  if (!roleFromId) {
    return "CUSTOMER";
  }
  
  // Map role names to Role type
  const roleMap: Record<string, Role> = {
    OWNER: "OWNER",
    ADMIN: "ADMIN",
    MANAGER: "MANAGER",
    VOLUNTEER: "VOLUNTEER",
    CUSTOMER: "CUSTOMER",
    ARTIST: "ARTIST",
    SUPERADMIN: "OWNER",
    USER: "CUSTOMER", // Legacy support - map USER to CUSTOMER
  };
  
  return roleMap[roleFromId.toUpperCase()] || "CUSTOMER";
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
  return getRole(userIdOrRole) === "OWNER";
}

/**
 * Check if user is admin or owner
 */
export function isAdminOrOwner(userIdOrRole: string): boolean {
  const role = getRole(userIdOrRole);
  return role === "ADMIN" || role === "OWNER";
}

/**
 * Check if user is manager or higher
 */
export function isManagerOrHigher(userIdOrRole: string): boolean {
  const role = getRole(userIdOrRole);
  return ROLE_HIERARCHY[role] >= ROLE_HIERARCHY.MANAGER;
}


