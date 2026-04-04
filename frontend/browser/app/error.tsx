"use client";

// TODO:
// [ ] "use client" boundary; Sentry when NEXT_PUBLIC_SENTRY_DSN; PostHog when NEXT_PUBLIC_POSTHOG_KEY — https://nextjs.org/docs/app/api-reference/file-conventions/error
// [ ] UI: retry via reset(); report via web/mail.go endpoint from env
//
import { useEffect } from "react";

export type ErrorPageProps = {
	error: Error & { digest?: string };
	reset: () => void;
};

export default function ErrorPage({ error, reset }: ErrorPageProps) {
	useEffect(() => {
		// Surface to monitoring in production integrations.
		console.error(error);
	}, [error]);

	return (
		<div className="flex min-h-dvh flex-col items-center justify-center gap-4 p-8 text-center">
			<h1 className="text-xl font-semibold">Something went wrong</h1>
			<p className="max-w-md text-sm text-neutral-600 dark:text-neutral-400">{error.message}</p>
			<button
				type="button"
				className="rounded-md bg-neutral-900 px-4 py-2 text-sm text-white dark:bg-neutral-100 dark:text-neutral-900"
				onClick={() => reset()}
			>
				Try again
			</button>
		</div>
	);
}
