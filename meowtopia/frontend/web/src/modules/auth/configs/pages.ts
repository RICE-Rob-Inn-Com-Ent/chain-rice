// ============================================================================
// AUTH PAGES CONFIGURATION
// ============================================================================

import type { 
  AuthMessages, 
  LoginMessages, 
  RegisterMessages, 
  ForgotPasswordMessages, 
  ResetPasswordMessages 
} from '../interfaces/pages';
import type { CommonMessages } from '../../../global';

export const authMessages: AuthMessages = {
  title: "",
  subtitle: "",
  loading: "",
  error: "",
  success: "",
  backToLogin: "Powrót do logowania",
  forgotPassword: "Zapomniałeś hasła?",
  noAccount: "Nie masz konta?",
  hasAccount: "Masz już konto?",
  orDivider: "lub",
  passwordMismatch: "Hasła nie są identyczne",
  termsRequired: "Musisz zaakceptować regulamin",
  passwordRequirements: "Hasło musi zawierać co najmniej 8 znaków, w tym wielką literę, małą literę, cyfrę i znak specjalny",

  fields: {
    fullName: {
      label: "Imię i nazwisko",
      placeholder: "Wprowadź swoje imię i nazwisko",
      icon: "user",
      type: "text",
      required: true,
      validation: {
        minLength: 2,
        maxLength: 100
      }
    },
    email: {
      label: "Adres email",
      placeholder: "Wprowadź swój adres email",
      icon: "mail",
      type: "email",
      required: true,
      validation: {
        pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
        custom: (value: string) => {
          if (!value.includes('@')) {
            return "Adres email musi zawierać @";
          }
          return null;
        }
      }
    },
    password: {
      label: "Hasło",
      placeholder: "Wprowadź swoje hasło",
      icon: "lock",
      type: "password",
      required: true,
      validation: {
        minLength: 8,
        custom: (value: string) => {
          const hasUpper = /[A-Z]/.test(value);
          const hasLower = /[a-z]/.test(value);
          const hasNumber = /\d/.test(value);
          const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(value);
          if (!hasUpper || !hasLower || !hasNumber || !hasSpecial) {
            return "Hasło musi zawierać wielką literę, małą literę, cyfrę i znak specjalny";
          }
          return null;
        }
      }
    },
    confirmPassword: {
      label: "Potwierdź hasło",
      placeholder: "Wprowadź hasło ponownie",
      icon: "lock",
      type: "password",
      required: true,
      validation: {
        custom: (value: string) => {
          // This will be validated against the password field
          return null;
        }
      }
    },
    rememberMe: {
      label: "Zapamiętaj mnie"
    },
    terms: {
      label: "Akceptuję regulamin i politykę prywatności"
    },
    marketing: {
      label: "Chcę otrzymywać informacje marketingowe"
    }
  },
  
  buttons: {
    login: "Zaloguj się",
    register: "Zarejestruj się",
    forgotPassword: "Zapomniałem hasła",
    sendReset: "Wyślij link resetujący",
    resetPassword: "Zmień hasło",
    backToLogin: "Powrót do logowania"
  },
  
  errors: {
    invalidCredentials: "Nieprawidłowy adres email lub hasło",
    accountLocked: "Konto zostało zablokowane. Spróbuj ponownie za 15 minut",
    emailNotVerified: "Adres email nie został zweryfikowany",
    tooManyAttempts: "Zbyt wiele prób logowania. Spróbuj ponownie później",
    emailExists: "Ten adres email jest już zajęty",
    weakPassword: "Hasło jest zbyt słabe",
    invalidEmail: "Nieprawidłowy format adresu email",
    emailNotFound: "Nie znaleziono konta z tym adresem email",
    tooManyRequests: "Zbyt wiele prób. Spróbuj ponownie za godzinę",
    invalidToken: "Nieprawidłowy token resetowania",
    expiredToken: "Token resetowania wygasł",
    passwordMismatch: "Hasła nie są identyczne",
    networkError: "Błąd połączenia. Sprawdź swoje połączenie internetowe"
  }
};

// Login page messages
export const loginMessages: LoginMessages = {
  ...authMessages,
  title: "Zaloguj się",
  subtitle: "Witaj ponownie! Zaloguj się do swojego konta",
  loading: "Logowanie...",
  error: "Wystąpił błąd podczas logowania",
  success: "Pomyślnie zalogowano",
  forgotPassword: "Zapomniałeś hasła?",
  noAccount: "Nie masz konta?",
  orDivider: "lub",
  fields: {
    email: authMessages.fields.email!,
    password: authMessages.fields.password!,
    rememberMe: authMessages.fields.rememberMe!
  },
  buttons: {
    login: "Zaloguj się",
    forgotPassword: "Zapomniałem hasła",
    register: "Zarejestruj się"
  },
  errors: {
    invalidCredentials: "Nieprawidłowy adres email lub hasło",
    accountLocked: "Konto zostało zablokowane. Spróbuj ponownie za 15 minut",
    emailNotVerified: "Adres email nie został zweryfikowany",
    tooManyAttempts: "Zbyt wiele prób logowania. Spróbuj ponownie później",
    networkError: "Błąd połączenia. Sprawdź swoje połączenie internetowe"
  }
};

// Register page messages
export const registerMessages: RegisterMessages = {
  ...authMessages,
  title: "Zarejestruj się",
  subtitle: "Utwórz nowe konto w Meowtopia",
  loading: "Rejestracja...",
  error: "Wystąpił błąd podczas rejestracji",
  success: "Konto zostało utworzone pomyślnie",
  passwordMismatch: "Hasła nie są identyczne",
  termsRequired: "Musisz zaakceptować regulamin",
  hasAccount: "Masz już konto?",
  orDivider: "lub",
  passwordRequirements: "Hasło musi zawierać co najmniej 8 znaków, w tym wielką literę, małą literę, cyfrę i znak specjalny",
  fields: {
    fullName: authMessages.fields.fullName!,
    email: authMessages.fields.email!,
    password: authMessages.fields.password!,
    confirmPassword: authMessages.fields.confirmPassword!,
    terms: authMessages.fields.terms!,
    marketing: authMessages.fields.marketing
  },
  buttons: {
    register: "Zarejestruj się",
    login: "Zaloguj się"
  },
  errors: {
    emailExists: "Ten adres email jest już zajęty",
    weakPassword: "Hasło jest zbyt słabe",
    invalidEmail: "Nieprawidłowy format adresu email",
    networkError: "Błąd połączenia. Sprawdź swoje połączenie internetowe"
  }
};

// Forgot password page messages
export const forgotPasswordMessages: ForgotPasswordMessages = {
  ...authMessages,
  title: "Zapomniałeś hasła?",
  subtitle: "Wprowadź swój adres email, a wyślemy Ci link do resetowania hasła",
  loading: "Wysyłanie...",
  error: "Wystąpił błąd podczas wysyłania emaila",
  success: "Email z linkiem do resetowania hasła został wysłany",
  backToLogin: "Powrót do logowania",
  fields: {
    email: authMessages.fields.email!
  },
  buttons: {
    sendReset: "Wyślij link resetujący",
    backToLogin: "Powrót do logowania"
  },
  errors: {
    emailNotFound: "Nie znaleziono konta z tym adresem email",
    tooManyRequests: "Zbyt wiele prób. Spróbuj ponownie za godzinę",
    networkError: "Błąd połączenia. Sprawdź swoje połączenie internetowe"
  }
};

// Reset password page messages
export const resetPasswordMessages: ResetPasswordMessages = {
  ...authMessages,
  title: "Resetuj hasło",
  subtitle: "Wprowadź nowe hasło dla swojego konta",
  loading: "Resetowanie hasła...",
  error: "Wystąpił błąd podczas resetowania hasła",
  success: "Hasło zostało zmienione pomyślnie",
  backToLogin: "Powrót do logowania",
  fields: {
    password: authMessages.fields.password!,
    confirmPassword: authMessages.fields.confirmPassword!
  },
  buttons: {
    resetPassword: "Zmień hasło",
    backToLogin: "Powrót do logowania"
  },
  errors: {
    invalidToken: "Nieprawidłowy token resetowania",
    expiredToken: "Token resetowania wygasł",
    passwordMismatch: "Hasła nie są identyczne",
    weakPassword: "Hasło jest zbyt słabe",
    networkError: "Błąd połączenia. Sprawdź swoje połączenie internetowe"
  }
};

// Common messages for all auth pages
export const commonMessages: CommonMessages = {
  loading: "Ładowanie...",
  error: "Wystąpił błąd",
  success: "Operacja zakończona pomyślnie",
  cancel: "Anuluj",
  save: "Zapisz",
  delete: "Usuń",
  edit: "Edytuj",
  view: "Zobacz",
  back: "Wstecz",
  next: "Dalej",
  previous: "Poprzedni",
  submit: "Wyślij",
  reset: "Resetuj",
  close: "Zamknij",
  confirm: "Potwierdź",
  yes: "Tak",
  no: "Nie"
};

// Export all messages as a single object for easy access
export const authPageMessages = {
  auth: authMessages,
  login: loginMessages,
  register: registerMessages,
  forgotPassword: forgotPasswordMessages,
  resetPassword: resetPasswordMessages,
  common: commonMessages
}; 