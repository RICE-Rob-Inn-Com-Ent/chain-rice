import type { Metadata } from "next";
import { Gauge } from "lucide-react";
import { GiptHeroPanel } from "@/components/gipt-admin/GiptHeroPanel";

export const metadata: Metadata = {
  title: "Dashboard",
  description: "GiPT-1 AGI System Overview",
};

export default function GiptDashboardPage() {
  return (
    <GiptHeroPanel
      icon={<Gauge className="h-10 w-10" />}
      title="Dashboard"
      subtitle="GiPT-1 AGI System Overview"
      accent="border-purple-500 text-purple-400"
    />
  );
}

