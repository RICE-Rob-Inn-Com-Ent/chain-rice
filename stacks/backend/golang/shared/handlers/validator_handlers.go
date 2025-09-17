package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"chainrice/shared/services"
)

type ValidatorHandler struct {
	validatorService *services.ValidatorService
}

func NewValidatorHandler(db *sql.DB) *ValidatorHandler {
	return &ValidatorHandler{
		validatorService: services.NewValidatorService(db),
	}
}

func (h *ValidatorHandler) GetAllValidators(w http.ResponseWriter, r *http.Request) {
	validators, err := h.validatorService.GetAllValidators()
	if err != nil {
		http.Error(w, "Failed to get validators", http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"validators": validators,
		"timestamp":  time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (h *ValidatorHandler) GetValidatorByID(w http.ResponseWriter, r *http.Request) {
	// Extract ID from URL path or query parameter
	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, "Validator ID is required", http.StatusBadRequest)
		return
	}

	validator, err := h.validatorService.GetValidatorByID(id)
	if err != nil {
		http.Error(w, "Validator not found", http.StatusNotFound)
		return
	}

	response := map[string]interface{}{
		"validator": validator,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (h *ValidatorHandler) GetValidatorStats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.validatorService.GetValidatorStats()
	if err != nil {
		http.Error(w, "Failed to get validator stats", http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"stats":     stats,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (h *ValidatorHandler) GetBitcoinBalances(w http.ResponseWriter, r *http.Request) {
	balances, err := h.validatorService.GetBitcoinBalances()
	if err != nil {
		http.Error(w, "Failed to get bitcoin balances", http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"balances":  balances,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (h *ValidatorHandler) UpdateValidatorPerformance(w http.ResponseWriter, r *http.Request) {
	var req struct {
		ValidatorID     string  `json:"validator_id"`
		Uptime          float64 `json:"uptime"`
		VotingPower     float64 `json:"voting_power"`
		CommissionRate  float64 `json:"commission_rate"`
		StakeAmount     int64   `json:"stake_amount"`
		TokenBalance    int64   `json:"token_balance"`
		BitcoinBalance  float64 `json:"bitcoin_balance"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	err := h.validatorService.UpdateValidatorPerformance(
		req.ValidatorID, req.Uptime, req.VotingPower, req.CommissionRate,
		req.StakeAmount, req.TokenBalance, req.BitcoinBalance,
	)
	if err != nil {
		http.Error(w, "Failed to update validator performance", http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"message":   "Validator performance updated successfully",
		"timestamp": time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (h *ValidatorHandler) UpdateBitcoinBalance(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Address         string  `json:"address"`
		BalanceBTC      float64 `json:"balance_btc"`
		BalanceSatoshis int64   `json:"balance_satoshis"`
		USDValue        float64 `json:"usd_value"`
		Confirmations   int32   `json:"confirmations"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	err := h.validatorService.UpdateBitcoinBalance(
		req.Address, req.BalanceBTC, req.BalanceSatoshis, req.USDValue, req.Confirmations,
	)
	if err != nil {
		http.Error(w, "Failed to update bitcoin balance", http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"message":   "Bitcoin balance updated successfully",
		"timestamp": time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}