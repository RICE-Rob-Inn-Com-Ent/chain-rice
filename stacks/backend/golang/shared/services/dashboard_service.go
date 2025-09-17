package services

import (
	"database/sql"
	"time"
)

type DashboardService struct {
	db *sql.DB
}

func NewDashboardService(db *sql.DB) *DashboardService {
	return &DashboardService{db: db}
}

type DashboardStats struct {
	TotalRevenue     float64            `json:"total_revenue"`
	TotalExpenses    float64            `json:"total_expenses"`
	NetProfit        float64            `json:"net_profit"`
	TotalInvoices    int32              `json:"total_invoices"`
	PendingInvoices  int32              `json:"pending_invoices"`
	OverdueInvoices  int32              `json:"overdue_invoices"`
	MonthlyRevenue   float64            `json:"monthly_revenue"`
	MonthlyExpenses  float64            `json:"monthly_expenses"`
	MonthlyData      []MonthlyData      `json:"monthly_data"`
	CategoryExpenses []CategoryExpense  `json:"category_expenses"`
}

type MonthlyData struct {
	Month    string  `json:"month"`
	Revenue  float64 `json:"revenue"`
	Expenses float64 `json:"expenses"`
	Profit   float64 `json:"profit"`
}

type CategoryExpense struct {
	Category   string  `json:"category"`
	Amount     float64 `json:"amount"`
	Percentage float64 `json:"percentage"`
}

func (s *DashboardService) GetDashboardStats(startDate, endDate *time.Time) (*DashboardStats, error) {
	stats := &DashboardStats{}

	// Get total revenue
	err := s.db.QueryRow("SELECT COALESCE(SUM(total_amount), 0) FROM invoices WHERE status = 'paid'").Scan(&stats.TotalRevenue)
	if err != nil {
		return nil, err
	}

	// Get total expenses
	err = s.db.QueryRow("SELECT COALESCE(SUM(total_amount), 0) FROM invoices WHERE status = 'paid' AND total_amount < 0").Scan(&stats.TotalExpenses)
	if err != nil {
		return nil, err
	}

	// Calculate net profit
	stats.NetProfit = stats.TotalRevenue - stats.TotalExpenses

	// Get invoice counts
	err = s.db.QueryRow("SELECT COUNT(*) FROM invoices").Scan(&stats.TotalInvoices)
	if err != nil {
		return nil, err
	}

	err = s.db.QueryRow("SELECT COUNT(*) FROM invoices WHERE status = 'pending'").Scan(&stats.PendingInvoices)
	if err != nil {
		return nil, err
	}

	err = s.db.QueryRow("SELECT COUNT(*) FROM invoices WHERE status = 'overdue'").Scan(&stats.OverdueInvoices)
	if err != nil {
		return nil, err
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

	return stats, nil
}

func (s *DashboardService) getMonthlyData(startDate, endDate *time.Time) ([]MonthlyData, error) {
	query := `
		SELECT 
			strftime('%Y-%m', date) as month,
			COALESCE(SUM(CASE WHEN total_amount > 0 THEN total_amount ELSE 0 END), 0) as revenue,
			COALESCE(SUM(CASE WHEN total_amount < 0 THEN ABS(total_amount) ELSE 0 END), 0) as expenses
		FROM invoices 
		WHERE status = 'paid'
	`

	args := []interface{}{}
	if startDate != nil {
		query += " AND date >= ?"
		args = append(args, *startDate)
	}
	if endDate != nil {
		query += " AND date <= ?"
		args = append(args, *endDate)
	}

	query += " GROUP BY strftime('%Y-%m', date) ORDER BY month"

	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var monthlyData []MonthlyData
	for rows.Next() {
		var data MonthlyData
		err := rows.Scan(&data.Month, &data.Revenue, &data.Expenses)
		if err != nil {
			return nil, err
		}
		data.Profit = data.Revenue - data.Expenses
		monthlyData = append(monthlyData, data)
	}

	return monthlyData, nil
}

func (s *DashboardService) getCategoryExpenses(startDate, endDate *time.Time) ([]CategoryExpense, error) {
	query := `
		SELECT 
			category,
			COALESCE(SUM(ABS(total_amount)), 0) as amount
		FROM invoices 
		WHERE status = 'paid' AND total_amount < 0 AND category IS NOT NULL
	`

	args := []interface{}{}
	if startDate != nil {
		query += " AND date >= ?"
		args = append(args, *startDate)
	}
	if endDate != nil {
		query += " AND date <= ?"
		args = append(args, *endDate)
	}

	query += " GROUP BY category ORDER BY amount DESC"

	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var categoryExpenses []CategoryExpense
	totalAmount := 0.0

	// First pass: collect data and calculate total
	for rows.Next() {
		var expense CategoryExpense
		err := rows.Scan(&expense.Category, &expense.Amount)
		if err != nil {
			return nil, err
		}
		totalAmount += expense.Amount
		categoryExpenses = append(categoryExpenses, expense)
	}

	// Second pass: calculate percentages
	for i := range categoryExpenses {
		if totalAmount > 0 {
			categoryExpenses[i].Percentage = (categoryExpenses[i].Amount / totalAmount) * 100
		}
	}

	return categoryExpenses, nil
}