import { NextResponse, NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const products = await prisma.product.findMany({
      where: {
        active: true,
      },
      include: {
        category: true,
      },
      orderBy: [
        { featured: 'desc' },
        { createdAt: 'desc' }
      ],
    })

    // Mapowanie produktów z bazy na format oczekiwany przez komponenty
    const mappedProducts = products.map(product => {
      const dimensions = product.dimensions as any || {}
      const categorySlug = product.category.slug.toLowerCase()
      
      // Przygotuj szczegóły w zależności od kategorii
      const details: any = {
        weight: product.weight ? `${product.weight}g` : undefined,
      }
      
      // Szczegóły dla kawy
      if (categorySlug.includes('kawa') || categorySlug === 'kawa') {
        if (dimensions.roastProfile) details.roastProfile = dimensions.roastProfile
        if (dimensions.flavorProfile) details.flavorProfile = dimensions.flavorProfile
        if (dimensions.originCountry) details.origin = dimensions.originCountry
      }
      
      // Szczegóły dla herbaty
      if (categorySlug.includes('herbata') || categorySlug === 'herbata') {
        if (dimensions.brewingTemperature) details.brewingTemperature = `${dimensions.brewingTemperature}°C`
        if (dimensions.brewingTime) details.brewingTime = dimensions.brewingTime
        if (dimensions.flavorNotes) details.flavorProfile = dimensions.flavorNotes
        if (dimensions.originCountry) details.origin = dimensions.originCountry
      }
      
      return {
        id: product.id,
        name: product.name,
        price: Number(product.price),
        category: product.category.slug.toUpperCase() as 'COFFEE' | 'TEA' | 'ILLUSTRATION',
        categoryId: product.categoryId,
        categoryName: product.category.name,
        categorySlug: product.category.slug,
        images: product.images.length > 0 ? product.images : ['/placeholder-product.jpg'],
        featured: product.featured,
        specialOffer: product.specialOffer,
        isBundle: product.isBundle,
        description: product.description || undefined,
        details
      }
    })

    return NextResponse.json(mappedProducts)
  } catch (error) {
    console.error('Error fetching products:', error)
    return NextResponse.json(
      { error: 'Failed to fetch products' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { category, coffeeData, teaData, artistWorkData } = body

    // Mapowanie kategorii z formularza na slug i nazwę
    const categoryMap: Record<string, { slug: string; name: string }> = {
      'kawa': { slug: 'kawa', name: 'Kawa' },
      'herbata': { slug: 'herbata', name: 'Herbata' },
      'dzieła-artystów': { slug: 'dzieła-artystów', name: 'Dzieła artystów' }
    }

    const categoryInfo = categoryMap[category]
    if (!categoryInfo) {
      return NextResponse.json(
        { error: 'Invalid category' },
        { status: 400 }
      )
    }

    // Znajdź lub utwórz kategorię
    let categoryRecord = await prisma.category.findUnique({
      where: { slug: categoryInfo.slug }
    })

    if (!categoryRecord) {
      categoryRecord = await prisma.category.create({
        data: {
          name: categoryInfo.name,
          slug: categoryInfo.slug,
          active: true,
          order: 0
        }
      })
    }

    // Przygotuj dane produktu w zależności od kategorii
    let productData: any = {
      categoryId: categoryRecord.id,
      active: true,
      featured: false,
      specialOffer: false,
      isBundle: false,
      stock: 0,
      images: [],
      tags: []
    }

    if (category === 'kawa' && coffeeData) {
      productData = {
        ...productData,
        name: coffeeData.name,
        description: coffeeData.description || null,
        price: parseFloat(coffeeData.price) || 0,
        stock: parseInt(coffeeData.quantity) || 0,
        weight: coffeeData.weight ? parseFloat(coffeeData.weight) : null,
        images: coffeeData.images && Array.isArray(coffeeData.images) && coffeeData.images.length > 0
          ? coffeeData.images
          : [],
        dimensions: {
          roastProfile: coffeeData.roastProfile || null,
          flavorProfile: coffeeData.flavorProfile || null,
          originCountry: coffeeData.originCountry || null,
        } as any
      }
    } else if (category === 'herbata' && teaData) {
      productData = {
        ...productData,
        name: teaData.name,
        description: teaData.description || null,
        price: parseFloat(teaData.price) || 0,
        stock: parseInt(teaData.quantity) || 0,
        weight: teaData.weight ? parseFloat(teaData.weight) : null,
        images: teaData.images && Array.isArray(teaData.images) && teaData.images.length > 0
          ? teaData.images
          : [],
        dimensions: {
          brewingTemperature: teaData.brewingTemperature || null,
          brewingTime: teaData.brewingTime || null,
          flavorNotes: teaData.flavorNotes || null,
          originCountry: teaData.originCountry || null,
        } as any
      }
    } else if (category === 'dzieła-artystów' && artistWorkData) {
      productData = {
        ...productData,
        name: artistWorkData.title,
        description: artistWorkData.description || null,
        price: parseFloat(artistWorkData.price) || 0,
        stock: 1, // Dzieła artystów są zwykle unikalne
        weight: artistWorkData.weight ? parseFloat(artistWorkData.weight) : null,
        images: artistWorkData.images && Array.isArray(artistWorkData.images) && artistWorkData.images.length > 0
          ? artistWorkData.images
          : []
      }
    } else {
      return NextResponse.json(
        { error: 'Missing product data' },
        { status: 400 }
      )
    }

    // Walidacja wymaganych pól
    if (!productData.name || !productData.price) {
      return NextResponse.json(
        { error: 'Name and price are required' },
        { status: 400 }
      )
    }

    // Log przed utworzeniem produktu
    console.log('Creating product with data:', {
      name: productData.name,
      imagesCount: productData.images?.length || 0,
      images: productData.images
    })

    // Utwórz produkt
    const product = await prisma.product.create({
      data: productData,
      include: {
        category: true
      }
    })

    console.log('Product created successfully:', {
      id: product.id,
      name: product.name,
      imagesCount: product.images.length,
      images: product.images
    })

    return NextResponse.json({ success: true, product }, { status: 201 })
  } catch (error) {
    console.error('Error creating product:', error)
    return NextResponse.json(
      { error: 'Failed to create product', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

