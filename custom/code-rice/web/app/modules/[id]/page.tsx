import { notFound } from "next/navigation";
import { getModuleById } from "@/lib/company-modules";
import type { Metadata } from "next";

// Import dedykowanych komponentów modułów - HIGH
// AlanSystemsModule przeniesiony do Dashboard jako główny AI Training Hub
// SharpAIModule przeniesiony do zakładki Geny (Training)
import ApjectModule from "../../pages/modules/Apject";
import HostersiModule from "../../pages/modules/Hostersi";
import SpiidModule from "../../pages/modules/Spiid";
// Import MEDIUM priority
import BioStatModule from "../../pages/modules/BioStat";
import DigiTreeModule from "../../pages/modules/DigiTree";
import FireTMSModule from "../../pages/modules/FireTMS";
import LinkPointModule from "../../pages/modules/LinkPoint";
import MedifileModule from "../../pages/modules/Medifile";
import NoMondayModule from "../../pages/modules/NoMonday";
import SixteractiveModule from "../../pages/modules/Sixteractive";
// Import LOW priority
import FireUpModule from "../../pages/modules/FireUp";
import ServerSMSModule from "../../pages/modules/ServerSMS";

type Props = {
  params: { id: string };
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const module = getModuleById(params.id);
  
  if (!module) {
    return {
      title: "Moduł nie znaleziony | RICE",
    };
  }

  return {
    title: `${module.name} | Moduły Firm IT | RICE`,
    description: module.description,
    keywords: [module.name, module.category, module.inspiredBy, "RICE", "moduły IT"],
  };
}

export default function ModulePage({ params }: Props) {
  const module = getModuleById(params.id);

  if (!module) {
    notFound();
  }

  // Routing do dedykowanych komponentów
  switch (params.id) {
    // HIGH PRIORITY
    // alan-systems przeniesiony do Dashboard
    // sharpai przeniesiony do Geny (Training)
    case "apject":
      return <ApjectModule />;
    case "hostersi":
      return <HostersiModule />;
    case "spiid":
      return <SpiidModule />;
    
    // MEDIUM PRIORITY
    case "biostat":
      return <BioStatModule />;
    case "digitree":
      return <DigiTreeModule />;
    case "firetms":
      return <FireTMSModule />;
    case "linkpoint":
      return <LinkPointModule />;
    case "medifile":
      return <MedifileModule />;
    case "nomonday":
      return <NoMondayModule />;
    case "sixteractive":
      return <SixteractiveModule />;
    
    // LOW PRIORITY
    case "fireup":
      return <FireUpModule />;
    case "serversms":
      return <ServerSMSModule />;
    
    default:
      notFound();
  }
}


