import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";
import AccountingPage from "@/app/admin/accounting/page";

export default async function OwnerAccountingPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // Immediately redirect to /me which will redirect to username-based route
  redirect("/me");

  // Owner uses the same accounting page as admin
  return <AccountingPage />;
}

