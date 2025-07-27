from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
from datetime import datetime, timedelta
from .models import (
    Transaction, CreateTransaction, FinancialReport, 
    CategoryStats, Invoice, CreateInvoice, PaymentReminder,
    TransactionType, PaymentMethod
)

router = APIRouter(tags=["Financial Management"])

@router.get("/transactions", response_model=List[Transaction])
async def get_transactions(
    start_date: Optional[datetime] = Query(None, description="Start date for filtering"),
    end_date: Optional[datetime] = Query(None, description="End date for filtering"),
    transaction_type: Optional[TransactionType] = Query(None, description="Filter by transaction type"),
    limit: int = Query(50, ge=1, le=100, description="Number of transactions to return")
):
    """Get financial transactions with filtering options"""
    # Mock data
    transactions = [
        Transaction(
            id=1,
            amount=150.00,
            description="Cat grooming service",
            transaction_type=TransactionType.INCOME,
            payment_method=PaymentMethod.CARD,
            category="Services",
            date=datetime.now(),
            customer_name="John Doe"
        ),
        Transaction(
            id=2,
            amount=89.99,
            description="Cat food supplies",
            transaction_type=TransactionType.EXPENSE,
            payment_method=PaymentMethod.CASH,
            category="Supplies",
            date=datetime.now() - timedelta(days=1)
        )
    ]
    return transactions

@router.post("/transactions", response_model=Transaction, status_code=status.HTTP_201_CREATED)
async def create_transaction(transaction: CreateTransaction):
    """Record a new financial transaction"""
    return Transaction(
        id=999,
        date=datetime.now(),
        created_at=datetime.now(),
        **transaction.dict()
    )

@router.get("/transactions/{transaction_id}", response_model=Transaction)
async def get_transaction(transaction_id: int):
    """Get specific transaction details"""
    return Transaction(
        id=transaction_id,
        amount=100.00,
        description="Sample transaction",
        transaction_type=TransactionType.INCOME,
        payment_method=PaymentMethod.CARD,
        category="Services",
        date=datetime.now()
    )

@router.delete("/transactions/{transaction_id}")
async def delete_transaction(transaction_id: int):
    """Delete a transaction record"""
    return {"message": f"Transaction {transaction_id} deleted successfully"}

@router.get("/reports/financial", response_model=FinancialReport)
async def get_financial_report(
    start_date: datetime = Query(..., description="Report start date"),
    end_date: datetime = Query(..., description="Report end date")
):
    """Generate financial report for specified period"""
    return FinancialReport(
        period_start=start_date,
        period_end=end_date,
        total_income=5250.00,
        total_expenses=2180.50,
        net_profit=3069.50,
        transaction_count=45
    )

@router.get("/reports/categories", response_model=List[CategoryStats])
async def get_category_statistics(
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None)
):
    """Get spending/income statistics by category"""
    return [
        CategoryStats(
            category="Services",
            total_amount=3200.00,
            transaction_count=28,
            percentage=61.0
        ),
        CategoryStats(
            category="Supplies",
            total_amount=1250.00,
            transaction_count=12,
            percentage=23.8
        ),
        CategoryStats(
            category="Equipment",
            total_amount=800.00,
            transaction_count=5,
            percentage=15.2
        )
    ]

@router.get("/invoices", response_model=List[Invoice])
async def get_invoices(
    status: Optional[str] = Query(None, description="Filter by invoice status"),
    customer: Optional[str] = Query(None, description="Filter by customer name")
):
    """Get all invoices with optional filtering"""
    return [
        Invoice(
            id=1,
            invoice_number="INV-2025-001",
            customer_name="Cat Lovers Inc.",
            customer_email="billing@catlovers.com",
            amount=500.00,
            tax_amount=115.00,
            total_amount=615.00,
            issue_date=datetime.now(),
            due_date=datetime.now() + timedelta(days=30),
            status="sent",
            items=[
                {"description": "Cat grooming service", "quantity": 5, "price": 100.00}
            ]
        )
    ]

@router.post("/invoices", response_model=Invoice, status_code=status.HTTP_201_CREATED)
async def create_invoice(invoice: CreateInvoice):
    """Create a new invoice"""
    tax_amount = invoice.amount * (invoice.tax_rate if hasattr(invoice, 'tax_rate') else 0.23)
    total_amount = invoice.amount + tax_amount
    
    return Invoice(
        id=999,
        invoice_number=f"INV-{datetime.now().year}-{datetime.now().month:02d}-999",
        total_amount=total_amount,
        tax_amount=tax_amount,
        issue_date=datetime.now(),
        due_date=datetime.now() + timedelta(days=invoice.due_days if hasattr(invoice, 'due_days') else 30),
        status="draft",
        **invoice.dict()
    )

@router.get("/invoices/{invoice_id}", response_model=Invoice)
async def get_invoice(invoice_id: int):
    """Get specific invoice details"""
    return Invoice(
        id=invoice_id,
        invoice_number=f"INV-2025-{invoice_id:03d}",
        customer_name="Sample Customer",
        amount=300.00,
        tax_amount=69.00,
        total_amount=369.00,
        issue_date=datetime.now(),
        due_date=datetime.now() + timedelta(days=30),
        status="sent",
        items=[]
    )

@router.put("/invoices/{invoice_id}/status")
async def update_invoice_status(invoice_id: int, status: str):
    """Update invoice status (draft, sent, paid, overdue)"""
    valid_statuses = ["draft", "sent", "paid", "overdue", "cancelled"]
    if status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")
    
    return {"message": f"Invoice {invoice_id} status updated to {status}"}

@router.get("/payment-reminders", response_model=List[PaymentReminder])
async def get_payment_reminders():
    """Get list of overdue invoices requiring payment reminders"""
    return [
        PaymentReminder(
            invoice_id=1,
            customer_name="Late Payer Corp",
            amount=1250.00,
            days_overdue=15,
            last_reminder_sent=datetime.now() - timedelta(days=7)
        )
    ]

@router.post("/payment-reminders/{invoice_id}/send")
async def send_payment_reminder(invoice_id: int):
    """Send payment reminder for overdue invoice"""
    return {"message": f"Payment reminder sent for invoice {invoice_id}"}

@router.get("/dashboard/summary")
async def get_dashboard_summary():
    """Get financial dashboard summary"""
    return {
        "today_income": 450.00,
        "today_expenses": 125.00,
        "monthly_income": 12500.00,
        "monthly_expenses": 4750.00,
        "pending_invoices": 8,
        "overdue_invoices": 2,
        "total_customers": 45,
        "average_transaction": 95.50
    }
