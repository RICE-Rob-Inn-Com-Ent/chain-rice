import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";

export default async function OwnerSettingsPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // Immediately redirect to /me which will redirect to username-based route
  redirect("/me");

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-ivory-100">Ustawienia</h1>
        <p className="mt-2 text-ivory-100/60">Zarządzaj ustawieniami systemu</p>
      </div>
      
      <div className="marble-card p-6">
        <h2 className="text-xl font-semibold text-ivory-100 mb-4">Ustawienia konta</h2>
        <p className="text-ivory-100/60">Strona w budowie...</p>
      </div>
    </div>
  );
}

