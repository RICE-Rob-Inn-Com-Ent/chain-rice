import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { getAIWorkflowsCollection } from "@/lib/mongodb";

export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { query, workflowType } = body;

    if (!query || !workflowType) {
      return NextResponse.json(
        { error: "Missing query or workflowType" },
        { status: 400 }
      );
    }

    // Save workflow interaction to MongoDB
    const workflowsCollection = await getAIWorkflowsCollection();
    await workflowsCollection.insertOne({
      user_id: user.id,
      workflow_type: workflowType,
      query,
      created_at: new Date(),
      status: "pending",
    });

    // TODO: Integrate with actual AI bot service
    // For now, return a mock response based on workflow type
    let response = "";
    
    switch (workflowType) {
      case "dashboard":
        response = `🤖 Rozumiem Twoje zapytanie dotyczące dashboardu: "${query}"\n\n` +
          `Workflow "Zarządzca Rezerwacji" jest w trakcie rozwoju.\n` +
          `Wkrótce będę mógł pomóc z:\n` +
          `• Automatycznym planowaniem wizyt\n` +
          `• Optymalizacją grafiku\n` +
          `• Analizą danych i trendów\n` +
          `• Sugestiami terminów\n\n` +
          `Twoje zapytanie zostało zapisane do bazy danych dla przyszłego treningu LoRA.`;
        break;
      case "accounting":
        response = `💰 Rozumiem Twoje zapytanie dotyczące księgowości: "${query}"\n\n` +
          `Workflow "Asystent Księgowy" jest w trakcie rozwoju.\n` +
          `Wkrótce będę mógł pomóc z:\n` +
          `• Analizą przychodów i kosztów\n` +
          `• Generowaniem raportów finansowych\n` +
          `• Prognozowaniem finansowym\n` +
          `• Zarządzaniem fakturami\n\n` +
          `Twoje zapytanie zostało zapisane do bazy danych dla przyszłego treningu LoRA.`;
        break;
      case "social":
        response = `📱 Rozumiem Twoje zapytanie dotyczące social media: "${query}"\n\n` +
          `Workflow "Specjalista Social Media" jest w trakcie rozwoju.\n` +
          `Wkrótce będę mógł pomóc z:\n` +
          `• Planowaniem postów\n` +
          `• Analizą zasięgu\n` +
          `• Odpowiedziami na komentarze\n` +
          `• Kampaniami reklamowymi\n\n` +
          `Twoje zapytanie zostało zapisane do bazy danych dla przyszłego treningu LoRA.`;
        break;
      default:
        response = `Rozumiem Twoje zapytanie: "${query}"\n\nWorkflow AI jest w trakcie rozwoju.`;
    }

    return NextResponse.json({ response });
  } catch (error: any) {
    console.error("AI workflow error:", error);
    return NextResponse.json(
      { error: error.message || "Internal server error" },
      { status: 500 }
    );
  }
}

