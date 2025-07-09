from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.docs import get_swagger_ui_html, get_redoc_html
from fastapi.openapi.utils import get_openapi

# Import API routers
from app.api.v1.endpoints import auth, cats, cafe

app = FastAPI(
    title="Meowtopia API",
    description="""
    🐱 **Meowtopia - Virtual Cat Universe API**
    
    A comprehensive blockchain-based virtual cat universe that integrates with the Chain-Rice blockchain infrastructure.
    
    ## Features
    - 🎮 **Game Management**: Cat collection, breeding, training, and tournaments
    - 💰 **Token Economics**: MWT token integration for game activities
    - 🔗 **Blockchain Integration**: Smart contract interactions and wallet management
    - 👤 **User Management**: Authentication, profiles, and game progress
    - 📊 **Analytics**: Game statistics and user performance tracking
    - ☕ **Cafe Management**: Complete cafe management system for virtual cat cafes
    
    ## Authentication
    Most endpoints require JWT authentication. Include your token in the Authorization header:
    ```
    Authorization: Bearer <your-jwt-token>
    ```
    
    ## Game Mechanics
    - **Cats**: Own and manage virtual cats with unique attributes
    - **Energy System**: Cats have energy that depletes with activities
    - **MWT Tokens**: Earn and spend tokens for game activities
    - **Breeding**: Combine cats to create new offspring
    - **Tournaments**: Compete with other players for rewards
    
    ## Cafe Management
    - **Inventory**: Manage cafe items, stock levels, and pricing
    - **Staff**: Hire and manage cafe staff members
    - **Customers**: Track customer visits and preferences
    - **Orders**: Process orders and track order status
    - **Analytics**: Comprehensive cafe performance metrics
    """,
    version="1.0.0",
    contact={
        "name": "Meowtopia Development Team",
        "email": "dev@meowtopia.com",
        "url": "https://meowtopia.com",
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT",
    },
    docs_url=None,  # Disable default docs to customize
    redoc_url=None,  # Disable default redoc to customize
)

# CORS configuration for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # React web app
        "http://localhost:19006",  # React Native Expo
        "http://localhost:8081",   # React Native Metro
        "https://meowtopia.com",   # Production web
        "https://app.meowtopia.com", # Production mobile
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(cats.router, prefix="/api/v1")
app.include_router(cafe.router, prefix="/api/v1")

@app.get("/")
def read_root():
    """
    🏠 **Welcome to Meowtopia API**
    
    This is the main entry point for the Meowtopia virtual cat universe API.
    """
    return {
        "message": "Welcome to Meowtopia! 🐱",
        "version": "1.0.0",
        "status": "active",
        "docs": "/docs",
        "redoc": "/redoc",
        "health": "/health",
        "features": [
            "Cat Management",
            "Cafe Management", 
            "User Authentication",
            "Analytics & Reporting"
        ]
    }

@app.get("/health")
def health_check():
    """
    🏥 **Health Check**
    
    Check the health status of the Meowtopia API service.
    """
    return {
        "status": "healthy",
        "service": "meowtopia-backend",
        "version": "1.0.0",
        "timestamp": "2024-01-01T00:00:00Z"
    }

# Custom OpenAPI schema
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title="Meowtopia API",
        version="1.0.0",
        description="""
        🐱 **Meowtopia - Virtual Cat Universe API**
        
        A comprehensive blockchain-based virtual cat universe that integrates with the Chain-Rice blockchain infrastructure.
        
        ## Game Features
        - **Cat Management**: Collect, breed, and train virtual cats
        - **Token Economics**: Earn and spend MWT tokens
        - **Blockchain Integration**: Smart contract interactions
        - **Tournaments**: Compete with other players
        - **User Profiles**: Track progress and achievements
        - **Cafe Management**: Complete virtual cafe management system
        
        ## Authentication
        Most endpoints require JWT authentication via Bearer token.
        """,
        routes=app.routes,
    )
    
    # Add custom tags for better organization
    openapi_schema["tags"] = [
        {
            "name": "Authentication",
            "description": "User authentication and authorization endpoints"
        },
        {
            "name": "Users",
            "description": "User profile and account management"
        },
        {
            "name": "Cats",
            "description": "Virtual cat management and interactions"
        },
        {
            "name": "Game",
            "description": "Game mechanics and activities"
        },
        {
            "name": "Cafe Management",
            "description": "Complete cafe management system including inventory, staff, customers, orders, and analytics"
        },
        {
            "name": "Blockchain",
            "description": "Blockchain and smart contract interactions"
        },
        {
            "name": "Tournaments",
            "description": "Competitive gameplay and tournaments"
        },
        {
            "name": "Analytics",
            "description": "Game statistics and analytics"
        }
    ]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

# Custom documentation endpoints
@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html():
    return get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=f"{app.title} - Swagger UI",
        oauth2_redirect_url=app.swagger_ui_oauth2_redirect_url,
        swagger_js_url="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui-bundle.js",
        swagger_css_url="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui.css",
        swagger_ui_parameters={
            "defaultModelsExpandDepth": -1,
            "docExpansion": "list",
            "filter": True,
            "showExtensions": True,
            "showCommonExtensions": True,
        }
    )

@app.get("/redoc", include_in_schema=False)
async def redoc_html():
    return get_redoc_html(
        openapi_url=app.openapi_url,
        title=f"{app.title} - ReDoc",
        redoc_js_url="https://cdn.jsdelivr.net/npm/redoc@2.1.3/bundles/redoc.standalone.js",
        redoc_favicon_url="https://fastapi.tiangolo.com/img/favicon.png",
    )
