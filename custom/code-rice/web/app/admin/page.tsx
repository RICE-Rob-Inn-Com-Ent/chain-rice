import type { Metadata } from "next";
import { redirect } from "next/navigation";

export const metadata: Metadata = {
  title: "Admin Dashboard",
  description: "RICE Admin Dashboard - Manage your AI models and training",
};

export default function AdminRootPage() {
  redirect("/admin/dashboard");
}

