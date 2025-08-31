import { Routes, Route, Navigate } from "react-router-dom";
import { TwoFactorAuth } from "./pages/2FA";
import { ChangePass } from "./pages/ChangePass";
import { ConfirmEmail } from "./pages/ConfirmEmail";
import { ForgotPass } from "./pages/ForgotPass";
import { ResetPass } from "./pages/ResetPass";
import { SignIn } from "./pages/SignIn";
import { SignUp } from "./pages/SignUp";

const Auth = () => {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/sign-in" replace />} />
      <Route path="/2fa" element={<TwoFactorAuth />} />
      <Route path="/change-pass" element={<ChangePass />} />
      <Route path="/confirm-email" element={<ConfirmEmail />} />
      <Route path="/forgot-pass" element={<ForgotPass />} />
      <Route path="/reset-pass" element={<ResetPass />} />
      <Route path="/sign-in" element={<SignIn />} />
      <Route path="/sign-up" element={<SignUp />} />
    </Routes>
  );
};

export default Auth;
