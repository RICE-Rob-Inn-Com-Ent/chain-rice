"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { useRef, useState } from "react";
import { cn } from "@/browser/lib/cn";

export type UploadProps = {
	accept?: string;
	multiple?: boolean;
	maxSize?: number;
	onUpload: (files: File[]) => void | Promise<void>;
	onError?: (err: Error) => void;
	dragDrop?: boolean;
	preview?: boolean;
	progress?: number;
	value?: File[];
	onChange?: (files: File[]) => void;
	className?: string;
};

export function Upload({
	accept,
	multiple,
	maxSize = 10 * 1024 * 1024,
	onUpload,
	onError,
	dragDrop,
	preview,
	progress,
	value,
	onChange,
	className,
}: UploadProps) {
	const inputRef = useRef<HTMLInputElement>(null);
	const [drag, setDrag] = useState(false);

	const handleFiles = async (files: FileList | null) => {
		if (!files?.length) return;
		const list = Array.from(files);
		for (const f of list) {
			if (f.size > maxSize) {
				onError?.(new Error(`File too large: ${f.name}`));
				return;
			}
		}
		onChange?.(list);
		try {
			await onUpload(list);
		} catch (e) {
			onError?.(e instanceof Error ? e : new Error("upload failed"));
		}
	};

	return (
		<div
			className={cn(
				"rounded-lg border border-dashed border-neutral-300 p-6 text-center dark:border-neutral-700",
				drag && dragDrop && "border-neutral-900 dark:border-neutral-100",
				className,
			)}
			onDragOver={(e) => {
				e.preventDefault();
				if (dragDrop) setDrag(true);
			}}
			onDragLeave={() => setDrag(false)}
			onDrop={(e) => {
				e.preventDefault();
				setDrag(false);
				void handleFiles(e.dataTransfer.files);
			}}
		>
			<input
				ref={inputRef}
				type="file"
				accept={accept}
				multiple={multiple}
				className="hidden"
				onChange={(e) => void handleFiles(e.target.files)}
			/>
			<button type="button" className="text-sm underline" onClick={() => inputRef.current?.click()}>
				Choose files
			</button>
			{progress != null ? <div className="mt-2 h-1 w-full overflow-hidden rounded bg-neutral-200"><div className="h-full bg-neutral-900 transition-[width]" style={{ width: `${progress}%` }} /></div> : null}
			{preview && value?.length ? (
				<ul className="mt-2 text-left text-xs">
					{value.map((f) => (
						<li key={f.name}>{f.name}</li>
					))}
				</ul>
			) : null}
		</div>
	);
}
