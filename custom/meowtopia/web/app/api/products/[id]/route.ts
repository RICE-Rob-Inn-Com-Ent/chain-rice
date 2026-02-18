import { NextResponse, NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { updateBundlesContainingProduct } from '@/lib/bundle-products'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> | { id: string } }
) {
  try {
    const resolvedParams = await Promise.resolve(params)
    const { id } = resolvedParams

    if (!id) {
      return NextResponse.json(
        { error: 'Product ID is required' },
        { status: 400 }
      )
    }

    const product = await prisma.product.findUnique({
      where: { id },
      include: {
        category: true
      }
    })

    if (!product) {
      return NextResponse.json(
        { error: 'Product not found' },
        { status: 404 }
      )
    }

    return NextResponse.json({ success: true, product })
  } catch (error) {
    console.error('Error fetching product:', error)
    return NextResponse.json(
      { error: 'Failed to fetch product', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> | { id: string } }
) {
  try {
    const resolvedParams = await Promise.resolve(params)
    const { id } = resolvedParams

    if (!id) {
      return NextResponse.json(
        { error: 'Product ID is required' },
        { status: 400 }
      )
    }

    const body = await request.json()
    const { category, name, price, stock, description, images, weight, roastProfile, flavorProfile, originCountry, brewingTemperature, brewingTime, flavorNotes, ...otherData } = body

    // Sprawdź czy produkt istnieje
    const existingProduct = await prisma.product.findUnique({
      where: { id },
      include: { category: true }
    })

    if (!existingProduct) {
      return NextResponse.json(
        { error: 'Product not found' },
        { status: 404 }
      )
    }

    // Przygotuj dane do aktualizacji
    const categorySlug = existingProduct.category.slug.toLowerCase()
    const existingDimensions = (existingProduct.dimensions as any) || {}
    
    // Aktualizuj dimensions w zależności od kategorii
    let dimensions: any = { ...existingDimensions }
    if (categorySlug.includes('kawa') || categorySlug === 'kawa') {
      if (roastProfile !== undefined) dimensions.roastProfile = roastProfile || null
      if (flavorProfile !== undefined) dimensions.flavorProfile = flavorProfile || null
      if (originCountry !== undefined) dimensions.originCountry = originCountry || null
    } else if (categorySlug.includes('herbata') || categorySlug === 'herbata') {
      if (brewingTemperature !== undefined) dimensions.brewingTemperature = brewingTemperature || null
      if (brewingTime !== undefined) dimensions.brewingTime = brewingTime || null
      if (flavorNotes !== undefined) dimensions.flavorNotes = flavorNotes || null
      if (originCountry !== undefined) dimensions.originCountry = originCountry || null
    }
    
    const updateData: any = {
      name: name || existingProduct.name,
      price: price ? parseFloat(price) : existingProduct.price,
      stock: stock !== undefined ? parseInt(stock) : existingProduct.stock,
      description: description !== undefined ? description : existingProduct.description,
      images: images && Array.isArray(images) && images.length > 0 ? images : existingProduct.images,
      weight: weight ? parseFloat(weight) : existingProduct.weight,
      dimensions: dimensions as any,
    }

    // Aktualizuj produkt
    const updatedProduct = await prisma.product.update({
      where: { id },
      data: updateData,
      include: {
        category: true
      }
    })

    // If stock was updated, update all bundles containing this product
    if (stock !== undefined) {
      try {
        await updateBundlesContainingProduct(id)
      } catch (error) {
        console.error('Error updating bundles containing product:', error)
        // Don't fail the request if bundle update fails
      }
    }

    console.log('Product updated successfully:', {
      id: updatedProduct.id,
      name: updatedProduct.name,
      imagesCount: updatedProduct.images.length,
      images: updatedProduct.images
    })

    return NextResponse.json({ success: true, product: updatedProduct })
  } catch (error) {
    console.error('Error updating product:', error)
    return NextResponse.json(
      { error: 'Failed to update product', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> | { id: string } }
) {
  try {
    const resolvedParams = await Promise.resolve(params)
    const { id } = resolvedParams

    if (!id) {
      return NextResponse.json(
        { error: 'Product ID is required' },
        { status: 400 }
      )
    }

    // Sprawdź czy produkt istnieje
    const product = await prisma.product.findUnique({
      where: { id }
    })

    if (!product) {
      return NextResponse.json(
        { error: 'Product not found' },
        { status: 404 }
      )
    }

    // Usuń produkt
    await prisma.product.delete({
      where: { id }
    })

    return NextResponse.json({ success: true, message: 'Product deleted successfully' })
  } catch (error) {
    console.error('Error deleting product:', error)
    return NextResponse.json(
      { error: 'Failed to delete product', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

