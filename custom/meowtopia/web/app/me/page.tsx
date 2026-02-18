import { redirect } from "next/navigation";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

/**
 * /me route - redirects to user's ID-based URL
 * Example: /me -> /OWN-20251123-143025-000001
 */
export default async function MePage() {
  const session = await getServerSession(authOptions);

  if (!session?.user?.email) {
    redirect("/signin");
  }

  const user = await prisma.user.findUnique({
    where: { email: session.user.email },
  });

  if (!user) {
    redirect("/signin");
  }

  // Redirect to user's ID-based URL
  redirect(`/${user.id}`);
}

