import { getCurrentUser } from "@/lib/auth";
import { query } from "@/lib/db";
import { redirect } from "next/navigation";
import UserManagementTable from "@/app/admin/users/UserManagementTable";
import { getRoleFromId } from "@/lib/user-id-generator";
import { getRoleGroups } from "@/lib/role-groups";
import { isOwner } from "@/lib/rbac";
import { isValidUsername, getUserByUsername } from "@/lib/username-utils";

type User = {
  id: string;
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

export default async function UsernameUsersPage({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const resolvedParams = await params;
  const username = resolvedParams.username || '';

  // Validate username
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
    redirect(`/sign-in?redirect=/${username}/users`);
  }

  // Check if user is accessing their own username
  if (currentUser.username !== username) {
    redirect(`/${currentUser.username}/users`);
  }

  // Check permissions
  if (currentUser.role !== "admin" && currentUser.role !== "owner" && currentUser.role !== "dentist") {
    redirect(`/${username}/dashboard`);
  }

  const isOwnerUser = isOwner(currentUser.id);

  // Get all users from users table
  const usersFromTable = await query<User & { username: string }>(
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
  
  // Add role from ID prefix to each user
  const usersWithRoles = usersFromTable.rows.map((u: User) => ({
    ...u,
    role: getRoleFromId(u.id) || "user",
  }));

  // Sort by created_at descending and limit to 100
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

  const serializedUsers = users.rows.map((u) => ({
    ...u,
    pesel: u.pesel,
    last_login_at: u.last_login_at ? new Date(u.last_login_at).toISOString() : null,
    created_at: u.created_at ? new Date(u.created_at).toISOString() : null,
  }));

  return (
    <div>
      <UserManagementTable
        currentUserId={currentUser.username}
        initialUsers={serializedUsers}
        initialRoleGroups={roleGroups}
        canEditRoles={isOwnerUser}
        isSuperadmin={isOwnerUser}
      />
    </div>
  );
}


