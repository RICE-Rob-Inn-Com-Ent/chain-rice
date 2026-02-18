import { notFound } from "next/navigation";
import SuperAdminDashboard from "@/app/admin/components/SuperAdminDashboard";

export default async function OwnerDashboard() {
  // This route should only be accessible via exact /own/dashboard match
  // If Next.js incorrectly matches a username like "own1" to this route,
  // the middleware should have handled it, but if we reach here incorrectly,
  // we'll let it render (the middleware headers will help Next.js route correctly)
  
  // Owner uses the same dashboard as SuperAdmin - full calendar and management
  return <SuperAdminDashboard />;
}


