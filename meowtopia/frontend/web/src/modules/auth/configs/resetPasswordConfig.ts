import type { TextProps } from "@/components/Text";
import type { FieldProps } from "@/components/Field";
import type { ClickProps } from "@/components/Click";
import { useState } from "react";
import axios from "axios";

const resetPasswordConfig = {
  resetPasswordForm: {
    className: "flex flex-col bg-[#000000]",
    apiRoute: "/api/v1/auth/reset-password",
    successMessage: "Hasło zmienione pomyślnie!",
    defaultErrorMessage: "Błąd zmiany hasła lub sieci",
    extractErrorMessage: (err: any) => err?.response?.data?.message || null,
    useResetPasswordForm: () => {
      const [password, setPassword] = useState("");
      const [loading, setLoading] = useState(false);
      const [error, setError] = useState("");
      const [success, setSuccess] = useState("");
      const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setLoading(true);
        setError("");
        setSuccess("");
        try {
          await axios.post(resetPasswordConfig.resetPasswordForm.apiRoute, { password });
          setSuccess(resetPasswordConfig.resetPasswordForm.successMessage);
        } catch (err: any) {
          const msg = resetPasswordConfig.resetPasswordForm.extractErrorMessage(err);
          setError(msg || resetPasswordConfig.resetPasswordForm.defaultErrorMessage);
        } finally {
          setLoading(false);
        }
      };
      return {
        passwordFieldProps: {
          value: password,
          onChange: (e: React.ChangeEvent<HTMLInputElement>) => setPassword(e.target.value),
        },
        changeButtonProps: {
          disabled: loading,
        },
        formProps: {
          onSubmit: handleSubmit,
        },
        loading,
        error,
        success,
      };
    },
  },
  pageTitle: {
    tag: "h2",
    children: "Resetuj hasło",
    className: "mb-4",
  } as const,
  passwordField: {
    tag: "input",
    type: "password",
    label: "Nowe hasło",
    icon: "lock-outline",
    placeholder: "Wpisz nowe hasło",
    className: "mb-4",
  } as const,
  changeButton: {
    tag: "button",
    type: "submit",
    children: "Zmień hasło",
    ariaLabel: "Zmień hasło",
    className: "mb-4",
  } as const,
  errorText: {
    tag: "span",
    className: "text-red-500 mb-2",
  } as const,
  successText: {
    tag: "span",
    className: "text-green-500 mb-2",
  } as const,
};

export default resetPasswordConfig; 