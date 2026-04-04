// TODO:
// [ ] token, user, claims; login/logout/refresh — https://docs.pmnd.rs/zustand
// [ ] persist token httpOnly cookie path — never localStorage for PASETO
//
import { create } from "zustand";

export type User = {
	id: string;
	email?: string;
	name?: string;
};

export type Session = {
	token: string;
	expiresAt?: string;
};

type AuthState = {
	user: User | null;
	session: Session | null;
	permissions: string[];
	isAuthenticated: boolean;
	setUser: (user: User | null) => void;
	setSession: (session: Session | null) => void;
	setPermissions: (permissions: string[]) => void;
	clearSession: () => void;
	hasPermission: (permission: string) => boolean;
};

export const useAuthStore = create<AuthState>((set, get) => ({
	user: null,
	session: null,
	permissions: [],
	isAuthenticated: false,
	setUser: (user) =>
		set({
			user,
			isAuthenticated: Boolean(user),
		}),
	setSession: (session) => set({ session }),
	setPermissions: (permissions) => set({ permissions }),
	clearSession: () =>
		set({
			user: null,
			session: null,
			permissions: [],
			isAuthenticated: false,
		}),
	hasPermission: (permission) => get().permissions.includes(permission),
}));
