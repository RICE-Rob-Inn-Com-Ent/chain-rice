import type { Metadata } from "next";
import { Database } from "lucide-react";
import { GiptHeroPanel } from "@/components/gipt-admin/GiptHeroPanel";

export const metadata: Metadata = {
  title: "Data Manager",
  description: "Data Management Interface",
};

export default function DataManagerPage() {
  return (
    <GiptHeroPanel
      icon={<Database className="h-10 w-10" />}
      title="Data Manager"
      subtitle="Data Management Interface"
      accent="border-blue-400 text-blue-300"
    />
  );
}







