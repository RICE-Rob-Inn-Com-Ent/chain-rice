import type { Metadata } from "next";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";
import PanelSidebar from "@/components/panel/PanelSidebar";
import PanelHeader from "@/components/panel/PanelHeader";

export const metadata: Metadata = {
  title: {
    default: "Panel ERP - MeoWTopia",
    template: "%s | Panel ERP - MeoWTopia",
  },
};

export default async function UsernamePanelLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { username: string };
}) {
  let session = await getServerSession(authOptions);

  // If no session, wait a bit and retry (cookies might still be setting after login redirect)
  if (!session) {
    // Wait a bit and try to get session again (cookies might still be setting)
    await new Promise(resolve => setTimeout(resolve, 500));
    session = await getServerSession(authOptions);
    if (!session) {
      // Still no session - redirect to signin
      redirect(`/signin?callbackUrl=/${params.username}/dashboard`);
    }
  }

  const userRole = (session.user as any)?.role || "USER";
  const allowedRoles = ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"];

  if (!allowedRoles.includes(userRole)) {
    redirect("/");
  }

  // NOTE: Middleware already handles username verification and routing
  // We don't need to check or redirect here to avoid redirect loops
  // If middleware passed this request, user has access to this route

  // Panel layout - NO Header and Footer (handled by route group layout)
  return (
    <div className="flex min-h-screen bg-gray-50">
      <PanelSidebar userRole={userRole} />
      <div className="flex flex-1 flex-col min-w-0">
        <PanelHeader user={session.user} />
        <main className="flex-1 overflow-auto bg-gray-50 p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
