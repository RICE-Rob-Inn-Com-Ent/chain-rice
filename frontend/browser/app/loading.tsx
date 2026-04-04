// TODO:
// [ ] Shell + Skeleton matching target layout — zero layout shift — https://nextjs.org/docs/app/api-reference/file-conventions/loading
//
import { Skeleton } from "@/browser/components/feedback/Skeleton";

export default function Loading() {
	return (
		<div className="flex min-h-dvh flex-col gap-4 p-6">
			<Skeleton variant="rect" height={48} className="w-full max-w-md" />
			<Skeleton variant="text" count={3} className="w-full max-w-lg" />
			<div className="grid gap-3 md:grid-cols-2">
				<Skeleton variant="card" height={160} />
				<Skeleton variant="card" height={160} />
			</div>
		</div>
	);
}
