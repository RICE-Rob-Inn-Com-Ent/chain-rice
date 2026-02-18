import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";

export default async function DentistsPage() {
  const user = await getCurrentUser();

  // Jeśli użytkownik nie jest zalogowany, przenieś go do logowania
  if (!user) {
    redirect("/sign-in");
  }

  // Przekieruj do zintegrowanej strony wizyt z filtrem na dentystów
  redirect(`/${user.username}/appointments?filter=dentists`);
}

