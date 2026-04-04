"use client";

// TODO:
// [ ] next-themes attribute class, default system, storageKey from env — https://github.com/pacocoursey/next-themes
//
import {
	createContext,
	useCallback,
	useContext,
	useEffect,
	useMemo,
	useState,
	type ReactNode,
} from "react";

export type ThemeMode = "light" | "dark" | "system";

type ThemeContextValue = {
	theme: ThemeMode;
	resolved: "light" | "dark";
	setTheme: (mode: ThemeMode) => void;
};

const ThemeContext = createContext<ThemeContextValue | null>(null);

const STORAGE_KEY = "rice.theme";

function getSystemDark(): boolean {
	if (typeof window === "undefined") return false;
	return window.matchMedia?.("(prefers-color-scheme: dark)")?.matches ?? false;
}

function resolveTheme(mode: ThemeMode): "light" | "dark" {
	if (mode === "system") return getSystemDark() ? "dark" : "light";
	return mode;
}

export type ThemeProviderProps = {
	children: ReactNode;
	defaultTheme?: ThemeMode;
};

export function ThemeProvider({ children, defaultTheme = "system" }: ThemeProviderProps) {
	const [theme, setThemeState] = useState<ThemeMode>(defaultTheme);
	const [resolved, setResolved] = useState<"light" | "dark">(() => resolveTheme(defaultTheme));

	useEffect(() => {
		try {
			const stored = window.localStorage.getItem(STORAGE_KEY) as ThemeMode | null;
			if (stored === "light" || stored === "dark" || stored === "system") {
				setThemeState(stored);
				setResolved(resolveTheme(stored));
			}
		} catch {
			/* ignore */
		}
	}, []);

	useEffect(() => {
		setResolved(resolveTheme(theme));
	}, [theme]);

	useEffect(() => {
		const root = document.documentElement;
		root.classList.toggle("dark", resolved === "dark");
		try {
			window.localStorage.setItem(STORAGE_KEY, theme);
		} catch {
			/* ignore */
		}
	}, [theme, resolved]);

	useEffect(() => {
		const mq = window.matchMedia?.("(prefers-color-scheme: dark)");
		if (!mq) return;
		const onChange = () => {
			if (theme === "system") setResolved(resolveTheme("system"));
		};
		mq.addEventListener("change", onChange);
		return () => mq.removeEventListener("change", onChange);
	}, [theme]);

	const setTheme = useCallback((mode: ThemeMode) => {
		setThemeState(mode);
		setResolved(resolveTheme(mode));
	}, []);

	const value = useMemo(() => ({ theme, resolved, setTheme }), [theme, resolved, setTheme]);

	return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
	const ctx = useContext(ThemeContext);
	if (!ctx) {
		throw new Error("useTheme must be used within ThemeProvider");
	}
	return ctx;
}
