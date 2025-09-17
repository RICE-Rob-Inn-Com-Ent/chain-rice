package handlers

import (
	"net/http"
	"strconv"
	"time"

	"chainrice/internal/services"

	"github.com/gin-gonic/gin"
)

type ValidatorHandlers struct {
	validatorService *services.ValidatorService
}

func NewValidatorHandlers(validatorService *services.ValidatorService) *ValidatorHandlers {
	return &ValidatorHandlers{
		validatorService: validatorService,
	}
}

// GetValidators returns all validators with their Bitcoin balances
func (h *ValidatorHandlers) GetValidators(c *gin.Context) {
	ctx := c.Request.Context()

	validators, err := h.validatorService.GetAllValidators(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to fetch validators",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"validators": validators,
		"count":      len(validators),
		"timestamp":  time.Now().ISO8601(),
	})
}

// GetValidator returns a specific validator by ID
func (h *ValidatorHandlers) GetValidator(c *gin.Context) {
	ctx := c.Request.Context()
	id := c.Param("id")

	validator, err := h.validatorService.GetValidatorByID(ctx, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Validator not found",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"validator": validator,
		"timestamp": time.Now().ISO8601(),
	})
}

// GetValidatorStats returns network-wide statistics
func (h *ValidatorHandlers) GetValidatorStats(c *gin.Context) {
	ctx := c.Request.Context()

	stats, err := h.validatorService.GetValidatorStats(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to fetch validator stats",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"stats":     stats,
		"timestamp": time.Now().ISO8601(),
	})
}

// GetBitcoinBalances returns all Bitcoin balances
func (h *ValidatorHandlers) GetBitcoinBalances(c *gin.Context) {
	ctx := c.Request.Context()

	balances, err := h.validatorService.GetBitcoinBalances(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to fetch Bitcoin balances",
			"details": err.Error(),
		})
		return
	}

	// Calculate totals
	var totalBTC, totalUSD float64
	for _, balance := range balances {
		totalBTC += balance.BalanceBTC
		totalUSD += balance.USDValue
	}

	c.JSON(http.StatusOK, gin.H{
		"balances": balances,
		"summary": gin.H{
			"total_btc": totalBTC,
			"total_usd": totalUSD,
			"count":     len(balances),
		},
		"timestamp": time.Now().ISO8601(),
	})
}

// GetValidatorPerformance returns performance history for a validator
func (h *ValidatorHandlers) GetValidatorPerformance(c *gin.Context) {
	ctx := c.Request.Context()
	id := c.Param("id")

	daysStr := c.DefaultQuery("days", "30")
	days, err := strconv.Atoi(daysStr)
	if err != nil || days < 1 || days > 365 {
		days = 30
	}

	history, err := h.validatorService.GetValidatorPerformanceHistory(ctx, id, days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to fetch performance history",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"validator_id":        id,
		"performance_history": history,
		"days":                days,
		"count":               len(history),
		"timestamp":           time.Now().ISO8601(),
	})
}

// UpdateValidatorPerformance updates validator performance metrics
func (h *ValidatorHandlers) UpdateValidatorPerformance(c *gin.Context) {
	ctx := c.Request.Context()
	id := c.Param("id")

	var updateData struct {
		Uptime         float64 `json:"uptime" binding:"required"`
		VotingPower    float64 `json:"voting_power" binding:"required"`
		CommissionRate float64 `json:"commission_rate" binding:"required"`
		StakeAmount    int64   `json:"stake_amount" binding:"required"`
		TokenBalance   int64   `json:"token_balance" binding:"required"`
		BitcoinBalance float64 `json:"bitcoin_balance" binding:"required"`
	}

	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	err := h.validatorService.UpdateValidatorPerformance(
		ctx, id,
		updateData.Uptime,
		updateData.VotingPower,
		updateData.CommissionRate,
		updateData.StakeAmount,
		updateData.TokenBalance,
		updateData.BitcoinBalance,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to update validator performance",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "Validator performance updated successfully",
		"validator_id": id,
		"timestamp":    time.Now().ISO8601(),
	})
}

// UpdateBitcoinBalance updates Bitcoin balance for an address
func (h *ValidatorHandlers) UpdateBitcoinBalance(c *gin.Context) {
	ctx := c.Request.Context()

	var updateData struct {
		Address         string  `json:"address" binding:"required"`
		BalanceBTC      float64 `json:"balance_btc" binding:"required"`
		BalanceSatoshis int64   `json:"balance_satoshis" binding:"required"`
		USDValue        float64 `json:"usd_value" binding:"required"`
		Confirmations   int32   `json:"confirmations" binding:"required"`
	}

	if err := c.ShouldBindJSON(&updateData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	err := h.validatorService.UpdateBitcoinBalance(
		ctx,
		updateData.Address,
		updateData.BalanceBTC,
		updateData.BalanceSatoshis,
		updateData.USDValue,
		updateData.Confirmations,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to update Bitcoin balance",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Bitcoin balance updated successfully",
		"address":   updateData.Address,
		"timestamp": time.Now().ISO8601(),
	})
}

// GetNetworkHealth returns overall network health metrics
func (h *ValidatorHandlers) GetNetworkHealth(c *gin.Context) {
	ctx := c.Request.Context()

	stats, err := h.validatorService.GetValidatorStats(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to fetch network health",
			"details": err.Error(),
		})
		return
	}

	// Calculate health score based on various metrics
	healthScore := calculateHealthScore(stats)

	// Determine health status
	var status string
	var color string
	switch {
	case healthScore >= 90:
		status = "Excellent"
		color = "green"
	case healthScore >= 75:
		status = "Good"
		color = "yellow"
	case healthScore >= 60:
		status = "Fair"
		color = "orange"
	default:
		status = "Poor"
		color = "red"
	}

	c.JSON(http.StatusOK, gin.H{
		"network_health": gin.H{
			"score":  healthScore,
			"status": status,
			"color":  color,
			"metrics": gin.H{
				"total_validators":      stats.TotalValidators,
				"active_validators":     stats.ActiveValidators,
				"network_uptime":        stats.NetworkUptime,
				"total_stake":           stats.TotalStake,
				"total_bitcoin_balance": stats.TotalBitcoinBalance,
			},
		},
		"timestamp": time.Now().ISO8601(),
	})
}

// RefreshNetworkData refreshes all network data
func (h *ValidatorHandlers) RefreshNetworkData(c *gin.Context) {
	ctx := c.Request.Context()

	// Record new network statistics
	err := h.validatorService.RecordNetworkStatistics(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to refresh network data",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Network data refreshed successfully",
		"timestamp": time.Now().ISO8601(),
	})
}

// calculateHealthScore calculates a health score based on network metrics
func calculateHealthScore(stats *services.ValidatorStats) float64 {
	// Base score from uptime
	score := stats.NetworkUptime

	// Bonus for having active validators
	if stats.TotalValidators > 0 {
		activeRatio := float64(stats.ActiveValidators) / float64(stats.TotalValidators)
		score += activeRatio * 10 // Up to 10 bonus points
	}

	// Ensure score doesn't exceed 100
	if score > 100 {
		score = 100
	}

	return score
}

// SetupValidatorRoutes sets up all validator-related routes
func SetupValidatorRoutes(router *gin.Engine, validatorService *services.ValidatorService) {
	handlers := NewValidatorHandlers(validatorService)

	api := router.Group("/api/v1/validators")
	{
		api.GET("/", handlers.GetValidators)
		api.GET("/stats", handlers.GetValidatorStats)
		api.GET("/bitcoin-balances", handlers.GetBitcoinBalances)
		api.GET("/network-health", handlers.GetNetworkHealth)
		api.POST("/refresh", handlers.RefreshNetworkData)

		// Validator-specific routes
		api.GET("/:id", handlers.GetValidator)
		api.GET("/:id/performance", handlers.GetValidatorPerformance)
		api.PUT("/:id/performance", handlers.UpdateValidatorPerformance)

		// Bitcoin-specific routes
		api.PUT("/bitcoin-balance", handlers.UpdateBitcoinBalance)
	}
}
