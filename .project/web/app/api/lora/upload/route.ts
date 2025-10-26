import { NextRequest, NextResponse } from "next/server";
import { writeFile } from "fs/promises";
import path from "path";

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get("file") as File;
    const godId = formData.get("godId") as string;

    if (!file) {
      return NextResponse.json({ error: "No file provided" }, { status: 400 });
    }

    // Save LoRA file to god's directory
    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);

    // Save to volume/lora directory (mapped in docker-compose)
    const loraDir = `/tmp/lora-adapters/${godId}`;
    const filePath = path.join(loraDir, file.name);

    // Note: In production, this should save to Docker volume
    // For now, save to /tmp and inform god container via API

    await writeFile(filePath, buffer);

    // Notify god container to load LoRA
    const godPorts: Record<string, number> = {
      thoth: 11434,
      ra: 11435,
      isis: 11436,
      bastet: 11437,
      maat: 11438,
      khnum: 11439,
    };

    const port = godPorts[godId] || 8000;

    // Call god's API to load LoRA (if god supports it)
    try {
      const response = await fetch(`http://localhost:${port}/lora/load`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          adapter_path: filePath,
          adapter_name: file.name.replace(/\.[^/.]+$/, ""),
        }),
      });

      if (response.ok) {
        return NextResponse.json({
          success: true,
          message: `LoRA adapter loaded for ${godId}`,
          fileName: file.name,
          godId: godId,
        });
      }
    } catch (apiError) {
      // If god doesn't support LoRA API yet, just save file
      console.warn(`God ${godId} doesn't support LoRA API yet`);
    }

    return NextResponse.json({
      success: true,
      message: `LoRA adapter saved for ${godId}`,
      fileName: file.name,
      godId: godId,
      note: "File saved. God will load it on next restart.",
    });
  } catch (error: any) {
    console.error("LoRA upload error:", error);
    return NextResponse.json({ error: "Upload failed", details: error.message }, { status: 500 });
  }
}
