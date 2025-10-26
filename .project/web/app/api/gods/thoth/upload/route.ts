import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get("file") as File;

    if (!file) {
      return NextResponse.json({ error: "No file provided" }, { status: 400 });
    }

    // Read file content
    let content = "";
    const fileType = file.type;

    if (fileType === "text/plain" || file.name.endsWith(".txt")) {
      // Plain text
      content = await file.text();
    } else if (fileType === "application/pdf" || file.name.endsWith(".pdf")) {
      // For PDF - we'll extract text (simplified - in production use pdf-parse)
      const arrayBuffer = await file.arrayBuffer();
      const text = new TextDecoder().decode(arrayBuffer);
      // Simple extraction - looks for readable text
      content = text.replace(/[^\x20-\x7E\u00A0-\uFFFF]/g, " ").trim();

      if (content.length < 50) {
        // PDF is binary - inform user
        content = `[PDF Document: ${file.name}]\n\nUwaga: To jest plik PDF binarny. W pełnej wersji użyję OCR do ekstrakcji tekstu.\n\nTymczasowo, opisz mi co jest w tym dokumencie, a ja pomogę w analizie.`;
      }
    } else {
      // Other file types
      content = await file.text();
    }

    return NextResponse.json({
      success: true,
      fileName: file.name,
      fileSize: file.size,
      fileType: file.type,
      content: content.substring(0, 10000), // Limit to 10k chars
      preview: content.substring(0, 500) + (content.length > 500 ? "..." : ""),
    });
  } catch (error: any) {
    console.error("File upload error:", error);
    return NextResponse.json({ error: "Failed to process file", details: error.message }, { status: 500 });
  }
}
