import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import Link from "next/link";

export default async function CustomerDashboard() {
  const session = await getServerSession(authOptions);
  const user = session?.user?.email
    ? await prisma.user.findUnique({ where: { email: session.user.email } })
    : null;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-foam-50">Witaj, {user?.name || user?.email}!</h1>
        <p className="mt-2 text-foam-100/60">Panel klienta - MeoWTopia</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <Link
          href="/products"
          className="rounded-lg border border-white/10 bg-jungle-900/50 p-6 hover:bg-jungle-900/70 transition"
        >
          <h3 className="text-lg font-semibold text-foam-50">Przeglądaj Produkty</h3>
          <p className="mt-2 text-foam-100/60">Zobacz nasz asortyment</p>
        </Link>

        <Link
          href={`/${user?.id}/orders`}
          className="rounded-lg border border-white/10 bg-jungle-900/50 p-6 hover:bg-jungle-900/70 transition"
        >
          <h3 className="text-lg font-semibold text-foam-50">Moje Zamówienia</h3>
          <p className="mt-2 text-foam-100/60">Sprawdź status zamówień</p>
        </Link>

        <Link
          href="/shopping-bag"
          className="rounded-lg border border-white/10 bg-jungle-900/50 p-6 hover:bg-jungle-900/70 transition"
        >
          <h3 className="text-lg font-semibold text-foam-50">Koszyk</h3>
          <p className="mt-2 text-foam-100/60">Zobacz produkty w koszyku</p>
        </Link>
      </div>
    </div>
  );
}

