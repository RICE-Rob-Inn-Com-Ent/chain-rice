import { getCurrentUser } from "@/lib/auth";
import { redirect } from "next/navigation";
import dynamic from "next/dynamic";
import { trackComponentLoad } from "@/app/components/loading-tracker";

// Lazy load dashboards for better performance
const SuperAdminDashboard = dynamic(() => import("./components/SuperAdminDashboard"), {
  ssr: false,
  loading: () => {
    trackComponentLoad('SuperAdminDashboard', 10);
    return <div className="animate-pulse bg-white/5 rounded-lg h-96" />;
  },
});

const AdminDashboard = dynamic(() => import("./components/AdminDashboard"), {
  ssr: false,
  loading: () => {
    trackComponentLoad('AdminDashboard', 10);
    return <div className="animate-pulse bg-white/5 rounded-lg h-96" />;
  },
});

const DentistDashboard = dynamic(() => import("./components/DentistDashboard"), {
  ssr: false,
  loading: () => {
    trackComponentLoad('DentistDashboard', 10);
    return <div className="animate-pulse bg-white/5 rounded-lg h-96" />;
  },
});

export default async function AdminDashboardPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // Redirect to user's ID-based URL
  redirect(`/${user.username}`);

  // Render different dashboard based on user role
  if (user.role === "owner") {
    return <SuperAdminDashboard />;
  }

  if (user.role === "admin") {
    return <AdminDashboard />;
  }

  if (user.role === "dentist") {
    return <DentistDashboard />;
  }

  // Fallback for other roles
  return (
    <div>
      <header className="mb-8">
        <h1 className="font-display text-4xl text-ivory-100">Dashboard</h1>
        <p className="mt-2 text-ivory-100/70">Witaj, {user.display_name}</p>
      </header>
      <div className="marble-card p-6">
        <p className="text-ivory-100/60">Dashboard dla Twojej roli będzie dostępny wkrótce.</p>
      </div>
    </div>
  );
}
