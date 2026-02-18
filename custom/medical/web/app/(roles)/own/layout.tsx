import { redirect, notFound } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";
import { isValidUsername } from "@/lib/username-utils";
import Link from "next/link";

/**
 * DEPRECATED LAYOUT - This layout is no longer used.
 * All routing is now username-based (e.g., /username/dashboard)
 * This file exists only to redirect legacy routes.
 * 
 * If Next.js matches a route like /own1/dashboard to this layout,
 * we need to redirect it to /me which will route to the correct username-based route.
 */
export default async function OwnerLayout({ children }: { children: React.ReactNode }) {
  // This layout should only handle exact /own/* routes (3 characters)
  // If we reach here with a longer segment (like "own1"), it means Next.js
  // incorrectly matched it. We should redirect to /me.
  
  // Try to get the current path from headers or context
  // Since we can't access the path directly in layout, we'll always redirect
  // Middleware should catch exact /own/* routes, but if we reach here,
  // it means something went wrong - redirect to /me
  redirect("/me");
}


