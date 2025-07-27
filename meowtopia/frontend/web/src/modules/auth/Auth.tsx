import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import Register from "./pages/Register";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import ConfirmEmail from "./pages/ConfirmEmail";

const Auth: React.FC = () => (
  <Routes>
    <Route path="login" element={<Login />} />
    <Route path="register" element={<Register />} />
    <Route path="forgot-password" element={<ForgotPassword />} />
    <Route path="reset-password" element={<ResetPassword />} />
    <Route path="confirm-email" element={<ConfirmEmail />} />
    <Route path="" element={<Navigate to="/auth/login" replace />} />
    <Route path="*" element={<Navigate to="/auth/login" replace />} />
  </Routes>
);

export default Auth;
