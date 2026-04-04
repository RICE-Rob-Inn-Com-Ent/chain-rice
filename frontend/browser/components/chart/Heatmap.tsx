"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { cn } from "@/browser/lib/cn";

export type HeatmapCell = { x: string | number; y: string | number; value: number };

export type HeatmapProps = {
	data: HeatmapCell[];
	colors?: string[];
	tooltip?: boolean;
	xAxis?: boolean;
	yAxis?: boolean;
	cellSize?: number;
	gap?: number;
	height?: number;
	loading?: boolean;
	className?: string;
};

export function Heatmap({
	data,
	colors = ["#0ea5e9", "#0369a1"],
	tooltip: _tooltip,
	xAxis: _xAxis,
	yAxis: _yAxis,
	cellSize = 24,
	gap = 2,
	height = 320,
	loading,
	className,
}: HeatmapProps) {
	const max = Math.max(1, ...data.map((d) => d.value));
	if (loading) return <div className={cn("h-80 animate-pulse rounded bg-neutral-100 dark:bg-neutral-900", className)} />;
	return (
		<div className={cn("w-full overflow-auto", className)} style={{ height }}>
			<div className="grid" style={{ gap, gridTemplateColumns: `repeat(auto-fill, minmax(${cellSize}px, 1fr))` }}>
				{data.map((d, i) => (
					<div
						key={i}
						title={`${d.x},${d.y}: ${d.value}`}
						className="rounded-sm"
						style={{
							width: cellSize,
							height: cellSize,
							background: `color-mix(in oklab, ${colors[1]} ${(d.value / max) * 100}%, ${colors[0]})`,
						}}
					/>
				))}
			</div>
		</div>
	);
}
