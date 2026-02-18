import type { Metadata } from "next";
import { Cloud } from "lucide-react";
import { GiptHeroPanel } from "@/components/gipt-admin/GiptHeroPanel";

export const metadata: Metadata = {
  title: "Cloud Manager",
  description: "Cloud Infrastructure Management",
};

export default function CloudManagerPage() {
  return (
    <GiptHeroPanel
      icon={<Cloud className="h-10 w-10" />}
      title="Cloud Manager"
      subtitle="Cloud Infrastructure Management"
      accent="border-orange-400 text-orange-300"
    />
  );
}







