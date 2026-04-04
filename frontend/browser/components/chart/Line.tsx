"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import {
	CartesianGrid,
	Line as RLine,
	LineChart,
	ResponsiveContainer,
	Tooltip,
	XAxis,
	YAxis,
	Legend,
	Area,
} from "recharts";
import { cn } from "@/browser/lib/cn";

export type LinePoint = { x: string | number; y: number; series?: string };

export type LineChartProps = {
	data: LinePoint[];
	xAxis?: boolean;
	yAxis?: boolean;
	tooltip?: boolean;
	legend?: boolean;
	zoom?: boolean;
	brush?: boolean;
	colors?: string[];
	smooth?: boolean;
	area?: boolean;
	height?: number;
	loading?: boolean;
	className?: string;
};

export function Line({
	data,
	xAxis = true,
	yAxis = true,
	tooltip = true,
	legend = true,
	colors = ["#3b82f6"],
	smooth,
	area,
	height = 320,
	loading,
	className,
}: LineChartProps) {
	if (loading) return <div className={cn("h-80 animate-pulse rounded bg-neutral-100 dark:bg-neutral-900", className)} />;
	return (
		<div className={cn("w-full", className)} style={{ height }}>
			<ResponsiveContainer width="100%" height="100%">
				<LineChart data={data}>
					{xAxis ? <XAxis dataKey="x" /> : null}
					{yAxis ? <YAxis /> : null}
					<CartesianGrid strokeDasharray="3 3" />
					{tooltip ? <Tooltip /> : null}
					{legend ? <Legend /> : null}
					{area ? <Area type={smooth ? "monotone" : "linear"} dataKey="y" stroke={colors[0]} fill={colors[0]} fillOpacity={0.1} /> : null}
					<RLine type={smooth ? "monotone" : "linear"} dataKey="y" stroke={colors[0]} dot={false} />
				</LineChart>
			</ResponsiveContainer>
		</div>
	);
}
