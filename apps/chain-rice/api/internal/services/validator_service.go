package services

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"time"

	"chainrice/x/chainrice/types"
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

func (s *ValidatorService) GetAllValidators(ctx context.Context) ([]Validator, error) {
	query := `
		SELECT 
			v.validator_id,
			v.name,
			v.bonded,
			v.stake_amount,
			v.token_balance,
			v.status,
			v.commission_rate,
			v.uptime,
			v.voting_power,
			v.bitcoin_address,
			v.bitcoin_balance,
			COALESCE(ba.usd_value, 0) as bitcoin_usd_value,
			v.created_at,
			v.updated_at,
			v.last_activity
		FROM validators v
		LEFT JOIN bitcoin_addresses ba ON v.validator_id = ba.validator_id AND ba.is_active = TRUE
		ORDER BY v.stake_amount DESC
	`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query validators: %w", err)
	}
	defer rows.Close()

	var validators []Validator
	for rows.Next() {
		var v Validator
		err := rows.Scan(
			&v.ID,
			&v.Name,
			&v.Bonded,
			&v.StakeAmount,
			&v.TokenBalance,
			&v.Status,
			&v.CommissionRate,
			&v.Uptime,
			&v.VotingPower,
			&v.BitcoinAddress,
			&v.BitcoinBalance,
			&v.BitcoinUSDValue,
			&v.CreatedAt,
			&v.UpdatedAt,
			&v.LastActivity,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan validator: %w", err)
		}
		validators = append(validators, v)
	}

	return validators, nil
}

func (s *ValidatorService) GetValidatorByID(ctx context.Context, id string) (*Validator, error) {
	query := `
		SELECT 
			v.validator_id,
			v.name,
			v.bonded,
			v.stake_amount,
			v.token_balance,
			v.status,
			v.commission_rate,
			v.uptime,
			v.voting_power,
			v.bitcoin_address,
			v.bitcoin_balance,
			COALESCE(ba.usd_value, 0) as bitcoin_usd_value,
			v.created_at,
			v.updated_at,
			v.last_activity
		FROM validators v
		LEFT JOIN bitcoin_addresses ba ON v.validator_id = ba.validator_id AND ba.is_active = TRUE
		WHERE v.validator_id = $1
	`

	var v Validator
	err := s.db.QueryRowContext(ctx, query, id).Scan(
		&v.ID,
		&v.Name,
		&v.Bonded,
		&v.StakeAmount,
		&v.TokenBalance,
		&v.Status,
		&v.CommissionRate,
		&v.Uptime,
		&v.VotingPower,
		&v.BitcoinAddress,
		&v.BitcoinBalance,
		&v.BitcoinUSDValue,
		&v.CreatedAt,
		&v.UpdatedAt,
		&v.LastActivity,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("validator not found")
		}
		return nil, fmt.Errorf("failed to query validator: %w", err)
	}

	return &v, nil
}

func (s *ValidatorService) GetValidatorStats(ctx context.Context) (*ValidatorStats, error) {
	query := `
		SELECT 
			COUNT(*) as total_validators,
			COUNT(CASE WHEN status = 'active' THEN 1 END) as active_validators,
			SUM(stake_amount) as total_stake,
			SUM(token_balance) as total_tokens,
			AVG(uptime) as avg_uptime,
			SUM(bitcoin_balance) as total_bitcoin_balance,
			SUM(COALESCE(ba.usd_value, 0)) as total_bitcoin_usd_value
		FROM validators v
		LEFT JOIN bitcoin_addresses ba ON v.validator_id = ba.validator_id AND ba.is_active = TRUE
	`

	var stats ValidatorStats
	err := s.db.QueryRowContext(ctx, query).Scan(
		&stats.TotalValidators,
		&stats.ActiveValidators,
		&stats.TotalStake,
		&stats.TotalTokens,
		&stats.NetworkUptime,
		&stats.TotalBitcoinBalance,
		&stats.TotalBitcoinUSDValue,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to query validator stats: %w", err)
	}

	return &stats, nil
}

func (s *ValidatorService) GetBitcoinBalances(ctx context.Context) ([]BitcoinBalance, error) {
	query := `
		SELECT 
			ba.address,
			v.name as validator_name,
			ba.balance_btc,
			ba.balance_satoshis,
			ba.usd_value,
			ba.confirmations,
			ba.transaction_count,
			ba.updated_at
		FROM bitcoin_addresses ba
		LEFT JOIN validators v ON ba.validator_id = v.validator_id
		WHERE ba.is_active = TRUE
		ORDER BY ba.usd_value DESC
	`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query bitcoin balances: %w", err)
	}
	defer rows.Close()

	var balances []BitcoinBalance
	for rows.Next() {
		var b BitcoinBalance
		err := rows.Scan(
			&b.Address,
			&b.ValidatorName,
			&b.BalanceBTC,
			&b.BalanceSatoshis,
			&b.USDValue,
			&b.Confirmations,
			&b.TransactionCount,
			&b.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan bitcoin balance: %w", err)
		}
		balances = append(balances, b)
	}

	return balances, nil
}

func (s *ValidatorService) UpdateValidatorPerformance(ctx context.Context, validatorID string, uptime, votingPower, commissionRate float64, stakeAmount, tokenBalance int64, bitcoinBalance float64) error {
	// Update validator record
	updateQuery := `
		UPDATE validators 
		SET 
			uptime = $2,
			voting_power = $3,
			commission_rate = $4,
			stake_amount = $5,
			token_balance = $6,
			bitcoin_balance = $7,
			updated_at = CURRENT_TIMESTAMP,
			last_activity = CURRENT_TIMESTAMP
		WHERE validator_id = $1
	`

	_, err := s.db.ExecContext(ctx, updateQuery, validatorID, uptime, votingPower, commissionRate, stakeAmount, tokenBalance, bitcoinBalance)
	if err != nil {
		return fmt.Errorf("failed to update validator: %w", err)
	}

	// Record performance history
	historyQuery := `
		INSERT INTO validator_performance_history (
			validator_id, uptime, voting_power, commission_rate, 
			stake_amount, token_balance, bitcoin_balance
		) VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	_, err = s.db.ExecContext(ctx, historyQuery, validatorID, uptime, votingPower, commissionRate, stakeAmount, tokenBalance, bitcoinBalance)
	if err != nil {
		log.Printf("Warning: failed to record performance history: %v", err)
	}

	return nil
}

func (s *ValidatorService) UpdateBitcoinBalance(ctx context.Context, address string, balanceBTC float64, balanceSatoshis int64, usdValue float64, confirmations int32) error {
	query := `
		UPDATE bitcoin_addresses 
		SET 
			balance_btc = $2,
			balance_satoshis = $3,
			usd_value = $4,
			confirmations = $5,
			updated_at = CURRENT_TIMESTAMP
		WHERE address = $1
	`

	result, err := s.db.ExecContext(ctx, query, address, balanceBTC, balanceSatoshis, usdValue, confirmations)
	if err != nil {
		return fmt.Errorf("failed to update bitcoin balance: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("bitcoin address not found: %s", address)
	}

	return nil
}

func (s *ValidatorService) GetValidatorPerformanceHistory(ctx context.Context, validatorID string, days int) ([]map[string]interface{}, error) {
	query := `
		SELECT 
			uptime,
			voting_power,
			commission_rate,
			stake_amount,
			token_balance,
			bitcoin_balance,
			recorded_at
		FROM validator_performance_history
		WHERE validator_id = $1 
		AND recorded_at >= NOW() - INTERVAL '%d days'
		ORDER BY recorded_at DESC
	`

	rows, err := s.db.QueryContext(ctx, fmt.Sprintf(query, days), validatorID)
	if err != nil {
		return nil, fmt.Errorf("failed to query performance history: %w", err)
	}
	defer rows.Close()

	var history []map[string]interface{}
	for rows.Next() {
		var uptime, votingPower, commissionRate, bitcoinBalance float64
		var stakeAmount, tokenBalance int64
		var recordedAt time.Time

		err := rows.Scan(&uptime, &votingPower, &commissionRate, &stakeAmount, &tokenBalance, &bitcoinBalance, &recordedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan performance history: %w", err)
		}

		history = append(history, map[string]interface{}{
			"uptime":          uptime,
			"voting_power":    votingPower,
			"commission_rate": commissionRate,
			"stake_amount":    stakeAmount,
			"token_balance":   tokenBalance,
			"bitcoin_balance": bitcoinBalance,
			"recorded_at":     recordedAt,
		})
	}

	return history, nil
}

func (s *ValidatorService) RecordNetworkStatistics(ctx context.Context) error {
	query := `SELECT update_validator_stats()`

	_, err := s.db.ExecContext(ctx, query)
	if err != nil {
		return fmt.Errorf("failed to record network statistics: %w", err)
	}

	return nil
}

// Convert to protobuf types for API responses
func (s *ValidatorService) ToProtoValidators(validators []Validator) []*types.Validator {
	var protoValidators []*types.Validator

	for _, v := range validators {
		protoValidator := &types.Validator{
			Name:           v.Name,
			Bonded:         v.Bonded,
			StakeAmount:    v.StakeAmount,
			TokenBalance:   v.TokenBalance,
			CommissionRate: v.CommissionRate,
			Uptime:         v.Uptime,
			VotingPower:    v.VotingPower,
			BitcoinBalance: v.BitcoinBalance,
			BitcoinAddress: v.BitcoinAddress,
		}

		// Set status enum
		switch v.Status {
		case "active":
			protoValidator.Status = types.ValidatorStatus_VALIDATOR_STATUS_ACTIVE
		case "inactive":
			protoValidator.Status = types.ValidatorStatus_VALIDATOR_STATUS_INACTIVE
		case "jailed":
			protoValidator.Status = types.ValidatorStatus_VALIDATOR_STATUS_JAILED
		case "tombstoned":
			protoValidator.Status = types.ValidatorStatus_VALIDATOR_STATUS_TOMBSTONED
		default:
			protoValidator.Status = types.ValidatorStatus_VALIDATOR_STATUS_UNSPECIFIED
		}

		protoValidators = append(protoValidators, protoValidator)
	}

	return protoValidators
}

func (s *ValidatorService) ToProtoValidatorStats(stats *ValidatorStats) *types.ValidatorStats {
	return &types.ValidatorStats{
		TotalValidators:     stats.TotalValidators,
		ActiveValidators:    stats.ActiveValidators,
		TotalStake:          stats.TotalStake,
		TotalTokens:         stats.TotalTokens,
		NetworkUptime:       stats.NetworkUptime,
		TotalBitcoinBalance: stats.TotalBitcoinBalance,
		BitcoinUsdValue:     stats.TotalBitcoinUSDValue,
	}
}
