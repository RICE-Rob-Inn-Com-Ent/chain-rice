import axios from axios;

const API_BASE_URL =
  (typeof import.meta !== undefined && (import.meta as any)?.env?.VITE_API_BASE_URL) ||
  (typeof process !== undefined && (process as any)?.env?.NEXT_PUBLIC_API_BASE_URL) ||
  http://localhost:8000;

const TOKEN_KEY = auth_token;

const http = axios.create({
  baseURL: API_BASE_URL,
  headers: { Content-Type: application/json },
});

http.interceptors.request.use((config) => {
  const token = getToken();
  if (token) {
    config.headers = config.headers ?? {};
    (config.headers as any).Authorization = `Bearer ${token}`;
  }
  return config;
});

type TokenResponse = {
  access_token?: string;
  token_type?: bearer;
  requires_2fa?: boolean;
  temp_token?: string;
};

type TwoFAInitResponse = {
  secret: string;
  otpauth_url?: string | null;
};

type MeResponse = {
  id: string;
  email: string;
  role: string;
  is_email_confirmed: boolean;
  twofa_enabled: boolean;
};

export function setToken(token: string) {
  if (typeof localStorage !== undefined) {
    localStorage.setItem(TOKEN_KEY, token);
  }
}

export function getToken(): string | null {
  return typeof localStorage !== undefined ? localStorage.getItem(TOKEN_KEY) : null;
}

export function clearToken() {
  if (typeof localStorage !== undefined) {
    localStorage.removeItem(TOKEN_KEY);
  }
}

// Sign Up
export async function signUp(email: string, password: string) {
  const res = await http.post(/auth/register, { email, password });
  return res.data as { message: string; confirm_token?: string; user_id?: string };
}

// Confirm Email
export async function confirmEmail(token: string) {
  const res = await http.post(/auth/confirm-email, { token });
  return res.data as { message: string };
}

// Sign In (handles optional inline 2FA)
export async function signIn(email: string, password: string, twofaCode?: string) {
  const res = await http.post<TokenResponse>(/auth/login, {
    email,
    password,
    twofa_code: twofaCode,
  });

  const data = res.data;
  if (data.access_token) {
    setToken(data.access_token);
    return { ok: true as const, requires2fa: false as const, token: data.access_token };
  }
  if (data.requires_2fa && data.temp_token) {
    return { ok: true as const, requires2fa: true as const, tempToken: data.temp_token };
  }
  return { ok: false as const };
}

// 2FA: initiate (after logged in)
export async function twofaInitiate() {
  const res = await http.post<TwoFAInitResponse>(/auth/2fa/initiate);
  return res.data;
}

// 2FA: verify during login (tempToken) or after initiate (bearer)
export async function send2faCode(code: string, tempToken?: string) {
  const res = await http.post(/auth/2fa/verify, { code, temp_token: tempToken });
  const data = res.data as { message: string; access_token?: string; token_type?: bearer };
  if (data.access_token) {
    setToken(data.access_token);
  }
  return data;
}

// Forgot Password
export async function forgotPassword(email: string) {
  const res = await http.post(/auth/forgot-password, { email });
  return res.data as { message: string; reset_token?: string | null };
}

// Reset Password
export async function resetPassword(token: string, newPassword: string) {
  const res = await http.post(/auth/reset-password, { token, new_password: newPassword });
  return res.data as { message: string };
}

// Change Password (auth required)
export async function changePassword(oldPassword: string, newPassword: string) {
  const res = await http.post(/auth/change-password, {
    old_password: oldPassword,
    new_password: newPassword,
  });
  return res.data as { message: string };
}

// Me (auth required)
export async function me() {
  const res = await http.get<MeResponse>(/auth/me);
  return res.data;
}

const authApi = {
  setToken,
  getToken,
  clearToken,
  signUp,
  confirmEmail,
  signIn,
  twofaInitiate,
  send2faCode,
  forgotPassword,
  resetPassword,
  changePassword,
  me,
};

export default authApi;

