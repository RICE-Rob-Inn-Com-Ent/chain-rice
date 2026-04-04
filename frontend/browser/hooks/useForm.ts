"use client";

// TODO:
// [ ] useRiceForm zodResolver + react-hook-form — https://react-hook-form.com/
// [ ] ConnectRPC errors → field errors
//
import { useForm as useTanstackForm } from "@tanstack/react-form";
import { useCallback, useState } from "react";
import type { z } from "zod";
import { toast } from "sonner";

export type UseRiceFormOptions<T extends Record<string, unknown>> = {
	defaultValues: T;
	onSubmit: (values: T) => void | Promise<void>;
	schema?: z.ZodType<T>;
};

export function useForm<T extends Record<string, unknown>>({
	defaultValues,
	onSubmit,
	schema,
}: UseRiceFormOptions<T>) {
	const [submitError, setSubmitError] = useState<string | null>(null);

	const form = useTanstackForm({
		defaultValues,
		onSubmit: async ({ value }) => {
			setSubmitError(null);
			try {
				let data = value as T;
				if (schema) {
					const parsed = schema.safeParse(value);
					if (!parsed.success) {
						const msg = parsed.error.issues[0]?.message ?? "Validation failed";
						setSubmitError(msg);
						toast.error(msg);
						return;
					}
					data = parsed.data;
				}
				await onSubmit(data);
			} catch (e) {
				const msg = e instanceof Error ? e.message : "Submit failed";
				setSubmitError(msg);
				toast.error(msg);
			}
		},
	});

	const handleSubmit = useCallback(async () => {
		await form.handleSubmit();
	}, [form]);

	return { form, submitError, handleSubmit };
}
