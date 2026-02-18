import { NextRequest, NextResponse } from 'next/server'
import { getProjectEnv } from '@/lib/projectEnv'

/**
 * Stub/proxy pod integrację z Przelewy24.
 *
 * Front (koszyk) wysyła tu dane zamówienia i oczekuje w odpowiedzi URL-a
 * do przekierowania użytkownika na bramkę płatniczą.
 *
 * Uwaga: poniżej jest tylko szkic – ścieżki, body i nazwy zmiennych
 * środowiskowych trzeba dopasować do Twojej konfiguracji w `.env.project`
 * i oficjalnej dokumentacji Przelewy24.
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()

    // TODO: walidacja danych zamówienia (produkty, suma, dane klienta itd.)

    const merchantId = getProjectEnv('PRZELEWY24_MERCHANT_ID')
    const apiKey = getProjectEnv('PRZELEWY24_API_KEY')
    const apiUrl = getProjectEnv('PRZELEWY24_API_URL')

    if (!merchantId || !apiKey || !apiUrl) {
      console.warn(
        '[Przelewy24] Brak konfiguracji środowiska (PRZELEWY24_MERCHANT_ID / PRZELEWY24_API_KEY / PRZELEWY24_API_URL)'
      )
      return NextResponse.json(
        {
          ok: false,
          error:
            'Integracja z Przelewy24 nie jest jeszcze skonfigurowana na serwerze. Sprawdź zmienne środowiskowe.'
        },
        { status: 500 }
      )
    }

    return NextResponse.json({
      ok: true,
      /**
       * Na razie jako URL przekierowania zwracamy dokładnie to,
       * co masz ustawione w PRZELEWY24_API_URL (u Ciebie sandbox:
       * https://sandbox.przelewy24.pl/api/v1/).
       *
       * Gdy będziesz miał pełną integrację, w tym miejscu:
       *  - wywołasz endpoint register transaction na PRZELEWY24_API_URL
       *  - z odpowiedzi weźmiesz właściwy redirect URL i tu zwrócisz.
       */
      redirectUrl: apiUrl
    })
  } catch (error) {
    console.error('[Przelewy24] Internal error', error)
    return NextResponse.json(
      { ok: false, error: 'Błąd po stronie serwera płatności' },
      { status: 500 }
    )
  }
}


