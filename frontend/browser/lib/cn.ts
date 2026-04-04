// TODO:
// [ ] cn(): clsx + tailwind-merge dedupe — https://github.com/dcastil/tailwind-merge
//
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
	return twMerge(clsx(inputs));
}
