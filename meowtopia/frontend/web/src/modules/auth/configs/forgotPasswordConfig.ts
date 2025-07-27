import type { TextProps } from "@/components/Text";
import type { FieldProps } from "@/components/Field";
import type { ClickProps } from "@/components/Click";
import { useState } from "react";
import axios from "axios";

const forgotPasswordConfig = {
  forgotPasswordForm: {
    className: "flex flex-col bg-[#000000]",
    apiRoute: "/api/v1/auth/forgot-password",
    successMessage: "Wysłano e-mail z instrukcjami!",
    defaultErrorMessage: "Błąd wysyłania e-maila lub sieci",
    extractErrorMessage: (err: any) => err?.response?.data?.message || null,
    useForgotPasswordForm: () => {
      const [email, setEmail] = useState("");
      const [loading, setLoading] = useState(false);
      const [error, setError] = useState("");
      const [success, setSuccess] = useState("");
      const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setLoading(true);
        setError("");
        setSuccess("");
        try {
          await axios.post(forgotPasswordConfig.forgotPasswordForm.apiRoute, { email });
          setSuccess(forgotPasswordConfig.forgotPasswordForm.successMessage);
        } catch (err: any) {
          const msg = forgotPasswordConfig.forgotPasswordForm.extractErrorMessage(err);
          setError(msg || forgotPasswordConfig.forgotPasswordForm.defaultErrorMessage);
        } finally {
          setLoading(false);
        }
      };
      return {
        emailFieldProps: {
          value: email,
          onChange: (e: React.ChangeEvent<HTMLInputElement>) => setEmail(e.target.value),
        },
        sendButtonProps: {
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
    children: "Odzyskaj hasło",
    className: "mb-4",
  } as const,
  emailField: {
    tag: "input",
    type: "email",
    label: "E-mail",
    icon: "alternate-email-rounded",
    placeholder: "Wpisz e-mail",
    className: "mb-4",
  } as const,
  sendButton: {
    tag: "button",
    type: "submit",
    children: "Wyślij",
    ariaLabel: "Wyślij",
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

export default forgotPasswordConfig; 