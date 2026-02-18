import { redirect } from "next/navigation";

/**
 * Not found handler for (roles)/own routes
 * This catches any routes that match /own* but shouldn't (like /own1, /own123, etc.)
 * and redirects them to /me which will redirect to the correct username-based route
 */
export default function NotFound() {
  redirect("/me");
}

