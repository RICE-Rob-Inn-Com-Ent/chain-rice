import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";

export default async function PatientDetailsPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // Redirect based on role using role prefix
  const role = getRoleFromId(user.id) || "user";
  const ROLE_ROUTE_MAP: Record<string, string> = {
    patient: 'pat',
    doctor: 'doc',
    admin: 'adm',
    owner: 'own',
    user: 'pat',
  };
  const rolePrefix = ROLE_ROUTE_MAP[role] || 'pat';
  redirect(`/${rolePrefix}/users`);
}
