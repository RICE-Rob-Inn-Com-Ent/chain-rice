"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { cn } from "@/browser/lib/cn";

export type SliderProps = {
	min: number;
	max: number;
	step?: number;
	value: number | [number, number];
	onChange: (v: number | [number, number]) => void;
	marks?: { value: number; label?: string }[];
	range?: boolean;
	vertical?: boolean;
	formatLabel?: (v: number) => string;
	disabled?: boolean;
	className?: string;
};

export function Slider({
	min,
	max,
	step = 1,
	value,
	onChange,
	marks,
	range,
	vertical,
	formatLabel = (v) => String(v),
	disabled,
	className,
}: SliderProps) {
	if (range && Array.isArray(value)) {
		return (
			<div className={cn(vertical && "flex flex-col gap-2", className)}>
				<input
					type="range"
					min={min}
					max={value[1]}
					step={step}
					value={value[0]}
					disabled={disabled}
					onChange={(e) => onChange([Number(e.target.value), value[1]])}
				/>
				<input
					type="range"
					min={value[0]}
					max={max}
					step={step}
					value={value[1]}
					disabled={disabled}
					onChange={(e) => onChange([value[0], Number(e.target.value)])}
				/>
				<span className="text-xs text-neutral-500">
					{formatLabel(value[0])} — {formatLabel(value[1])}
				</span>
				{marks?.map((m) => (
					<div key={m.value} className="text-xs">
						{m.label ?? m.value}
					</div>
				))}
			</div>
		);
	}
	const v = Array.isArray(value) ? value[0] : value;
	return (
		<div className={cn(vertical && "flex flex-col", className)}>
			<input
				type="range"
				min={min}
				max={max}
				step={step}
				value={v}
				disabled={disabled}
				onChange={(e) => onChange(Number(e.target.value))}
			/>
			<span className="text-xs text-neutral-500">{formatLabel(v)}</span>
		</div>
	);
}
