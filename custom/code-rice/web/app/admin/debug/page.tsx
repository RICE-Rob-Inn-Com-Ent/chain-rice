import { getCurrentUser } from "@/lib/auth";

export default async function DebugPage() {
  const user = await getCurrentUser();

  if (!user) {
    return (
      <div className="p-8 text-white">
        <h1 className="text-2xl font-bold mb-4">Debug: No User</h1>
        <p>You are not logged in.</p>
      </div>
    );
  }

  return (
    <div className="p-8 text-white font-mono">
      <h1 className="text-2xl font-bold mb-4">Debug: User Info</h1>
      <div className="space-y-2">
        <p><strong>ID:</strong> {user.id}</p>
        <p><strong>Email:</strong> {user.email}</p>
        <p><strong>Display Name:</strong> {user.display_name}</p>
        <p><strong>Role (raw):</strong> {user.role || "null"}</p>
        <p><strong>Role (lowercase):</strong> {(user.role || "").toLowerCase()}</p>
        <p><strong>Is Owner?</strong> {(user.role || "").toLowerCase() === "owner" || user.role === "OWN" ? "YES" : "NO"}</p>
        <p><strong>Is Admin?</strong> {(user.role || "").toLowerCase() === "admin" || user.role === "ADM" ? "YES" : "NO"}</p>
        <p><strong>Active:</strong> {user.active ? "YES" : "NO"}</p>
      </div>
    </div>
  );
}






