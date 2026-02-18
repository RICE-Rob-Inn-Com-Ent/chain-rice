import fs from 'fs'
import path from 'path'

let cachedEnvFromProject: Record<string, string> | null = null

function loadEnvProject(): Record<string, string> {
  if (cachedEnvFromProject) return cachedEnvFromProject

  try {
    // Zakładamy strukturę monorepo: /rice-mono/.project/meowtopia/web
    // -> cofamy się 3 katalogi w górę do /rice-mono i tam szukamy .env.project
    const rootDir = path.resolve(process.cwd(), '../../../')
    const envPath = path.join(rootDir, '.env.project')

    if (!fs.existsSync(envPath)) {
      cachedEnvFromProject = {}
      return cachedEnvFromProject
    }

    const raw = fs.readFileSync(envPath, 'utf8')
    const result: Record<string, string> = {}

    for (const line of raw.split('\n')) {
      const trimmed = line.trim()
      if (!trimmed || trimmed.startsWith('#')) continue
      const idx = trimmed.indexOf('=')
      if (idx === -1) continue
      const key = trimmed.slice(0, idx).trim()
      const value = trimmed.slice(idx + 1).trim()
      if (!key) continue
      // Usuwamy opcjonalne cudzysłowy
      result[key] = value.replace(/^"(.+)"$/,'$1').replace(/^'(.+)'$/,'$1')
    }

    cachedEnvFromProject = result
    return result
  } catch (err) {
    console.error('[projectEnv] Failed to read .env.project', err)
    cachedEnvFromProject = {}
    return cachedEnvFromProject
  }
}

export function getProjectEnv(key: string): string | undefined {
  if (process.env[key]) return process.env[key]
  const env = loadEnvProject()
  return env[key]
}




