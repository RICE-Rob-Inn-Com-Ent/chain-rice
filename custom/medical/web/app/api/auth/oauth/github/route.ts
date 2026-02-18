import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const redirectUri = searchParams.get("redirect_uri") || "/account";
  
  // GitHub OAuth configuration
  const clientId = process.env.GITHUB_CLIENT_ID;
  // Get base URL without port (Traefik handles routing on standard ports 80/443)
  let baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "http://ceramix.ltd";
  // Remove port from baseUrl if present (except for localhost in development)
  if (!baseUrl.includes('localhost')) {
    baseUrl = baseUrl.replace(/^(https?:\/\/[^:]+):\d+/, '$1');
  }
  const redirectUrl = `${baseUrl}/api/auth/oauth/github/callback`;
  
  if (!clientId) {
    return NextResponse.json(
      { error: "GitHub OAuth nie jest skonfigurowany" },
      { status: 500 }
    );
  }

  // Store redirect URI in state for later use
  const state = Buffer.from(JSON.stringify({ redirectUri })).toString("base64");
  
  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUrl,
    scope: "user:email",
    state: state,
  });

  const authUrl = `https://github.com/login/oauth/authorize?${params.toString()}`;
  
  return NextResponse.redirect(authUrl);
}













