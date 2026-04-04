"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";
import type { PaginationProps } from "@/browser/components/navigation/Pagination";
import { Pagination } from "@/browser/components/navigation/Pagination";

export type TableColumn<T> = {
	key: string;
	header: ReactNode;
	render?: (row: T) => ReactNode;
	sortable?: boolean;
	width?: string | number;
};

export type TableProps<T> = {
	columns: TableColumn<T>[];
	data: T[];
	loading?: boolean;
	onSort?: (key: string, direction: "asc" | "desc") => void;
	onRowClick?: (row: T) => void;
	pagination?: PaginationProps;
	emptyState?: ReactNode;
	stickyHeader?: boolean;
	striped?: boolean;
	className?: string;
};

export function Table<T extends Record<string, unknown>>({
	columns,
	data,
	loading,
	onSort,
	onRowClick,
	pagination,
	emptyState,
	stickyHeader,
	striped,
	className,
}: TableProps<T>) {
	return (
		<div className={cn("w-full overflow-x-auto", className)}>
			<table className="w-full border-collapse text-left text-sm">
				<thead
					className={cn(
						"bg-neutral-50 dark:bg-neutral-900",
						stickyHeader && "sticky top-0 z-10",
					)}
				>
					<tr>
						{columns.map((col) => (
							<th
								key={col.key}
								className="border-b px-3 py-2 font-medium"
								style={{ width: col.width }}
							>
								<button
									type="button"
									className={cn(col.sortable && "underline decoration-dotted")}
									onClick={() => col.sortable && onSort?.(col.key, "asc")}
								>
									{col.header}
								</button>
							</th>
						))}
					</tr>
				</thead>
				<tbody>
					{loading ? (
						<tr>
							<td colSpan={columns.length} className="px-3 py-6 text-center text-neutral-500">
								Loading…
							</td>
						</tr>
					) : data.length === 0 ? (
						<tr>
							<td colSpan={columns.length} className="px-3 py-6 text-center text-neutral-500">
								{emptyState ?? "No data"}
							</td>
						</tr>
					) : (
						data.map((row, ri) => (
							<tr
								key={ri}
								className={cn(
									"border-b border-neutral-100 dark:border-neutral-800",
									striped && ri % 2 === 1 && "bg-neutral-50/50 dark:bg-neutral-900/40",
									onRowClick && "cursor-pointer hover:bg-neutral-50 dark:hover:bg-neutral-900",
								)}
								onClick={() => onRowClick?.(row)}
							>
								{columns.map((col) => (
									<td key={col.key} className="px-3 py-2 align-middle">
										{col.render ? col.render(row) : String(row[col.key] ?? "")}
									</td>
								))}
							</tr>
						))
					)}
				</tbody>
			</table>
			{pagination ? <Pagination {...pagination} className="mt-4" /> : null}
		</div>
	);
}
