import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { isValidUsername, getUserByUsername } from "@/lib/username-utils";
import { getRoleFromId } from "@/lib/user-id-generator";
import SuperAdminDashboard from "@/app/admin/components/SuperAdminDashboard";
import AdminDashboard from "@/app/admin/components/AdminDashboard";
import DentistDashboard from "@/app/admin/components/DentistDashboard";

/**
 * Dashboard page for username-based routes
 * Handles: /username/dashboard
 * 
 * This route:
 * 1. Validates the username format
 * 2. Checks if user is logged in and owns this username
 * 3. Renders appropriate dashboard based on user role
 */
export default async function UsernameDashboardPage({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const resolvedParams = await params;
  const username = resolvedParams.username || '';
  
  // Block user IDs (format: PREFIX-YYYYMMDD-HHMMSS-XXXXXX or PREFIX-YYYYMMDD-XXXXXX)
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
    redirect(`/sign-in?redirect=/${username}/dashboard`);
  }

  // Check if user is accessing their own username
  if (currentUser.username !== username) {
    redirect(`/${currentUser.username}/dashboard`);
  }

  // Get role and render appropriate dashboard
  const role = getRoleFromId(user.id) || user.role || "user";

  if (role === "owner" || role === "superadmin") {
    return <SuperAdminDashboard />;
  }

  if (role === "admin") {
    return <AdminDashboard />;
  }

  if (role === "dentist" || role === "doctor") {
    return <DentistDashboard />;
  }

  // Fallback for other roles
  return (
    <div>
      <header className="mb-8">
        <h1 className="font-display text-4xl text-ivory-100">Dashboard</h1>
        <p className="mt-2 text-ivory-100/70">Witaj, {user.display_name}</p>
      </header>
      <div className="marble-card p-6">
        <p className="text-ivory-100/60">Dashboard dla Twojej roli będzie dostępny wkrótce.</p>
      </div>
    </div>
  );
}


