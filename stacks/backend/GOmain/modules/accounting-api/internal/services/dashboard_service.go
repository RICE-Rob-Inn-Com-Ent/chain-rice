package services

import (
	"database/sql"
	"fmt"
	"time"

	accountingv1 "chainrice/x/chainrice/types"
)

type DashboardService struct {
	db *sql.DB
}

func NewDashboardService(db *sql.DB) *DashboardService {
	return &DashboardService{db: db}
}

func (s *DashboardService) GetDashboardStats(startDate, endDate *time.Time) (*accountingv1.DashboardStats, error) {
	stats := &accountingv1.DashboardStats{}

	// Set default date range if not provided
	if startDate == nil {
		yearStart := time.Date(time.Now().Year(), 1, 1, 0, 0, 0, 0, time.UTC)
		startDate = &yearStart
	}
	if endDate == nil {
		now := time.Now()
		endDate = &now
	}

	// Get total revenue (income invoices)
	revenueQuery := `
		SELECT COALESCE(SUM(total_amount), 0) 
		FROM invoices 
		WHERE status = 'paid' AND date BETWEEN ? AND ?`

	err := s.db.QueryRow(revenueQuery, startDate, endDate).Scan(&stats.TotalRevenue)
	if err != nil {
		return nil, fmt.Errorf("failed to get total revenue: %w", err)
	}

	// Get total expenses (outgoing invoices)
	expensesQuery := `
		SELECT COALESCE(SUM(total_amount), 0) 
		FROM invoices 
		WHERE status = 'paid' AND date BETWEEN ? AND ? AND category != 'income'`

	err = s.db.QueryRow(expensesQuery, startDate, endDate).Scan(&stats.TotalExpenses)
	if err != nil {
		return nil, fmt.Errorf("failed to get total expenses: %w", err)
	}

	// Calculate net profit
	stats.NetProfit = stats.TotalRevenue - stats.TotalExpenses

	// Get invoice counts
	countsQuery := `
		SELECT 
			COUNT(*) as total_invoices,
			SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_invoices,
			SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) as overdue_invoices
		FROM invoices 
		WHERE date BETWEEN ? AND ?`

	err = s.db.QueryRow(countsQuery, startDate, endDate).Scan(
		&stats.TotalInvoices, &stats.PendingInvoices, &stats.OverdueInvoices)
	if err != nil {
		return nil, fmt.Errorf("failed to get invoice counts: %w", err)
	}

	// Get monthly data
	monthlyData, err := s.getMonthlyData(startDate, endDate)
	if err != nil {
		return nil, err
	}
	stats.MonthlyData = monthlyData

	// Get category expenses
	categoryExpenses, err := s.getCategoryExpenses(startDate, endDate)
	if err != nil {
		return nil, err
	}
	stats.CategoryExpenses = categoryExpenses

	// Calculate monthly revenue and expenses (current month)
	currentMonth := time.Date(time.Now().Year(), time.Now().Month(), 1, 0, 0, 0, 0, time.UTC)
	monthEnd := currentMonth.AddDate(0, 1, 0)

	err = s.db.QueryRow(revenueQuery, currentMonth, monthEnd).Scan(&stats.MonthlyRevenue)
	if err != nil {
		return nil, fmt.Errorf("failed to get monthly revenue: %w", err)
	}

	err = s.db.QueryRow(expensesQuery, currentMonth, monthEnd).Scan(&stats.MonthlyExpenses)
	if err != nil {
		return nil, fmt.Errorf("failed to get monthly expenses: %w", err)
	}

	return stats, nil
}

func (s *DashboardService) getMonthlyData(startDate, endDate *time.Time) ([]*accountingv1.MonthlyData, error) {
	query := `
		SELECT 
			strftime('%Y-%m', date) as month,
			COALESCE(SUM(CASE WHEN category = 'income' THEN total_amount ELSE 0 END), 0) as revenue,
			COALESCE(SUM(CASE WHEN category != 'income' THEN total_amount ELSE 0 END), 0) as expenses
		FROM invoices 
		WHERE status = 'paid' AND date BETWEEN ? AND ?
		GROUP BY strftime('%Y-%m', date)
		ORDER BY month`

	rows, err := s.db.Query(query, startDate, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var monthlyData []*accountingv1.MonthlyData
	for rows.Next() {
		var data accountingv1.MonthlyData
		err := rows.Scan(&data.Month, &data.Revenue, &data.Expenses)
		if err != nil {
			return nil, err
		}
		data.Profit = data.Revenue - data.Expenses
		monthlyData = append(monthlyData, &data)
	}

	return monthlyData, nil
}

func (s *DashboardService) getCategoryExpenses(startDate, endDate *time.Time) ([]*accountingv1.CategoryExpense, error) {
	query := `
		SELECT 
			COALESCE(category, 'Без категорії') as category,
			SUM(total_amount) as amount
		FROM invoices 
		WHERE status = 'paid' AND date BETWEEN ? AND ? AND category != 'income'
		GROUP BY category
		ORDER BY amount DESC`

	rows, err := s.db.Query(query, startDate, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var categoryExpenses []*accountingv1.CategoryExpense
	var totalAmount float64

	// First pass: collect data and calculate total
	for rows.Next() {
		var expense accountingv1.CategoryExpense
		err := rows.Scan(&expense.Category, &expense.Amount)
		if err != nil {
			return nil, err
		}
		totalAmount += expense.Amount
		categoryExpenses = append(categoryExpenses, &expense)
	}

	// Second pass: calculate percentages
	for _, expense := range categoryExpenses {
		if totalAmount > 0 {
			expense.Percentage = (expense.Amount / totalAmount) * 100
		}
	}

	return categoryExpenses, nil
}
