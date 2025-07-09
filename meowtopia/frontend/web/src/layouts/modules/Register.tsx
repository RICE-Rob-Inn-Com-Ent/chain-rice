import React, { useState } from "react";
import { Icon } from "@iconify/react";
import { authStyles } from "../styles/authStyles";
import Field from "@/layouts/components/Field";
import Checkbox from "@/layouts/components/Checkbox";
import Button from "@/layouts/components/Button";
import Message from "@/layouts/components/Message";

export const Register = ({
  onSwitchToLogin,
}: {
  onSwitchToLogin?: () => void;
}) => {
  const [email, setEmail] = useState<string>("");
  const [password, setPassword] = useState<string>("");
  const [confirmPassword, setConfirmPassword] = useState<string>("");
  const [showPassword, setShowPassword] = useState<boolean>(false); // Not needed, handled in PasswordField
  const [showConfirmPassword, setShowConfirmPassword] = useState<boolean>(false); // Not needed, handled in PasswordField
  const [agree, setAgree] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>("");
  const [success, setSuccess] = useState<string>("");
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");
    if (password !== confirmPassword) {
      setError("Hasła nie są identyczne");
      setLoading(false);
      return;
    }
    if (!agree) {
      setError("Musisz zaakceptować regulamin");
      setLoading(false);
      return;
    }
    try {
      const response = await fetch("/api/v1/auth/register", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          username: email.split("@")[0],
          email: email,
          password: password,
          full_name: email.split("@")[0],
          role: "USER",
        }),
      });
      if (response.ok) {
        setSuccess("Konto zostało utworzone! Możesz się teraz zalogować.");
        setEmail("");
        setPassword("");
        setConfirmPassword("");
        setAgree(false);
      } else {
        const errorData = await response.json();
        setError(errorData.detail || "Błąd rejestracji");
      }
    } catch (err) {
      setError("Błąd połączenia z serwerem");
    } finally {
      setLoading(false);
    }
  };
  return (
    <form className={authStyles.form} onSubmit={handleSubmit}>
      <img src="/img/logos/meowtopia-logo.png" alt="Meowtopia logo" />
      {error && <Message message={error} />}
      {success && <Message message={success} />}
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
      <Field
        label="Potwierdź hasło:"
        icon="material-symbols-light:lock-outline"
        name="confirmPassword"
        placeholder="••••••••"
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        required
        className={authStyles.label}
      />
      <Checkbox
        label={<p>Zapoznałem się i zgadzam się z całą {" "}
          <a href="/docs" className={authStyles.link}>
            dokumentacją projektu
          </a>{" "}
          oraz zaznaczam wszystkie wymagane zgody.
        </p>}
        checked={agree}
        onChange={() => setAgree((v) => !v)}
        required
        className={authStyles.label}
      />
      <Button
        type="submit"
        loading={loading}
        className={authStyles.submitBtn}
        disabled={loading}
        icon="material-symbols-light:person-add-outline"
      >
        Zarejestruj
      </Button>
      {onSwitchToLogin && (
        <div className={authStyles.switchFormContainer}>
          <p className={authStyles.switchFormText}>
            Masz już konto?{" "}
            <Button
              type="button"
              onClick={onSwitchToLogin}
              className={authStyles.link}
            >
              Zaloguj się
            </Button>
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
    </form>
  );
};
