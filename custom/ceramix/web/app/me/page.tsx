import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";

/**
 * /me route - redirects to user's username-based dashboard
 * Example: /me -> /username/dashboard
 */
export default async function MePage() {
  const user = await getCurrentUser();

  if (!user) {
    console.log('[me/page] No user found, redirecting to sign-in');
    redirect("/sign-in");
  }

  // Ensure username exists and is not a reserved route prefix
  if (!user.username) {
    console.log('[me/page] User found but username is missing:', user.id);
    // If username is missing, redirect to sign-in
    redirect("/sign-in");
  }

  // Check if username is a reserved route prefix (this would cause redirect loops)
  const reservedPrefixes = ['own', 'pat', 'doc', 'adm', 'me', 'sign-in', 'sign-up', 'login', 'register', 'api', 'admin'];
  if (reservedPrefixes.includes(user.username.toLowerCase())) {
    console.error(`[me/page] ERROR: User ${user.id} has reserved username "${user.username}" - this will cause redirect loops!`);
    // Fallback: try to get username from database or use user ID
    // For now, just log error and redirect to sign-in so user can fix their account
    console.error('[me/page] User needs to have their username changed in the database');
    redirect("/sign-in?error=invalid_username");
  }

  console.log('[me/page] User:', user.id, 'username:', user.username, 'Redirecting to:', `/${user.username}/dashboard`);
  // Redirect based on username (not role prefix)
  redirect(`/${user.username}/dashboard`);
}

