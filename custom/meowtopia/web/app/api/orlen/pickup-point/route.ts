import { NextRequest, NextResponse } from 'next/server'

/**
 * Proxy endpoint pod integrację z API ORLEN Paczka.
 *
 * Po stronie frontu (modal Orlen) wysyłamy tu wybrany punkt,
 * a ten endpoint może go dalej przekazać do oficjalnego API ORLEN Paczki.
 *
 * Uwaga: ścieżka i payload do zewnętrznego API są przykładowe – trzeba je
 * dopasować do oficjalnej dokumentacji ORLEN Paczki i ustawić zmienne środowiskowe:
 * - ORLEN_PACZKA_API_BASE_URL
 * - ORLEN_PACZKA_PARTNER_ID
 * - ORLEN_PACZKA_PARTNER_KEY
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, address } = body as { name?: string; address?: string }

    if (!name || !address) {
      return NextResponse.json(
        { ok: false, error: 'Missing name or address' },
        { status: 400 }
      )
    }

    const baseUrl = process.env.ORLEN_PACZKA_API_BASE_URL
    const partnerId = process.env.ORLEN_PACZKA_PARTNER_ID
    const partnerKey = process.env.ORLEN_PACZKA_PARTNER_KEY

    // Jeśli nie skonfigurowano jeszcze danych do ORLEN Paczki,
    // nie przerywamy zamówienia – tylko logujemy ostrzeżenie.
    if (!baseUrl || !partnerId || !partnerKey) {
      console.warn(
        '[ORLEN_PACZKA] Missing API env vars (ORLEN_PACZKA_API_BASE_URL / ORLEN_PACZKA_PARTNER_ID / ORLEN_PACZKA_PARTNER_KEY). ' +
          'Point will be saved only locally.'
      )
      return NextResponse.json({
        ok: true,
        forwarded: false,
        message: 'ORLEN Paczka API not configured – point accepted only in app.'
      })
    }

    // TODO: dopasuj ścieżkę i strukturę body do oficjalnego API ORLEN Paczki.
    const url = `${baseUrl}/pickup-point`

    const externalRes = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Partner-ID': partnerId,
        'X-Partner-Key': partnerKey
      },
      body: JSON.stringify({
        name,
        address
      })
    })

    const text = await externalRes.text()

    if (!externalRes.ok) {
      console.error('[ORLEN_PACZKA] API error', externalRes.status, text)
      return NextResponse.json(
        {
          ok: false,
          forwarded: true,
          status: externalRes.status,
          body: text
        },
        { status: 502 }
      )
    }

    let data: unknown = null
    try {
      data = JSON.parse(text)
    } catch {
      data = text
    }

    return NextResponse.json({
      ok: true,
      forwarded: true,
      data
    })
  } catch (error) {
    console.error('[ORLEN_PACZKA] Internal proxy error', error)
    return NextResponse.json(
      { ok: false, error: 'Internal ORLEN proxy error' },
      { status: 500 }
    )
  }
}






































