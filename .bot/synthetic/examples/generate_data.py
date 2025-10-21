#!/usr/bin/env python3
"""
Synthetic Data Generation Examples
"""

import random
from datetime import datetime, timedelta

import numpy as np
import pandas as pd
from faker import Faker

fake = Faker()


def generate_ecommerce_data(n_customers=1000, n_products=100, n_orders=5000):
    """Generate realistic e-commerce dataset"""

    # Generate customers
    customers = []
    for i in range(n_customers):
        customers.append(
            {
                "customer_id": i + 1,
                "name": fake.name(),
                "email": fake.email(),
                "phone": fake.phone_number(),
                "address": fake.address(),
                "city": fake.city(),
                "country": fake.country(),
                "registration_date": fake.date_between(start_date="-2y", end_date="today"),
                "loyalty_points": random.randint(0, 10000),
            }
        )

    # Generate products
    categories = ["Electronics", "Clothing", "Books", "Home", "Sports", "Toys"]
    products = []
    for i in range(n_products):
        category = random.choice(categories)
        products.append(
            {
                "product_id": i + 1,
                "name": fake.catch_phrase(),
                "category": category,
                "price": round(random.uniform(10, 1000), 2),
                "cost": round(random.uniform(5, 500), 2),
                "stock": random.randint(0, 1000),
                "rating": round(random.uniform(1, 5), 1),
                "num_reviews": random.randint(0, 1000),
            }
        )

    # Generate orders
    orders = []
    for i in range(n_orders):
        customer = random.choice(customers)
        product = random.choice(products)
        quantity = random.randint(1, 5)

        orders.append(
            {
                "order_id": i + 1,
                "customer_id": customer["customer_id"],
                "product_id": product["product_id"],
                "quantity": quantity,
                "unit_price": product["price"],
                "total_price": product["price"] * quantity,
                "order_date": fake.date_time_between(start_date="-1y", end_date="now"),
                "status": random.choice(["pending", "shipped", "delivered", "cancelled"]),
                "payment_method": random.choice(["credit_card", "paypal", "bank_transfer"]),
            }
        )

    return {"customers": pd.DataFrame(customers), "products": pd.DataFrame(products), "orders": pd.DataFrame(orders)}


def generate_time_series(start_date="2020-01-01", periods=365, freq="D"):
    """Generate synthetic time series data"""

    dates = pd.date_range(start=start_date, periods=periods, freq=freq)

    # Base trend
    trend = np.linspace(100, 200, periods)

    # Seasonal component
    seasonal = 20 * np.sin(2 * np.pi * np.arange(periods) / 7)  # Weekly pattern

    # Random noise
    noise = np.random.normal(0, 5, periods)

    # Combine
    values = trend + seasonal + noise

    df = pd.DataFrame(
        {
            "date": dates,
            "value": values,
            "ma_7": pd.Series(values).rolling(7).mean(),
            "ma_30": pd.Series(values).rolling(30).mean(),
        }
    )

    return df


def generate_sensor_data(n_sensors=10, n_readings=1000):
    """Generate IoT sensor data"""

    data = []
    for sensor_id in range(1, n_sensors + 1):
        base_temp = random.uniform(15, 30)
        base_humidity = random.uniform(30, 70)

        for i in range(n_readings):
            timestamp = datetime.now() - timedelta(minutes=n_readings - i)

            data.append(
                {
                    "sensor_id": f"SENSOR_{sensor_id:03d}",
                    "timestamp": timestamp,
                    "temperature": base_temp + random.gauss(0, 2),
                    "humidity": base_humidity + random.gauss(0, 5),
                    "pressure": 1013 + random.gauss(0, 10),
                    "battery_level": max(0, 100 - (i / 10) + random.gauss(0, 2)),
                    "status": random.choice(["active", "active", "active", "warning", "error"]),
                }
            )

    return pd.DataFrame(data)


def generate_user_behavior(n_users=500, n_events=10000):
    """Generate user behavior/clickstream data"""

    pages = ["/", "/products", "/cart", "/checkout", "/profile", "/search"]
    devices = ["desktop", "mobile", "tablet"]
    browsers = ["chrome", "firefox", "safari", "edge"]

    events = []
    for _ in range(n_events):
        user_id = random.randint(1, n_users)
        session_id = fake.uuid4()

        events.append(
            {
                "event_id": fake.uuid4(),
                "user_id": user_id,
                "session_id": session_id,
                "timestamp": fake.date_time_between(start_date="-30d", end_date="now"),
                "page": random.choice(pages),
                "action": random.choice(["view", "click", "scroll", "submit"]),
                "device": random.choice(devices),
                "browser": random.choice(browsers),
                "ip_address": fake.ipv4(),
                "duration_seconds": random.randint(1, 300),
            }
        )

    return pd.DataFrame(events)


def generate_financial_transactions(n_accounts=100, n_transactions=5000):
    """Generate financial transaction data"""

    accounts = []
    for i in range(n_accounts):
        accounts.append(
            {
                "account_id": f"ACC_{i:06d}",
                "account_type": random.choice(["checking", "savings", "credit"]),
                "balance": round(random.uniform(100, 50000), 2),
                "currency": random.choice(["USD", "EUR", "GBP"]),
            }
        )

    transactions = []
    for i in range(n_transactions):
        account = random.choice(accounts)

        transactions.append(
            {
                "transaction_id": f"TXN_{i:08d}",
                "account_id": account["account_id"],
                "timestamp": fake.date_time_between(start_date="-1y", end_date="now"),
                "amount": round(random.uniform(-1000, 1000), 2),
                "type": random.choice(["debit", "credit", "transfer"]),
                "category": random.choice(["food", "transport", "entertainment", "bills", "salary"]),
                "merchant": fake.company(),
                "location": fake.city(),
            }
        )

    return {"accounts": pd.DataFrame(accounts), "transactions": pd.DataFrame(transactions)}


if __name__ == "__main__":
    print("Generating synthetic datasets...")

    # E-commerce data
    ecommerce = generate_ecommerce_data()
    ecommerce["customers"].to_csv("synthetic_customers.csv", index=False)
    ecommerce["products"].to_csv("synthetic_products.csv", index=False)
    ecommerce["orders"].to_csv("synthetic_orders.csv", index=False)
    print(f"✓ E-commerce: {len(ecommerce['customers'])} customers, {len(ecommerce['orders'])} orders")

    # Time series
    ts = generate_time_series(periods=365 * 2)
    ts.to_csv("synthetic_timeseries.csv", index=False)
    print(f"✓ Time series: {len(ts)} data points")

    # Sensor data
    sensors = generate_sensor_data(n_sensors=20, n_readings=1000)
    sensors.to_csv("synthetic_sensors.csv", index=False)
    print(f"✓ Sensor data: {len(sensors)} readings")

    # User behavior
    behavior = generate_user_behavior(n_users=1000, n_events=20000)
    behavior.to_csv("synthetic_user_behavior.csv", index=False)
    print(f"✓ User behavior: {len(behavior)} events")

    # Financial
    financial = generate_financial_transactions(n_accounts=200, n_transactions=10000)
    financial["accounts"].to_csv("synthetic_accounts.csv", index=False)
    financial["transactions"].to_csv("synthetic_transactions.csv", index=False)
    print(f"✓ Financial: {len(financial['transactions'])} transactions")

    print("\n✅ All synthetic datasets generated successfully!")
