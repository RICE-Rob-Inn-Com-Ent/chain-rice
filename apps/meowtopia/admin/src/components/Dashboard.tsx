import { useState, useEffect } from "html6";
import { apiClient, authAPI } from "html6";

export const Dashboard = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [user, setUser] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    // Check authentication first
    if (!authAPI.isAuthenticated()) {
      window.location.href = '/sign-in';
      return;
    }
    
    setIsAuthenticated(true);
    fetchUserProfile();
    fetchAdminData();
  }, []);

  const fetchUserProfile = async () => {
    try {
      const response = await apiClient.get('/api/auth/profile');
      setUser(response.data.user);
    } catch (error) {
      console.error('Failed to fetch user profile:', error);
    }
  };

  const fetchAdminData = async () => {
    setLoading(true);
    try {
      const response = await apiClient.get('/api/admin/data');
      setData(response.data);
    } catch (error) {
      console.error('Failed to fetch admin data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    await authAPI.logout();
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-xl">Redirecting to sign-in...</div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-xl">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
            </div>
            <div className="flex items-center space-x-4">
              {user && (
                <span className="text-sm text-gray-700">
                  Welcome, {user.name} ({user.role})
                </span>
              )}
              <button
                onClick={handleLogout}
                className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h2 className="text-lg font-medium text-gray-900 mb-4">
                Admin Panel
              </h2>
              
              {data && (
                <div className="space-y-4">
                  <div className="bg-green-50 border border-green-200 rounded-md p-4">
                    <h3 className="text-sm font-medium text-green-800">
                      {data.message}
                    </h3>
                    <p className="text-sm text-green-700 mt-1">
                      You have successfully accessed the admin area.
                    </p>
                  </div>
                  
                  <div className="bg-gray-50 rounded-md p-4">
                    <h4 className="text-sm font-medium text-gray-900 mb-2">
                      Admin Data:
                    </h4>
                    <pre className="text-xs text-gray-600 overflow-auto">
                      {JSON.stringify(data, null, 2)}
                    </pre>
                  </div>
                </div>
              )}

              <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
                  <h3 className="text-sm font-medium text-blue-800">Users</h3>
                  <p className="text-sm text-blue-600 mt-1">Manage user accounts</p>
                </div>
                
                <div className="bg-green-50 border border-green-200 rounded-md p-4">
                  <h3 className="text-sm font-medium text-green-800">Settings</h3>
                  <p className="text-sm text-green-600 mt-1">Configure system settings</p>
                </div>
                
                <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4">
                  <h3 className="text-sm font-medium text-yellow-800">Analytics</h3>
                  <p className="text-sm text-yellow-600 mt-1">View system analytics</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};
