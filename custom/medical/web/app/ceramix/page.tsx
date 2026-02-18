import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";

/**
 * /ceramix route - redirects to user's ID-based URL
 * Legacy route, redirects to user ID
 */
export default async function CeramixPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // Redirect to user's username-based URL (GitHub style)
  redirect(`/${user.username}`);
}

