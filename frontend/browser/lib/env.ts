// TODO:
// [ ] zod schema all NEXT_PUBLIC_* types; parse on load — https://zod.dev/
// [ ] export const env = { apiUrl, wsUrl, appName, ... }; ban raw process.env elsewhere
// [ ] isProduction / isDevelopment / isServer guards
//
import { z } from "zod";

/**
 * Validated public env for BARD browser. All keys are optional at parse time;
 * callers decide fallbacks. Never hardcode URLs or secrets here.
 */
const publicEnvSchema = z.object({
	NEXT_PUBLIC_SMITH_URL: z.string().optional(),
	NEXT_PUBLIC_APP_URL: z.string().optional(),
	NEXT_PUBLIC_APP_TITLE: z.string().optional(),
	NEXT_PUBLIC_APP_DESCRIPTION: z.string().optional(),
	NEXT_PUBLIC_DEFAULT_LOCALE: z.string().optional(),
	NEXT_PUBLIC_POSTHOG_KEY: z.string().optional(),
	NEXT_PUBLIC_POSTHOG_HOST: z.string().optional(),
});

export type PublicEnv = z.infer<typeof publicEnvSchema>;

export function readPublicEnv(): PublicEnv {
	return publicEnvSchema.parse({
		NEXT_PUBLIC_SMITH_URL: process.env.NEXT_PUBLIC_SMITH_URL,
		NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
		NEXT_PUBLIC_APP_TITLE: process.env.NEXT_PUBLIC_APP_TITLE,
		NEXT_PUBLIC_APP_DESCRIPTION: process.env.NEXT_PUBLIC_APP_DESCRIPTION,
		NEXT_PUBLIC_DEFAULT_LOCALE: process.env.NEXT_PUBLIC_DEFAULT_LOCALE,
		NEXT_PUBLIC_POSTHOG_KEY: process.env.NEXT_PUBLIC_POSTHOG_KEY,
		NEXT_PUBLIC_POSTHOG_HOST: process.env.NEXT_PUBLIC_POSTHOG_HOST,
	});
}

// TODO:
// [ ] Extend schema when new NEXT_PUBLIC_* keys are added; keep in sync with Cue smith export.
// [ ] Add RICE_QUERY_STALE_MS-style keys when TanStack Query defaults move to env.
