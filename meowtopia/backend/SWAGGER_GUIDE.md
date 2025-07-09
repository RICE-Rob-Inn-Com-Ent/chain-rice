# 🐱 Swagger/OpenAPI Guide for Meowtopia

This guide explains how Swagger/OpenAPI documentation helps you build and maintain your Meowtopia virtual cat universe app.

## 🚀 What is Swagger/OpenAPI?

Swagger (now OpenAPI) is a specification for documenting REST APIs. In your Meowtopia project, it automatically generates:

- **Interactive API Documentation** - Test endpoints directly in the browser
- **TypeScript Type Generation** - Auto-generate types for frontend development
- **API Contract Validation** - Ensure frontend and backend stay in sync
- **Team Collaboration** - Shared understanding of API structure

## 📚 Available Documentation

### 1. Swagger UI (`/docs`)
- **URL**: `http://localhost:8000/docs`
- **Features**: Interactive testing, request/response examples, authentication
- **Best for**: Development and testing

### 2. ReDoc (`/redoc`)
- **URL**: `http://localhost:8000/redoc`
- **Features**: Clean, responsive documentation
- **Best for**: Sharing with stakeholders and team members

### 3. OpenAPI JSON Schema (`/openapi.json`)
- **URL**: `http://localhost:8000/openapi.json`
- **Features**: Machine-readable API specification
- **Best for**: Code generation and automation

## 🛠️ How to Use Swagger for Meowtopia Development

### 1. **Start the Backend Server**

```bash
cd meowtopia/backend
poetry install
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. **Access Swagger Documentation**

Open your browser and navigate to:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### 3. **Test API Endpoints**

#### Authentication Flow
1. **Register a new user**:
   - Go to `/api/v1/auth/register`
   - Click "Try it out"
   - Enter user data:
   ```json
   {
     "username": "catlover",
     "email": "catlover@meowtopia.com",
     "password": "securepassword123",
     "wallet_address": "cosmos1..."
   }
   ```
   - Click "Execute"
   - Copy the `access_token` from the response

2. **Authenticate requests**:
   - Click the "Authorize" button at the top
   - Enter: `Bearer <your-access-token>`
   - Click "Authorize"

#### Cat Management
1. **Create a cat**:
   - Go to `/api/v1/cats/` (POST)
   - Enter cat data:
   ```json
   {
     "name": "Whiskers",
     "rarity": "rare",
     "breed": "Persian"
   }
   ```

2. **View your cats**:
   - Go to `/api/v1/cats/` (GET)
   - Execute to see all your cats

3. **Perform activities**:
   - Go to `/api/v1/cats/{cat_id}/activity`
   - Enter activity data:
   ```json
   {
     "activity": "play",
     "duration_minutes": 30
   }
   ```

## 🔧 Frontend Integration

### TypeScript Type Generation

The Swagger setup automatically generates TypeScript types for your frontend:

```bash
# Generate types from OpenAPI schema
cd meowtopia/backend
python scripts/generate_types.py
```

This creates:
- `meowtopia/frontend/web/src/types/api.ts` - TypeScript interfaces
- `meowtopia/frontend/web/src/types/client.ts` - API client class

### Using Generated Types

```typescript
import { MeowtopiaApiClient, CatRarity, CatActivity } from './types/client';

const api = new MeowtopiaApiClient({
  baseUrl: 'http://localhost:8000',
  timeout: 5000
});

// Set authentication token
api.setAuthToken('your-jwt-token');

// Create a cat with full type safety
const newCat = await api.createCat({
  name: "Fluffy",
  rarity: CatRarity.EPIC,
  breed: "Maine Coon"
});

// Perform activities with type checking
const activity = await api.performCatActivity(newCat.data.id, {
  activity: CatActivity.PLAY,
  duration_minutes: 45
});
```

## 🎯 Benefits for Meowtopia Development

### 1. **Faster Development**
- **Auto-completion**: IDE suggests correct field names and types
- **Error Prevention**: TypeScript catches API contract violations
- **Live Testing**: Test endpoints without writing test code

### 2. **Better Team Collaboration**
- **Shared Understanding**: Everyone sees the same API documentation
- **Version Control**: API changes are tracked in code
- **Onboarding**: New developers can understand the API quickly

### 3. **Quality Assurance**
- **Contract Testing**: Ensure frontend and backend match
- **Validation**: Automatic request/response validation
- **Error Handling**: Consistent error responses

### 4. **Mobile Development**
- **React Native**: Same types work for mobile app
- **Cross-platform**: Consistent API across web and mobile
- **Offline Support**: Generate offline-capable clients

## 🔄 API Development Workflow

### 1. **Design First**
```python
# Define your Pydantic models
class CatCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    rarity: CatRarity
    breed: str
```

### 2. **Implement Endpoints**
```python
@router.post("/", response_model=CatResponse)
async def create_cat(cat_data: CatCreate):
    """Create a new cat with full documentation"""
    # Implementation here
```

### 3. **Test in Swagger**
- Open `/docs`
- Test the endpoint with real data
- Verify responses and error handling

### 4. **Generate Frontend Types**
```bash
python scripts/generate_types.py
```

### 5. **Use in Frontend**
```typescript
// Full type safety and auto-completion
const cat = await api.createCat({
  name: "Whiskers",
  rarity: CatRarity.RARE,  // Auto-completion works
  breed: "Persian"
});
```

## 🚀 Advanced Features

### 1. **Custom Documentation**
```python
@router.post("/cats/{cat_id}/activity")
async def perform_cat_activity(
    cat_id: str,
    activity_data: CatActivityRequest
):
    """
    🎮 **Perform Cat Activity**
    
    Perform an activity with a cat (feed, play, train, sleep).
    
    - **cat_id**: ID of the cat to interact with
    - **activity**: Type of activity (feed, play, train, sleep)
    - **duration_minutes**: Duration of the activity (1-480 minutes)
    
    Returns the result of the activity including energy changes and rewards.
    """
```

### 2. **Response Examples**
```python
class CatResponse(BaseModel):
    id: str = Field(..., example="cat_123")
    name: str = Field(..., example="Whiskers")
    rarity: CatRarity = Field(..., example=CatRarity.RARE)
    energy: int = Field(100, ge=0, le=100, example=85)
```

### 3. **Authentication**
```python
# Swagger automatically shows authentication requirements
@router.get("/me", response_model=UserProfile)
async def get_current_user_profile(
    current_user: dict = Depends(get_current_user)
):
    """Requires JWT authentication"""
```

## 🔍 Monitoring and Debugging

### 1. **Request/Response Logging**
Swagger UI shows:
- Request headers and body
- Response status and body
- Execution time
- Error details

### 2. **Schema Validation**
- Automatic validation of request data
- Clear error messages for invalid data
- Type checking for all fields

### 3. **API Testing**
- Test different scenarios
- Verify error handling
- Check authentication flows

## 📈 Best Practices

### 1. **Keep Documentation Updated**
- Update docstrings when changing endpoints
- Add examples for complex requests
- Document error responses

### 2. **Use Consistent Naming**
- Follow REST conventions
- Use clear, descriptive endpoint names
- Maintain consistent response formats

### 3. **Version Your API**
- Use URL versioning (`/api/v1/`)
- Document breaking changes
- Maintain backward compatibility

### 4. **Security**
- Document authentication requirements
- Show required permissions
- Include security examples

## 🎮 Meowtopia-Specific Features

### Game Mechanics Documentation
- **Cat Activities**: Feed, play, train, sleep
- **Energy System**: Energy costs and gains
- **Token Economics**: MWT earning and spending
- **Breeding System**: Cat combination logic

### Blockchain Integration
- **Wallet Management**: Address linking and validation
- **Smart Contract Calls**: Token minting and burning
- **Transaction Tracking**: Status and confirmation

### Analytics and Reporting
- **User Statistics**: Game progress tracking
- **Cat Performance**: Attribute improvements
- **Economic Metrics**: Token flow analysis

## 🚀 Next Steps

1. **Start the server** and explore the documentation
2. **Test the authentication flow** with Swagger UI
3. **Create and interact with cats** using the API
4. **Generate TypeScript types** for your frontend
5. **Integrate the API client** into your React/React Native apps

Swagger will significantly speed up your Meowtopia development by providing clear documentation, type safety, and interactive testing capabilities! 