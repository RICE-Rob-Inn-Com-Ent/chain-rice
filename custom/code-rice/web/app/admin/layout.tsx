import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import GiptAdminShell from "@/components/gipt-admin/GiptAdminShell";

export const metadata: Metadata = {
  title: {
    default: "Admin Panel",
    template: "%s | RICE Admin",
  },
};

const ADMIN_ROLES = new Set(["superadmin", "admin", "developer", "owner", "OWN", "ADM", "DEV"]);

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getCurrentUser();

  if (!user) {
    console.log("[admin-layout] No user found, redirecting to signin");
    redirect(`/signin?redirect=${encodeURIComponent("/admin")}`);
  }

  const userRole = String(user.role || "").trim();
  const roleLower = userRole.toLowerCase();
  const isOwner = roleLower === "owner" || userRole === "OWN";
  const isAdmin = roleLower === "admin" || userRole === "ADM" || roleLower === "superadmin";
  const isDeveloper = roleLower === "developer" || userRole === "DEV";
  const isAllowed = isOwner || isAdmin || isDeveloper;

  console.log("[admin-layout] ===== ACCESS CHECK =====");
  console.log("[admin-layout] User:", user.email, "ID:", user.id);
  console.log("[admin-layout] Raw role:", userRole);
  console.log("[admin-layout] Role lower:", roleLower);
  console.log("[admin-layout] Is owner?", isOwner);
  console.log("[admin-layout] Is admin?", isAdmin);
  console.log("[admin-layout] Is developer?", isDeveloper);
  console.log("[admin-layout] Is allowed?", isAllowed);
  console.log("[admin-layout] =======================");

  if (!isAllowed) {
    console.log("[admin-layout] Access denied, redirecting to /");
    redirect("/");
  }

  console.log("[admin-layout] Access granted, rendering GiPT shell");
  return <GiptAdminShell>{children}</GiptAdminShell>;
}

