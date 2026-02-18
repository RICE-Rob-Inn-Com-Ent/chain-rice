import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";

export default async function PatientsPage() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  redirect(`/${user.username}/uzytkownicy`);
}
