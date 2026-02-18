import { NextRequest, NextResponse } from 'next/server'
import { uploadToS3, uploadMultipleToS3 } from '@/lib/s3'

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData()
    const files = formData.getAll('files') as File[]
    const category = formData.get('category') as string
    const productName = formData.get('productName') as string

    if (!files || files.length === 0) {
      return NextResponse.json(
        { error: 'No files provided' },
        { status: 400 }
      )
    }

    if (!category || !productName) {
      return NextResponse.json(
        { error: 'Category and productName are required' },
        { status: 400 }
      )
    }

    // Konwersja File do Buffer i upload do S3 (z fallback do lokalnego)
    const uploadPromises = files.map(async (file) => {
      const buffer = Buffer.from(await file.arrayBuffer())
      return {
        buffer,
        filename: file.name,
        contentType: file.type || 'image/jpeg',
      }
    })

    const fileData = await Promise.all(uploadPromises)
    console.log(`Uploading ${fileData.length} files for category: ${category}, product: ${productName}`)
    
    const urls = await uploadMultipleToS3(fileData, 'products', category, productName)
    console.log(`Upload completed. Generated ${urls.length} URLs:`, urls)

    if (urls.length === 0) {
      console.error('No URLs generated from upload')
      return NextResponse.json(
        { error: 'Failed to generate URLs for uploaded files' },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true, urls })
  } catch (error) {
    console.error('Error uploading files:', error)
    return NextResponse.json(
      { error: 'Failed to upload files', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

