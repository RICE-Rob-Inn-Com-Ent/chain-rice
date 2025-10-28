/**
 * Stable Diffusion WebUI API Integration
 * Connects to Automatic1111 WebUI on localhost:7860
 */

export interface SDGenerationParams {
  prompt: string;
  negative_prompt?: string;
  steps?: number;
  cfg_scale?: number;
  width?: number;
  height?: number;
  seed?: number;
  sampler_name?: string;
  batch_size?: number;
}

export interface SDGenerationResponse {
  images: string[]; // Base64 encoded images
  parameters: any;
  info: string;
}

// Use Vite proxy to avoid CORS issues
const SD_API_BASE = "/api/sd";

/**
 * Check if Stable Diffusion WebUI is running
 */
export async function checkSDHealth(): Promise<boolean> {
  try {
    const response = await fetch(`${SD_API_BASE}/sdapi/v1/sd-models`, {
      method: "GET",
    });
    return response.ok;
  } catch (error) {
    console.error("[SD] Health check failed:", error);
    return false;
  }
}

/**
 * Get list of available models
 */
export async function getSDModels(): Promise<any[]> {
  try {
    const response = await fetch(`${SD_API_BASE}/sdapi/v1/sd-models`);
    if (!response.ok) {
      throw new Error(`Failed to fetch SD models: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error("[SD] Failed to get models:", error);
    return [];
  }
}

/**
 * Generate image using txt2img
 */
export async function generateImage(params: SDGenerationParams): Promise<SDGenerationResponse> {
  const payload = {
    prompt: params.prompt,
    negative_prompt: params.negative_prompt || "blurry, low quality, distorted, ugly",
    steps: params.steps || 30,
    cfg_scale: params.cfg_scale || 7.5,
    width: params.width || 512,
    height: params.height || 512,
    seed: params.seed || -1,
    sampler_name: params.sampler_name || "DPM++ 2M Karras",
    batch_size: params.batch_size || 1,
    // Optimizations for 6GB VRAM
    enable_hr: false, // Disable hires fix to save memory
    denoising_strength: 0.7,
  };

  console.log("[SD] Generating image with params:", payload);

  try {
    const response = await fetch(`${SD_API_BASE}/sdapi/v1/txt2img`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(`SD API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    console.log("[SD] Generation successful");
    return data;
  } catch (error) {
    console.error("[SD] Generation failed:", error);
    throw error;
  }
}

/**
 * Upscale image using extras API
 */
export async function upscaleImage(
  imageBase64: string,
  upscaler: string = "RealESRGAN_x4plus",
  upscaling_resize: number = 4
): Promise<{ image: string }> {
  const payload = {
    image: imageBase64,
    upscaler_1: upscaler,
    upscaling_resize: upscaling_resize,
  };

  try {
    const response = await fetch(`${SD_API_BASE}/sdapi/v1/extra-single-image`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(`SD upscale error: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error("[SD] Upscale failed:", error);
    throw error;
  }
}

/**
 * Generate variations using img2img
 */
export async function generateVariations(
  imageBase64: string,
  prompt: string,
  denoisingStrength: number = 0.5
): Promise<SDGenerationResponse> {
  const payload = {
    init_images: [imageBase64],
    prompt: prompt,
    denoising_strength: denoisingStrength,
    steps: 30,
    cfg_scale: 7.5,
  };

  try {
    const response = await fetch(`${SD_API_BASE}/sdapi/v1/img2img`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(`SD img2img error: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error("[SD] Variations failed:", error);
    throw error;
  }
}

/**
 * Get generation progress
 */
export async function getProgress(): Promise<{
  progress: number;
  eta_relative: number;
  state: { job: string; job_count: number; job_no: number };
}> {
  try {
    const response = await fetch(`${SD_API_BASE}/sdapi/v1/progress`);
    if (!response.ok) {
      throw new Error(`Failed to get progress: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error("[SD] Failed to get progress:", error);
    return { progress: 0, eta_relative: 0, state: { job: "", job_count: 0, job_no: 0 } };
  }
}

/**
 * Interrupt current generation
 */
export async function interruptGeneration(): Promise<void> {
  try {
    await fetch(`${SD_API_BASE}/sdapi/v1/interrupt`, { method: "POST" });
  } catch (error) {
    console.error("[SD] Failed to interrupt:", error);
  }
}

