import axios from "axios";
import { useState } from "react";
import type { TextConfig } from "@/components/Text";
import type { FieldConfig } from "@/components/Field";
import type { ClickConfig } from "@/components/Click";

export function useLoginConfig() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError("");
    setSuccess("");
    try {
      const response = await axios.post("/api/v1/auth/login", {
        email,
        password,
        rememberMe,
      });
      if (response.data?.access_token) {
        localStorage.setItem("access_token", response.data.access_token);
      }
      setSuccess("Zalogowano pomyślnie!");
      setTimeout(() => {
        window.location.href = "/admin";
      }, 1000);
    } catch (err: any) {
      const msg = err?.response?.data?.message || null;
      setError(msg || "Błąd logowania lub sieci");
    }
  };

  return {
    formConfig: {
      className: "bg-red-50 p-6 rounded-lg shadow-md max-w-md mx-auto",
      onSubmit: handleSubmit,
    },
    containerConfig: {
      className: "flex items-center",
    },
    titleText: {
      tag: "h1",
      variant: "title-1",
      children: "Logowanie",
    } as TextConfig,
    emailField: {
      tag: "input",
      type: "email",
      role: "default",
      size: "md",
      children: "E-mail",
      icon: "alternate-email-rounded",
      placeholder: "Wpisz e-mail",
      value: email,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setEmail(e.target.value),
    } as FieldConfig,
    passwordField: {
      tag: "input",
      type: "password",
      role: "default",
      size: "md",
      children: "Hasło",
      icon: "lock-outline",
      placeholder: "********",
      value: password,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setPassword(e.target.value),
    } as FieldConfig,
    rememberMeField: {
      tag: "input",
      type: "checkbox",
      role: "default",
      size: "md",
      children: "Zapamiętaj mnie",
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setRememberMe(e.target.checked),
    } as FieldConfig,
    loginClick: {
      type: "submit",
      role: "primary",
      state: "pressed",
      ariaLabel: "Zaloguj się",
      children: "Zaloguj się",
    } as ClickConfig,
    registerText: {
      tag: "span",
      variant: "body",
      children: "Nie masz konta?",
    } as TextConfig,
    registerClick: {
      type: "button",
      role: "secondary",
      state: "pressed",
      ariaLabel: "Zarejestruj się",
      children: "Zarejestruj się",
      onClick: () => {
        window.location.href = "/auth/register";
      },
    } as ClickConfig,
    emailErrorText: {
      tag: "h1",
      variant: "title-1",
      children: "Logowanie",
    } as TextConfig,
    passwordErrorText: {
      tag: "h1",
      variant: "title-1",
      children: "Logowanie",
    } as TextConfig,
    successIcon: {
      icon: "h1",
    },
    useSocialText: {
      tag: "h1",
      variant: "title-1",
      children: "Logowanie",
    } as TextConfig,
  };
}
