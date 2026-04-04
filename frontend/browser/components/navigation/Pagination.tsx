"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { cn } from "@/browser/lib/cn";

export type PaginationProps = {
	page: number;
	total: number;
	pageSize: number;
	onChange: (page: number) => void;
	showTotal?: boolean;
	siblingCount?: number;
	className?: string;
};

function range(start: number, end: number) {
	return Array.from({ length: end - start + 1 }, (_, i) => start + i);
}

export function Pagination({
	page,
	total,
	pageSize,
	onChange,
	showTotal = true,
	siblingCount = 1,
	className,
}: PaginationProps) {
	const pageCount = Math.max(1, Math.ceil(total / pageSize));
	const start = Math.max(2, page - siblingCount);
	const end = Math.min(pageCount - 1, page + siblingCount);
	const pages = new Set<number>([1, pageCount, page, ...range(start, end)]);

	return (
		<div className={cn("flex flex-wrap items-center gap-2 text-sm", className)}>
			{showTotal ? (
				<span className="text-neutral-600 dark:text-neutral-400">
					{total} total
				</span>
			) : null}
			<div className="flex gap-1">
				<button
					type="button"
					className="rounded border px-2 py-1 disabled:opacity-40"
					disabled={page <= 1}
					onClick={() => onChange(page - 1)}
				>
					Prev
				</button>
				{[...pages]
					.sort((a, b) => a - b)
					.map((p, i, arr) => {
						const prev = arr[i - 1];
						const showEllipsis = prev && p - prev > 1;
						return (
							<span key={p} className="flex items-center gap-1">
								{showEllipsis ? <span className="px-1">…</span> : null}
								<button
									type="button"
									className={cn(
										"min-w-8 rounded border px-2 py-1",
										p === page && "border-neutral-900 bg-neutral-900 text-white dark:border-neutral-100 dark:bg-neutral-100 dark:text-neutral-900",
									)}
									onClick={() => onChange(p)}
								>
									{p}
								</button>
							</span>
						);
					})}
				<button
					type="button"
					className="rounded border px-2 py-1 disabled:opacity-40"
					disabled={page >= pageCount}
					onClick={() => onChange(page + 1)}
				>
					Next
				</button>
			</div>
		</div>
	);
}
