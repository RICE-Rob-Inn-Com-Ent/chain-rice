import { Routes, Route } from "html6";
import {
  ForgotPass,
  TwoFactorAuth,
  ChangePass,
  ConfirmEmail,
  ResetPass,
  SignIn,
  SignUp,
} from "html6/auth";

export const AuthRoutes = () => {
  return (
    <Routes>
      <Route path="/two-factor-auth" element={<TwoFactorAuth />} />
      <Route path="/change-pass" element={<ChangePass />} />
      <Route path="/confirm-email" element={<ConfirmEmail />} />
      <Route path="/forgot-pass" element={<ForgotPass />} />
      <Route path="/reset-pass" element={<ResetPass />} />
      <Route path="/sign-in" element={<SignIn />} />
      <Route path="/sign-up" element={<SignUp />} />
    </Routes>
  );
};
