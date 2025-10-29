/**
 * Bes Service - Egyptian God of Music and Voice
 * 
 * Audio AI service providing:
 * - Text-to-Speech (Coqui TTS)
 * - Voice Cloning (XTTS)
 * - Music Generation (MusicGen)
 * 
 * Port: 8007
 */

const BES_API_URL = import.meta.env.VITE_BES_API || "http://localhost:8007";

/**
 * Health check response from Bes API
 */
export interface BesHealthResponse {
  status: "active" | "sleeping";
  device: "cuda" | "cpu";
  models: {
    tortoise_tts: "loaded" | "not_loaded";
    xtts: "loaded" | "not_loaded";
    musicgen: "loaded" | "not_loaded";
  };
  memory: {
    total: string;
    allocated: string;
    cached: string;
  };
}

/**
 * TTS request
 */
export interface TTSRequest {
  text: string;
  voice?: string;  // "default" or speaker index
  preset?: "fast" | "standard" | "high_quality";
}

/**
 * TTS response
 */
export interface TTSResponse {
  status: "success";
  file: string;
  path: string;
}

/**
 * Voice clone response
 */
export interface VoiceCloneResponse {
  status: "success";
  file: string;
}

/**
 * Music generation request
 */
export interface MusicGenRequest {
  prompt: string;
  duration?: number;  // seconds
  temperature?: number;
}

/**
 * Music generation response
 */
export interface MusicGenResponse {
  status: "success";
  file: string;
  prompt: string;
}

/**
 * Check if Bes API is available and healthy
 */
export async function checkBesHealth(): Promise<BesHealthResponse> {
  const response = await fetch(`${BES_API_URL}/health`);
  
  if (!response.ok) {
    throw new Error(`Bes health check failed: ${response.statusText}`);
  }
  
  return await response.json();
}

/**
 * Generate speech from text using TTS
 */
export async function generateSpeech(request: TTSRequest): Promise<TTSResponse> {
  const response = await fetch(`${BES_API_URL}/tts`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(request),
  });
  
  if (!response.ok) {
    throw new Error(`TTS generation failed: ${response.statusText}`);
  }
  
  return await response.json();
}

/**
 * Clone voice and generate speech
 */
export async function cloneVoice(text: string, referenceAudio: File): Promise<VoiceCloneResponse> {
  const formData = new FormData();
  formData.append("text", text);
  formData.append("reference_audio", referenceAudio);
  
  const response = await fetch(`${BES_API_URL}/voice-clone`, {
    method: "POST",
    body: formData,
  });
  
  if (!response.ok) {
    throw new Error(`Voice cloning failed: ${response.statusText}`);
  }
  
  return await response.json();
}

/**
 * Generate music from text prompt
 */
export async function generateMusic(request: MusicGenRequest): Promise<MusicGenResponse> {
  const response = await fetch(`${BES_API_URL}/music-gen`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(request),
  });
  
  if (!response.ok) {
    throw new Error(`Music generation failed: ${response.statusText}`);
  }
  
  return await response.json();
}

/**
 * Get audio file URL
 */
export function getAudioUrl(filename: string): string {
  return `${BES_API_URL}/audio/${filename}`;
}


