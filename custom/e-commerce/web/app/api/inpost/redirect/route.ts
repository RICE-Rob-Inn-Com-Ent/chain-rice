import { NextRequest, NextResponse } from 'next/server'
import { getProjectEnv } from '@/lib/projectEnv'

/**
 * Proxy endpoint zwracający URL sandboxa InPosta z env:
 * INPOST_API_URL=https://sandbox-api-shipx-pl.easypack24.net/v1/
 */
export async function GET(_req: NextRequest) {
  const apiUrl =
    getProjectEnv('INPOST_API_URL') || getProjectEnv('NEXT_PUBLIC_INPOST_API_URL')

  if (!apiUrl) {
    console.warn('[InPost] Brak INPOST_API_URL / NEXT_PUBLIC_INPOST_API_URL w env')
    return NextResponse.json(
      {
        ok: false,
        error:
          'INPOST_API_URL nie jest ustawione na serwerze. Dodaj je do .env.project, żeby używać sandboxa.'
      },
      { status: 500 }
    )
  }

  return NextResponse.json({
    ok: true,
    redirectUrl: apiUrl
  })
}


