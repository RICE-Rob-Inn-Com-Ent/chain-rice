import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";

const GIPT_ROLES = new Set(["owner", "admin", "OWN", "ADM", "superadmin"]);

/**
 * /me route - central dispatcher after login.
 * Owners/admins should always land inside the GiPT-1 console, everyone else keeps legacy routing.
 */
export default async function MePage() {
  const user = await getCurrentUser();

  if (!user) {
    console.log("[me] No user found, redirecting to signin");
    redirect("/signin");
  }

  const userRole = String(user.role || "").trim();
  const roleLower = userRole.toLowerCase();
  const isOwner = roleLower === "owner" || userRole === "OWN";
  const isAdmin = roleLower === "admin" || userRole === "ADM" || roleLower === "superadmin";
  const isGiptUser = isOwner || isAdmin;

  console.log("[me] ===== USER CHECK =====");
  console.log("[me] User:", user.email, "ID:", user.id);
  console.log("[me] Raw role:", userRole);
  console.log("[me] Role lower:", roleLower);
  console.log("[me] Is owner?", isOwner);
  console.log("[me] Is admin?", isAdmin);
  console.log("[me] Is GiPT user?", isGiptUser);
  console.log("[me] =====================");

  if (isGiptUser) {
    console.log("[me] Redirecting to /admin/dashboard");
    redirect("/admin/dashboard");
  }

  console.log("[me] Redirecting to user ID route:", `/${user.id}`);
  redirect(`/${user.id}`);
}

