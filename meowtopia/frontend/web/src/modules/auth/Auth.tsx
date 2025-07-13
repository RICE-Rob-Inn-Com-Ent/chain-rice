import React, { useState, useEffect } from "react";
import { Routes, Route, Navigate, useNavigate, useLocation } from "react-router-dom";
import Login from "./pages/Login";
import Register from "./pages/Register";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import { 
  authPageMessages,
  loginMessages,
  registerMessages,
  forgotPasswordMessages,
  resetPasswordMessages
} from "./configs/pages";
import type { 
  LoginFormData, 
  RegisterFormData, 
  ForgotPasswordFormData, 
  ResetPasswordFormData 
} from "./interfaces/pages";
import { validateField, makeApiCall, handleAuthError } from "./utils";
import { useAuth } from "../../contexts/AuthContext";

const Auth: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuth();
  
  // Form states
  const [loginData, setLoginData] = useState<LoginFormData>({
    email: "",
    password: "",
    rememberMe: false,
  });
  
  const [registerData, setRegisterData] = useState<RegisterFormData>({
    fullName: "",
    email: "",
    password: "",
    confirmPassword: "",
    terms: false,
    marketing: false,
  });
  
  const [forgotPasswordData, setForgotPasswordData] = useState<ForgotPasswordFormData>({
    email: "",
  });
  
  const [resetPasswordData, setResetPasswordData] = useState<ResetPasswordFormData>({
    password: "",
    confirmPassword: "",
  });
  
  // UI states
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  
  // Get token from URL for reset password
  const token = new URLSearchParams(location.search).get("token");

  // Clear messages when route changes
  useEffect(() => {
    setError("");
    setSuccess("");
  }, [location.pathname]);

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================

  const clearMessages = () => {
    setError("");
    setSuccess("");
  };

  const setLoadingState = (isLoading: boolean) => {
    setLoading(isLoading);
    if (isLoading) clearMessages();
  };

  // ============================================================================
  // LOGIN LOGIC
  // ============================================================================

  const handleLoginInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    const checked = (e.target as HTMLInputElement).checked;
    setLoginData(prev => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleLoginSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      // Validate email
      const emailError = validateField(loginData.email, [
        { type: "required", message: "Email jest wymagany" },
        { type: "email", message: "Nieprawidłowy format email" }
      ]);
      if (emailError) {
        setError(emailError);
        return;
      }

      // Make API call (placeholder - replace with actual API endpoint)
      const response = await makeApiCall({
        url: "/api/auth/login",
        method: "POST",
        headers: {},
        timeout: 10000,
        retryAttempts: 3
      }, {
        email: loginData.email,
        password: loginData.password,
      });

      // Store tokens
      localStorage.setItem("access_token", response.access_token);
      localStorage.setItem("refresh_token", response.refresh_token);
      
      // Store remember me preference
      if (loginData.rememberMe) {
        localStorage.setItem("remember_me", "true");
      }

      // Update auth context with user data
      login(response.user);

      setSuccess(loginMessages.success);
      
      // Redirect after success
      setTimeout(() => {
        navigate("/");
      }, 1000);

    } catch (err: any) {
      setError(handleAuthError(err));
    } finally {
      setLoadingState(false);
    }
  };

  const handleSocialLogin = (provider: any) => {
    // Placeholder for social login
    console.log("Social login with:", provider);
  };

  // ============================================================================
  // REGISTER LOGIC
  // ============================================================================

  const handleRegisterInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    const checked = (e.target as HTMLInputElement).checked;
    setRegisterData(prev => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleRegisterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      // Validate all fields
      const emailError = validateField(registerData.email, [
        { type: "required", message: "Email jest wymagany" },
        { type: "email", message: "Nieprawidłowy format email" }
      ]);
      const fullNameError = validateField(registerData.fullName, [
        { type: "required", message: "Imię i nazwisko jest wymagane" },
        { type: "minLength", value: 2, message: "Imię i nazwisko musi mieć co najmniej 2 znaki" }
      ]);
      const passwordError = validateField(registerData.password, [
        { type: "required", message: "Hasło jest wymagane" },
        { type: "minLength", value: 8, message: "Hasło musi mieć co najmniej 8 znaków" }
      ]);

      if (emailError) {
        setError(emailError);
        return;
      }
      if (fullNameError) {
        setError(fullNameError);
        return;
      }
      if (passwordError) {
        setError(passwordError);
        return;
      }

      // Check password confirmation
      if (registerData.password !== registerData.confirmPassword) {
        setError(registerMessages.passwordMismatch);
        return;
      }

      // Check terms acceptance
      if (!registerData.terms) {
        setError(registerMessages.termsRequired);
        return;
      }

      // Make API call (placeholder - replace with actual API endpoint)
      await makeApiCall({
        url: "/api/auth/register",
        method: "POST",
        headers: {},
        timeout: 10000,
        retryAttempts: 3
      }, {
        username: registerData.email.split("@")[0],
        email: registerData.email,
        password: registerData.password,
        full_name: registerData.fullName,
        role: "USER",
        marketing_opt_in: registerData.marketing || false,
      });

      setSuccess(registerMessages.success);
      
      // Reset form
      setRegisterData({
        fullName: "",
        email: "",
        password: "",
        confirmPassword: "",
        terms: false,
        marketing: false,
      });

      // Redirect to login after 2 seconds
      setTimeout(() => {
        navigate("/auth/login");
      }, 2000);

    } catch (err: any) {
      setError(handleAuthError(err));
    } finally {
      setLoadingState(false);
    }
  };

  const handleSocialRegister = (provider: any) => {
    // Placeholder for social register
    console.log("Social register with:", provider);
  };

  // ============================================================================
  // FORGOT PASSWORD LOGIC
  // ============================================================================

  const handleForgotPasswordInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForgotPasswordData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleForgotPasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      // Validate email
      const emailError = validateField(forgotPasswordData.email, [
        { type: "required", message: "Email jest wymagany" },
        { type: "email", message: "Nieprawidłowy format email" }
      ]);
      if (emailError) {
        setError(emailError);
        return;
      }

      // Make API call (placeholder - replace with actual API endpoint)
      await makeApiCall({
        url: "/api/auth/forgot-password",
        method: "POST",
        headers: {},
        timeout: 10000,
        retryAttempts: 3
      }, {
        email: forgotPasswordData.email,
      });

      setSuccess(forgotPasswordMessages.success);
      
      // Reset form
      setForgotPasswordData({ email: "" });

    } catch (err: any) {
      setError(handleAuthError(err));
    } finally {
      setLoadingState(false);
    }
  };

  // ============================================================================
  // RESET PASSWORD LOGIC
  // ============================================================================

  const handleResetPasswordInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setResetPasswordData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleResetPasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      if (!token) {
        setError(resetPasswordMessages.errors.invalidToken);
        return;
      }

      // Validate password
      const passwordError = validateField(resetPasswordData.password, [
        { type: "required", message: "Hasło jest wymagane" },
        { type: "minLength", value: 8, message: "Hasło musi mieć co najmniej 8 znaków" }
      ]);
      if (passwordError) {
        setError(passwordError);
        return;
      }

      // Check password confirmation
      if (resetPasswordData.password !== resetPasswordData.confirmPassword) {
        setError(resetPasswordMessages.errors.passwordMismatch);
        return;
      }

      // Make API call (placeholder - replace with actual API endpoint)
      await makeApiCall({
        url: "/api/auth/reset-password",
        method: "POST",
        headers: {},
        timeout: 10000,
        retryAttempts: 3
      }, {
        token: token,
        password: resetPasswordData.password,
      });

      setSuccess(resetPasswordMessages.success);
      
      // Reset form
      setResetPasswordData({
        password: "",
        confirmPassword: "",
      });

      // Redirect to login after 2 seconds
      setTimeout(() => {
        navigate("/auth/login");
      }, 2000);

    } catch (err: any) {
      setError(handleAuthError(err));
    } finally {
      setLoadingState(false);
    }
  };

  // ============================================================================
  // NAVIGATION HANDLERS
  // ============================================================================

  const handleForgotPassword = () => {
    navigate("/auth/forgot-password");
  };

  const handleRegister = () => {
    navigate("/auth/register");
  };

  const handleLogin = () => {
    navigate("/auth/login");
  };

  const handleBackToLogin = () => {
    navigate("/auth/login");
  };

  // ============================================================================
  // RENDER
  // ============================================================================

  return (
    <Routes>
      <Route 
        path="login" 
        element={
          <Login
            formData={loginData}
            loading={loading}
            error={error}
            success={success}
            onInputChange={handleLoginInputChange}
            onSubmit={handleLoginSubmit}
            onSocialLogin={handleSocialLogin}
            onForgotPassword={handleForgotPassword}
            onRegister={handleRegister}
          />
        } 
      />
      <Route 
        path="register" 
        element={
          <Register
            formData={registerData}
            loading={loading}
            error={error}
            success={success}
            onInputChange={handleRegisterInputChange}
            onSubmit={handleRegisterSubmit}
            onSocialRegister={handleSocialRegister}
            onLogin={handleLogin}
          />
        } 
      />
      <Route 
        path="forgot-password" 
        element={
          <ForgotPassword
            formData={forgotPasswordData}
            loading={loading}
            error={error}
            success={success}
            onInputChange={handleForgotPasswordInputChange}
            onSubmit={handleForgotPasswordSubmit}
            onBackToLogin={handleBackToLogin}
          />
        } 
      />
      <Route 
        path="reset-password" 
        element={
          <ResetPassword
            formData={resetPasswordData}
            loading={loading}
            error={error}
            success={success}
            onInputChange={handleResetPasswordInputChange}
            onSubmit={handleResetPasswordSubmit}
            onBackToLogin={handleBackToLogin}
          />
        } 
      />
      <Route path="" element={<Navigate to="/auth/login" replace />} />
      <Route path="*" element={<Navigate to="/auth/login" replace />} />
    </Routes>
  );
};

export default Auth;
