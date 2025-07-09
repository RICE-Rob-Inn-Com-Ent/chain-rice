import React, { useState } from "react";
import { Icon } from "@iconify/react";
import { authStyles } from "../styles/authStyles";
import Field from "@/layouts/components/Field";
import Checkbox from "@/layouts/components/Checkbox";
import Button from "@/layouts/components/Button";
import Message from "@/layouts/components/Message";

export const Login = ({
  onSwitchToRegister,
}: {
  onSwitchToRegister?: () => void;
}) => {
  const [email, setEmail] = useState<string>("");
  const [password, setPassword] = useState<string>("");
  const [showPassword, setShowPassword] = useState<boolean>(false); // Not needed, handled in PasswordField
  const [rememberMe, setRememberMe] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>("");
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const response = await fetch("/api/v1/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email: email,
          password: password,
        }),
      });
      if (response.ok) {
        const data = await response.json();
        localStorage.setItem("access_token", data.access_token);
        localStorage.setItem("refresh_token", data.refresh_token);
        window.location.href = "/";
      } else {
        const errorData = await response.json();
        setError(errorData.detail || "Błąd logowania");
      }
    } catch (err) {
      setError("Błąd połączenia z serwerem");
    } finally {
      setLoading(false);
    }
  };
  return (
    <form className={authStyles.form} onSubmit={handleSubmit}>
      <img src="/img/logos/chc-logo-color.png" alt="Cat House Caffè logo" />
      {error && <Message message={error} />}
      <Field
        label="Email:"
        icon="material-symbols-light:alternate-email-rounded"
        type="email"
        name="email"
        placeholder="przykład@mail.com"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
        className={authStyles.label}
      />
      <Field
        label="Hasło:"
        icon="material-symbols-light:lock-open-outline-rounded"
        name="password"
        placeholder="••••••••"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
        className={authStyles.label}
      />
      <Checkbox
        label={"Pamiętaj mnie"}
        checked={rememberMe}
        onChange={() => setRememberMe((v) => !v)}
        className={authStyles.label}
      />
      <Button
        type="submit"
        loading={loading}
        className={authStyles.submitBtn}
        disabled={loading}
        icon="material-symbols-light:login-outline-rounded"
      >
        Login
      </Button>
      {onSwitchToRegister && (
        <div className={authStyles.switchFormContainer}>
          <p className={authStyles.switchFormText}>
            Nie masz jeszcze konta?{" "}
            <button
              type="button"
              onClick={onSwitchToRegister}
              className={authStyles.link}
            >
              Zarejestruj się
            </button>
          </p>
        </div>
      )}
      <div className={authStyles.socialButtonsContainer}>
        <Button type="button" className={authStyles.socialButton}>
          <Icon icon="simple-icons:google" /> Google
        </Button>
        <Button type="button" className={authStyles.socialButton}>
          <Icon icon="simple-icons:meta" /> Meta
        </Button>
      </div>
      {/* Dedicated Register Button */}
      <Button
        type="button"
        className={authStyles.submitBtn + " mt-4"}
        onClick={() => {
          if (onSwitchToRegister) {
            onSwitchToRegister();
          } else {
            window.location.href = "/register";
          }
        }}
        icon="material-symbols-light:person-add-outline-rounded"
      >
        Zarejestruj się
      </Button>
    </form>
  );
};
