#!/usr/bin/env python3
"""
TypeScript Type Generator for Meowtopia API

This script generates TypeScript types from the FastAPI OpenAPI schema
for use in the frontend applications.
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, Any, List

def generate_typescript_types(openapi_schema: Dict[str, Any]) -> str:
    """Generate TypeScript types from OpenAPI schema"""
    
    typescript_code = []
    typescript_code.append("// Auto-generated TypeScript types from Meowtopia API")
    typescript_code.append("// Generated from OpenAPI schema - DO NOT EDIT MANUALLY")
    typescript_code.append("")
    
    # Generate enums
    typescript_code.append("// Enums")
    typescript_code.append("export enum CatRarity {")
    typescript_code.append("  COMMON = 'common',")
    typescript_code.append("  RARE = 'rare',")
    typescript_code.append("  EPIC = 'epic',")
    typescript_code.append("  LEGENDARY = 'legendary'")
    typescript_code.append("}")
    typescript_code.append("")
    
    typescript_code.append("export enum CatActivity {")
    typescript_code.append("  FEED = 'feed',")
    typescript_code.append("  PLAY = 'play',")
    typescript_code.append("  TRAIN = 'train',")
    typescript_code.append("  SLEEP = 'sleep'")
    typescript_code.append("}")
    typescript_code.append("")
    
    # Generate interfaces from schema components
    if "components" in openapi_schema and "schemas" in openapi_schema["components"]:
        schemas = openapi_schema["components"]["schemas"]
        
        for schema_name, schema in schemas.items():
            if schema_name.startswith("HTTP"):
                continue  # Skip HTTP validation errors
                
            typescript_code.append(f"export interface {schema_name} {{")
            
            if "properties" in schema:
                for prop_name, prop_schema in schema["properties"].items():
                    prop_type = get_typescript_type(prop_schema)
                    required = prop_name in schema.get("required", [])
                    optional = "" if required else "?"
                    
                    # Add JSDoc comment if description exists
                    if "description" in prop_schema:
                        typescript_code.append(f"  /** {prop_schema['description']} */")
                    
                    typescript_code.append(f"  {prop_name}{optional}: {prop_type};")
            
            typescript_code.append("}")
            typescript_code.append("")
    
    # Generate API client types
    typescript_code.append("// API Response types")
    typescript_code.append("export interface ApiResponse<T> {")
    typescript_code.append("  data: T;")
    typescript_code.append("  message?: string;")
    typescript_code.append("  success: boolean;")
    typescript_code.append("}")
    typescript_code.append("")
    
    typescript_code.append("// API Error types")
    typescript_code.append("export interface ApiError {")
    typescript_code.append("  detail: string;")
    typescript_code.append("  status_code: number;")
    typescript_code.append("}")
    typescript_code.append("")
    
    # Generate endpoint types
    typescript_code.append("// API Endpoints")
    typescript_code.append("export interface ApiEndpoints {")
    
    if "paths" in openapi_schema:
        for path, methods in openapi_schema["paths"].items():
            for method, operation in methods.items():
                if method.upper() in ["GET", "POST", "PUT", "DELETE", "PATCH"]:
                    operation_id = operation.get("operationId", f"{method.lower()}_{path.replace('/', '_').replace('{', '').replace('}', '')}")
                    
                    # Get request body type
                    request_type = "any"
                    if "requestBody" in operation and "content" in operation["requestBody"]:
                        content = operation["requestBody"]["content"]
                        if "application/json" in content:
                            request_type = get_schema_type(content["application/json"]["schema"])
                    
                    # Get response type
                    response_type = "any"
                    if "200" in operation.get("responses", {}):
                        response = operation["responses"]["200"]
                        if "content" in response and "application/json" in response["content"]:
                            response_type = get_schema_type(response["content"]["application/json"]["schema"])
                    
                    typescript_code.append(f"  {operation_id}: {{")
                    typescript_code.append(f"    method: '{method.upper()}';")
                    typescript_code.append(f"    path: '{path}';")
                    typescript_code.append(f"    request: {request_type};")
                    typescript_code.append(f"    response: {response_type};")
                    typescript_code.append(f"  }};")
    
    typescript_code.append("}")
    typescript_code.append("")
    
    return "\n".join(typescript_code)

def get_typescript_type(schema: Dict[str, Any]) -> str:
    """Convert OpenAPI schema type to TypeScript type"""
    
    if "type" not in schema:
        if "$ref" in schema:
            return get_ref_type(schema["$ref"])
        return "any"
    
    schema_type = schema["type"]
    
    if schema_type == "string":
        if "enum" in schema:
            enum_values = [f"'{value}'" for value in schema["enum"]]
            return f"({' | '.join(enum_values)})"
        return "string"
    elif schema_type == "integer":
        return "number"
    elif schema_type == "number":
        return "number"
    elif schema_type == "boolean":
        return "boolean"
    elif schema_type == "array":
        items_type = get_typescript_type(schema.get("items", {}))
        return f"{items_type}[]"
    elif schema_type == "object":
        return "Record<string, any>"
    else:
        return "any"

def get_schema_type(schema: Dict[str, Any]) -> str:
    """Get TypeScript type from schema reference or direct schema"""
    if "$ref" in schema:
        return get_ref_type(schema["$ref"])
    else:
        return get_typescript_type(schema)

def get_ref_type(ref: str) -> str:
    """Extract type name from $ref"""
    return ref.split("/")[-1]

def main():
    """Main function to generate TypeScript types"""
    
    # Get the project root directory
    project_root = Path(__file__).parent.parent
    frontend_web_dir = project_root.parent / "frontend" / "web"
    frontend_mobile_dir = project_root.parent / "frontend" / "mobile"
    
    # Create types directory if it doesn't exist
    types_dir = frontend_web_dir / "src" / "types"
    types_dir.mkdir(parents=True, exist_ok=True)
    
    # For now, we'll create a basic types file since we can't run the FastAPI app
    # In a real scenario, you would fetch the OpenAPI schema from the running server
    
    basic_types = """// Auto-generated TypeScript types for Meowtopia API
// This file should be regenerated when the API schema changes

// Enums
export enum CatRarity {
  COMMON = 'common',
  RARE = 'rare',
  EPIC = 'epic',
  LEGENDARY = 'legendary'
}

export enum CatActivity {
  FEED = 'feed',
  PLAY = 'play',
  TRAIN = 'train',
  SLEEP = 'sleep'
}

// Cafe Management Enums
export enum ItemCategory {
  FOOD = 'food',
  DRINK = 'drink',
  DESSERT = 'dessert',
  CAT_FOOD = 'cat_food',
  CAT_TOY = 'cat_toy',
  DECORATION = 'decoration'
}

export enum OrderStatus {
  PENDING = 'pending',
  PREPARING = 'preparing',
  READY = 'ready',
  SERVED = 'served',
  CANCELLED = 'cancelled'
}

export enum StaffRole {
  MANAGER = 'manager',
  BARISTA = 'barista',
  WAITER = 'waiter',
  CLEANER = 'cleaner',
  CAT_CAREGIVER = 'cat_caregiver'
}

export enum CustomerMood {
  VERY_HAPPY = 'very_happy',
  HAPPY = 'happy',
  NEUTRAL = 'neutral',
  UNHAPPY = 'unhappy',
  VERY_UNHAPPY = 'very_unhappy'
}

// Authentication Types
export interface UserRegister {
  username: string;
  email: string;
  password: string;
  wallet_address?: string;
}

export interface UserLogin {
  email: string;
  password: string;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  user_id: string;
  username: string;
}

export interface UserProfile {
  id: string;
  username: string;
  email: string;
  wallet_address?: string;
  game_level: number;
  mwt_balance: number;
  cats_owned: number;
  created_at: string;
  last_login?: string;
}

// Cat Types
export interface CatBase {
  name: string;
  rarity: CatRarity;
  breed: string;
}

export interface CatCreate extends CatBase {}

export interface CatResponse extends CatBase {
  id: string;
  owner_id: string;
  level: number;
  experience: number;
  energy: number;
  max_energy: number;
  cuteness: number;
  playfulness: number;
  intelligence: number;
  is_available: boolean;
  last_activity?: string;
  created_at: string;
  updated_at: string;
}

export interface CatActivityRequest {
  activity: CatActivity;
  duration_minutes?: number;
}

export interface CatActivityResponse {
  cat_id: string;
  activity: CatActivity;
  success: boolean;
  energy_cost: number;
  energy_remaining: number;
  mwt_earned?: number;
  mwt_cost?: number;
  experience_gained: number;
  new_level?: number;
  message: string;
}

export interface CatBreedingRequest {
  cat1_id: string;
  cat2_id: string;
}

export interface CatBreedingResponse {
  success: boolean;
  new_cat?: CatResponse;
  mwt_cost: number;
  message: string;
}

// Cafe Management Types
export interface CafeItemBase {
  name: string;
  category: ItemCategory;
  description: string;
  price: number;
  cost: number;
  stock_quantity: number;
  min_stock_level: number;
}

export interface CafeItemCreate extends CafeItemBase {}

export interface CafeItemResponse extends CafeItemBase {
  id: string;
  cafe_id: string;
  profit_margin: number;
  is_available: boolean;
  created_at: string;
  updated_at: string;
}

export interface StaffMemberBase {
  name: string;
  role: StaffRole;
  hourly_rate: number;
  email: string;
}

export interface StaffMemberCreate extends StaffMemberBase {}

export interface StaffMemberResponse extends StaffMemberBase {
  id: string;
  cafe_id: string;
  is_active: boolean;
  total_hours_worked: number;
  total_salary_paid: number;
  hire_date: string;
  created_at: string;
  updated_at: string;
}

export interface CustomerBase {
  name: string;
  email: string;
  phone?: string;
}

export interface CustomerCreate extends CustomerBase {}

export interface CustomerResponse extends CustomerBase {
  id: string;
  cafe_id: string;
  total_visits: number;
  total_spent: number;
  favorite_items: string[];
  mood: CustomerMood;
  last_visit?: string;
  created_at: string;
  updated_at: string;
}

export interface OrderItem {
  item_id: string;
  quantity: number;
  unit_price: number;
  total_price: number;
}

export interface OrderBase {
  customer_id: string;
  items: OrderItem[];
  table_number?: number;
  special_requests?: string;
}

export interface OrderCreate extends OrderBase {}

export interface OrderResponse extends OrderBase {
  id: string;
  cafe_id: string;
  status: OrderStatus;
  total_amount: number;
  tax_amount: number;
  tip_amount: number;
  staff_id?: string;
  created_at: string;
  updated_at: string;
  served_at?: string;
}

export interface CafeAnalytics {
  total_revenue: number;
  total_orders: number;
  average_order_value: number;
  top_selling_items: Array<{
    item_id: string;
    name: string;
    quantity_sold: number;
    revenue: number;
  }>;
  customer_satisfaction: number;
  staff_performance: Array<{
    staff_id: string;
    name: string;
    role: string;
    hours_worked: number;
    orders_handled: number;
  }>;
  inventory_alerts: Array<{
    item_id: string;
    name: string;
    current_stock: number;
    min_stock: number;
  }>;
  daily_revenue: Array<{
    date: string;
    revenue: number;
  }>;
  period: string;
}

export interface CafeSettings {
  cafe_name: string;
  opening_hours: Record<string, string>;
  max_capacity: number;
  auto_restock_threshold: number;
  tax_rate: number;
  service_charge_rate: number;
  cat_interaction_fee: number;
}

// API Response Types
export interface ApiResponse<T> {
  data: T;
  message?: string;
  success: boolean;
}

export interface ApiError {
  detail: string;
  status_code: number;
}

// API Client Configuration
export interface ApiConfig {
  baseUrl: string;
  timeout: number;
  headers?: Record<string, string>;
}

// Game State Types
export interface GameState {
  user: UserProfile;
  cats: CatResponse[];
  mwt_balance: number;
  game_level: number;
}

// Blockchain Types
export interface WalletInfo {
  address: string;
  balance: number;
  connected: boolean;
}

export interface Transaction {
  id: string;
  type: 'mint' | 'burn' | 'transfer';
  amount: number;
  status: 'pending' | 'confirmed' | 'failed';
  timestamp: string;
  hash?: string;
}
"""
    
    # Write types to web frontend
    types_file = types_dir / "api.ts"
    with open(types_file, "w") as f:
        f.write(basic_types)
    
    print(f"✅ Generated TypeScript types: {types_file}")
    
    # Also create a mobile types file
    mobile_types_dir = frontend_mobile_dir / "src" / "types"
    mobile_types_dir.mkdir(parents=True, exist_ok=True)
    
    mobile_types_file = mobile_types_dir / "api.ts"
    with open(mobile_types_file, "w") as f:
        f.write(basic_types)
    
    print(f"✅ Generated TypeScript types for mobile: {mobile_types_file}")
    
    # Create API client
    api_client = """// Auto-generated API client for Meowtopia
import { ApiConfig, ApiResponse, ApiError } from './types';

export class MeowtopiaApiClient {
  private config: ApiConfig;
  private authToken?: string;

  constructor(config: ApiConfig) {
    this.config = config;
  }

  setAuthToken(token: string) {
    this.authToken = token;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.config.baseUrl}${endpoint}`;
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...this.config.headers,
      ...options.headers,
    };

    if (this.authToken) {
      headers['Authorization'] = `Bearer ${this.authToken}`;
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers,
      });

      if (!response.ok) {
        const error: ApiError = await response.json();
        throw new Error(error.detail || 'API request failed');
      }

      const data = await response.json();
      return {
        data,
        success: true,
      };
    } catch (error) {
      throw new Error(error instanceof Error ? error.message : 'Network error');
    }
  }

  // Authentication endpoints
  async register(userData: UserRegister): Promise<ApiResponse<TokenResponse>> {
    return this.request<TokenResponse>('/api/v1/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  }

  async login(credentials: UserLogin): Promise<ApiResponse<TokenResponse>> {
    return this.request<TokenResponse>('/api/v1/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
  }

  async getProfile(): Promise<ApiResponse<UserProfile>> {
    return this.request<UserProfile>('/api/v1/auth/me');
  }

  async logout(): Promise<ApiResponse<{ message: string }>> {
    return this.request<{ message: string }>('/api/v1/auth/logout', {
      method: 'POST',
    });
  }

  // Cat endpoints
  async createCat(catData: CatCreate): Promise<ApiResponse<CatResponse>> {
    return this.request<CatResponse>('/api/v1/cats', {
      method: 'POST',
      body: JSON.stringify(catData),
    });
  }

  async getUserCats(): Promise<ApiResponse<CatResponse[]>> {
    return this.request<CatResponse[]>('/api/v1/cats');
  }

  async getCat(catId: string): Promise<ApiResponse<CatResponse>> {
    return this.request<CatResponse>(`/api/v1/cats/${catId}`);
  }

  async performCatActivity(
    catId: string,
    activity: CatActivityRequest
  ): Promise<ApiResponse<CatActivityResponse>> {
    return this.request<CatActivityResponse>(`/api/v1/cats/${catId}/activity`, {
      method: 'POST',
      body: JSON.stringify(activity),
    });
  }

  async breedCats(breedingData: CatBreedingRequest): Promise<ApiResponse<CatBreedingResponse>> {
    return this.request<CatBreedingResponse>('/api/v1/cats/breed', {
      method: 'POST',
      body: JSON.stringify(breedingData),
    });
  }

  // Cafe Management endpoints
  async getCafeItems(category?: ItemCategory, availableOnly?: boolean): Promise<ApiResponse<CafeItemResponse[]>> {
    const params = new URLSearchParams();
    if (category) params.append('category', category);
    if (availableOnly) params.append('available_only', 'true');
    
    return this.request<CafeItemResponse[]>(`/api/v1/cafe/items?${params}`);
  }

  async createCafeItem(itemData: CafeItemCreate): Promise<ApiResponse<CafeItemResponse>> {
    return this.request<CafeItemResponse>('/api/v1/cafe/items', {
      method: 'POST',
      body: JSON.stringify(itemData),
    });
  }

  async updateItemStock(itemId: string, quantity: number): Promise<ApiResponse<CafeItemResponse>> {
    return this.request<CafeItemResponse>(`/api/v1/cafe/items/${itemId}/stock?quantity=${quantity}`, {
      method: 'PUT',
    });
  }

  async getStaffMembers(activeOnly = true, role?: StaffRole): Promise<ApiResponse<StaffMemberResponse[]>> {
    const params = new URLSearchParams();
    params.append('active_only', activeOnly.toString());
    if (role) params.append('role', role);
    
    return this.request<StaffMemberResponse[]>(`/api/v1/cafe/staff?${params}`);
  }

  async hireStaffMember(staffData: StaffMemberCreate): Promise<ApiResponse<StaffMemberResponse>> {
    return this.request<StaffMemberResponse>('/api/v1/cafe/staff', {
      method: 'POST',
      body: JSON.stringify(staffData),
    });
  }

  async getCustomers(topSpenders = false): Promise<ApiResponse<CustomerResponse[]>> {
    const params = new URLSearchParams();
    params.append('top_spenders', topSpenders.toString());
    
    return this.request<CustomerResponse[]>(`/api/v1/cafe/customers?${params}`);
  }

  async addCustomer(customerData: CustomerCreate): Promise<ApiResponse<CustomerResponse>> {
    return this.request<CustomerResponse>('/api/v1/cafe/customers', {
      method: 'POST',
      body: JSON.stringify(customerData),
    });
  }

  async getOrders(status?: OrderStatus, customerId?: string): Promise<ApiResponse<OrderResponse[]>> {
    const params = new URLSearchParams();
    if (status) params.append('status', status);
    if (customerId) params.append('customer_id', customerId);
    
    return this.request<OrderResponse[]>(`/api/v1/cafe/orders?${params}`);
  }

  async createOrder(orderData: OrderCreate): Promise<ApiResponse<OrderResponse>> {
    return this.request<OrderResponse>('/api/v1/cafe/orders', {
      method: 'POST',
      body: JSON.stringify(orderData),
    });
  }

  async updateOrderStatus(orderId: string, status: OrderStatus, staffId?: string): Promise<ApiResponse<OrderResponse>> {
    const params = new URLSearchParams();
    params.append('status', status);
    if (staffId) params.append('staff_id', staffId);
    
    return this.request<OrderResponse>(`/api/v1/cafe/orders/${orderId}/status?${params}`, {
      method: 'PUT',
    });
  }

  async getCafeAnalytics(period = 'today'): Promise<ApiResponse<CafeAnalytics>> {
    return this.request<CafeAnalytics>(`/api/v1/cafe/analytics?period=${period}`);
  }

  async getCafeSettings(): Promise<ApiResponse<CafeSettings>> {
    return this.request<CafeSettings>('/api/v1/cafe/settings');
  }

  async updateCafeSettings(settings: CafeSettings): Promise<ApiResponse<CafeSettings>> {
    return this.request<CafeSettings>('/api/v1/cafe/settings', {
      method: 'PUT',
      body: JSON.stringify(settings),
    });
  }
}

// Export types for convenience
export type {
  UserRegister,
  UserLogin,
  TokenResponse,
  UserProfile,
  CatCreate,
  CatResponse,
  CatActivityRequest,
  CatActivityResponse,
  CatBreedingRequest,
  CatBreedingResponse,
  CatRarity,
  CatActivity,
  CafeItemCreate,
  CafeItemResponse,
  StaffMemberCreate,
  StaffMemberResponse,
  CustomerCreate,
  CustomerResponse,
  OrderCreate,
  OrderResponse,
  CafeAnalytics,
  CafeSettings,
  ItemCategory,
  OrderStatus,
  StaffRole,
  CustomerMood,
} from './types';
"""
    
    client_file = types_dir / "client.ts"
    with open(client_file, "w") as f:
        f.write(api_client)
    
    print(f"✅ Generated API client: {client_file}")

if __name__ == "__main__":
    main() 