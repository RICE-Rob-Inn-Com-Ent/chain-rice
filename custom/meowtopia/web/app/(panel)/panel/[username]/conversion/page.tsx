import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function ConversionPage({
  params,
}: {
  params: { username: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect(`/signin?callbackUrl=/${params.username}/conversion`);
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Współczynnik konwersji</h1>
        <p className="text-gray-600 mt-2">
          Analiza współczynnika konwersji i optymalizacja
        </p>
      </div>
      <div className="bg-white rounded-xl p-6 shadow-sm">
        <p className="text-gray-600">Strona w budowie...</p>
      </div>
    </div>
  );
}





































