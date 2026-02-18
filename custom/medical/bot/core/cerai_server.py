"""CerAI - FastAPI Server for Ceramix AI Assistant.

Integrates LangGraph, OCR, RAG, and database connections.
"""
import base64
import json
import logging
import os
import re
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Annotated, Any

import asyncpg  # type: ignore[import-untyped]
import httpx  # type: ignore[import-untyped]
import motor.motor_asyncio  # type: ignore[import-untyped]
import redis.asyncio as redis  # type: ignore[import-untyped]
from bson import ObjectId  # type: ignore[import-untyped]
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from langgraph.graph import END, StateGraph  # type: ignore[import-untyped]
from langgraph.graph.message import (  # type: ignore[import-untyped]
    add_messages,
)
from pydantic import BaseModel, Field
from typing_extensions import TypedDict

# Setup module logger
logger = logging.getLogger(__name__)

# OCR imports
try:
    import cv2  # type: ignore[import-untyped]
    import easyocr  # type: ignore[import-untyped]
    import numpy as np  # type: ignore[import-untyped]

    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False
    logger.warning(
        "OCR libraries not available. "
        "Install easyocr and opencv-python"
    )

# PDF imports
try:
    from pdf2image import convert_from_bytes  # type: ignore[import-untyped]
    PDF_AVAILABLE = True
except ImportError:
    PDF_AVAILABLE = False
    logger.warning(
        "PDF libraries not available. "
        "Install pdf2image and poppler-utils"
    )

# LangChain imports (for future RAG features)
try:
    # These imports are kept for future use
    # type: ignore[import-untyped]
    from langchain.embeddings import (  # noqa: F401
        HuggingFaceEmbeddings,
    )
    # type: ignore[import-untyped]
    from langchain.schema import Document  # noqa: F401
    # type: ignore[import-untyped]
    from langchain.text_splitter import (  # noqa: F401
        RecursiveCharacterTextSplitter,
    )
    # type: ignore[import-untyped]
    from langchain.vectorstores import PGVector  # noqa: F401

    RAG_AVAILABLE = True
except ImportError:
    RAG_AVAILABLE = False
    logger.warning(
        "LangChain not available. RAG features will be limited"
    )

# Environment variables
# NOTE: Default password is for development only.
# In production, use DATABASE_URL env var.
DEFAULT_DB_URL = (
    "postgresql://ceramix_user:ceramix_pass@"  # NOSONAR
    "devcontainer-postgres:5432/ceramix"
)
DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_DB_URL)
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://mongo:27017/ceramix")
CERAI_API_KEY = os.getenv("CERAI_API_KEY", "cerai-dev-key")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://devcontainer-ollama:11434")

# Global connections
db_pool: asyncpg.Pool | None = None
redis_client: redis.Redis | None = None
mongo_client: motor.motor_asyncio.AsyncIOMotorClient | None = None
reader: Any | None = None  # easyocr.Reader when available


# LangGraph State
class CerAIState(TypedDict):
    """State for CerAI LangGraph workflow."""

    messages: Annotated[list[dict], add_messages]
    context: str
    bot_type: str  # "accounting" | "client_management"
    extracted_data: dict[str, Any]
    report_data: dict[str, Any]


@asynccontextmanager
async def lifespan(_app: FastAPI):
    """Initialize and cleanup resources."""
    # Module-level variables for connection pooling
    # Using global is acceptable in lifespan context managers
    global db_pool, redis_client, mongo_client, reader  # noqa: PLW0603

    # Initialize PostgreSQL pool
    try:
        db_pool = await asyncpg.create_pool(DATABASE_URL)
        logger.info("✅ Connected to PostgreSQL")
    except (asyncpg.exceptions.InvalidPasswordError, OSError) as e:
        logger.warning("⚠️  PostgreSQL connection error: %s", e)
    except Exception as e:  # noqa: BLE001
        logger.warning("⚠️  PostgreSQL connection error: %s", e)

    # Initialize Redis
    try:
        redis_client = redis.from_url(REDIS_URL, decode_responses=True)
        await redis_client.ping()
        logger.info("✅ Connected to Redis")
    except (redis.ConnectionError, OSError) as e:
        logger.warning("⚠️  Redis connection error: %s", e)
    except Exception as e:  # noqa: BLE001
        logger.warning("⚠️  Redis connection error: %s", e)

    # Initialize MongoDB
    try:
        mongo_client = motor.motor_asyncio.AsyncIOMotorClient(MONGODB_URL)
        await mongo_client.admin.command("ping")
        logger.info("✅ Connected to MongoDB")
    except (
        motor.motor_asyncio.errors.ServerSelectionTimeoutError,
        OSError,
    ) as e:
        logger.warning("⚠️  MongoDB connection error: %s", e)
    except Exception as e:  # noqa: BLE001
        logger.warning("⚠️  MongoDB connection error: %s", e)

    # Initialize OCR reader (Polish + English)
    if OCR_AVAILABLE:
        try:
            # easyocr is imported at top level
            reader = easyocr.Reader(  # type: ignore[assignment]
                ["pl", "en"], gpu=False
            )
            logger.info("✅ OCR Reader initialized")
        except (RuntimeError, OSError) as e:
            logger.warning("⚠️  OCR initialization error: %s", e)
        except Exception as e:  # noqa: BLE001
            logger.warning("⚠️  OCR initialization error: %s", e)

    yield

    # Cleanup
    if db_pool:
        await db_pool.close()
    if redis_client:
        await redis_client.close()
    if mongo_client:
        mongo_client.close()


app = FastAPI(
    title="CerAI API",
    description="AI Assistant for Ceramix - Accounting and Client Management",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


# Pydantic models
class ChatMessage(BaseModel):
    """Chat message model."""

    message: str
    bot_type: str = Field(
        ...,
        description="Type of bot: 'accounting' or 'client_management'"
    )
    context: str | None = None
    session_id: str | None = None


class OCRRequest(BaseModel):
    """OCR request model."""

    image_base64: str | None = None
    document_type: str = Field(
        default="receipt",
        description="Type: 'receipt' or 'invoice'"
    )


class ReportRequest(BaseModel):
    """Report request model."""

    report_type: str = Field(..., description="Type of report to generate")
    period: str | None = None
    filters: dict[str, Any] | None = None
    bot_type: str = Field(default="accounting")


class BotConfigRequest(BaseModel):
    """Bot configuration request model."""

    name: str
    description: str | None = None
    enabled: bool = True
    model: str
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(default=1024, gt=0)
    use_lora: bool = False
    lora_adapter: str | None = None
    context_window: int = Field(default=2048, gt=0)


class BotConfigResponse(BotConfigRequest):
    """Bot configuration response model."""

    bot_type: str
    created_at: str | None = None
    updated_at: str | None = None


class LangChainWorkflowRequest(BaseModel):
    """LangChain workflow request model."""

    name: str
    description: str | None = None
    nodes: list[dict[str, Any]] = Field(default_factory=list)
    edges: list[dict[str, Any]] = Field(default_factory=list)
    status: str = Field(default="inactive", pattern="^(active|inactive)$")


class LangChainWorkflowResponse(LangChainWorkflowRequest):
    """LangChain workflow response model."""

    id: str
    created_at: str | None = None
    updated_at: str | None = None


# LangGraph Nodes
async def analyze_receipt_node(  # NOSONAR
    state: CerAIState,
) -> CerAIState:
    """Analyze receipt/invoice and extract structured data."""
    # This would analyze extracted text from OCR
    # Async for future LLM integration
    extracted = state.get("extracted_data", {})

    # Extract key information (amount, date, vendor, items)
    # In production, use LLM to extract structured data

    return {
        **state,
        "extracted_data": extracted
    }


async def query_database_node(state: CerAIState) -> CerAIState:
    """Query PostgreSQL database based on context."""
    if not db_pool:
        return state

    bot_type = state.get("bot_type", "accounting")

    # Simple SQL query generation based on bot type
    # In production, use LLM to generate SQL queries

    if bot_type == "accounting":
        # Query invoices, payments, etc.
        async with db_pool.acquire() as conn:
            # Example: Get recent invoices
            rows = await conn.fetch("""
                SELECT invoice_number, total_amount, status, issue_date
                FROM invoices
                ORDER BY issue_date DESC
                LIMIT 10
            """)

            results = [dict(row) for row in rows]
            state["context"] = f"Recent invoices: {results}"

    elif bot_type == "client_management":
        # Query users, appointments, etc.
        async with db_pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT id, email, display_name, created_at
                FROM users
                WHERE active = true
                ORDER BY created_at DESC
                LIMIT 10
            """)

            results = [dict(row) for row in rows]
            state["context"] = f"Recent clients: {results}"

    return state


async def generate_response_node(  # NOSONAR
    state: CerAIState,
) -> CerAIState:
    """Generate AI response based on context."""
    # In production, use LLM (Ollama, OpenAI, etc.)
    # Async for future LLM API calls
    messages = state.get("messages", [])
    context = state.get("context", "")
    bot_type = state.get("bot_type", "accounting")
    extracted_data = state.get("extracted_data", {})

    # Handle both dict and message objects from LangGraph
    last_msg_obj = messages[-1] if messages else None
    if last_msg_obj:
        last_msg = (
            last_msg_obj.get("content", "")
            if isinstance(last_msg_obj, dict)
            else getattr(last_msg_obj, "content", "")
        )
    else:
        last_msg = ""

    # Auto-detect OCR text in message
    # (if message starts with "Przeanalizuj ten dokument")
    # and extract the document text
    ocr_text = None
    if last_msg.startswith("Przeanalizuj ten dokument"):
        # Extract text after the prompt
        lines = last_msg.split("\n")
        if len(lines) > 2:
            # Skip first 2 lines (prompt)
            ocr_text = "\n".join(lines[2:])
            if not extracted_data.get("text"):
                extracted_data["text"] = ocr_text

    # Use LoRA adapters for invoice extraction (both accounting and client_management)
    if extracted_data.get("text"):
        # First, get context from database - similar invoices, sellers, buyers
        db_context = ""
        if db_pool and bot_type == "accounting":
            try:
                async with db_pool.acquire() as conn:
                    # Get recent invoices for context
                    recent_invoices = await conn.fetch("""
                        SELECT invoice_number, seller_name, buyer_name, issue_date, gross_amount
                        FROM invoices
                        ORDER BY issue_date DESC
                        LIMIT 5
                    """)
                    
                    # Get unique sellers and buyers
                    sellers = await conn.fetch("""
                        SELECT DISTINCT seller_name, seller_nip
                        FROM invoices
                        WHERE seller_name IS NOT NULL
                        LIMIT 10
                    """)
                    
                    buyers = await conn.fetch("""
                        SELECT DISTINCT buyer_name, buyer_nip
                        FROM invoices
                        WHERE buyer_name IS NOT NULL
                        LIMIT 10
                    """)
                    
                    db_context = f"""
KONTEKST Z BAZY DANYCH:
- Ostatnie faktury: {[dict(row) for row in recent_invoices]}
- Znani sprzedawcy: {[dict(row) for row in sellers]}
- Znani nabywcy: {[dict(row) for row in buyers]}

Użyj tych danych jako referencji przy analizie nowego dokumentu.
"""
            except Exception as db_error:
                logger.warning(f"Error fetching database context: {db_error}")
        
        try:
            cerai_lora_url = os.getenv("CERAI_LORA_URL", "http://cerai-lora:8007")

            # Step 1: Extract data with Bielik adapter
            async with httpx.AsyncClient(timeout=60.0) as client:
                # Extract with Bielik - include database context
                extraction_prompt = f"""Przeanalizuj ten dokument i wyciągnij kluczowe informacje:

{db_context}

DOKUMENT DO ANALIZY:
{extracted_data.get("text", last_msg)}

Wyciągnij: numer faktury, data wystawienia, data sprzedaży, sprzedawca (nazwa, adres, NIP), nabywca (nazwa, adres, NIP), forma płatności, produkty/usługi, kwoty (netto, VAT, brutto), stawka VAT, suma całkowita.

Porównaj z danymi z bazy - jeśli sprzedawca/nabywca już istnieje w bazie, użyj tych samych danych."""

                extraction_response = await client.post(
                    f"{cerai_lora_url}/inference",
                    json={
                        "adapter_name": "bielik-invoice-extraction",
                        "prompt": extraction_prompt,
                        "max_length": 1024,
                        "temperature": 0.3,
                    }
                )

                if extraction_response.status_code == 200:
                    extracted_text = extraction_response.json()["text"]

                    # Step 2: Format to JSON with Formatter adapter
                    format_prompt = f"""Sformatuj te dane do JSON:

{extracted_text}

Zwróć TYLKO poprawny JSON z polami:
- invoice_number (string)
- issue_date (string, format YYYY-MM-DD)
- sale_date (string, format YYYY-MM-DD)
- seller (object: name, address, nip)
- buyer (object: name, address, nip)
- payment_method (string)
- items (array: name, quantity, unit_price, net_amount, vat_rate, vat_amount, gross_amount)
- totals (object: net_amount, vat_amount, gross_amount, currency)
- vat_summary (array: rate, net_amount, vat_amount, gross_amount)

Zwróć TYLKO JSON, bez dodatkowego tekstu."""

                    format_response = await client.post(
                        f"{cerai_lora_url}/inference",
                        json={
                            "adapter_name": "formatter-json-output",
                            "prompt": format_prompt,
                            "max_length": 2048,
                            "temperature": 0.1,
                        }
                    )

                    if format_response.status_code == 200:
                        formatted_text = format_response.json()["text"]
                        # Try to parse JSON from response
                        # Extract JSON from response
                        json_match = re.search(
                            r'\{.*\}', formatted_text, re.DOTALL
                        )
                        if json_match:
                            try:
                                parsed_json = json.loads(json_match.group())
                                response = json.dumps(parsed_json, indent=2, ensure_ascii=False)
                                state["extracted_data"] = parsed_json
                                # Save invoice to database
                                await save_invoice_to_db(parsed_json, bot_type)
                            except json.JSONDecodeError:
                                response = formatted_text
                        else:
                            response = formatted_text
                    else:
                        response = extracted_text
                else:
                    # Fallback to Ollama when LoRA is unavailable
                    logger.info("LoRA unavailable, falling back to Ollama")
                    try:
                        async with httpx.AsyncClient(timeout=120.0) as client:
                            ollama_prompt = f"""Przeanalizuj ten dokument faktury i wyciągnij kluczowe informacje w formacie JSON:

{db_context}

DOKUMENT DO ANALIZY:
{extracted_data.get("text", last_msg)}

Wyciągnij i zwróć TYLKO poprawny JSON z polami:
- invoice_number (string)
- issue_date (string, format YYYY-MM-DD)
- sale_date (string, format YYYY-MM-DD)
- seller (object: name, address, nip)
- buyer (object: name, address, nip)
- payment_method (string)
- items (array: name, quantity, unit_price, net_amount, vat_rate, vat_amount, gross_amount)
- totals (object: net_amount, vat_amount, gross_amount, currency)
- vat_summary (array: rate, net_amount, vat_amount, gross_amount)

Zwróć TYLKO JSON, bez dodatkowego tekstu."""

                            ollama_response = await client.post(
                                f"{OLLAMA_URL}/api/generate",
                                json={
                                    "model": "llama3.2",
                                    "prompt": ollama_prompt,
                                    "stream": False,
                                    "options": {
                                        "temperature": 0.3,
                                        "num_predict": 2048
                                    }
                                }
                            )
                            
                            if ollama_response.status_code == 200:
                                ollama_data = ollama_response.json()
                                ollama_text = ollama_data.get("response", "")
                                # Extract JSON from response
                                json_match = re.search(r'\{.*\}', ollama_text, re.DOTALL)
                                if json_match:
                                    try:
                                        parsed_json = json.loads(json_match.group())
                                        response = json.dumps(parsed_json, indent=2, ensure_ascii=False)
                                        state["extracted_data"] = parsed_json
                                    except json.JSONDecodeError:
                                        response = ollama_text
                                else:
                                    response = ollama_text
                            else:
                                # Final fallback
                                response = f"""Przeanalizowałem dokument. Oto wyciągnięte informacje:

{extracted_data.get("text", last_msg)}

⚠️ Uwaga: Automatyczne wyciąganie danych jest niedostępne. Proszę ręcznie wprowadzić dane faktury do systemu księgowego."""
                    except Exception as ollama_error:
                        logger.warning(f"Ollama fallback failed: {ollama_error}")
                        response = f"""Przeanalizowałem dokument. Oto wyciągnięte informacje:

{extracted_data.get("text", last_msg)}

⚠️ Uwaga: Automatyczne wyciąganie danych jest niedostępne. Proszę ręcznie wprowadzić dane faktury do systemu księgowego."""
        except Exception as e:
            logger.warning(f"LoRA inference failed: {e}")
            # Fallback to Ollama
            try:
                logger.info("LoRA failed, falling back to Ollama")
                async with httpx.AsyncClient(timeout=120.0) as client:
                    # Get database context
                    db_context = ""
                    if db_pool and bot_type == "accounting":
                        try:
                            async with db_pool.acquire() as conn:
                                recent_invoices = await conn.fetch("""
                                    SELECT invoice_number, seller_name, buyer_name, issue_date, gross_amount
                                    FROM invoices
                                    ORDER BY issue_date DESC
                                    LIMIT 5
                                """)
                                sellers = await conn.fetch("""
                                    SELECT DISTINCT seller_name, seller_nip
                                    FROM invoices
                                    WHERE seller_name IS NOT NULL
                                    LIMIT 10
                                """)
                                buyers = await conn.fetch("""
                                    SELECT DISTINCT buyer_name, buyer_nip
                                    FROM invoices
                                    WHERE buyer_name IS NOT NULL
                                    LIMIT 10
                                """)
                                db_context = f"""
KONTEKST Z BAZY DANYCH:
- Ostatnie faktury: {[dict(row) for row in recent_invoices]}
- Znani sprzedawcy: {[dict(row) for row in sellers]}
- Znani nabywcy: {[dict(row) for row in buyers]}

Użyj tych danych jako referencji przy analizie nowego dokumentu.
"""
                        except Exception as db_error:
                            logger.warning(f"Error fetching database context: {db_error}")
                    
                    ollama_prompt = f"""Przeanalizuj ten dokument faktury i wyciągnij kluczowe informacje w formacie JSON:

{db_context}

DOKUMENT DO ANALIZY:
{extracted_data.get("text", last_msg)}

Wyciągnij i zwróć TYLKO poprawny JSON z polami:
- invoice_number (string)
- issue_date (string, format YYYY-MM-DD)
- sale_date (string, format YYYY-MM-DD)
- seller (object: name, address, nip)
- buyer (object: name, address, nip)
- payment_method (string)
- items (array: name, quantity, unit_price, net_amount, vat_rate, vat_amount, gross_amount)
- totals (object: net_amount, vat_amount, gross_amount, currency)
- vat_summary (array: rate, net_amount, vat_amount, gross_amount)

Zwróć TYLKO JSON, bez dodatkowego tekstu."""

                    ollama_response = await client.post(
                        f"{OLLAMA_URL}/api/generate",
                        json={
                            "model": "llama3.2",
                            "prompt": ollama_prompt,
                            "stream": False,
                            "options": {
                                "temperature": 0.3,
                                "num_predict": 2048
                            }
                        }
                    )
                    
                    if ollama_response.status_code == 200:
                        ollama_data = ollama_response.json()
                        ollama_text = ollama_data.get("response", "")
                        json_match = re.search(r'\{.*\}', ollama_text, re.DOTALL)
                        if json_match:
                            try:
                                parsed_json = json.loads(json_match.group())
                                response = json.dumps(parsed_json, indent=2, ensure_ascii=False)
                                state["extracted_data"] = parsed_json
                                # Save invoice to database
                                await save_invoice_to_db(parsed_json, bot_type)
                            except json.JSONDecodeError:
                                response = ollama_text
                        else:
                            response = ollama_text
                    else:
                        response = f"""Przeanalizowałem dokument. Oto wyciągnięte informacje:

{extracted_data.get("text", last_msg)}

⚠️ Uwaga: Automatyczne wyciąganie danych jest niedostępne. Proszę ręcznie wprowadzić dane faktury do systemu księgowego."""
            except Exception as ollama_error:
                logger.warning(f"Ollama fallback failed: {ollama_error}")
                response = f"""Przeanalizowałem dokument. Oto wyciągnięte informacje:

{extracted_data.get("text", last_msg)}

⚠️ Uwaga: Automatyczne wyciąganie danych jest niedostępne. Proszę ręcznie wprowadzić dane faktury do systemu księgowego."""
    else:
        # Placeholder response for non-accounting or no extracted data
        response = f"""
Bot Type: {bot_type}
Context: {context}
Message: {last_msg}

This is a placeholder response.
In production, this would use a language model.
"""

    new_messages = [*messages, {"role": "assistant", "content": response}]
    return {
        **state,
        "messages": new_messages
    }


async def save_invoice_to_db(invoice_data: dict[str, Any], bot_type: str) -> None:
    """Save extracted invoice data to database."""
    if not db_pool or bot_type != "accounting":
        return
    
    try:
        async with db_pool.acquire() as conn:
            # Check if invoice already exists
            invoice_number = invoice_data.get("invoice_number")
            if invoice_number:
                existing = await conn.fetchrow(
                    "SELECT id FROM invoices WHERE invoice_number = $1",
                    invoice_number
                )
                if existing:
                    logger.info(f"Invoice {invoice_number} already exists, skipping save")
                    return
            
            # Extract data
            issue_date = invoice_data.get("issue_date")
            sale_date = invoice_data.get("sale_date")
            seller = invoice_data.get("seller", {})
            buyer = invoice_data.get("buyer", {})
            payment_method = invoice_data.get("payment_method", "Gotówka")
            totals = invoice_data.get("totals", {})
            items = invoice_data.get("items", [])
            
            # Calculate totals
            total_net = totals.get("net_amount", 0) or sum(
                item.get("net_amount", 0) or 0 for item in items
            )
            total_vat = totals.get("vat_amount", 0) or sum(
                item.get("vat_amount", 0) or 0 for item in items
            )
            total_gross = totals.get("gross_amount", 0) or (total_net + total_vat)
            
            # Insert invoice
            await conn.execute("""
                INSERT INTO invoices (
                    invoice_number, issue_date, sale_date,
                    seller_name, seller_address, seller_nip,
                    buyer_name, buyer_address, buyer_nip,
                    payment_method, net_amount, vat_amount, gross_amount,
                    currency, status, created_at
                ) VALUES (
                    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, 'pending', NOW()
                )
            """,
                invoice_number or f"INV-{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')}",
                issue_date,
                sale_date,
                seller.get("name"),
                seller.get("address"),
                seller.get("nip"),
                buyer.get("name"),
                buyer.get("address"),
                buyer.get("nip"),
                payment_method,
                float(total_net),
                float(total_vat),
                float(total_gross),
                totals.get("currency", "PLN")
            )
            
            logger.info(f"Invoice {invoice_number} saved to database")
    except Exception as e:
        logger.error(f"Error saving invoice to database: {e}")


async def generate_report_node(  # NOSONAR
    state: CerAIState,
) -> CerAIState:
    """Generate report data and visualizations."""
    # Async for future database queries and chart generation
    report_type = state.get("report_data", {}).get("type", "summary")

    # In production, generate actual report data and charts
    report_data = {
        "type": report_type,
        "data": {},
        "charts": []
    }

    return {
        **state,
        "report_data": report_data
    }


# Build LangGraph
def create_accounting_graph() -> Any:  # noqa: ANN401
    """Create LangGraph for accounting bot."""
    builder = StateGraph(CerAIState)

    builder.add_node("analyze_receipt", analyze_receipt_node)
    builder.add_node("query_db", query_database_node)
    builder.add_node("generate_response", generate_response_node)
    builder.add_node("generate_report", generate_report_node)

    builder.set_entry_point("query_db")
    builder.add_edge("query_db", "generate_response")
    builder.add_edge("generate_response", END)

    return builder.compile()


def create_client_management_graph() -> Any:  # noqa: ANN401
    """Create LangGraph for client management bot."""
    builder = StateGraph(CerAIState)

    builder.add_node("query_db", query_database_node)
    builder.add_node("generate_response", generate_response_node)

    builder.set_entry_point("query_db")
    builder.add_edge("query_db", "generate_response")
    builder.add_edge("generate_response", END)

    return builder.compile()


# Graph instances
accounting_graph = create_accounting_graph()
client_management_graph = create_client_management_graph()


# API Endpoints
@app.get("/")
async def root() -> dict[str, Any]:
    """Root endpoint."""
    return {
        "name": "CerAI API",
        "version": "1.0.0",
        "status": "running",
        "features": {
            "ocr": OCR_AVAILABLE,
            "rag": RAG_AVAILABLE,
            "postgres": db_pool is not None,
            "redis": redis_client is not None,
            "mongodb": mongo_client is not None
        }
    }


@app.post("/api/chat")
async def chat(request: ChatMessage) -> dict[str, Any]:
    """Chat endpoint with LangGraph."""
    # Select graph based on bot type
    if request.bot_type == "accounting":
        graph = accounting_graph
    elif request.bot_type == "client_management":
        graph = client_management_graph
    else:
        raise HTTPException(
            status_code=400,
            detail="Invalid bot_type"
        )

    try:
        # Prepare initial state
        initial_state: CerAIState = {
            "messages": [{"role": "user", "content": request.message}],
            "context": request.context or "",
            "bot_type": request.bot_type,
            "extracted_data": {},
            "report_data": {}
        }

        # Run graph
        result = await graph.ainvoke(initial_state)

        # Get last assistant message
        messages = result.get("messages", [])
        # Handle both dict and message objects from LangGraph
        assistant_messages = []
        for m in messages:
            if isinstance(m, dict):
                if m.get("role") == "assistant":
                    assistant_messages.append(m)
            else:
                # LangChain message object (AIMessage, HumanMessage, etc.)
                msg_type = type(m).__name__
                if "AI" in msg_type or "Assistant" in msg_type:
                    assistant_messages.append(m)

        if assistant_messages:
            last_msg = assistant_messages[-1]
            response_text = (
                last_msg.get("content", "")
                if isinstance(last_msg, dict)
                else getattr(last_msg, "content", "No response generated")
            )
        else:
            response_text = "No response generated"

        return {
            "response": response_text,
            "context": result.get("context", ""),
            "session_id": request.session_id,
            "extracted_data": result.get("extracted_data", {})
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e


@app.post("/api/ocr")
async def process_ocr(
    file: UploadFile = File(...),  # noqa: B008
    document_type: str = Form(default="receipt")
) -> dict[str, Any]:
    """Process receipt/invoice with OCR."""
    if not OCR_AVAILABLE or not reader:
        raise HTTPException(status_code=503, detail="OCR not available")

    # Read file
    contents = await file.read()
    file_type = file.content_type or ""

    # Handle PDF files
    if file_type == "application/pdf" or file.filename and file.filename.lower().endswith(".pdf"):
        if not PDF_AVAILABLE:
            raise HTTPException(
                status_code=503,
                detail="PDF processing not available. Install pdf2image"
            )

        try:
            # Convert PDF to images
            images = convert_from_bytes(contents)
            if not images:
                raise HTTPException(
                    status_code=400,
                    detail="Could not extract images from PDF"
                )

            # Process first page (or all pages)
            all_text_lines = []
            all_results = []

            for img in images:
                # Convert PIL image to OpenCV format
                img_array = np.array(img)
                img_cv = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)

                # OCR
                results = reader.readtext(img_cv)
                text_lines = [result[1] for result in results]
                all_text_lines.extend(text_lines)
                all_results.extend(results)

            full_text = "\n".join(all_text_lines)
            text_lines = all_text_lines
            results = all_results
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"PDF processing error: {str(e)}"
            ) from e
    else:
        # Handle image files
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            raise HTTPException(
                status_code=400,
                detail="Invalid image format"
            )

        # OCR
        try:
            results = reader.readtext(img)
            # Extract text
            text_lines = [result[1] for result in results]
            full_text = "\n".join(text_lines)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e)) from e

    # Convert numpy types to native Python types for JSON serialization
    def convert_numpy_types(obj):
        """Recursively convert numpy types to native Python types."""
        if isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        elif isinstance(obj, dict):
            return {
                key: convert_numpy_types(value)
                for key, value in obj.items()
            }
        elif isinstance(obj, (list, tuple)):
            return [convert_numpy_types(item) for item in obj]
        return obj

    # Convert raw OCR results to serializable format
    serializable_results = []
    for result in results:
        bbox, text, confidence = result
        conf_value = (
            float(confidence)
            if isinstance(confidence, (np.floating, float))
            else confidence
        )
        serializable_results.append({
            "bbox": convert_numpy_types(bbox),
            "text": str(text),
            "confidence": conf_value
        })

    # Extract structured data (simplified)
    # In production, use LLM to extract structured data
    extracted_data = {
        "text": full_text,
        "lines": text_lines,
        "document_type": document_type,
        "raw_ocr": serializable_results
    }

    return {
        "success": True,
        "text": full_text,
        "extracted_data": extracted_data
    }


@app.post("/api/ocr/base64")
async def process_ocr_base64(
    request: OCRRequest
) -> dict[str, Any]:
    """Process OCR from base64 image."""
    if not OCR_AVAILABLE or not reader:
        raise HTTPException(status_code=503, detail="OCR not available")

    if not request.image_base64:
        raise HTTPException(
            status_code=400,
            detail="image_base64 is required"
        )

    # Decode base64
    image_data = base64.b64decode(request.image_base64)
    nparr = np.frombuffer(image_data, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        raise HTTPException(status_code=400, detail="Invalid image format")

    try:
        # OCR
        results = reader.readtext(img)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e
    else:
        text_lines = [result[1] for result in results]
        full_text = "\n".join(text_lines)

        # Convert numpy types to native Python types for JSON serialization
        def convert_numpy_types(obj):
            """Recursively convert numpy types to native Python types."""
            if isinstance(obj, np.integer):
                return int(obj)
            elif isinstance(obj, np.floating):
                return float(obj)
            elif isinstance(obj, np.ndarray):
                return obj.tolist()
            elif isinstance(obj, dict):
                return {key: convert_numpy_types(value) for key, value in obj.items()}
            elif isinstance(obj, (list, tuple)):
                return [convert_numpy_types(item) for item in obj]
            return obj

        # Convert raw OCR results to serializable format
        serializable_results = []
        for result in results:
            bbox, text, confidence = result
            serializable_results.append({
                "bbox": convert_numpy_types(bbox),
                "text": str(text),
                "confidence": float(confidence) if isinstance(confidence, (np.floating, float)) else confidence
            })

        extracted_data = {
            "text": full_text,
            "lines": text_lines,
            "document_type": request.document_type,
            "raw_ocr": serializable_results
        }

        return {
            "success": True,
            "text": full_text,
            "extracted_data": extracted_data
        }


@app.post("/api/reports/generate")
async def generate_report(
    request: ReportRequest
) -> dict[str, Any]:
    """Generate report with data and visualizations."""
    # Query database for report data
    if not db_pool:
        raise HTTPException(
            status_code=503,
            detail="Database not available"
        )

    try:
        async with db_pool.acquire() as conn:
            if request.report_type == "accounting_summary":
                # Get accounting summary data
                invoices = await conn.fetch("""
                    SELECT
                        COUNT(*) as total_invoices,
                        SUM(total_amount) as total_revenue,
                        COUNT(CASE WHEN status = 'paid' THEN 1 END)
                            as paid_count,
                        COUNT(CASE WHEN status = 'overdue' THEN 1 END)
                            as overdue_count
                    FROM invoices
                    WHERE issue_date >= CURRENT_DATE - INTERVAL '30 days'
                """)

                data = dict(invoices[0]) if invoices else {}

                return {
                    "report_type": "accounting_summary",
                    "data": data,
                    "charts": [
                        {
                            "type": "bar",
                            "title": "Revenue by Status",
                            "data": {
                                "paid": data.get("paid_count", 0),
                                "overdue": data.get("overdue_count", 0)
                            }
                        }
                    ]
                }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e

    return {"error": "Report type not implemented"}


# Bot Configuration Endpoints
@app.get("/api/bot-config")
async def get_all_bot_configs() -> dict[str, Any]:
    """Get all bot configurations."""
    if not db_pool:
        raise HTTPException(
            status_code=503, detail="Database not available"
        )

    try:
        async with db_pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT bot_type, name, description, enabled, model,
                       temperature, max_tokens, use_lora, lora_adapter,
                       context_window, created_at, updated_at
                FROM bot_configurations
                ORDER BY bot_type
            """)

            configs = []
            for row in rows:
                configs.append({
                    "bot_type": row["bot_type"],
                    "name": row["name"],
                    "description": row["description"],
                    "enabled": row["enabled"],
                    "model": row["model"],
                    "temperature": float(row["temperature"]),
                    "max_tokens": row["max_tokens"],
                    "use_lora": row["use_lora"],
                    "lora_adapter": row["lora_adapter"],
                    "context_window": row["context_window"],
                    "created_at": (
                        row["created_at"].isoformat()
                        if row["created_at"] else None
                    ),
                    "updated_at": (
                        row["updated_at"].isoformat()
                        if row["updated_at"] else None
                    ),
                })

            return {"configs": configs}
    except Exception as e:
        logger.error("Error fetching bot configs: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to fetch configs: {str(e)}"
        ) from e


@app.get("/api/bot-config/{bot_type}")
async def get_bot_config(bot_type: str) -> BotConfigResponse:
    """Get configuration for specific bot type."""
    if not db_pool:
        raise HTTPException(
            status_code=503, detail="Database not available"
        )

    try:
        async with db_pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT bot_type, name, description, enabled, model,
                       temperature, max_tokens, use_lora, lora_adapter,
                       context_window, created_at, updated_at
                FROM bot_configurations
                WHERE bot_type = $1
            """, bot_type)

            if not row:
                raise HTTPException(
                    status_code=404,
                    detail=f"Bot configuration not found: {bot_type}"
                )

            return BotConfigResponse(
                bot_type=row["bot_type"],
                name=row["name"],
                description=row["description"],
                enabled=row["enabled"],
                model=row["model"],
                temperature=float(row["temperature"]),
                max_tokens=row["max_tokens"],
                use_lora=row["use_lora"],
                lora_adapter=row["lora_adapter"],
                context_window=row["context_window"],
                created_at=(
                    row["created_at"].isoformat()
                    if row["created_at"] else None
                ),
                updated_at=(
                    row["updated_at"].isoformat()
                    if row["updated_at"] else None
                ),
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error fetching bot config: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to fetch config: {str(e)}"
        ) from e


@app.put("/api/bot-config/{bot_type}")
async def update_bot_config(
    bot_type: str, request: BotConfigRequest
) -> BotConfigResponse:
    """Update bot configuration."""
    if not db_pool:
        raise HTTPException(
            status_code=503, detail="Database not available"
        )

    try:
        async with db_pool.acquire() as conn:
            # Check if exists
            exists = await conn.fetchval("""
                SELECT EXISTS(SELECT 1 FROM bot_configurations WHERE bot_type = $1)
            """, bot_type)

            if not exists:
                raise HTTPException(
                    status_code=404,
                    detail=f"Bot configuration not found: {bot_type}"
                )

            # Update
            row = await conn.fetchrow("""
                UPDATE bot_configurations
                SET name = $2, description = $3, enabled = $4, model = $5,
                    temperature = $6, max_tokens = $7, use_lora = $8,
                    lora_adapter = $9, context_window = $10,
                    updated_at = CURRENT_TIMESTAMP
                WHERE bot_type = $1
                RETURNING bot_type, name, description, enabled, model,
                          temperature, max_tokens, use_lora, lora_adapter,
                          context_window, created_at, updated_at
            """, bot_type, request.name, request.description, request.enabled,
                request.model, request.temperature, request.max_tokens,
                request.use_lora, request.lora_adapter, request.context_window)

            return BotConfigResponse(
                bot_type=row["bot_type"],
                name=row["name"],
                description=row["description"],
                enabled=row["enabled"],
                model=row["model"],
                temperature=float(row["temperature"]),
                max_tokens=row["max_tokens"],
                use_lora=row["use_lora"],
                lora_adapter=row["lora_adapter"],
                context_window=row["context_window"],
                created_at=(
                    row["created_at"].isoformat()
                    if row["created_at"] else None
                ),
                updated_at=(
                    row["updated_at"].isoformat()
                    if row["updated_at"] else None
                ),
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error updating bot config: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to update config: {str(e)}"
        ) from e


@app.post("/api/bot-config/{bot_type}/test")
async def test_bot(bot_type: str) -> dict[str, Any]:
    """Test bot connection and configuration."""
    if not db_pool:
        raise HTTPException(
            status_code=503, detail="Database not available"
        )

    try:
        # Get bot config
        async with db_pool.acquire() as conn:
            config = await conn.fetchrow("""
                SELECT enabled, model, use_lora, lora_adapter
                FROM bot_configurations
                WHERE bot_type = $1
            """, bot_type)

            if not config:
                raise HTTPException(
                    status_code=404,
                    detail=f"Bot configuration not found: {bot_type}"
                )

            if not config["enabled"]:
                return {
                    "status": "disabled",
                    "message": "Bot is disabled"
                }

            # Test by sending a simple chat message
            test_state: CerAIState = {
                "messages": [
                    {"role": "user", "content": "Test połączenia"}
                ],
                "context": "",
                "bot_type": bot_type,
                "extracted_data": {},
                "report_data": {}
            }

            # Use appropriate graph
            if bot_type == "accounting":
                result = await accounting_graph.ainvoke(test_state)
            elif bot_type == "client_management":
                result = await client_management_graph.ainvoke(test_state)
            else:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid bot type: {bot_type}"
                )

            # Check if we got a response
            messages = result.get("messages", [])
            if messages and len(messages) > 0:
                return {
                    "status": "success",
                    "message": "Bot responded successfully",
                    "bot_type": bot_type,
                    "model": config["model"],
                    "use_lora": config["use_lora"]
                }
            else:
                return {
                    "status": "error",
                    "message": "Bot did not respond"
                }

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error testing bot: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Test failed: {str(e)}"
        ) from e


# LangChain Workflow Endpoints
@app.get("/api/langchain/workflows")
async def get_workflows() -> dict[str, Any]:
    """Get all LangChain workflows."""
    if not mongo_client:
        raise HTTPException(
            status_code=503, detail="MongoDB not available"
        )

    try:
        db = mongo_client.ceramix
        collection = db.langchain_workflows

        workflows = []
        async for doc in collection.find({}):
            workflows.append({
                "id": str(doc["_id"]),
                "name": doc.get("name", ""),
                "description": doc.get("description"),
                "nodes": doc.get("nodes", []),
                "edges": doc.get("edges", []),
                "status": doc.get("status", "inactive"),
                "created_at": (
                    doc.get("created_at").isoformat()
                    if doc.get("created_at") else None
                ),
                "updated_at": (
                    doc.get("updated_at").isoformat()
                    if doc.get("updated_at") else None
                ),
            })

        return {"workflows": workflows}
    except Exception as e:
        logger.error("Error fetching workflows: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to fetch workflows: {str(e)}"
        ) from e


@app.get("/api/langchain/workflows/{workflow_id}")
async def get_workflow(workflow_id: str) -> LangChainWorkflowResponse:
    """Get specific LangChain workflow."""
    if not mongo_client:
        raise HTTPException(
            status_code=503, detail="MongoDB not available"
        )

    try:
        db = mongo_client.ceramix
        collection = db.langchain_workflows

        doc = await collection.find_one({"_id": ObjectId(workflow_id)})
        if not doc:
            raise HTTPException(
                status_code=404,
                detail=f"Workflow not found: {workflow_id}"
            )

        return LangChainWorkflowResponse(
            id=str(doc["_id"]),
            name=doc.get("name", ""),
            description=doc.get("description"),
            nodes=doc.get("nodes", []),
            edges=doc.get("edges", []),
            status=doc.get("status", "inactive"),
            created_at=(
                doc.get("created_at").isoformat()
                if doc.get("created_at") else None
            ),
            updated_at=(
                doc.get("updated_at").isoformat()
                if doc.get("updated_at") else None
            ),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error fetching workflow: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to fetch workflow: {str(e)}"
        ) from e


@app.post("/api/langchain/workflows")
async def create_workflow(
    request: LangChainWorkflowRequest
) -> LangChainWorkflowResponse:
    """Create new LangChain workflow."""
    if not mongo_client:
        raise HTTPException(
            status_code=503, detail="MongoDB not available"
        )

    try:
        db = mongo_client.ceramix
        collection = db.langchain_workflows

        workflow_doc = {
            "_id": ObjectId(),
            "name": request.name,
            "description": request.description,
            "nodes": request.nodes,
            "edges": request.edges,
            "status": request.status,
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
        }

        await collection.insert_one(workflow_doc)

        return LangChainWorkflowResponse(
            id=str(workflow_doc["_id"]),
            name=workflow_doc["name"],
            description=workflow_doc["description"],
            nodes=workflow_doc["nodes"],
            edges=workflow_doc["edges"],
            status=workflow_doc["status"],
            created_at=workflow_doc["created_at"].isoformat(),
            updated_at=workflow_doc["updated_at"].isoformat(),
        )
    except Exception as e:
        logger.error("Error creating workflow: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to create workflow: {str(e)}"
        ) from e


@app.put("/api/langchain/workflows/{workflow_id}")
async def update_workflow(
    workflow_id: str, request: LangChainWorkflowRequest
) -> LangChainWorkflowResponse:
    """Update LangChain workflow."""
    if not mongo_client:
        raise HTTPException(
            status_code=503, detail="MongoDB not available"
        )

    try:
        db = mongo_client.ceramix
        collection = db.langchain_workflows

        update_doc = {
            "name": request.name,
            "description": request.description,
            "nodes": request.nodes,
            "edges": request.edges,
            "status": request.status,
            "updated_at": datetime.now(timezone.utc),
        }

        result = await collection.update_one(
            {"_id": ObjectId(workflow_id)},
            {"$set": update_doc}
        )

        if result.matched_count == 0:
            raise HTTPException(
                status_code=404,
                detail=f"Workflow not found: {workflow_id}"
            )

        # Fetch updated document
        doc = await collection.find_one({"_id": ObjectId(workflow_id)})

        return LangChainWorkflowResponse(
            id=str(doc["_id"]),
            name=doc["name"],
            description=doc.get("description"),
            nodes=doc.get("nodes", []),
            edges=doc.get("edges", []),
            status=doc.get("status", "inactive"),
            created_at=(
                doc.get("created_at").isoformat()
                if doc.get("created_at") else None
            ),
            updated_at=(
                doc.get("updated_at").isoformat()
                if doc.get("updated_at") else None
            ),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error updating workflow: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to update workflow: {str(e)}"
        ) from e


@app.delete("/api/langchain/workflows/{workflow_id}")
async def delete_workflow(workflow_id: str) -> dict[str, Any]:
    """Delete LangChain workflow."""
    if not mongo_client:
        raise HTTPException(
            status_code=503, detail="MongoDB not available"
        )

    try:
        db = mongo_client.ceramix
        collection = db.langchain_workflows

        result = await collection.delete_one({"_id": ObjectId(workflow_id)})

        if result.deleted_count == 0:
            raise HTTPException(
                status_code=404,
                detail=f"Workflow not found: {workflow_id}"
            )

        return {"message": "Workflow deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error deleting workflow: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to delete workflow: {str(e)}"
        ) from e


@app.post("/api/langchain/workflows/{workflow_id}/run")
async def run_workflow(
    workflow_id: str, input_data: dict[str, Any] | None = None
) -> dict[str, Any]:
    """Run LangChain workflow."""
    if not mongo_client:
        raise HTTPException(
            status_code=503, detail="MongoDB not available"
        )

    try:
        db = mongo_client.ceramix
        collection = db.langchain_workflows

        doc = await collection.find_one({"_id": ObjectId(workflow_id)})
        if not doc:
            raise HTTPException(
                status_code=404,
                detail=f"Workflow not found: {workflow_id}"
            )

        if doc.get("status") != "active":
            raise HTTPException(
                status_code=400,
                detail="Workflow is not active"
            )

        # TODO: Implement actual workflow execution
        # For now, return a placeholder response
        return {
            "workflow_id": workflow_id,
            "status": "completed",
            "message": "Workflow execution not yet implemented",
            "input": input_data,
            "output": {}
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error running workflow: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to run workflow: {str(e)}"
        ) from e


@app.get("/api/health")
async def health_check() -> dict[str, Any]:
    """Health check endpoint with detailed service status."""
    services_status: dict[str, Any] = {
        "cerai_bot": {"status": "healthy", "message": "CerAI Bot is running"}
    }

    # Check PostgreSQL
    postgres_healthy = False
    if db_pool:
        try:
            async with db_pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
            postgres_healthy = True
            services_status["postgres"] = {
                "status": "healthy",
                "message": "Connected"
            }
        except Exception as e:
            services_status["postgres"] = {
                "status": "unhealthy",
                "message": str(e)
            }
    else:
        services_status["postgres"] = {
            "status": "unavailable",
            "message": "Not connected"
        }

    # Check Redis
    redis_healthy = False
    if redis_client:
        try:
            await redis_client.ping()
            redis_healthy = True
            services_status["redis"] = {
                "status": "healthy",
                "message": "Connected"
            }
        except Exception as e:
            services_status["redis"] = {
                "status": "unhealthy",
                "message": str(e)
            }
    else:
        services_status["redis"] = {
            "status": "unavailable",
            "message": "Not connected"
        }

    # Check MongoDB
    mongodb_healthy = False
    if mongo_client:
        try:
            await mongo_client.admin.command("ping")
            mongodb_healthy = True
            services_status["mongodb"] = {
                "status": "healthy",
                "message": "Connected"
            }
        except Exception as e:
            services_status["mongodb"] = {
                "status": "unhealthy",
                "message": str(e)
            }
    else:
        services_status["mongodb"] = {
            "status": "unavailable",
            "message": "Not connected"
        }

    # Check OCR
    ocr_healthy = OCR_AVAILABLE and reader is not None
    services_status["ocr"] = {
        "status": "healthy" if ocr_healthy else "unavailable",
        "message": "Available" if ocr_healthy else "Not initialized"
    }

    # Check LoRA Service
    lora_url = os.getenv("CERAI_LORA_URL", "http://cerai-lora:8007")
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{lora_url}/health")
            if response.status_code == 200:
                # Check if adapters are available
                try:
                    adapters_response = await client.get(
                        f"{lora_url}/adapters"
                    )
                    adapters_data = (
                        adapters_response.json()
                        if adapters_response.status_code == 200
                        else {}
                    )
                    adapter_count = adapters_data.get("count", 0)
                    services_status["lora"] = {
                        "status": "healthy",
                        "message": (
                            f"Connected ({adapter_count} adapters)"
                        ),
                        "url": lora_url,
                        "adapters_count": adapter_count
                    }
                except Exception:
                    services_status["lora"] = {
                        "status": "healthy",
                        "message": (
                            "Connected (unable to check adapters)"
                        ),
                        "url": lora_url
                    }
            else:
                services_status["lora"] = {
                    "status": "unhealthy",
                    "message": f"HTTP {response.status_code}",
                    "url": lora_url
                }
    except httpx.ConnectError:
        services_status["lora"] = {
            "status": "unavailable",
            "message": (
                "Service not running or unreachable. "
                "Check if cerai-lora container is running."
            ),
            "url": lora_url
        }
    except httpx.TimeoutException:
        services_status["lora"] = {
            "status": "unavailable",
            "message": (
                "Connection timeout. "
                "Service may be slow or unreachable."
            ),
            "url": lora_url
        }
    except Exception as e:
        services_status["lora"] = {
            "status": "unavailable",
            "message": f"Error: {str(e)}",
            "url": lora_url
        }

    # Overall status
    all_critical_healthy = (
        postgres_healthy and redis_healthy and mongodb_healthy
    )
    overall_status = "healthy" if all_critical_healthy else "degraded"

    return {
        "status": overall_status,
        "services": services_status
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
