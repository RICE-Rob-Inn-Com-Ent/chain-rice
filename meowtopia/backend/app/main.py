"""
Meowtopia Backend API - Main FastAPI application with production-ready features.
"""
import logging
import structlog
import datetime
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.security import HTTPBearer
from fastapi.openapi.docs import get_swagger_ui_html, get_redoc_html
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

from app.config import settings

# Try to import database components if available
try:
    from app.config import engine, Base, SessionLocal
    DATABASE_AVAILABLE = True
except ImportError:
    DATABASE_AVAILABLE = False
    engine = None
    Base = None
    SessionLocal = None

# Try to import routers if available
try:
    from app.api.v1.auth.endpoints import router as auth_router
    AUTH_ROUTER_AVAILABLE = True
except ImportError:
    AUTH_ROUTER_AVAILABLE = False
    auth_router = None

try:
    from app.api.v1.storage.endpoints import router as storage_router
    STORAGE_ROUTER_AVAILABLE = True
except ImportError:
    STORAGE_ROUTER_AVAILABLE = False
    storage_router = None

try:
    from app.api.v1.accounting.endpoints import router as accounting_router
    ACCOUNTING_ROUTER_AVAILABLE = True
except ImportError:
    ACCOUNTING_ROUTER_AVAILABLE = False
    accounting_router = None

try:
    from app.api.v1.cafe.endpoints import router as cafe_router
    CAFE_ROUTER_AVAILABLE = True
except ImportError:
    CAFE_ROUTER_AVAILABLE = False
    cafe_router = None

# Configure structured logging
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.StackInfoRenderer(),
        structlog.dev.set_exc_info,
        structlog.processors.JSONRenderer() if settings.LOG_FORMAT == "json" else structlog.dev.ConsoleRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(
        logging.getLevelName(settings.LOG_LEVEL.upper())
    ),
    logger_factory=structlog.WriteLoggerFactory(),
    cache_logger_on_first_use=True,
)

# Configure Sentry for error tracking
if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        environment=settings.SENTRY_ENVIRONMENT,
        integrations=[
            FastApiIntegration(auto_enabling_integrations=False),
        ],
        traces_sample_rate=0.1 if settings.SENTRY_ENVIRONMENT == "production" else 1.0,
        profiles_sample_rate=0.1 if settings.SENTRY_ENVIRONMENT == "production" else 1.0,
    )

# Configure rate limiter
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[f"{settings.RATE_LIMIT_PER_MINUTE}/minute"]
)

# Application lifespan management
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management."""
    logger = structlog.get_logger()
    
    # Startup
    logger.info("Starting Meowtopia Backend API", version=settings.APP_VERSION)
    
    # Create database tables only if database is available
    if DATABASE_AVAILABLE:
        try:
            from app.api.v1.auth.models import User
            Base.metadata.create_all(bind=engine)
            logger.info("Database tables created successfully")
        except Exception as e:
            logger.error("Failed to create database tables", error=str(e))
            logger.warning("Continuing without database functionality")
    else:
        logger.info("Database functionality disabled - continuing in simple mode")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Meowtopia Backend API")

# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="""
    🐱 **Meowtopia Cat Cafe - Business Management API**
    
    Complete business management system for cat cafe operations with blockchain integration.
    
    ## 🏪 Business Features
    
    ### Authentication & Security
    - 🔐 Secure user registration and login
    - 👥 Staff and customer management
    - 🛡️ Role-based access control
    - 📧 Email verification and password recovery
    
    ### Storage & Inventory Management
    - 📦 Real-time inventory tracking
    - 🏷️ Product categorization and labeling
    - 📊 Stock level monitoring and alerts
    - 📅 Expiry date management
    - 🔄 Automated reorder notifications
    
    ### Financial Management & Accounting
    - 💰 Complete transaction tracking
    - 📋 Invoice generation and management
    - Financial reporting and analytics
    - 💳 Multiple payment method support
    - 📊 Profit/loss statements
    - 🧾 Tax calculation and compliance
    
    ## 🚀 Advanced Features
    - 🤖 AI-powered business insights
    - 📱 Mobile-first responsive design
    - ⛓️ Blockchain integration with Chain-Rice
    - 🎮 Gamification elements for customer engagement
    - 📧 Automated customer communications
    
    ## 🔒 Enterprise Security
    - Rate limiting and DDoS protection
    - CORS and trusted host validation
    - Comprehensive audit logging
    - Real-time error monitoring
    - GDPR compliance features
    """,
    version=settings.APP_VERSION,
    contact={
        "name": "Meowtopia Development Team",
        "email": "dev@meowtopia.com",
        "url": "https://meowtopia.com",
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT",
    },
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan,
)

# Add security middleware
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"] if settings.DEBUG else ["meowtopia.app", "api.meowtopia.app", "localhost"]
)

# Add GZIP compression
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
)

# Add rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Security scheme
security = HTTPBearer()

# Include routers only if available
if AUTH_ROUTER_AVAILABLE:
    app.include_router(auth_router, prefix="/api/v1/auth")

if STORAGE_ROUTER_AVAILABLE:
    app.include_router(storage_router, prefix="/api/v1/storage")

if ACCOUNTING_ROUTER_AVAILABLE:
    app.include_router(accounting_router, prefix="/api/v1/accounting")

# Moduł kawiarni (PL): logika biznesowa menu, koty, rezerwacje, zamówienia
if CAFE_ROUTER_AVAILABLE:
    app.include_router(cafe_router, prefix="/api/v1/cafe")

# Health check endpoints
@app.get("/health", tags=["health"])
async def health_check():
    """Health check endpoint for load balancers and monitoring."""
    return {
        "status": "healthy",
        "version": settings.APP_VERSION,
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "environment": settings.SENTRY_ENVIRONMENT
    }

@app.get("/ready", tags=["health"])
async def readiness_check():
    """Readiness check endpoint for Kubernetes deployments."""
    try:
        if DATABASE_AVAILABLE:
            # Test database connection
            from app.config import SessionLocal
            db = SessionLocal()
            db.execute("SELECT 1")
            db.close()
            
            return {
                "status": "ready",
                "database": "connected",
                "timestamp": datetime.datetime.utcnow().isoformat()
            }
        else:
            return {
                "status": "ready",
                "database": "disabled",
                "mode": "simple",
                "timestamp": datetime.datetime.utcnow().isoformat()
            }
    except Exception as e:
        logger = structlog.get_logger()
        logger.error("Readiness check failed", error=str(e))
        return JSONResponse(
            status_code=503,
            content={
                "status": "not_ready",
                "error": "Database connection failed",
                "timestamp": datetime.datetime.utcnow().isoformat()
            }
        )

@app.get("/", tags=["root"])
@limiter.limit(f"{settings.RATE_LIMIT_PER_MINUTE}/minute")
async def root(request: Request):
    """Root endpoint with API information."""
    return {
        "message": "Welcome to Meowtopia Cat Cafe Management System! 🐱☕",
        "description": "Complete business management solution for cat cafe operations",
        "version": settings.APP_VERSION,
        "docs": "/docs" if settings.DEBUG else "Contact admin for API documentation",
        "api_modules": {
            "authentication": "/api/v1/auth" if AUTH_ROUTER_AVAILABLE else "unavailable",
            "storage_management": "/api/v1/storage" if STORAGE_ROUTER_AVAILABLE else "unavailable", 
            "financial_accounting": "/api/v1/accounting" if ACCOUNTING_ROUTER_AVAILABLE else "unavailable",
            "cafe_management": "/api/v1/cafe" if CAFE_ROUTER_AVAILABLE else "unavailable"
        },
        "system_status": {
            "api": "operational",
            "database": "connected" if DATABASE_AVAILABLE else "disabled",
            "modules": {
                "auth": AUTH_ROUTER_AVAILABLE,
                "storage": STORAGE_ROUTER_AVAILABLE, 
                "accounting": ACCOUNTING_ROUTER_AVAILABLE,
                "cafe": CAFE_ROUTER_AVAILABLE
            }
        },
        "business_features": [
            "🔐 User Authentication & Access Control",
            "📦 Inventory & Storage Management", 
            "💰 Financial Tracking & Accounting",
            "📊 Business Analytics & Reporting",
            "📱 Mobile-Friendly Interface",
            "⛓️ Blockchain Integration"
        ]
    }

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for unhandled errors."""
    logger = structlog.get_logger()
    logger.error(
        "Unhandled exception",
        path=request.url.path,
        method=request.method,
        error=str(exc),
        exc_info=True
    )
    
    if settings.DEBUG:
        return JSONResponse(
            status_code=500,
            content={
                "error": "Internal server error",
                "detail": str(exc),
                "path": request.url.path
            }
        )
    else:
        return JSONResponse(
            status_code=500,
            content={
                "error": "Internal server error",
                "message": "An unexpected error occurred. Please try again later."
            }
        )

"""
Dokumentacja OpenAPI i eksport (PL):
- W trybie developerskim udostępniamy GUI Swagger i Redoc
- Dodatkowo wystawiamy statyczny eksport specyfikacji pod /openapi.yaml
"""
if settings.DEBUG:
    @app.get("/docs", include_in_schema=False)
    async def custom_swagger_ui_html():
        return get_swagger_ui_html(
            openapi_url=app.openapi_url,
            title=f"{app.title} - Interactive API Documentation",
            swagger_favicon_url="/static/favicon.ico"
        )

    @app.get("/redoc", include_in_schema=False)
    async def redoc_html():
        return get_redoc_html(
            openapi_url=app.openapi_url,
            title=f"{app.title} - API Documentation",
            redoc_favicon_url="/static/favicon.ico"
        )

    @app.get("/openapi.yaml", include_in_schema=False)
    async def openapi_yaml():
        import yaml
        return Response(
            content=yaml.dump(app.openapi()),
            media_type="application/yaml"
        )

# For development and testing
if __name__ == "__main__":
    import uvicorn
    print("Starting Meowtopia Backend in development mode...")
    print(f"Configuration loaded from: {settings.APP_NAME}")
    print(f"Debug mode: {settings.DEBUG}")
    print(f"Database available: {DATABASE_AVAILABLE}")
    print(f"Auth router available: {AUTH_ROUTER_AVAILABLE}")
    print(f"Cafe router available: {CAFE_ROUTER_AVAILABLE}")
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info" if not settings.DEBUG else "debug"
    )
