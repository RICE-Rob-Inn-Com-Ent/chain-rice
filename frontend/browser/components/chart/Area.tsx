"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { Area as RArea, AreaChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { cn } from "@/browser/lib/cn";

export type AreaChartProps = {
	data: Record<string, string | number>[];
	fill?: "solid" | "gradient";
	stacked?: boolean;
	colors?: string[];
	xAxis?: boolean;
	yAxis?: boolean;
	tooltip?: boolean;
	brush?: boolean;
	height?: number;
	loading?: boolean;
	className?: string;
};

export function Area({
	data,
	fill = "gradient",
	stacked,
	colors = ["#22c55e"],
	xAxis = true,
	yAxis = true,
	tooltip = true,
	brush: _brush,
	height = 320,
	loading,
	className,
}: AreaChartProps) {
	if (loading) return <div className={cn("h-80 animate-pulse rounded bg-neutral-100 dark:bg-neutral-900", className)} />;
	return (
		<div className={cn("w-full", className)} style={{ height }}>
			<ResponsiveContainer width="100%" height="100%">
				<AreaChart data={data}>
					<defs>
						<linearGradient id="riceArea" x1="0" y1="0" x2="0" y2="1">
							<stop offset="5%" stopColor={colors[0]} stopOpacity={0.8} />
							<stop offset="95%" stopColor={colors[0]} stopOpacity={0} />
						</linearGradient>
					</defs>
					{xAxis ? <XAxis dataKey="x" /> : null}
					{yAxis ? <YAxis /> : null}
					<CartesianGrid strokeDasharray="3 3" />
					{tooltip ? <Tooltip /> : null}
					<Legend />
					<RArea
						type="monotone"
						dataKey="y"
						stackId={stacked ? "1" : undefined}
						stroke={colors[0]}
						fill={fill === "gradient" ? "url(#riceArea)" : colors[0]}
					/>
				</AreaChart>
			</ResponsiveContainer>
		</div>
	);
}
