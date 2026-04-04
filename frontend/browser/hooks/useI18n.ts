"use client";

// TODO:
// [ ] useI18n: t, locale, setLocale — next-intl — https://next-intl.dev/docs/usage/messages
// [ ] setLocale + cookie for SSR — https://next-intl.dev/docs/routing/middleware
//
import { useLocale as useNextLocale } from "next-intl";
import { useCallback } from "react";
import { useTranslations } from "next-intl";

export function useT(namespace?: string) {
	return useTranslations(namespace);
}

export function useLocale(): string {
	return useNextLocale();
}

/** Wire to your next-intl / app router locale strategy; this keeps a synchronous hook surface. */
export function useChangeLocale() {
	return useCallback((locale: string) => {
		try {
			document.cookie = `NEXT_LOCALE=${encodeURIComponent(locale)}; path=/; max-age=31536000`;
			document.documentElement.lang = locale;
		} catch {
			/* ignore */
		}
		window.location.reload();
	}, []);
}
