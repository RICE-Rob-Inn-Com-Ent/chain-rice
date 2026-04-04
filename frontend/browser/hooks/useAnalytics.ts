"use client";

// TODO:
// [ ] useAnalytics: track, page, identify — wraps lib/analytics — https://posthog.com/docs/libraries/js
// [ ] pathname effect page views
// [ ] trackCookStart, trackRuleDelegate helpers
//
import { useCallback } from "react";
import { featureFlag, identify, track } from "@/browser/lib/analytics";

export function useTrack() {
	return useCallback((event: string, props?: Record<string, unknown>) => {
		track(event, props);
	}, []);
}

export function useFeatureFlag(flag: string) {
	return featureFlag(flag) ?? false;
}

export function useIdentify() {
	return useCallback((userId: string, traits?: Record<string, unknown>) => {
		identify(userId, traits);
	}, []);
}
