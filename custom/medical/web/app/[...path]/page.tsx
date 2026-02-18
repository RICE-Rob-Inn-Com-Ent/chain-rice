import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { isValidUsername, getUserByUsername } from "@/lib/username-utils";
import { getRoleFromId } from "@/lib/user-id-generator";
import SuperAdminDashboard from "@/app/admin/components/SuperAdminDashboard";
import CerAI from "@/app/components/CerAI";

/**
 * Dynamic route for username-based paths
 * Handles: /username/dashboard, /username/users, /username/settings, etc.
 * 
 * This route:
 * 1. Validates the username format
 * 2. Checks if user is logged in and owns this username
 * 3. Renders the appropriate page based on role and path
 */
export const dynamic = 'force-dynamic';
export const dynamicParams = true;

export default async function UsernamePathPage({
  params,
}: {
  params: Promise<{ path: string[] }>;
}) {
  const resolvedParams = await params;
  const pathSegments = resolvedParams.path || [];
  // First segment is username, rest is path
  const username = pathSegments[0] || '';
  const path = pathSegments.slice(1).join('/') || 'dashboard';
  
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
    redirect(`/sign-in?redirect=/${username}/${path}`);
  }

  // Check if user is accessing their own username
  if (currentUser.username !== username) {
    // In future, this could show a public profile
    // For now, redirect to own path
    redirect(`/${currentUser.username}/${path}`);
  }

  // Get role from user
  const role = getRoleFromId(user.id) || user.role || "user";

  // Render dashboard based on path and role
  if (path === 'dashboard' || path === '') {
    // Render dashboard based on role
    if (role === 'owner') {
      return <SuperAdminDashboard />;
    } else if (role === 'admin') {
      return (
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-bold text-ivory-100">Witaj, {user.display_name}!</h1>
            <p className="mt-2 text-ivory-100/60">Panel administratora - Ceramix</p>
          </div>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Użytkownicy</h3>
              <p className="mt-2 text-ivory-100/60">Zarządzaj użytkownikami systemu</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Księgowość</h3>
              <p className="mt-2 text-ivory-100/60">Zarządzaj finansami i fakturami</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Wizyty</h3>
              <p className="mt-2 text-ivory-100/60">Zarządzaj wizytami i grafikiem</p>
            </div>
          </div>
        </div>
      );
    } else if (role === 'doctor') {
      return (
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-bold text-ivory-100">Witaj, {user.display_name}!</h1>
            <p className="mt-2 text-ivory-100/60">Panel lekarza - Ceramix</p>
          </div>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Dzisiejsze wizyty</h3>
              <p className="mt-2 text-ivory-100/60">Sprawdź zaplanowane wizyty</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Pacjenci</h3>
              <p className="mt-2 text-ivory-100/60">Zarządzaj pacjentami</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Grafik</h3>
              <p className="mt-2 text-ivory-100/60">Zarządzaj swoim grafikiem</p>
            </div>
          </div>
        </div>
      );
    } else {
      // patient or default
      return (
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-bold text-ivory-100">Witaj, {user.display_name}!</h1>
            <p className="mt-2 text-ivory-100/60">Panel pacjenta - Ceramix</p>
          </div>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Nadchodzące wizyty</h3>
              <p className="mt-2 text-ivory-100/60">Brak zaplanowanych wizyt</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Historia wizyt</h3>
              <p className="mt-2 text-ivory-100/60">Zobacz swoją historię leczenia</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
              <h3 className="text-lg font-semibold text-ivory-100">Faktury</h3>
              <p className="mt-2 text-ivory-100/60">Dostęp do faktur i dokumentów</p>
            </div>
          </div>
        </div>
      );
    }
  }

  // Handle other paths based on role
  // Import components dynamically based on path
  if (path === 'users' && (role === 'owner' || role === 'admin')) {
    try {
      const { query } = await import("@/lib/db");
      const UserManagementTableModule = await import("@/app/admin/users/UserManagementTable");
      const UserManagementTable = UserManagementTableModule.default;
      const { getRoleGroups } = await import("@/lib/role-groups");
      const { isOwner } = await import("@/lib/rbac");
      
      type User = {
        id: string;
      username: string;
      email: string;
      display_name: string;
      first_name: string | null;
      last_name: string | null;
      pesel: string | null;
      patient_number: string | null;
      phone: string | null;
      role: string;
      active: boolean;
      email_verified: boolean;
      phone_verified: boolean | null;
      created_at: Date;
      last_login_at: Date | null;
      employment_type: string | null;
      employment_status: string | null;
      };

      const usersFromTable = await query<User>(
      `SELECT 
        u.id, u.username, u.email, u.display_name, u.first_name, u.last_name,
        get_user_text_field(u.id, 'pesel') as pesel,
        get_patient_number(u.id) as patient_number, get_user_phone(u.id) as phone,
        get_user_text_field(u.id, 'employment_type') as employment_type,
        get_user_text_field(u.id, 'employment_status') as employment_status,
        u.active, u.email_verified, get_user_phone_verified(u.id) as phone_verified, u.created_at, u.last_login_at
       FROM users u
       ORDER BY u.created_at DESC`
      );
      
      const usersWithRoles = usersFromTable.rows.map((u: User) => ({
        ...u,
        role: getRoleFromId(u.id) || "user",
      }));

      const users = {
        rows: [...usersWithRoles]
          .sort((a, b) => {
            const dateA = a.created_at ? new Date(a.created_at).getTime() : 0;
            const dateB = b.created_at ? new Date(b.created_at).getTime() : 0;
            return dateB - dateA;
          })
          .slice(0, 100)
      };

      const roleGroups = await getRoleGroups();
      const isOwnerUser = isOwner(user.id);

      const serializedUsers = users.rows.map((u) => ({
        ...u,
        pesel: u.pesel,
        last_login_at: u.last_login_at ? new Date(u.last_login_at).toISOString() : null,
        created_at: u.created_at ? new Date(u.created_at).toISOString() : null,
      }));

      return (
        <div>
          <UserManagementTable
            currentUserId={user.username}
            initialUsers={serializedUsers}
            initialRoleGroups={roleGroups}
            canEditRoles={isOwnerUser}
            isSuperadmin={isOwnerUser}
          />
          <CerAI botType="client_management" context="users_page" />
        </div>
      );
    } catch (error) {
      console.error("Error loading users page:", error);
      return (
        <div className="flex min-h-screen items-center justify-center bg-obsidian-900">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-ivory-100">Błąd ładowania strony</h1>
            <p className="mt-2 text-ivory-100/60">Nie udało się załadować strony użytkowników</p>
            <a href={`/${username}/dashboard`} className="mt-4 text-ivory-100/80 hover:text-ivory-100 underline">
              Wróć do dashboardu
            </a>
          </div>
        </div>
      );
    }
  }

  if (path === 'settings' && role === 'owner') {
    const { default: LocationManagement } = await import('@/app/admin/components/LocationManagement');
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-ivory-100">Ustawienia</h1>
          <p className="mt-2 text-ivory-100/60">Zarządzaj ustawieniami systemu</p>
        </div>
        <div className="marble-card p-6">
          <LocationManagement />
        </div>
      </div>
    );
  }

  if (path === 'accounting' && (role === 'owner' || role === 'admin')) {
    try {
      const AccountingPageModule = await import("@/app/admin/accounting/page");
      const AccountingPage = AccountingPageModule.default;
      return (
        <div>
          <AccountingPage />
          <CerAI botType="accounting" context="accounting_page" />
        </div>
      );
    } catch (error) {
      console.error("Error loading accounting page:", error);
      return (
        <div className="flex min-h-screen items-center justify-center bg-obsidian-900">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-ivory-100">Błąd ładowania strony</h1>
            <p className="mt-2 text-ivory-100/60">Nie udało się załadować strony księgowości</p>
            <a href={`/${username}/dashboard`} className="mt-4 text-ivory-100/80 hover:text-ivory-100 underline">
              Wróć do dashboardu
            </a>
          </div>
        </div>
      );
    }
  }

  if (path === 'reports' && role === 'owner') {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-ivory-100">Raporty</h1>
          <p className="mt-2 text-ivory-100/60">Przeglądaj raporty i statystyki</p>
        </div>
        <div className="marble-card p-6">
          <p className="text-ivory-100/60">Strona w budowie...</p>
        </div>
      </div>
    );
  }

  // For other paths, show a 404-like message
  return (
    <div className="flex min-h-screen items-center justify-center bg-obsidian-900">
      <div className="text-center">
        <h1 className="text-2xl font-bold text-ivory-100">Strona nie znaleziona</h1>
        <p className="mt-2 text-ivory-100/60">Ścieżka "/{path}" nie istnieje</p>
        <a href={`/${username}/dashboard`} className="mt-4 text-ivory-100/80 hover:text-ivory-100 underline">
          Wróć do dashboardu
        </a>
      </div>
    </div>
  );
}
