// ========================================
// MAIN APP - USER APPLICATION
// ========================================

// React and DOM imports
import { createRoot } from "html6";

// React Router imports
import { BrowserRouter, Routes, Route, Navigate } from "html6";

// App components and routes
import { AuthRoutes } from "./routes";
import { Home } from "./components/Home";
import { Profile } from "./components/Profile";

// Authentication and API utilities from html6 package
import { apiClient, authAPI } from "html6";

// ========================================
// API INITIALIZATION
// ========================================
// Initialize axios interceptor for authentication
// This will automatically handle token refresh and redirects
apiClient;

// ========================================
// ROUTE PERMISSION CHECK FUNCTION
// ========================================
function checkUserPermission(route: string): boolean {
  // Define which routes require user authentication
  const protectedRoutes = ['/home', '/profile', '/settings'];
  return protectedRoutes.includes(route);
}

// ========================================
// MAIN APP COMPONENT
// ========================================
const App = () => {
  return (
    <BrowserRouter>
      <Routes>
        {/* ======================================== */}
        {/* AUTHENTICATION ROUTES - Public Access */}
        {/* ======================================== */}
        <Route path="/sign-in" element={<AuthRoutes />} />
        <Route path="/sign-up" element={<AuthRoutes />} />
        <Route path="/forgot-pass" element={<AuthRoutes />} />
        <Route path="/reset-pass" element={<AuthRoutes />} />
        <Route path="/change-pass" element={<AuthRoutes />} />
        <Route path="/confirm-email" element={<AuthRoutes />} />
        <Route path="/two-factor-auth" element={<AuthRoutes />} />

        {/* ======================================== */}
        {/* PROTECTED USER ROUTES - User Only */}
        {/* ======================================== */}
        <Route path="/" element={<Navigate to="/home" replace />} />
        <Route path="/home" element={<Home />} />
        <Route path="/profile" element={<Profile />} />
        <Route path="/settings" element={<div>Settings Page</div>} />
        
        {/* ======================================== */}
        {/* FALLBACK ROUTES - Redirects */}
        {/* ======================================== */}
        <Route path="*" element={<Navigate to="/sign-up" replace />} />
      </Routes>
    </BrowserRouter>
  );
};

// ========================================
// RENDER APP TO DOM
// ========================================
const root = createRoot(document.getElementById('root')!);
root.render(<App />);
