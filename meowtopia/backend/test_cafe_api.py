#!/usr/bin/env python3
"""
Cafe API Test Script

This script demonstrates how to use the Meowtopia Cafe API endpoints.
Run this after starting your FastAPI server to test all cafe functionality.
"""

import requests
import json
from typing import Dict, Any

class CafeAPITester:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.auth_token = None
        self.session = requests.Session()
    
    def register_user(self, username: str, email: str, password: str) -> Dict[str, Any]:
        """Register a new user for testing"""
        url = f"{self.base_url}/api/v1/auth/register"
        data = {
            "username": username,
            "email": email,
            "password": password
        }
        
        response = self.session.post(url, json=data)
        if response.status_code == 201:
            result = response.json()
            self.auth_token = result["access_token"]
            self.session.headers.update({"Authorization": f"Bearer {self.auth_token}"})
            print(f"✅ Registered user: {username}")
            return result
        else:
            print(f"❌ Failed to register user: {response.text}")
            return {}
    
    def login_user(self, email: str, password: str) -> Dict[str, Any]:
        """Login existing user"""
        url = f"{self.base_url}/api/v1/auth/login"
        data = {
            "email": email,
            "password": password
        }
        
        response = self.session.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            self.auth_token = result["access_token"]
            self.session.headers.update({"Authorization": f"Bearer {self.auth_token}"})
            print(f"✅ Logged in user: {email}")
            return result
        else:
            print(f"❌ Failed to login: {response.text}")
            return {}
    
    def create_cafe_item(self, item_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new cafe item"""
        url = f"{self.base_url}/api/v1/cafe/items"
        response = self.session.post(url, json=item_data)
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ Created cafe item: {item_data['name']}")
            return result
        else:
            print(f"❌ Failed to create item: {response.text}")
            return {}
    
    def get_cafe_items(self) -> Dict[str, Any]:
        """Get all cafe items"""
        url = f"{self.base_url}/api/v1/cafe/items"
        response = self.session.get(url)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved {len(result)} cafe items")
            return result
        else:
            print(f"❌ Failed to get items: {response.text}")
            return []
    
    def hire_staff_member(self, staff_data: Dict[str, Any]) -> Dict[str, Any]:
        """Hire a new staff member"""
        url = f"{self.base_url}/api/v1/cafe/staff"
        response = self.session.post(url, json=staff_data)
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ Hired staff member: {staff_data['name']}")
            return result
        else:
            print(f"❌ Failed to hire staff: {response.text}")
            return {}
    
    def get_staff_members(self) -> Dict[str, Any]:
        """Get all staff members"""
        url = f"{self.base_url}/api/v1/cafe/staff"
        response = self.session.get(url)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved {len(result)} staff members")
            return result
        else:
            print(f"❌ Failed to get staff: {response.text}")
            return []
    
    def add_customer(self, customer_data: Dict[str, Any]) -> Dict[str, Any]:
        """Add a new customer"""
        url = f"{self.base_url}/api/v1/cafe/customers"
        response = self.session.post(url, json=customer_data)
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ Added customer: {customer_data['name']}")
            return result
        else:
            print(f"❌ Failed to add customer: {response.text}")
            return {}
    
    def get_customers(self) -> Dict[str, Any]:
        """Get all customers"""
        url = f"{self.base_url}/api/v1/cafe/customers"
        response = self.session.get(url)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved {len(result)} customers")
            return result
        else:
            print(f"❌ Failed to get customers: {response.text}")
            return []
    
    def create_order(self, order_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new order"""
        url = f"{self.base_url}/api/v1/cafe/orders"
        response = self.session.post(url, json=order_data)
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ Created order: ${result['total_amount']}")
            return result
        else:
            print(f"❌ Failed to create order: {response.text}")
            return {}
    
    def get_orders(self) -> Dict[str, Any]:
        """Get all orders"""
        url = f"{self.base_url}/api/v1/cafe/orders"
        response = self.session.get(url)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved {len(result)} orders")
            return result
        else:
            print(f"❌ Failed to get orders: {response.text}")
            return []
    
    def get_analytics(self, period: str = "today") -> Dict[str, Any]:
        """Get cafe analytics"""
        url = f"{self.base_url}/api/v1/cafe/analytics?period={period}"
        response = self.session.get(url)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved analytics for {period}")
            return result
        else:
            print(f"❌ Failed to get analytics: {response.text}")
            return {}
    
    def get_settings(self) -> Dict[str, Any]:
        """Get cafe settings"""
        url = f"{self.base_url}/api/v1/cafe/settings"
        response = self.session.get(url)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved cafe settings")
            return result
        else:
            print(f"❌ Failed to get settings: {response.text}")
            return {}

def main():
    """Main test function"""
    print("🐱 Meowtopia Cafe API Test Script")
    print("=" * 50)
    
    # Initialize tester
    tester = CafeAPITester()
    
    try:
        # 1. Register a test user
        print("\n1. Registering test user...")
        user_data = tester.register_user(
            username="cafe_boss_test",
            email="boss@meowtopia.com",
            password="testpassword123"
        )
        
        if not user_data:
            print("Trying to login instead...")
            user_data = tester.login_user(
                email="boss@meowtopia.com",
                password="testpassword123"
            )
        
        if not user_data:
            print("❌ Authentication failed. Please check your server is running.")
            return
        
        # 2. Create cafe items
        print("\n2. Creating cafe items...")
        items = [
            {
                "name": "Catpuccino",
                "category": "drink",
                "description": "Delicious coffee with cat-themed latte art",
                "price": 4.50,
                "cost": 1.50,
                "stock_quantity": 25,
                "min_stock_level": 5
            },
            {
                "name": "Whisker Latte",
                "category": "drink",
                "description": "Smooth latte with vanilla and caramel",
                "price": 5.00,
                "cost": 1.75,
                "stock_quantity": 20,
                "min_stock_level": 5
            },
            {
                "name": "Cat Treats",
                "category": "cat_food",
                "description": "Premium cat treats for our feline friends",
                "price": 3.00,
                "cost": 1.00,
                "stock_quantity": 50,
                "min_stock_level": 10
            },
            {
                "name": "Cat Toy Ball",
                "category": "cat_toy",
                "description": "Interactive toy ball for cats",
                "price": 2.50,
                "cost": 0.75,
                "stock_quantity": 15,
                "min_stock_level": 5
            }
        ]
        
        created_items = []
        for item in items:
            result = tester.create_cafe_item(item)
            if result:
                created_items.append(result)
        
        # 3. Hire staff members
        print("\n3. Hiring staff members...")
        staff_members = [
            {
                "name": "Sarah Johnson",
                "role": "manager",
                "hourly_rate": 18.00,
                "email": "sarah@meowtopia.com"
            },
            {
                "name": "Mike Chen",
                "role": "barista",
                "hourly_rate": 15.00,
                "email": "mike@meowtopia.com"
            },
            {
                "name": "Emma Davis",
                "role": "cat_caregiver",
                "hourly_rate": 14.00,
                "email": "emma@meowtopia.com"
            }
        ]
        
        created_staff = []
        for staff in staff_members:
            result = tester.hire_staff_member(staff)
            if result:
                created_staff.append(result)
        
        # 4. Add customers
        print("\n4. Adding customers...")
        customers = [
            {
                "name": "Alice Smith",
                "email": "alice@example.com",
                "phone": "+1-555-123-4567"
            },
            {
                "name": "Bob Wilson",
                "email": "bob@example.com",
                "phone": "+1-555-234-5678"
            },
            {
                "name": "Carol Brown",
                "email": "carol@example.com",
                "phone": "+1-555-345-6789"
            }
        ]
        
        created_customers = []
        for customer in customers:
            result = tester.add_customer(customer)
            if result:
                created_customers.append(result)
        
        # 5. Create orders
        print("\n5. Creating orders...")
        if created_items and created_customers:
            orders = [
                {
                    "customer_id": created_customers[0]["id"],
                    "items": [
                        {
                            "item_id": created_items[0]["id"],
                            "quantity": 2,
                            "unit_price": created_items[0]["price"],
                            "total_price": created_items[0]["price"] * 2
                        }
                    ],
                    "table_number": 5,
                    "special_requests": "Extra hot, please!"
                },
                {
                    "customer_id": created_customers[1]["id"],
                    "items": [
                        {
                            "item_id": created_items[1]["id"],
                            "quantity": 1,
                            "unit_price": created_items[1]["price"],
                            "total_price": created_items[1]["price"]
                        },
                        {
                            "item_id": created_items[2]["id"],
                            "quantity": 2,
                            "unit_price": created_items[2]["price"],
                            "total_price": created_items[2]["price"] * 2
                        }
                    ],
                    "table_number": 3
                }
            ]
            
            created_orders = []
            for order in orders:
                result = tester.create_order(order)
                if result:
                    created_orders.append(result)
        
        # 6. Get analytics
        print("\n6. Getting analytics...")
        analytics = tester.get_analytics("today")
        
        # 7. Get settings
        print("\n7. Getting cafe settings...")
        settings = tester.get_settings()
        
        # 8. Display summary
        print("\n" + "=" * 50)
        print("📊 CAFE SETUP SUMMARY")
        print("=" * 50)
        print(f"✅ Items created: {len(created_items)}")
        print(f"✅ Staff hired: {len(created_staff)}")
        print(f"✅ Customers added: {len(created_customers)}")
        print(f"✅ Orders created: {len(created_orders) if 'created_orders' in locals() else 0}")
        
        if analytics:
            print(f"💰 Total revenue: ${analytics.get('total_revenue', 0):.2f}")
            print(f"📋 Total orders: {analytics.get('total_orders', 0)}")
            print(f"⭐ Customer satisfaction: {analytics.get('customer_satisfaction', 0)}/5.0")
        
        print("\n🎉 Cafe setup complete! You can now:")
        print("1. Visit http://localhost:8000/docs to explore the API")
        print("2. Use the frontend dashboard to manage your cafe")
        print("3. Test all the endpoints programmatically")
        
    except requests.exceptions.ConnectionError:
        print("❌ Connection failed. Make sure your FastAPI server is running:")
        print("   cd meowtopia/backend")
        print("   ./start_server.sh")
    except Exception as e:
        print(f"❌ Test failed with error: {e}")

if __name__ == "__main__":
    main() 