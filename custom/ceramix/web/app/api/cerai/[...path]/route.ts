import { NextRequest, NextResponse } from "next/server";

const CERAI_BOT_URL = process.env.CERAI_BOT_URL || "http://ceramix-bot:8000";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  return handleRequest(request, params, "GET");
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  return handleRequest(request, params, "POST");
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  return handleRequest(request, params, "PUT");
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  return handleRequest(request, params, "DELETE");
}

async function handleRequest(
  request: NextRequest,
  params: Promise<{ path: string[] }>,
  method: string
) {
  try {
    const resolvedParams = await params;
    const pathSegments = resolvedParams.path || [];
    const path = pathSegments.join("/");
    
    // Build target URL - path already includes the endpoint (e.g., "chat", "ocr/base64")
    const targetUrl = `${CERAI_BOT_URL}/api/${path}`;
    
    // Get request body if present
    let body: string | undefined;
    if (method !== "GET" && method !== "DELETE") {
      try {
        body = await request.text();
      } catch {
        // No body
      }
    }
    
    // Forward request to CerAI bot
    const response = await fetch(targetUrl, {
      method,
      headers: {
        "Content-Type": request.headers.get("Content-Type") || "application/json",
      },
      body: body || undefined,
    });
    
    // Get response data
    const data = await response.json().catch(() => ({}));
    
    // Return response with CORS headers
    return NextResponse.json(data, {
      status: response.status,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message || "Proxy error" },
      { status: 500 }
    );
  }
}

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
}

