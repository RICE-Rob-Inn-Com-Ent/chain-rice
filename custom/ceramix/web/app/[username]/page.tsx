import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { isValidUsername, getUserByUsername } from "@/lib/username-utils";

/**
 * Dynamic route for username-based URLs (GitHub style)
 * Handles: /username -> /username/dashboard (default redirect)
 * 
 * This route:
 * 1. Validates the username format
 * 2. Checks if user is logged in and owns this username
 * 3. Redirects to /username/dashboard
 */
export default async function UsernamePage({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const resolvedParams = await params;
  const username = resolvedParams.username || '';
  
  // Block user IDs (format: PREFIX-YYYYMMDD-HHMMSS-XXXXXX or PREFIX-YYYYMMDD-XXXXXX)
  // These should not be treated as usernames - redirect to /me
  const isUserIdFormat = /^(PAT|DOC|ADM|OWN|SUP|USR)-\d{8}(-\d{6})?(-\d{6})?$/.test(username);
  if (isUserIdFormat) {
    redirect('/me');
  }
  
  // Validate username format
  if (!isValidUsername(username)) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-obsidian-900">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-ivory-100">Nieprawidłowy identyfikator użytkownika</h1>
          <p className="mt-2 text-ivory-100/60">Format username jest nieprawidłowy</p>
        </div>
      </div>
    );
  }

  // Get user by username
  const user = await getUserByUsername(username);
  
  if (!user) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-obsidian-900">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-ivory-100">Użytkownik nie znaleziony</h1>
          <p className="mt-2 text-ivory-100/60">Użytkownik o username "{username}" nie istnieje</p>
        </div>
      </div>
    );
  }

  const currentUser = await getCurrentUser();
  
  if (!currentUser) {
    redirect(`/sign-in?redirect=/${username}`);
  }

  // Check if user is accessing their own username
  if (currentUser.username !== username) {
    // In future, this could show a public profile
    // For now, redirect to own dashboard
    redirect(`/${currentUser.username}/dashboard`);
  }

  // Redirect to dashboard (default page for username)
  redirect(`/${username}/dashboard`);
}










































