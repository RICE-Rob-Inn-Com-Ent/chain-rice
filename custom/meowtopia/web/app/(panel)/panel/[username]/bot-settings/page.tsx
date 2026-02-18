import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";
import { Bot, MessageSquare, Settings2, Zap } from "lucide-react";

export default async function BotSettingsPage({
  params,
}: {
  params: { username: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect(`/signin?callbackUrl=/${params.username}/bot-settings`);
  }

  const userRole = (session.user as any)?.role || "USER";
  const allowedRoles = ["ADMIN", "OWNER", "SUPERADMIN"];

  if (!allowedRoles.includes(userRole)) {
    redirect(`/${params.username}/dashboard`);
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Ustawienia dla bota</h1>
        <p className="text-gray-600 mt-2">
          Konfiguruj ustawienia bota i automatyzację
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Bot Configuration */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Bot className="w-6 h-6 text-blue-600" />
            </div>
            <h2 className="text-xl font-bold text-gray-900">
              Konfiguracja bota
            </h2>
          </div>
          <p className="text-gray-600 mb-4">
            Ustawienia podstawowe bota i jego zachowania
          </p>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-700">Status bota</span>
              <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-xs font-semibold">
                Aktywny
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-700">Tryb odpowiedzi</span>
              <span className="text-sm text-gray-600">Automatyczny</span>
            </div>
          </div>
        </div>

        {/* Message Settings */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-purple-100 rounded-lg">
              <MessageSquare className="w-6 h-6 text-purple-600" />
            </div>
            <h2 className="text-xl font-bold text-gray-900">
              Ustawienia wiadomości
            </h2>
          </div>
          <p className="text-gray-600 mb-4">
            Konfiguruj szablony wiadomości i odpowiedzi
          </p>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-700">Powitanie</span>
              <span className="text-sm text-gray-600">Włączone</span>
            </div>
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-700">Auto-odpowiedzi</span>
              <span className="text-sm text-gray-600">Włączone</span>
            </div>
          </div>
        </div>

        {/* Automation */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-orange-100 rounded-lg">
              <Zap className="w-6 h-6 text-orange-600" />
            </div>
            <h2 className="text-xl font-bold text-gray-900">
              Automatyzacja
            </h2>
          </div>
          <p className="text-gray-600 mb-4">
            Zarządzaj automatycznymi akcjami bota
          </p>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-700">Powiadomienia</span>
              <span className="text-sm text-gray-600">Włączone</span>
            </div>
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-700">Synchronizacja</span>
              <span className="text-sm text-gray-600">Co godzinę</span>
            </div>
          </div>
        </div>

        {/* Advanced Settings */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-gray-100 rounded-lg">
              <Settings2 className="w-6 h-6 text-gray-600" />
            </div>
            <h2 className="text-xl font-bold text-gray-900">
              Zaawansowane
            </h2>
          </div>
          <p className="text-gray-600 mb-4">
            Dodatkowe opcje konfiguracji
          </p>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-700">API Key</span>
              <span className="text-sm text-gray-600">••••••••</span>
            </div>
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-700">Webhook URL</span>
              <span className="text-sm text-gray-600">Skonfigurowany</span>
            </div>
          </div>
        </div>
      </div>

      {/* Coming Soon Notice */}
      <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
        <p className="text-sm text-blue-800">
          <strong>Uwaga:</strong> Pełna funkcjonalność ustawień bota będzie dostępna wkrótce.
        </p>
      </div>
    </div>
  );
}





































