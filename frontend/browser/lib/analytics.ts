// TODO:
// [ ] PostHog init: env.posthogKey/host; client-only — https://posthog.com/docs/libraries/next-js
// [ ] track(); pageview; feature flags useFeatureFlag — https://posthog.com/docs/libraries/js#feature-flags
// [ ] AI bot User-Agent → PostHog for GEO
//
import posthog from "posthog-js";

let initialized = false;

export function initAnalytics(): void {
	if (initialized || typeof window === "undefined") return;
	const key = process.env.NEXT_PUBLIC_POSTHOG_KEY;
	const host = process.env.NEXT_PUBLIC_POSTHOG_HOST ?? "https://app.posthog.com";
	if (!key) return;
	posthog.init(key, {
		api_host: host,
		persistence: "localStorage+cookie",
		capture_pageview: false,
	});
	initialized = true;
}

export function track(event: string, props?: Record<string, unknown>): void {
	if (!initialized) initAnalytics();
	if (!initialized) return;
	posthog.capture(event, props);
}

export function identify(userId: string, traits?: Record<string, unknown>): void {
	if (!initialized) initAnalytics();
	if (!initialized) return;
	posthog.identify(userId, traits);
}

export function pageview(path?: string): void {
	if (!initialized) initAnalytics();
	if (!initialized) return;
	posthog.capture("$pageview", path ? { path } : undefined);
}

export function featureFlag(flag: string): boolean | string | undefined {
	if (!initialized) initAnalytics();
	if (!initialized) return undefined;
	return posthog.getFeatureFlag(flag);
}
