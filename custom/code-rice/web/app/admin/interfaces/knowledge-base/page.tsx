import type { Metadata } from "next";
import { BookOpen } from "lucide-react";
import { GiptHeroPanel } from "@/components/gipt-admin/GiptHeroPanel";

export const metadata: Metadata = {
  title: "Knowledge Base",
  description: "Knowledge Management System",
};

export default function KnowledgeBasePage() {
  return (
    <GiptHeroPanel
      icon={<BookOpen className="h-10 w-10" />}
      title="Knowledge Base"
      subtitle="Knowledge Management System"
      accent="border-green-400 text-green-300"
    />
  );
}







