from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
import asyncio
from typing import Optional
import json
from datetime import datetime
import uuid

from services.receipt_processor import ReceiptProcessor
from services.grpc_client import AccountingGRPCClient
from models.invoice import Invoice, InvoiceItem

app = FastAPI(title="ChainRice AI Receipt Processor", version="1.0.0")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
receipt_processor = ReceiptProcessor()
grpc_client = AccountingGRPCClient()

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "ai-receipt-processor"}

@app.post("/process-receipt")
async def process_receipt(file: UploadFile = File(...)):
    """
    Process uploaded receipt image/PDF and extract invoice data using AI
    """
    try:
        # Validate file type
        if not file.content_type.startswith(('image/', 'application/pdf')):
            raise HTTPException(
                status_code=400, 
                detail="File must be an image or PDF"
            )
        
        # Read file content
        content = await file.read()
        
        # Process receipt with AI
        extracted_data = await receipt_processor.process_receipt(
            content, 
            file.content_type,
            file.filename
        )
        
        if not extracted_data:
            raise HTTPException(
                status_code=422,
                detail="Could not extract data from receipt"
            )
        
        return {
            "success": True,
            "message": "Receipt processed successfully",
            "data": extracted_data
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/process-receipt-and-save")
async def process_and_save_receipt(file: UploadFile = File(...)):
    """
    Process receipt and automatically save to database
    """
    try:
        # Process receipt
        extracted_data = await process_receipt(file)
        
        if not extracted_data["success"]:
            return extracted_data
        
        # Convert to Invoice model
        invoice_data = extracted_data["data"]
        invoice = Invoice(
            id=str(uuid.uuid4()),
            invoice_number=invoice_data.get("invoice_number", f"AUTO-{datetime.now().strftime('%Y%m%d%H%M%S')}"),
            vendor_name=invoice_data.get("vendor_name", "Не вказано"),
            vendor_tax_id=invoice_data.get("vendor_tax_id", ""),
            vendor_address=invoice_data.get("vendor_address", ""),
            date=datetime.now(),
            total_amount=float(invoice_data.get("total_amount", 0)),
            tax_amount=float(invoice_data.get("tax_amount", 0)),
            net_amount=float(invoice_data.get("net_amount", 0)),
            currency=invoice_data.get("currency", "PLN"),
            description=invoice_data.get("description", ""),
            category=invoice_data.get("category", "Офісні витрати"),
            status="pending",
            receipt_image_path=f"/uploads/{file.filename}"
        )
        
        # Save to database via gRPC
        result = await grpc_client.create_invoice(invoice)
        
        return {
            "success": True,
            "message": "Receipt processed and saved successfully",
            "data": result
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/categories")
async def get_categories():
    """
    Get available invoice categories
    """
    categories = [
        {"id": "cat-1", "name": "Офісні витрати", "color": "#3b82f6"},
        {"id": "cat-2", "name": "Програмне забезпечення", "color": "#8b5cf6"},
        {"id": "cat-3", "name": "Обладнання", "color": "#10b981"},
        {"id": "cat-4", "name": "Маркетинг", "color": "#f59e0b"},
        {"id": "cat-5", "name": "Подорожі", "color": "#ef4444"},
        {"id": "cat-6", "name": "Харчування", "color": "#f97316"},
    ]
    
    return {
        "success": True,
        "data": categories
    }

@app.get("/dashboard-stats")
async def get_dashboard_stats():
    """
    Get dashboard statistics
    """
    try:
        stats = await grpc_client.get_dashboard_stats()
        return {
            "success": True,
            "data": stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    # Create uploads directory
    os.makedirs("uploads", exist_ok=True)
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8005,
        reload=True,
        log_level="info"
    )
