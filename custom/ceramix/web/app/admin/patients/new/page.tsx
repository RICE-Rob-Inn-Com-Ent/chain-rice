import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";

export default async function NewPatientPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  redirect(`/${user.username}/users`);
}
