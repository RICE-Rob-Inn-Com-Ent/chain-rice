import type { Metadata } from "next";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";
import PanelSidebar from "@/components/panel/PanelSidebar";
import PanelHeader from "@/components/panel/PanelHeader";
import { Providers } from "@/components/providers";

export const metadata: Metadata = {
  title: {
    default: "Panel ERP - MeoWTopia",
    template: "%s | Panel ERP - MeoWTopia",
  },
};

export default async function PanelLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getServerSession(authOptions);

  // NOTE: Middleware already handles authentication and redirects for panel routes
  // This layout should only check session for rendering purposes, not redirect
  // If we reach here without session, middleware should have already redirected
  // But we still check to prevent rendering errors
  
  if (!session) {
    // If we somehow reach here without session, it means middleware didn't catch it
    // In this case, we should not redirect (to avoid loops) but show an error
    // Middleware will handle the redirect on next request
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Brak autoryzacji</h1>
          <p className="text-gray-600">Przekierowywanie do strony logowania...</p>
        </div>
      </div>
    );
  }

  const userRole = (session.user as any)?.role || "USER";
  const allowedRoles = ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"];

  if (!allowedRoles.includes(userRole)) {
    // Middleware should have caught this, but if we reach here, show error instead of redirect
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Brak uprawnień</h1>
          <p className="text-gray-600">Nie masz uprawnień do dostępu do panelu.</p>
        </div>
      </div>
    );
  }

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

