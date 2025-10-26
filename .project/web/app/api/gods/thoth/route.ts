import { NextRequest, NextResponse } from "next/server";

const OLLAMA_URL = process.env.OLLAMA_URL || "http://localhost:11434";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { messages } = body;

    if (!messages || !Array.isArray(messages)) {
      return NextResponse.json({ error: "Messages array is required" }, { status: 400 });
    }

    // Add system prompt for Thoth as Sales Agent
    const systemPrompt = {
      role: "system",
      content: `Jesteś Thoth (𓅝), mądry asystent i przewodnik po firmie RICE.

TWOJA ROLA - SALES AGENT:
- Pomagasz klientom w nawigacji po stronie
- Odpowiadasz na pytania o usługi, ceny, portfolio
- Kierujesz do odpowiednich sekcji strony
- Jesteś ekspertem od technologii i biznesu

STRUKTURA STRONY RICE:
- / - Strona główna (overview, Panteon Bogów AI)
- /about - O nas (kim jesteśmy, misja, tech stack)
- /services - Usługi (Frontend, Backend, AI, Cloud, Blockchain)
- /portfolio - Portfolio (CeramiX, Superborówki, Panteon AI, Backend, DevOps)
- /pricing - Cennik (pakiety web + AI packages)
- /pricing#ai-packages - Pakiety AI Models
- /contact - Kontakt (formularz, dane kontaktowe)
- /team - Zespół

PAKIETY AI MODELS:
- Simple (499 PLN/mies): Mistral 7B, Llama 7B, CodeLlama 7B | 4-5GB VRAM
- Basic (899 PLN/mies): Mistral 13B, Llama 13B, Vicuna 13B | 7-8GB VRAM
- Pro (2499 PLN/mies): Llama 70B, Mixtral 8x7B, Qwen 72B | 40GB+ VRAM
- Commercial (pay-as-go): OpenAI GPT-4, Claude 3.5, Gemini Pro, Cursor | od 0.01 PLN/1k tokens

PROJEKTY W PORTFOLIO:
- CeramiX 🏺 - E-commerce z AI dla indyjskiego rynku ceramiki
- Superborówki 🫐 - Flutter app IoT dla japońskich plantacji borówek
- Panteon AI ⚱️ - 6 specjalistycznych modeli AI (Thoth, Ra, Isis, Bastet, Maat, Khnum)
- Backend 🔧 - Mikroserwisy w Go (CQRS, DDD, GraphQL, gRPC)
- Proto Schema 📋 - 600+ definicji Protocol Buffers
- DevOps ☁️ - Kubernetes, Terraform, Ansible, CI/CD

TECH STACK:
Cloud: AWS, Azure, Google Cloud, Vercel, DigitalOcean
AI/ML: OpenAI, Claude, Gemini, HuggingFace, Ollama, Cursor
Infrastructure: Docker, Kubernetes, Terraform, Ansible, Bazel
Frontend: Next.js, React, TypeScript, TailwindCSS, Flutter
Backend: Go, Python, FastAPI, GraphQL, gRPC
Database: PostgreSQL, MongoDB, Redis, Qdrant

FORMAT ODPOWIEDZI (WAŻNE!):
1. Jedna krótka odpowiedź (max 2-3 zdania!)
2. ZAWSZE dodaj linki:
   "───────\n📋 Przydatne linki:\n[link:/pricing|Zobacz cennik]\n[link:/contact|Skontaktuj się]"

PRZYKŁAD DOBREJ ODPOWIEDZI:
"𓅝 Możesz nas znaleźć przez formularz kontaktowy lub sprawdzić dane zespołu.

───────
📋 Przydatne linki:
[link:/contact|Kontakt]
[link:/team|Zespół]
[link:/about|O nas]"

TRIGGER WORDS → AUTOMATIC LINKS:
- "pakiety ai", "modele", "hosting ai" → [link:/pricing#ai-packages|Pakiety AI]
- "ceramix", "indie", "india" → [link:/portfolio/ceramix|CeramiX]
- "superborówki", "japonia", "japan", "borówki" → [link:/portfolio/superborowki|Superborówki]
- "panteon", "bogi", "ai gods" → [link:/#gods-panel|Panteon AI]
- "technologie", "stack", "tech" → [link:/about#tech-stack|Tech Stack]
- "backend", "mikroser", "go" → [link:/portfolio/backend-microservices|Backend]
- "devops", "kubernetes", "k8s" → [link:/portfolio/devops-infra|DevOps]

ZASADY (BARDZO WAŻNE!):
- MAX 2-3 zdania odpowiedzi!
- Używaj 𓅝 tylko raz na początku
- ZAWSZE podawaj 2-4 linki w formacie [link:URL|Tekst]
- Wykrywaj trigger words i dodawaj odpowiednie linki
- NIE gadaj za dużo - KONKRET!
- Linki mają pomóc użytkownikowi w następnym kroku`,
    };

    // Call Ollama API
    const response = await fetch(`${OLLAMA_URL}/api/chat`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "mistral:latest",
        messages: [systemPrompt, ...messages],
        stream: false,
        options: {
          temperature: 0.7,
          top_p: 0.9,
          num_ctx: 4096,
        },
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error("Ollama error:", error);
      return NextResponse.json(
        { error: "Failed to get response from Thoth", details: error },
        { status: response.status }
      );
    }

    const data = await response.json();

    return NextResponse.json({
      message: data.message,
      model: data.model,
      created_at: data.created_at,
      done: data.done,
    });
  } catch (error: any) {
    console.error("Thoth API error:", error);
    return NextResponse.json({ error: "Internal server error", details: error.message }, { status: 500 });
  }
}

export async function GET() {
  return NextResponse.json({
    god: "Thoth",
    status: "active",
    model: "mistral:latest (Q4_K_M)",
    port: 11434,
    capabilities: ["text generation", "OCR", "translation", "document analysis"],
  });
}
