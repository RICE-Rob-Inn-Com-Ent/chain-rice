import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { isValidUsername, getUserByUsername } from "@/lib/username-utils";
import { getRoleFromId } from "@/lib/user-id-generator";
import { isOwner } from "@/lib/rbac";
import Link from "next/link";
import dynamic from "next/dynamic";
import Icon from "@/app/components/Icon";
import { trackComponentLoad } from "@/app/components/loading-tracker";
import PageLoader from "@/app/components/PageLoader";
import NavigationLink from "@/app/components/NavigationLink";

const LocationSelector = dynamic(
  () => import("@/app/admin/components/LocationSelector").then(mod => {
    // Track component load after module is loaded (not during render)
    setTimeout(() => {
      trackComponentLoad('LocationSelector', 10);
    }, 0);
    return mod;
  }),
  { 
    ssr: false,
    loading: () => {
      // Don't track here - it causes setState during render
      return null;
    },
  }
);

const SettingsButton = dynamic(
  () => import("@/app/admin/components/SettingsButton").then(mod => {
    // Track component load after module is loaded (not during render)
    setTimeout(() => {
      trackComponentLoad('SettingsButton', 10);
    }, 0);
    return mod;
  }),
  { 
    ssr: false,
    loading: () => {
      // Don't track here - it causes setState during render
      return null;
    },
  }
);

/**
 * Layout for username-based routes
 * Provides sidebar navigation based on user role
 */
export default async function UsernameLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ username: string }>;
}) {
  const resolvedParams = await params;
  const username = resolvedParams.username || '';
  
  // Validate username
  if (!isValidUsername(username)) {
    return <>{children}</>;
  }

  // Get user by username
  const user = await getUserByUsername(username);
  if (!user) {
    return <>{children}</>;
  }

  const currentUser = await getCurrentUser();
  if (!currentUser || currentUser.username !== username) {
    return <>{children}</>;
  }

  const role = getRoleFromId(user.id) || user.role || "user";
  const userIsOwner = isOwner(user.id);

  // Render navigation based on role
  const renderNavLinks = () => {
    if (role === 'owner') {
      return (
        <>
          <NavigationLink
            href={`/${username}/dashboard`}
            icon="dashboard"
            label="Dashboard"
          />
          <NavigationLink
            href={`/${username}/users`}
            icon="people"
            label="Użytkownicy"
          />
          <NavigationLink
            href={`/${username}/accounting`}
            icon="wallet"
            label="Księgowość"
          />
        </>
      );
    } else if (role === 'admin') {
      return (
        <>
          <NavigationLink
            href={`/${username}/dashboard`}
            icon="dashboard"
            label="Dashboard"
          />
          <NavigationLink
            href={`/${username}/users`}
            icon="people"
            label="Użytkownicy"
          />
          <NavigationLink
            href={`/${username}/accounting`}
            icon="wallet"
            label="Księgowość"
          />
          <NavigationLink
            href={`/${username}/appointments`}
            icon="event"
            label="Wizyty"
          />
        </>
      );
    } else if (role === 'doctor') {
      return (
        <>
          <NavigationLink
            href={`/${username}/dashboard`}
            icon="dashboard"
            label="Dashboard"
          />
          <NavigationLink
            href={`/${username}/appointments`}
            icon="event"
            label="Wizyty"
          />
          <NavigationLink
            href={`/${username}/patients`}
            icon="people"
            label="Pacjenci"
          />
          <NavigationLink
            href={`/${username}/schedule`}
            icon="calendar_month"
            label="Grafik"
          />
        </>
      );
    } else {
      // patient
      return (
        <>
          <NavigationLink
            href={`/${username}/dashboard`}
            icon="dashboard"
            label="Dashboard"
          />
          <NavigationLink
            href={`/${username}/appointments`}
            icon="event"
            label="Wizyty"
          />
          <NavigationLink
            href={`/${username}/invoices`}
            icon="receipt"
            label="Faktury"
          />
        </>
      );
    }
  };

  const getRoleLabel = () => {
    const roleLabels: Record<string, string> = {
      owner: 'Właściciel',
      admin: 'Administrator',
      doctor: 'Lekarz',
      patient: 'Pacjent',
    };
    return roleLabels[role] || 'Użytkownik';
  };

  return (
    <div className="flex min-h-screen bg-obsidian-900 relative">
      <aside className="hidden lg:block fixed left-0 top-0 h-screen w-64 border-r border-white/10 bg-obsidian-800/50 z-30">
        <div className="flex h-full flex-col">
          <div className="border-b border-white/10 p-6">
            <div className="flex items-center gap-3 mb-4">
              {/* Avatar */}
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold text-lg flex-shrink-0">
                {user.display_name?.charAt(0)?.toUpperCase() || user.username?.charAt(0)?.toUpperCase() || "U"}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h1 className="font-display text-xl text-ivory-100 truncate">{user.display_name || user.username || "Użytkownik"}</h1>
                  {userIsOwner && <SettingsButton />}
                </div>
                <p className="text-xs text-ivory-100/50 truncate">@{user.username}</p>
              </div>
            </div>
            <p className="text-xs text-ivory-100/40 uppercase font-medium mb-4">{getRoleLabel()}</p>
            
            {/* Location Selector - tylko dla ownerów */}
            {userIsOwner && (
              <LocationSelector username={username} isOwner={userIsOwner} />
            )}
          </div>
          <nav className="flex-1 space-y-1 p-4 overflow-y-auto">
            {renderNavLinks()}
          </nav>
          <div className="border-t border-white/10 p-4">
            <form action="/api/auth/logout" method="POST">
              <button
                type="submit"
                className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
              >
                <Icon icon="logout" className="text-[1.5rem]" />
                <span>Wyloguj</span>
              </button>
            </form>
          </div>
        </div>
      </aside>
      <main className="flex-1 overflow-auto pb-20 lg:pb-8 relative lg:ml-64">
        <div className="mx-auto w-full max-w-7xl p-2 sm:p-4 lg:p-8">
          <PageLoader>
            {children}
          </PageLoader>
        </div>
      </main>
    </div>
  );
}
