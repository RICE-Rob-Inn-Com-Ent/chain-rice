// TODO:
// [ ] 404 metadata; home link via next-intl locale — https://nextjs.org/docs/app/api-reference/file-conventions/not-found
//
import Link from "next/link";

export default function NotFoundPage() {
	return (
		<div className="flex min-h-dvh flex-col items-center justify-center gap-4 p-8 text-center">
			<h1 className="text-2xl font-semibold">404</h1>
			<p className="text-sm text-neutral-600 dark:text-neutral-400">This page could not be found.</p>
			<Link
				href="/"
				className="rounded-md border border-neutral-300 px-4 py-2 text-sm dark:border-neutral-700"
			>
				Back home
			</Link>
		</div>
	);
}
