"use client";
import React, { useEffect, useState } from "react";

// Prosty przełącznik motywu (dark/light) z pamięcią w localStorage
// i natychmiastową aktualizacją klasy na <html>.
const ThemeToggle: React.FC = () => {
	const [isDark, setIsDark] = useState<boolean>(false);

	// Ustal stan po montażu (SSR-safe)
	useEffect(() => {
		try {
			const ls = typeof window !== "undefined" ? localStorage.getItem("theme") : null;
			const prefersDark = typeof window !== "undefined" && window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
			const current = ls === "dark" || (!ls && prefersDark);
			setIsDark(current);
			const el = document.documentElement;
			if (current) el.classList.add("dark");
			else el.classList.remove("dark");
		} catch (_) {
			// ignoruj
		}
	}, []);

	const toggle = () => {
		const next = !isDark;
		setIsDark(next);
		const el = document.documentElement;
		if (next) {
			el.classList.add("dark");
			try { localStorage.setItem("theme", "dark"); } catch {}
		} else {
			el.classList.remove("dark");
			try { localStorage.setItem("theme", "light"); } catch {}
		}
	};

		return (
		<button
			type="button"
			onClick={toggle}
			aria-label={isDark ? "Przełącz na jasny motyw" : "Przełącz na ciemny motyw"}
			title={isDark ? "Jasny motyw" : "Ciemny motyw"}
			className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-white/10 bg-black/50 text-slate-200 shadow-sm backdrop-blur-md transition hover:border-white/20 hover:text-white focus:outline-none focus:ring-2 focus:ring-cyan-400/40 dark:bg-slate-900/60"
		>
				{isDark ? (
					// Księżyc (w trybie ciemnym pokazujemy księżyc)
					<svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
						<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79Z" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
					</svg>
				) : (
					// Słońce (w trybie jasnym pokazujemy słońce)
					<svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
						<path d="M12 18a6 6 0 1 0 0-12 6 6 0 0 0 0 12Z" stroke="currentColor" strokeWidth="1.8"/>
						<path d="M12 2v2m0 16v2M4.93 4.93l1.41 1.41m11.32 11.32 1.41 1.41M2 12h2m16 0h2M6.34 17.66l-1.41 1.41m13.72-13.72 1.41-1.41" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/>
					</svg>
				)}
		</button>
	);
};

export default ThemeToggle;
