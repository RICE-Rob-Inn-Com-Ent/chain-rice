import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions)

    if (!session?.user?.email) {
      return NextResponse.json(
        { error: 'Nie jesteś zalogowany' },
        { status: 401 }
      )
    }

    const user = await prisma.user.findUnique({
      where: { email: session.user.email },
      select: {
        firstName: true,
        lastName: true,
        email: true,
        phone: true,
        role: true
      }
    })

    if (!user) {
      return NextResponse.json(
        { error: 'Użytkownik nie został znaleziony' },
        { status: 404 }
      )
    }

    // Zwróć tylko dane dla CUSTOMER (lub innych ról jeśli chcesz)
    if (user.role !== 'CUSTOMER') {
      // Możesz też pozwolić innym rolom, ale na razie tylko CUSTOMER
      return NextResponse.json(
        { error: 'Tylko klienci mogą używać tego endpointu' },
        { status: 403 }
      )
    }

    return NextResponse.json({
      ok: true,
      customer: {
        firstName: user.firstName || '',
        lastName: user.lastName || '',
        email: user.email || '',
        phone: user.phone || ''
      }
    })
  } catch (error) {
    console.error('Error fetching customer profile:', error)
    return NextResponse.json(
      { error: 'Błąd podczas pobierania danych użytkownika' },
      { status: 500 }
    )
  }
}





































