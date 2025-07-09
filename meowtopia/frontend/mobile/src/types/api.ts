// Auto-generated TypeScript types for Meowtopia API
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
