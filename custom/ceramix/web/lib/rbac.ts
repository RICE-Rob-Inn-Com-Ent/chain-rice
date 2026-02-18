/**
 * Role-Based Access Control (RBAC) for Ceramix
 * 
 * Role Hierarchy: OWN > ADM > DOC > PAT
 * 
 * Resources and Actions:
 * - users: read, write, delete
 * - patients: read, write, delete
 * - appointments: read, write, delete, cancel
 * - invoices: read, write, delete, approve
 * - schedules: read, write, delete
 * - settings: read, write
 * - reports: read, generate
 */

import { getRoleFromId } from "./user-id-generator";

export type Role = "owner" | "admin" | "doctor" | "patient" | "user";

export type Resource = 
  | "users" 
  | "patients" 
  | "appointments" 
  | "invoices" 
  | "schedules" 
  | "settings" 
  | "reports"
  | "dental_charts"
  | "accounting";

export type Action = "read" | "write" | "delete" | "cancel" | "approve" | "generate";

// Role hierarchy: higher number = more permissions
const ROLE_HIERARCHY: Record<Role, number> = {
  owner: 4,
  admin: 3,
  doctor: 2,
  patient: 1,
  user: 0,
};

// Permission matrix: role -> resource -> actions
const PERMISSIONS: Record<Role, Partial<Record<Resource, Action[]>>> = {
  owner: {
    users: ["read", "write", "delete"],
    patients: ["read", "write", "delete"],
    appointments: ["read", "write", "delete", "cancel"],
    invoices: ["read", "write", "delete", "approve"],
    schedules: ["read", "write", "delete"],
    settings: ["read", "write"],
    reports: ["read", "generate"],
    dental_charts: ["read", "write", "delete"],
    accounting: ["read", "write", "delete"],
  },
  admin: {
    users: ["read", "write"],
    patients: ["read", "write", "delete"],
    appointments: ["read", "write", "delete", "cancel"],
    invoices: ["read", "write", "approve"],
    schedules: ["read", "write", "delete"],
    settings: ["read", "write"],
    reports: ["read", "generate"],
    dental_charts: ["read", "write"],
    accounting: ["read", "write"],
  },
  doctor: {
    patients: ["read", "write"],
    appointments: ["read", "write", "cancel"],
    invoices: ["read", "write"],
    schedules: ["read", "write"],
    dental_charts: ["read", "write"],
    reports: ["read"],
  },
  patient: {
    appointments: ["read"],
    invoices: ["read"],
    dental_charts: ["read"],
  },
  user: {
    appointments: ["read"],
  },
};

/**
 * Get role from user ID or role string
 */
export function getRole(userIdOrRole: string): Role {
  // If it's already a role, return it
  if (["owner", "admin", "doctor", "patient", "user"].includes(userIdOrRole.toLowerCase())) {
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
    doctor: "doctor",
    dentist: "doctor",
    patient: "patient",
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
 * Check if user is doctor or higher
 */
export function isDoctorOrHigher(userIdOrRole: string): boolean {
  const role = getRole(userIdOrRole);
  return ROLE_HIERARCHY[role] >= ROLE_HIERARCHY.doctor;
}


