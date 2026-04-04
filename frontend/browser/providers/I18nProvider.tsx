"use client";

// TODO:
// [ ] next-intl messages per locale — https://next-intl.dev/docs/usage/configuration
//
import { NextIntlClientProvider } from "next-intl";
import type { AbstractIntlMessages } from "next-intl";
import type { ReactNode } from "react";
import { useTranslations as useNextIntlTranslations } from "next-intl";

export type I18nProviderProps = {
	children: ReactNode;
	locale?: string;
	messages?: AbstractIntlMessages;
};

export function I18nProvider({ children, locale = "en", messages = {} }: I18nProviderProps) {
	return (
		<NextIntlClientProvider locale={locale} messages={messages}>
			{children}
		</NextIntlClientProvider>
	);
}

export { useNextIntlTranslations as useTranslations };
