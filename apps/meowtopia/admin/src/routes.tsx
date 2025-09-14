// ========================================
// ADMIN ROUTES - ROUTING CONFIGURATION
// ========================================

// React Router imports
import { Routes, Route, BrowserRouter, Navigate } from "html6";

// Authentication components from html6 package
import {
  ForgotPass,
  TwoFactorAuth,
  ChangePass,
  ConfirmEmail,
  ResetPass,
  SignIn,
  SignUp,
} from "html6/auth";

// Admin-specific components
import { Dashboard } from "./components/Dashboard";
import { Users } from "./components/Users";

// ========================================
// ROUTE PERMISSION CHECK FUNCTION
// ========================================
function checkRoutePermission(route: string): boolean {
  // Define which routes require admin permission
  const protectedRoutes = ['/dashboard', '/users', '/settings'];
  return protectedRoutes.includes(route);
}

// ========================================
// ADMIN ROUTES COMPONENT
// ========================================
export const RoutesAdmin = () => {
  return (
    <BrowserRouter>
      <Routes>
        {/* ======================================== */}
        {/* AUTHENTICATION ROUTES - Public Access */}
        {/* ======================================== */}
        <Route path="/sign-in" element={<SignIn />} />
        <Route path="/sign-up" element={<SignUp />} />
        <Route path="/forgot-pass" element={<ForgotPass />} />
        <Route path="/reset-pass" element={<ResetPass />} />
        <Route path="/change-pass" element={<ChangePass />} />
        <Route path="/confirm-email" element={<ConfirmEmail />} />
        <Route path="/two-factor-auth" element={<TwoFactorAuth />} />

        {/* ======================================== */}
        {/* PROTECTED ADMIN ROUTES - Admin Only */}
        {/* ======================================== */}
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/users" element={<Users />} />
        <Route path="/settings" element={<div>Settings Page</div>} />

        {/* ======================================== */}
        {/* FALLBACK ROUTES - Redirects */}
        {/* ======================================== */}
        <Route path="*" element={<Navigate to="/sign-in" replace />} />
      </Routes>
    </BrowserRouter>
  );
};
