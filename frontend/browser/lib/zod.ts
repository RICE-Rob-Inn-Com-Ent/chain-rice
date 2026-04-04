// TODO:
// [ ] shared schemas uuid, email, url, pagination — https://zod.dev/
// [ ] createFormSchema factory + id/createdAt/updatedAt
// [ ] formatZodErrors → Record<field, string> — https://zod.dev/?id=formatting-errors
//
import { z } from "zod";

export const emailSchema = z.string().email();

export const urlSchema = z.string().url();

export const uuidSchema = z.string().uuid();

export const paginationSchema = z.object({
	page: z.number().int().min(1).default(1),
	pageSize: z.number().int().min(1).max(200).default(20),
});

export const sortSchema = z.object({
	field: z.string().min(1),
	direction: z.enum(["asc", "desc"]).default("asc"),
});

export const riceValueSchema = z.union([
	z.string(),
	z.number(),
	z.boolean(),
	z.record(z.unknown()),
	z.array(z.unknown()),
	z.null(),
]);

export type RiceValue = z.infer<typeof riceValueSchema>;

export const riceInjectionSchema = z.record(z.string(), riceValueSchema);
