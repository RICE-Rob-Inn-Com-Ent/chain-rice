import { z } from "zod";

// Domain schema
const CreateOrder = z.object({
	customerId: z.string().uuid(),
	items: z.array(
		z.object({
			id: z.string().uuid(),
			qty: z.number().int().positive(),
			price: z.number().nonnegative(),
		})
	).min(1),
	currency: z.enum(["USD", "EUR", "PLN"]),
});

type CreateOrder = z.infer<typeof CreateOrder>;

// Pure domain logic (no IO in here)
export function calculateTotal(order: CreateOrder): number {
	return order.items.reduce((acc, it) => acc + it.qty * it.price, 0);
}

// IO-adapter (e.g., tRPC router) — pseudo example to keep it standalone
export async function handleCreateOrder(input: unknown) {
	const parsed = CreateOrder.parse(input);
	const total = calculateTotal(parsed);
	return { id: "order_" + Math.random().toString(36).slice(2), total };
}

// Example usage
async function demo() {
	const order = await handleCreateOrder({
		customerId: "c8b8f4a2-52f1-4a80-9a0f-9f5e61f3c3a0",
		items: [
			{ id: "c8b8f4a2-52f1-4a80-9a0f-9f5e61f3c3a1", qty: 2, price: 12.5 },
			{ id: "c8b8f4a2-52f1-4a80-9a0f-9f5e61f3c3a2", qty: 1, price: 30 },
		],
		currency: "PLN",
	});
	console.log(order);
}

demo().catch(console.error);