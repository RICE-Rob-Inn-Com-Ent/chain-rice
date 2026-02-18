import type { Metadata } from "next";
import { BarChart3 } from "lucide-react";
import { GiptHeroPanel } from "@/components/gipt-admin/GiptHeroPanel";

export const metadata: Metadata = {
  title: "Benchmark",
  description: "Model Performance & Comparison",
};

export default function BenchmarkPage() {
  return (
    <GiptHeroPanel
      icon={<BarChart3 className="h-10 w-10" />}
      title="Benchmark"
      subtitle="Model Performance & Comparison"
      accent="border-purple-300 text-purple-200"
    />
  );
}







