#!/usr/bin/env python3
"""
Script to generate password hashes for test users
"""
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Generate hashes for test passwords
admin_password = "admin123"
user_password = "user123"

admin_hash = pwd_context.hash(admin_password)
user_hash = pwd_context.hash(user_password)

print("Password hashes for test users:")
print(f"admin@test.com: {admin_hash}")
print(f"user@test.com: {user_hash}")
print()
print("Copy these hashes to jwt_auth.py TEST_USERS dictionary")
