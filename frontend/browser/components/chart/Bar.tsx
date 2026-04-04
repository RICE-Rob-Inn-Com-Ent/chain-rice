"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { BarChart, Bar as RBar, ResponsiveContainer, Tooltip, XAxis, YAxis, Legend, CartesianGrid } from "recharts";
import { cn } from "@/browser/lib/cn";

export type BarChartProps = {
	data: Record<string, string | number>[];
	orientation?: "horizontal" | "vertical";
	stacked?: boolean;
	grouped?: boolean;
	colors?: string[];
	xAxis?: boolean;
	yAxis?: boolean;
	tooltip?: boolean;
	legend?: boolean;
	radius?: number;
	height?: number;
	loading?: boolean;
	className?: string;
};

export function Bar({
	data,
	orientation = "vertical",
	stacked,
	grouped: _grouped,
	colors = ["#6366f1"],
	xAxis = true,
	yAxis = true,
	tooltip = true,
	legend = true,
	radius = 4,
	height = 320,
	loading,
	className,
}: BarChartProps) {
	if (loading) return <div className={cn("h-80 animate-pulse rounded bg-neutral-100 dark:bg-neutral-900", className)} />;
	const layout = orientation === "horizontal" ? "horizontal" : "vertical";
	return (
		<div className={cn("w-full", className)} style={{ height }}>
			<ResponsiveContainer width="100%" height="100%">
				<BarChart data={data} layout={layout}>
					{xAxis ? <XAxis type={layout === "vertical" ? "category" : "number"} dataKey="name" /> : null}
					{yAxis ? <YAxis type={layout === "vertical" ? "number" : "category"} /> : null}
					<CartesianGrid strokeDasharray="3 3" />
					{tooltip ? <Tooltip /> : null}
					{legend ? <Legend /> : null}
					<RBar dataKey="value" stackId={stacked ? "a" : undefined} fill={colors[0]} radius={[radius, radius, 0, 0]} />
				</BarChart>
			</ResponsiveContainer>
		</div>
	);
}
