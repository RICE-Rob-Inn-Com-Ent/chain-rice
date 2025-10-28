/**
 * Ra API Service
 * Communication with Ra container (Stable Diffusion 2.1 FP16)
 */

const RA_API_BASE = "/api/ra";

export interface RaImageGenRequest {
  prompt: string;
  negative_prompt?: string;
  steps?: number;
  cfg_scale?: number;
  width?: number;
  height?: number;
}

export interface RaHealthResponse {
  status: "active" | "sleeping";
  god: string;
  vram: string;
  models: {
    image_gen: string;
    upscaler: string;
    bg_removal: string;
  };
  optimizations: string[];
}

export interface RaImageResponse {
  image: string; // base64 data URL
  image_path: string;
  prompt: string;
}

/**
 * Check Ra health and status
 */
export async function checkRaHealth(): Promise<RaHealthResponse> {
  const response = await fetch(`${RA_API_BASE}/health`);
  if (!response.ok) {
    throw new Error(`Ra health check failed: ${response.statusText}`);
  }
  return response.json();
}

/**
 * Wake Ra (load models to GPU)
 */
export async function wakeRa(): Promise<{ success: boolean; god: string; status: string }> {
  const response = await fetch(`${RA_API_BASE}/wake`, {
    method: "POST",
  });
  if (!response.ok) {
    throw new Error(`Failed to wake Ra: ${response.statusText}`);
  }
  return response.json();
}

/**
 * Sleep Ra (unload models from GPU)
 */
export async function sleepRa(): Promise<{ success: boolean; god: string; status: string }> {
  const response = await fetch(`${RA_API_BASE}/sleep`, {
    method: "POST",
  });
  if (!response.ok) {
    throw new Error(`Failed to sleep Ra: ${response.statusText}`);
  }
  return response.json();
}

/**
 * Generate image using Ra's Stable Diffusion
 */
export async function generateImageWithRa(params: RaImageGenRequest): Promise<RaImageResponse> {
  const response = await fetch(`${RA_API_BASE}/generate`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      prompt: params.prompt,
      negative_prompt: params.negative_prompt || "",
      steps: params.steps || 30,
      cfg_scale: params.cfg_scale || 7.5,
      width: params.width || 512,
      height: params.height || 512,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Failed to generate image: ${response.status} - ${errorText}`);
  }

  const data: RaImageResponse = await response.json();
  return data;
}

/**
 * Check if Ra is available
 */
export async function isRaAvailable(): Promise<boolean> {
  try {
    const health = await checkRaHealth();
    return health.god === "Ra";
  } catch (error) {
    console.error("Ra not available:", error);
    return false;
  }
}
