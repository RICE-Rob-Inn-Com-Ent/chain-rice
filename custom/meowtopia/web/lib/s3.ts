import { createHash } from 'crypto'
import { writeFile, mkdir } from 'fs/promises'
import { join } from 'path'
import { existsSync } from 'fs'

// Sprawdź czy pakiet S3 jest dostępny (tylko podczas runtime, nie podczas build)
function checkS3Available(): boolean {
  if (typeof window !== 'undefined') return false // Tylko po stronie serwera
  
  try {
    // Sprawdź czy moduł istnieje bez jego importowania
    require.resolve('@aws-sdk/client-s3')
    return true
  } catch {
    return false
  }
}

const s3Available = checkS3Available()

// Konfiguracja S3/MinIO
const S3_ENDPOINT = process.env.MINIO_ENDPOINT || process.env.S3_ENDPOINT || 'http://devcontainer-minio:9000'
const S3_ACCESS_KEY = process.env.MINIO_ACCESS_KEY || process.env.S3_ACCESS_KEY || 'minioadmin'
const S3_SECRET_KEY = process.env.MINIO_SECRET_KEY || process.env.S3_SECRET_KEY || 'minioadmin'
const S3_BUCKET = process.env.S3_BUCKET || 'meowtopia-products'
const S3_REGION = process.env.S3_REGION || 'us-east-1'
const S3_USE_SSL = process.env.MINIO_USE_SSL === 'true' || process.env.S3_USE_SSL === 'true'
const STORAGE_BASE_URL = process.env.STORAGE_BASE_URL || process.env.S3_PUBLIC_URL || 'http://localhost:9000'
const USE_LOCAL_STORAGE = process.env.USE_LOCAL_STORAGE === 'true' || false

// Funkcja do inicjalizacji klienta S3 (tylko jeśli nie używamy lokalnego storage i pakiet jest zainstalowany)
function initS3Client(): any {
  if (USE_LOCAL_STORAGE || !s3Available) {
    return null
  }

  try {
    // Dynamiczny import tylko jeśli pakiet jest dostępny
    const s3Module = require('@aws-sdk/client-s3')
    const S3Client = s3Module.S3Client
    
    if (!S3Client) return null

    return new S3Client({
      endpoint: S3_ENDPOINT,
      region: S3_REGION,
      credentials: {
        accessKeyId: S3_ACCESS_KEY,
        secretAccessKey: S3_SECRET_KEY,
      },
      forcePathStyle: true, // Wymagane dla MinIO
    })
  } catch (error) {
    console.warn('Failed to initialize S3 client, will use local storage:', error)
    return null
  }
}

/**
 * Generuje szyfrowaną nazwę pliku na podstawie kategorii i nazwy produktu
 */
function generateEncryptedFilename(
  category: string,
  productName: string,
  originalFilename: string,
  index: number = 0
): string {
  // Normalizuj nazwę produktu (usuń znaki specjalne, spacje zamień na _)
  const normalizedName = productName
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Usuń znaki diakrytyczne
    .replace(/[^a-z0-9]/g, '_')
    .substring(0, 50) // Maksymalnie 50 znaków

  // Normalizuj kategorię
  const normalizedCategory = category
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '_')

  // Utwórz hash z kategorii, nazwy produktu i timestamp
  const hashInput = `${normalizedCategory}_${normalizedName}_${Date.now()}_${index}`
  const hash = createHash('sha256').update(hashInput).digest('hex').substring(0, 16)

  // Pobierz rozszerzenie z oryginalnego pliku
  const extension = originalFilename.split('.').pop() || 'jpg'

  // Zwróć szyfrowaną nazwę: {hash}_{normalizedCategory}_{normalizedName}_{index}.{ext}
  return `${hash}_${normalizedCategory}_${normalizedName}_${index}.${extension}`
}

/**
 * Upload pliku lokalnie
 */
async function uploadLocally(
  file: Buffer | Uint8Array,
  filename: string,
  category: string,
  productName: string,
  index: number = 0
): Promise<string> {
  try {
    const encryptedFilename = generateEncryptedFilename(category, productName, filename, index)
    const uploadDir = join(process.cwd(), 'public', 'uploads', 'products', category)
    
    console.log('Uploading locally to:', uploadDir, 'filename:', encryptedFilename)
    
    // Utwórz katalog jeśli nie istnieje
    if (!existsSync(uploadDir)) {
      console.log('Creating upload directory:', uploadDir)
      await mkdir(uploadDir, { recursive: true })
    }

    const filePath = join(uploadDir, encryptedFilename)
    await writeFile(filePath, file)
    
    // Sprawdź czy plik został zapisany
    if (!existsSync(filePath)) {
      throw new Error(`Failed to save file: ${filePath}`)
    }
    
    const publicUrl = `/uploads/products/${category}/${encryptedFilename}`
    console.log('File uploaded successfully. Public URL:', publicUrl)
    
    // Zwróć publiczny URL
    return publicUrl
  } catch (error) {
    console.error('Error in uploadLocally:', error)
    throw error
  }
}

/**
 * Upload pliku do S3/MinIO z fallback do lokalnego storage
 */
export async function uploadToS3(
  file: Buffer | Uint8Array,
  filename: string,
  contentType: string,
  folder: string = 'products',
  category?: string,
  productName?: string,
  index: number = 0
): Promise<string> {
  // Jeśli używamy lokalnego storage lub S3 nie jest dostępny
  if (USE_LOCAL_STORAGE || !s3Available) {
    if (!category || !productName) {
      throw new Error('Category and productName are required for local storage')
    }
    return uploadLocally(file, filename, category, productName, index)
  }

  try {
    // Dynamiczny import tylko jeśli pakiet jest dostępny
    const s3Module = require('@aws-sdk/client-s3')
    const PutObjectCommand = s3Module.PutObjectCommand
    
    if (!PutObjectCommand) {
      throw new Error('S3 SDK not available')
    }

    const s3Client = initS3Client()
    if (!s3Client) {
      throw new Error('Failed to initialize S3 client')
    }

    const key = `${folder}/${Date.now()}-${filename}`

    const command = new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: key,
      Body: file,
      ContentType: contentType,
    })

    await s3Client.send(command)

    // Zwróć publiczny URL
    return `${STORAGE_BASE_URL}/${S3_BUCKET}/${key}`
  } catch (error) {
    console.warn('S3 upload failed, falling back to local storage:', error)
    
    // Fallback do lokalnego storage
    if (category && productName) {
      return uploadLocally(file, filename, category, productName, index)
    }
    
    throw new Error('S3 upload failed and local storage fallback requires category and productName')
  }
}

/**
 * Upload wielu plików do S3/MinIO z fallback do lokalnego storage
 */
export async function uploadMultipleToS3(
  files: Array<{ buffer: Buffer | Uint8Array; filename: string; contentType: string }>,
  folder: string = 'products',
  category?: string,
  productName?: string
): Promise<string[]> {
  const uploadPromises = files.map((file, index) =>
    uploadToS3(file.buffer, file.filename, file.contentType, folder, category, productName, index)
  )

  return Promise.all(uploadPromises)
}

/**
 * Pobierz publiczny URL dla obiektu S3
 */
export function getS3PublicUrl(key: string): string {
  return `${STORAGE_BASE_URL}/${S3_BUCKET}/${key}`
}

/**
 * Sprawdź czy bucket istnieje i utwórz go jeśli nie istnieje
 */
export async function ensureBucketExists(): Promise<void> {
  // W produkcji można użyć CreateBucketCommand
  // Dla MinIO bucket jest zwykle tworzony automatycznie przy pierwszym uploadzie
  // lub można go utworzyć ręcznie w konsoli MinIO
}

