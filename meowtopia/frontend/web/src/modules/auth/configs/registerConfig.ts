import type { TextProps } from "@/components/Text";
import type { FieldProps } from "@/components/Field";
import type { ClickProps } from "@/components/Click";
import { useState } from "react";
import axios from "axios";

export function useRegisterConfig() {
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [username, setUsername] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirm, setPasswordConfirm] = useState("");
  const [terms, setTerms] = useState(false);
  const [privacy, setPrivacy] = useState(false);
  const [cookies, setCookies] = useState(false);
  const [aml, setAml] = useState(false);
  const [newsletter, setNewsletter] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const validate = () => {
    const errors: Record<string, string> = {};
    if (!firstName.trim()) errors.firstName = "Imię jest wymagane";
    if (!lastName.trim()) errors.lastName = "Nazwisko jest wymagane";
    if (!email.trim()) errors.email = "E-mail jest wymagany";
    else if (!/^\S+@\S+\.\S+$/.test(email))
      errors.email = "Nieprawidłowy e-mail";
    if (!username.trim()) errors.username = "Nazwa użytkownika jest wymagana";
    if (!password) errors.password = "Hasło jest wymagane";
    else if (password.length < 8)
      errors.password = "Hasło musi mieć min. 8 znaków";
    if (!passwordConfirm) errors.passwordConfirm = "Potwierdź hasło";
    else if (password !== passwordConfirm)
      errors.passwordConfirm = "Hasła nie są takie same";
    if (!terms) errors.terms = "Musisz zaakceptować regulamin";
    if (!privacy) errors.privacy = "Musisz zaakceptować politykę prywatności";
    if (!cookies) errors.cookies = "Musisz zaakceptować politykę cookies";
    if (!aml) errors.aml = "Musisz zaakceptować politykę AML/KYC";
    return errors;
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError("");
    setSuccess("");
    const errors = validate();
    setFieldErrors(errors);
    if (Object.keys(errors).length > 0) return;
    setLoading(true);
    try {
      await axios.post("/api/v1/auth/register", {
        fullName: firstName + " " + lastName,
        firstName,
        lastName,
        email,
        username,
        phone,
        password,
        confirmPassword: passwordConfirm,
        terms,
        privacy,
        cookies,
        aml,
        mica: false,
        marketing: false,
        newsletter,
      });
      window.location.href = "/auth/confirm-email";
    } catch (err: any) {
      const msg = err?.response?.data?.message || null;
      setError(msg || "Błąd rejestracji lub sieci");
    } finally {
      setLoading(false);
    }
  };

  return {
    formProps: {
      onSubmit: handleSubmit,
      className: "flex flex-col bg-[#000000]",
    },
    pageTitle: {
      tag: "h2" as const,
      children: "Rejestracja",
      className: "mb-4",
    },
    // Form fields
    firstNameField: {
      tag: "input",
      type: "text",
      label: "Imię",
      icon: "person-outline",
      placeholder: "Wpisz imię",
      className: "mb-4",
      value: firstName,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setFirstName(e.target.value),
    } as FieldProps,
    lastNameField: {
      tag: "input",
      type: "text",
      label: "Nazwisko",
      icon: "person-outline",
      placeholder: "Wpisz nazwisko",
      className: "mb-4",
      value: lastName,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setLastName(e.target.value),
    } as FieldProps,
    emailField: {
      tag: "input",
      type: "email",
      label: "E-mail",
      icon: "alternate-email-rounded",
      placeholder: "Wpisz e-mail",
      className: "mb-4",
      value: email,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setEmail(e.target.value),
    } as FieldProps,
    usernameField: {
      tag: "input",
      type: "text",
      label: "Nazwa użytkownika",
      icon: "person",
      placeholder: "Wpisz nazwę użytkownika",
      className: "mb-4",
      value: username,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setUsername(e.target.value),
    } as FieldProps,
    phoneField: {
      tag: "input",
      type: "tel",
      label: "Telefon (opcjonalnie)",
      icon: "call",
      placeholder: "Wpisz numer telefonu",
      className: "mb-4",
      value: phone,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setPhone(e.target.value),
    } as FieldProps,
    passwordField: {
      tag: "input",
      type: "password",
      label: "Hasło",
      icon: "lock-outline",
      placeholder: "********",
      className: "mb-4",
      value: password,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setPassword(e.target.value),
    } as FieldProps,
    passwordConfirmField: {
      tag: "input",
      type: "password",
      label: "Potwierdź hasło",
      icon: "lock-outline",
      placeholder: "********",
      className: "mb-4",
      value: passwordConfirm,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setPasswordConfirm(e.target.value),
    } as FieldProps,
    termsField: {
      tag: "input",
      type: "checkbox",
      label: "Akceptuję regulamin",
      className: "mb-2",
      checked: terms,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setTerms(e.target.checked),
    } as FieldProps,
    privacyField: {
      tag: "input",
      type: "checkbox",
      label: "Akceptuję politykę prywatności",
      className: "mb-2",
      checked: privacy,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setPrivacy(e.target.checked),
    } as FieldProps,
    cookiesField: {
      tag: "input",
      type: "checkbox",
      label: "Akceptuję politykę cookies",
      className: "mb-2",
      checked: cookies,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setCookies(e.target.checked),
    } as FieldProps,
    amlField: {
      tag: "input",
      type: "checkbox",
      label: "Akceptuję politykę AML/KYC",
      className: "mb-4",
      checked: aml,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setAml(e.target.checked),
    } as FieldProps,
    newsletterField: {
      tag: "input",
      type: "checkbox",
      label: "Chcę otrzymywać newsletter (opcjonalnie)",
      className: "mb-4",
      checked: newsletter,
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setNewsletter(e.target.checked),
    } as FieldProps,
    // Error/success text configs
    errorText: error
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: error,
        }
      : null,
    successText: success
      ? {
          tag: "span" as const,
          className: "text-green-500 mb-2",
          children: success,
        }
      : null,
    firstNameErrorText: fieldErrors.firstName
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.firstName,
        }
      : null,
    lastNameErrorText: fieldErrors.lastName
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.lastName,
        }
      : null,
    emailErrorText: fieldErrors.email
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.email,
        }
      : null,
    usernameErrorText: fieldErrors.username
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.username,
        }
      : null,
    passwordErrorText: fieldErrors.password
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.password,
        }
      : null,
    passwordConfirmErrorText: fieldErrors.passwordConfirm
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.passwordConfirm,
        }
      : null,
    termsErrorText: fieldErrors.terms
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.terms,
        }
      : null,
    privacyErrorText: fieldErrors.privacy
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.privacy,
        }
      : null,
    cookiesErrorText: fieldErrors.cookies
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.cookies,
        }
      : null,
    amlErrorText: fieldErrors.aml
      ? {
          tag: "span" as const,
          className: "text-red-500 mb-2",
          children: fieldErrors.aml,
        }
      : null,

    registerButton: {
      tag: "button",
      type: "submit",
      children: "Zarejestruj się",
      ariaLabel: "Zarejestruj się",
      api: "/api/v1/auth/register",
      className: "mb-4",
      disabled: loading,
    } as ClickProps,
    useSocial: {
      tag: "p" as const,
      children: "Lub zarejestruj się przez media społecznościowe",
      className: "mb-4",
    },
    socialProviders: [
      {
        name: "Google",
        tag: "button",
        type: "button",
        children: "Google",
        ariaLabel: "Zarejestruj się przez Google",
        className: "mb-2",
        icon: "logos:google",
        url: "/api/v1/auth/google",
        enabled: true,
        onClick: () => {
          window.location.href = "/api/v1/auth/google";
        },
        disabled: false,
      },
      {
        name: "Facebook",
        tag: "button",
        type: "button",
        children: "Facebook",
        ariaLabel: "Zarejestruj się przez Facebook",
        className: "mb-2",
        icon: "logos:meta",
        url: "/api/v1/auth/facebook",
        enabled: true,
        onClick: () => {
          window.location.href = "/api/v1/auth/facebook";
        },
        disabled: false,
      },
      {
        name: "GitHub",
        tag: "button",
        type: "button",
        children: "GitHub",
        ariaLabel: "Zarejestruj się przez GitHub",
        className: "mb-2",
        icon: "logos:github",
        url: "/api/v1/auth/github",
        enabled: true,
        onClick: () => {
          window.location.href = "/api/v1/auth/github";
        },
        disabled: false,
      },
    ],
    loading,
  };
}
