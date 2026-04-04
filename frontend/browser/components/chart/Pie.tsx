"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { Cell, Legend, Pie as RPie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { cn } from "@/browser/lib/cn";

export type PieSlice = { label: string; value: number; color?: string };

export type PieChartProps = {
	data: PieSlice[];
	donut?: boolean;
	innerRadius?: number;
	legend?: boolean;
	labels?: boolean;
	tooltip?: boolean;
	animate?: boolean;
	height?: number;
	loading?: boolean;
	className?: string;
};

export function Pie({
	data,
	donut,
	innerRadius = 40,
	legend = true,
	labels: _labels,
	tooltip = true,
	animate: _animate,
	height = 320,
	loading,
	className,
}: PieChartProps) {
	if (loading) return <div className={cn("h-80 animate-pulse rounded bg-neutral-100 dark:bg-neutral-900", className)} />;
	const outer = 100;
	return (
		<div className={cn("w-full", className)} style={{ height }}>
			<ResponsiveContainer width="100%" height="100%">
				<PieChart>
					<RPie
						data={data}
						dataKey="value"
						nameKey="label"
						cx="50%"
						cy="50%"
						outerRadius={outer}
						innerRadius={donut ? innerRadius : 0}
						label
					>
						{data.map((entry, index) => (
							<Cell key={entry.label} fill={entry.color ?? `hsl(${(index * 40) % 360} 70% 55%)`} />
						))}
					</RPie>
					{tooltip ? <Tooltip /> : null}
					{legend ? <Legend /> : null}
				</PieChart>
			</ResponsiveContainer>
		</div>
	);
}
