export default function SettingsPage({
  params,
}: {
  params: { username: string };
}) {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
        <p className="text-gray-600 mt-2">
          Manage your account and system preferences
        </p>
      </div>

      <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
        <h2 className="text-xl font-bold text-gray-900 mb-4">
          System Settings
        </h2>
        <p className="text-gray-600">Settings page coming soon...</p>
      </div>
    </div>
  );
}










