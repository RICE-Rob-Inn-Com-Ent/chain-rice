package services

import (
	"database/sql"
	"time"
)

type ValidatorService struct {
	db *sql.DB
}

func NewValidatorService(db *sql.DB) *ValidatorService {
	return &ValidatorService{db: db}
}

type Validator struct {
	ID              string    `json:"id"`
	Name            string    `json:"name"`
	Bonded          string    `json:"bonded"`
	StakeAmount     int64     `json:"stake_amount"`
	TokenBalance    int64     `json:"token_balance"`
	Status          string    `json:"status"`
	CommissionRate  float64   `json:"commission_rate"`
	Uptime          float64   `json:"uptime"`
	VotingPower     float64   `json:"voting_power"`
	BitcoinAddress  string    `json:"bitcoin_address"`
	BitcoinBalance  float64   `json:"bitcoin_balance"`
	BitcoinUSDValue float64   `json:"bitcoin_usd_value"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
	LastActivity    time.Time `json:"last_activity"`
}

type ValidatorStats struct {
	TotalValidators      int32   `json:"total_validators"`
	ActiveValidators     int32   `json:"active_validators"`
	TotalStake           int64   `json:"total_stake"`
	TotalTokens          int64   `json:"total_tokens"`
	NetworkUptime        float64 `json:"network_uptime"`
	TotalBitcoinBalance  float64 `json:"total_bitcoin_balance"`
	TotalBitcoinUSDValue float64 `json:"total_bitcoin_usd_value"`
}

type BitcoinBalance struct {
	Address          string    `json:"address"`
	ValidatorName    string    `json:"validator_name"`
	BalanceBTC       float64   `json:"balance_btc"`
	BalanceSatoshis  int64     `json:"balance_satoshis"`
	USDValue         float64   `json:"usd_value"`
	Confirmations    int32     `json:"confirmations"`
	TransactionCount int32     `json:"transaction_count"`
	UpdatedAt        time.Time `json:"updated_at"`
}

func (s *ValidatorService) GetAllValidators() ([]Validator, error) {
	rows, err := s.db.Query(`
		SELECT id, name, bonded, stake_amount, token_balance, status, commission_rate, 
			uptime, voting_power, bitcoin_address, bitcoin_balance, bitcoin_usd_value, 
			created_at, updated_at, last_activity
		FROM validators
		ORDER BY stake_amount DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var validators []Validator
	for rows.Next() {
		var validator Validator
		err := rows.Scan(
			&validator.ID, &validator.Name, &validator.Bonded, &validator.StakeAmount, &validator.TokenBalance,
			&validator.Status, &validator.CommissionRate, &validator.Uptime, &validator.VotingPower,
			&validator.BitcoinAddress, &validator.BitcoinBalance, &validator.BitcoinUSDValue,
			&validator.CreatedAt, &validator.UpdatedAt, &validator.LastActivity,
		)
		if err != nil {
			return nil, err
		}
		validators = append(validators, validator)
	}

	return validators, nil
}

func (s *ValidatorService) GetValidatorByID(id string) (*Validator, error) {
	var validator Validator
	err := s.db.QueryRow(`
		SELECT id, name, bonded, stake_amount, token_balance, status, commission_rate, 
			uptime, voting_power, bitcoin_address, bitcoin_balance, bitcoin_usd_value, 
			created_at, updated_at, last_activity
		FROM validators WHERE id = ?
	`, id).Scan(
		&validator.ID, &validator.Name, &validator.Bonded, &validator.StakeAmount, &validator.TokenBalance,
		&validator.Status, &validator.CommissionRate, &validator.Uptime, &validator.VotingPower,
		&validator.BitcoinAddress, &validator.BitcoinBalance, &validator.BitcoinUSDValue,
		&validator.CreatedAt, &validator.UpdatedAt, &validator.LastActivity,
	)

	if err != nil {
		return nil, err
	}

	return &validator, nil
}

func (s *ValidatorService) GetValidatorStats() (*ValidatorStats, error) {
	stats := &ValidatorStats{}

	// Get total validators
	err := s.db.QueryRow("SELECT COUNT(*) FROM validators").Scan(&stats.TotalValidators)
	if err != nil {
		return nil, err
	}

	// Get active validators
	err = s.db.QueryRow("SELECT COUNT(*) FROM validators WHERE status = 'active'").Scan(&stats.ActiveValidators)
	if err != nil {
		return nil, err
	}

	// Get total stake
	err = s.db.QueryRow("SELECT COALESCE(SUM(stake_amount), 0) FROM validators").Scan(&stats.TotalStake)
	if err != nil {
		return nil, err
	}

	// Get total tokens
	err = s.db.QueryRow("SELECT COALESCE(SUM(token_balance), 0) FROM validators").Scan(&stats.TotalTokens)
	if err != nil {
		return nil, err
	}

	// Get average uptime
	err = s.db.QueryRow("SELECT COALESCE(AVG(uptime), 0) FROM validators WHERE status = 'active'").Scan(&stats.NetworkUptime)
	if err != nil {
		return nil, err
	}

	// Get total bitcoin balance
	err = s.db.QueryRow("SELECT COALESCE(SUM(bitcoin_balance), 0) FROM validators").Scan(&stats.TotalBitcoinBalance)
	if err != nil {
		return nil, err
	}

	// Get total bitcoin USD value
	err = s.db.QueryRow("SELECT COALESCE(SUM(bitcoin_usd_value), 0) FROM validators").Scan(&stats.TotalBitcoinUSDValue)
	if err != nil {
		return nil, err
	}

	return stats, nil
}

func (s *ValidatorService) GetBitcoinBalances() ([]BitcoinBalance, error) {
	rows, err := s.db.Query(`
		SELECT v.bitcoin_address, v.name, bb.balance_btc, bb.balance_satoshis, 
			bb.usd_value, bb.confirmations, bb.transaction_count, bb.updated_at
		FROM validators v
		LEFT JOIN bitcoin_balances bb ON v.bitcoin_address = bb.address
		WHERE v.bitcoin_address IS NOT NULL
		ORDER BY bb.balance_btc DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var balances []BitcoinBalance
	for rows.Next() {
		var balance BitcoinBalance
		err := rows.Scan(
			&balance.Address, &balance.ValidatorName, &balance.BalanceBTC, &balance.BalanceSatoshis,
			&balance.USDValue, &balance.Confirmations, &balance.TransactionCount, &balance.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		balances = append(balances, balance)
	}

	return balances, nil
}

func (s *ValidatorService) UpdateValidatorPerformance(validatorID string, uptime, votingPower, commissionRate float64, stakeAmount, tokenBalance int64, bitcoinBalance float64) error {
	_, err := s.db.Exec(`
		UPDATE validators SET 
			uptime = ?, voting_power = ?, commission_rate = ?, stake_amount = ?, 
			token_balance = ?, bitcoin_balance = ?, updated_at = ?, last_activity = ?
		WHERE id = ?
	`, uptime, votingPower, commissionRate, stakeAmount, tokenBalance, bitcoinBalance, time.Now(), time.Now(), validatorID)
	return err
}

func (s *ValidatorService) UpdateBitcoinBalance(address string, balanceBTC float64, balanceSatoshis int64, usdValue float64, confirmations int32) error {
	_, err := s.db.Exec(`
		INSERT OR REPLACE INTO bitcoin_balances 
		(address, balance_btc, balance_satoshis, usd_value, confirmations, updated_at)
		VALUES (?, ?, ?, ?, ?, ?)
	`, address, balanceBTC, balanceSatoshis, usdValue, confirmations, time.Now())
	return err
}