import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export default async function AdminDashboard() {
  const session = await getServerSession(authOptions);
  const user = session?.user?.email
    ? await prisma.user.findUnique({ where: { email: session.user.email } })
    : null;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-foam-50">Witaj, {user?.name || user?.email}!</h1>
        <p className="mt-2 text-foam-100/60">Panel administratora - MeoWTopia</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg border border-white/10 bg-jungle-900/50 p-6">
          <h3 className="text-lg font-semibold text-foam-50">Produkty</h3>
          <p className="mt-2 text-foam-100/60">Zarządzaj produktami sklepu</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-jungle-900/50 p-6">
          <h3 className="text-lg font-semibold text-foam-50">Zamówienia</h3>
          <p className="mt-2 text-foam-100/60">Zarządzaj zamówieniami i fakturami</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-jungle-900/50 p-6">
          <h3 className="text-lg font-semibold text-foam-50">Klienci</h3>
          <p className="mt-2 text-foam-100/60">Zarządzaj klientami</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-jungle-900/50 p-6">
          <h3 className="text-lg font-semibold text-foam-50">Magazyn</h3>
          <p className="mt-2 text-foam-100/60">Kontrola stanów magazynowych</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-jungle-900/50 p-6">
          <h3 className="text-lg font-semibold text-foam-50">Raporty</h3>
          <p className="mt-2 text-foam-100/60">Generuj raporty i analizy</p>
        </div>
      </div>
    </div>
  );
}

