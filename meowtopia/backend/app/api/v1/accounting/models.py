from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum

class TransactionType(str, Enum):
    """Transaction Types"""
    INCOME = "income"
    EXPENSE = "expense"
    TRANSFER = "transfer"

class PaymentMethod(str, Enum):
    """Payment Methods"""
    CASH = "cash"
    CARD = "card"
    BANK_TRANSFER = "bank_transfer"
    CRYPTOCURRENCY = "cryptocurrency"

class Transaction(BaseModel):
    """Financial Transaction Model"""
    id: Optional[int] = None
    amount: float
    description: str
    transaction_type: TransactionType
    payment_method: PaymentMethod
    category: str
    date: datetime
    customer_name: Optional[str] = None
    invoice_number: Optional[str] = None
    created_at: Optional[datetime] = None

class CreateTransaction(BaseModel):
    """Create Transaction Request"""
    amount: float
    description: str
    transaction_type: TransactionType
    payment_method: PaymentMethod
    category: str
    customer_name: Optional[str] = None
    invoice_number: Optional[str] = None

class FinancialReport(BaseModel):
    """Financial Report"""
    period_start: datetime
    period_end: datetime
    total_income: float
    total_expenses: float
    net_profit: float
    transaction_count: int

class CategoryStats(BaseModel):
    """Category Statistics"""
    category: str
    total_amount: float
    transaction_count: int
    percentage: float

class Invoice(BaseModel):
    """Invoice Model"""
    id: Optional[int] = None
    invoice_number: str
    customer_name: str
    customer_email: Optional[str] = None
    amount: float
    tax_amount: float
    total_amount: float
    issue_date: datetime
    due_date: datetime
    status: str  # draft, sent, paid, overdue
    items: List[dict]

class CreateInvoice(BaseModel):
    """Create Invoice Request"""
    customer_name: str
    customer_email: Optional[str] = None
    amount: float
    tax_rate: float = 0.23  # Default VAT rate
    due_days: int = 30
    items: List[dict]

class PaymentReminder(BaseModel):
    """Payment Reminder"""
    invoice_id: int
    customer_name: str
    amount: float
    days_overdue: int
    last_reminder_sent: Optional[datetime] = None
