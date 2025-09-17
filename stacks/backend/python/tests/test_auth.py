#!/usr/bin/env python3
"""
Test script for the authentication system
"""
import requests
import json

API_BASE = "http://localhost:5000"

def test_login(email, password):
    """Test user login"""
    response = requests.post(f"{API_BASE}/auth/login", json={
        "email": email,
        "password": password
    })
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Login successful for {email}")
        print(f"   Token: {data['access_token'][:20]}...")
        print(f"   User: {data['user']['email']} ({data['user']['role']})")
        return data['access_token']
    else:
        print(f"❌ Login failed for {email}: {response.text}")
        return None

def test_verify_token(token):
    """Test token verification"""
    response = requests.post(f"{API_BASE}/auth/verify", json={"token": token})
    
    if response.status_code == 200:
        data = response.json()
        if data['valid']:
            print(f"✅ Token verification successful")
            print(f"   User: {data['user']['email']} ({data['user']['role']})")
            return True
        else:
            print(f"❌ Token verification failed: Invalid token")
            return False
    else:
        print(f"❌ Token verification failed: {response.text}")
        return False

def test_protected_endpoint(token):
    """Test protected endpoint"""
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{API_BASE}/auth/me", headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Protected endpoint access successful")
        print(f"   User: {data['email']} ({data['role']})")
        return True
    else:
        print(f"❌ Protected endpoint access failed: {response.text}")
        return False

def main():
    print("🧪 Testing Chain Rice Authentication System")
    print("=" * 50)
    
    # Test admin login
    print("\n1. Testing admin login...")
    admin_token = test_login("admin@test.com", "admin123")
    
    if admin_token:
        print("\n2. Testing admin token verification...")
        test_verify_token(admin_token)
        
        print("\n3. Testing admin protected endpoint...")
        test_protected_endpoint(admin_token)
    
    # Test user login
    print("\n4. Testing user login...")
    user_token = test_login("user@test.com", "user123")
    
    if user_token:
        print("\n5. Testing user token verification...")
        test_verify_token(user_token)
        
        print("\n6. Testing user protected endpoint...")
        test_protected_endpoint(user_token)
    
    # Test invalid login
    print("\n7. Testing invalid login...")
    test_login("invalid@test.com", "wrongpassword")
    
    print("\n✅ Authentication system test completed!")

if __name__ == "__main__":
    main()
