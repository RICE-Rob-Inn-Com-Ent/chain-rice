import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { isValidUsername, getUserByUsername } from "@/lib/username-utils";
import { getRoleFromId } from "@/lib/user-id-generator";
import AccountingPage from "@/app/admin/accounting/page";
import CerAI from "@/app/components/CerAI";

export default async function UsernameAccountingPage({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const resolvedParams = await params;
  const username = resolvedParams.username || '';
  
  // Block user IDs
  const isUserIdFormat = /^(PAT|DOC|ADM|OWN|SUP|USR)-\d{8}(-\d{6})?(-\d{6})?$/.test(username);
  if (isUserIdFormat) {
    redirect('/me');
  }
  
  // Validate username
  if (!isValidUsername(username)) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-obsidian-900">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-ivory-100">Nieprawidłowy identyfikator użytkownika</h1>
        </div>
      </div>
    );
  }

  const user = await getUserByUsername(username);
  if (!user) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-obsidian-900">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-ivory-100">Użytkownik nie znaleziony</h1>
        </div>
      </div>
    );
  }

  const currentUser = await getCurrentUser();
  if (!currentUser) {
    redirect(`/sign-in?redirect=/${username}/accounting`);
  }

  if (currentUser.username !== username) {
    redirect(`/${currentUser.username}/accounting`);
  }

  const role = getRoleFromId(user.id) || user.role || "user";
  
  if (role !== 'owner' && role !== 'admin') {
    redirect(`/${username}/dashboard`);
  }

  return (
    <div>
      <AccountingPage />
      <CerAI botType="accounting" context="accounting_page" />
    </div>
  );
}



