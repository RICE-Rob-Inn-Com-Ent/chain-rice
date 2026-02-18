import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const settings = await prisma.storeSettings.findFirst()
    return NextResponse.json({
      freeShippingThreshold: settings ? Number(settings.freeShippingThreshold) : 199,
    })
  } catch (error) {
    console.error('Error fetching store settings', error)
    return NextResponse.json(
      { freeShippingThreshold: 199 },
      { status: 200 },
    )
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json()
    const threshold = Number(body.freeShippingThreshold)

    if (Number.isNaN(threshold) || threshold < 0) {
      return NextResponse.json(
        { error: 'Invalid freeShippingThreshold' },
        { status: 400 },
      )
    }

    const existing = await prisma.storeSettings.findFirst()

    const settings = existing
      ? await prisma.storeSettings.update({
          where: { id: existing.id },
          data: { freeShippingThreshold: threshold },
        })
      : await prisma.storeSettings.create({
          data: { freeShippingThreshold: threshold },
        })

    return NextResponse.json({
      freeShippingThreshold: Number(settings.freeShippingThreshold),
    })
  } catch (error) {
    console.error('Error updating store settings', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 },
    )
  }
}






































