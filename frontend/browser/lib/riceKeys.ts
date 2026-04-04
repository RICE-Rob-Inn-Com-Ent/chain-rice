// TODO:
// [ ] key factory: all = ["rice"] as const; project(id); role(r); model(role) — https://tanstack.com/query/latest/docs/framework/react/guides/query-keys
// [ ] invalidateProject(queryClient, id); invalidateAll(queryClient)
//
/** Namespaced Rice runtime keys — CHIEF hydrates values; SMITH serves db/ai routes. */

export const ricePrefixes = {
	db: "db.",
	ai: "ai.",
	ui: "ui.",
	i18n: "i18n.",
	feature: "feature.",
} as const;

export function riceDbKey(path: string): string {
	return `${ricePrefixes.db}${path}`;
}

export function riceAiKey(path: string): string {
	return `${ricePrefixes.ai}${path}`;
}

export function riceUiKey(path: string): string {
	return `${ricePrefixes.ui}${path}`;
}

export function riceI18nKey(path: string): string {
	return `${ricePrefixes.i18n}${path}`;
}

export function riceFeatureKey(path: string): string {
	return `${ricePrefixes.feature}${path}`;
}

export function isRemoteRiceKey(key: string): boolean {
	return (
		key.startsWith(ricePrefixes.db) || key.startsWith(ricePrefixes.ai)
	);
}

// TODO:
// [ ] Optional allowlist from env (e.g. NEXT_PUBLIC_RICE_KEY_ALLOWLIST) for production hardening.
// [ ] Align key vocabulary with proto messages in frontend/gen/ when MASON adds rice config protos.
