import type { Metadata } from "next";
import { FlaskRound } from "lucide-react";
import { GiptHeroPanel } from "@/components/gipt-admin/GiptHeroPanel";

export const metadata: Metadata = {
  title: "Geny",
  description: "AI Model Training & Management",
};

export default function TrainingPage() {
  return (
    <GiptHeroPanel
      icon={<FlaskRound className="h-10 w-10" />}
      title="Geny"
      subtitle="AI Model Training & Management"
      accent="border-purple-400 text-purple-300"
    />
  );
}







