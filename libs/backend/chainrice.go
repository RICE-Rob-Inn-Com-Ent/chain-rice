package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"
)

type User struct {
	Username     string  `json:"username"`
	Address      string  `json:"address"`
	CRICEBalance float64 `json:"crice_balance"`
	NORIBalance  float64 `json:"nori_balance"`
}

type Transaction struct {
	Hash        string  `json:"hash"`
	FromAddress string  `json:"from_address"`
	ToAddress   string  `json:"to_address"`
	Amount      float64 `json:"amount"`
	Token       string  `json:"token"`
	Status      string  `json:"status"`
	Timestamp   string  `json:"timestamp"`
}

type LogEntry struct {
	Timestamp string `json:"timestamp"`
	Level     string `json:"level"`
	Message   string `json:"message"`
}

type ChainRiceBlockchain struct {
	BlockHeight  int64
	Users        map[string]*User
	Transactions []Transaction
	Logs         []LogEntry
	mutex        sync.RWMutex
}

var blockchain = &ChainRiceBlockchain{
	BlockHeight: 1,
	Users: map[string]*User{
		"crice1alice1234567890abcdefghijklmnopqrstuvwxyz": {
			Username:     "alice",
			Address:      "crice1alice1234567890abcdefghijklmnopqrstuvwxyz",
			CRICEBalance: 1000000.0,
			NORIBalance:  500000.0,
		},
		"crice1bob1234567890abcdefghijklmnopqrstuvwxyz": {
			Username:     "bob",
			Address:      "crice1bob1234567890abcdefghijklmnopqrstuvwxyz",
			CRICEBalance: 750000.0,
			NORIBalance:  250000.0,
		},
		"crice1charlie1234567890abcdefghijklmnopqrstuvwxyz": {
			Username:     "charlie",
			Address:      "crice1charlie1234567890abcdefghijklmnopqrstuvwxyz",
			CRICEBalance: 500000.0,
			NORIBalance:  750000.0,
		},
		"crice1diana1234567890abcdefghijklmnopqrstuvwxyz": {
			Username:     "diana",
			Address:      "crice1diana1234567890abcdefghijklmnopqrstuvwxyz",
			CRICEBalance: 250000.0,
			NORIBalance:  100000.0,
		},
		"crice1eve1234567890abcdefghijklmnopqrstuvwxyz": {
			Username:     "eve",
			Address:      "crice1eve1234567890abcdefghijklmnopqrstuvwxyz",
			CRICEBalance: 100000.0,
			NORIBalance:  50000.0,
		},
	},
	Transactions: []Transaction{},
	Logs:         []LogEntry{},
}

func (bc *ChainRiceBlockchain) addLog(level, message string) {
	bc.mutex.Lock()
	defer bc.mutex.Unlock()

	logEntry := LogEntry{
		Timestamp: time.Now().Format("2006-01-02 15:04:05"),
		Level:     level,
		Message:   message,
	}

	bc.Logs = append(bc.Logs, logEntry)

	// Keep only last 1000 logs
	if len(bc.Logs) > 1000 {
		bc.Logs = bc.Logs[len(bc.Logs)-1000:]
	}

	fmt.Printf("[%s] %s: %s\n", logEntry.Timestamp, level, message)
}

func (bc *ChainRiceBlockchain) TransferTokens(fromAddr, toAddr string, amount float64, token string) (bool, string) {
	bc.mutex.Lock()
	defer bc.mutex.Unlock()

	bc.addLog("INFO", fmt.Sprintf("Transfer request: %s -> %s, %.2f %s", fromAddr[:20]+"...", toAddr[:20]+"...", amount, token))

	fromUser, exists := bc.Users[fromAddr]
	if !exists {
		bc.addLog("ERROR", fmt.Sprintf("Sender not found: %s", fromAddr))
		return false, "Sender not found"
	}

	toUser, exists := bc.Users[toAddr]
	if !exists {
		bc.addLog("ERROR", fmt.Sprintf("Recipient not found: %s", toAddr))
		return false, "Recipient not found"
	}

	// Check balance
	var fromBalance *float64
	var toBalance *float64

	if token == "CRICE" {
		fromBalance = &fromUser.CRICEBalance
		toBalance = &toUser.CRICEBalance
	} else if token == "NORI" {
		fromBalance = &fromUser.NORIBalance
		toBalance = &toUser.NORIBalance
	} else {
		bc.addLog("ERROR", fmt.Sprintf("Invalid token: %s", token))
		return false, "Invalid token"
	}

	if *fromBalance < amount {
		bc.addLog("ERROR", fmt.Sprintf("Insufficient balance: %.2f %s available, %.2f %s requested", *fromBalance, token, amount, token))
		return false, "Insufficient balance"
	}

	// Transfer
	oldFromBalance := *fromBalance
	oldToBalance := *toBalance
	*fromBalance -= amount
	*toBalance += amount

	// Create transaction
	txHash := fmt.Sprintf("%x", sha256.Sum256([]byte(fmt.Sprintf("%d%s%s%f", time.Now().UnixNano(), fromAddr, toAddr, amount))))

	tx := Transaction{
		Hash:        txHash,
		FromAddress: fromAddr,
		ToAddress:   toAddr,
		Amount:      amount,
		Token:       token,
		Status:      "confirmed",
		Timestamp:   time.Now().Format(time.RFC3339),
	}

	bc.Transactions = append(bc.Transactions, tx)

	bc.addLog("SUCCESS", fmt.Sprintf("Transaction confirmed: %s", txHash))
	bc.addLog("SUCCESS", fmt.Sprintf("Balance update: %s %.2f->%.2f, %s %.2f->%.2f",
		fromUser.Username, oldFromBalance, *fromBalance, toUser.Username, oldToBalance, *toBalance))

	return true, txHash
}

func (bc *ChainRiceBlockchain) GetUserBalance(address string) (float64, float64) {
	bc.mutex.RLock()
	defer bc.mutex.RUnlock()

	user, exists := bc.Users[address]
	if !exists {
		return 0, 0
	}

	return user.CRICEBalance, user.NORIBalance
}

func (bc *ChainRiceBlockchain) StartBlockProduction() {
	for {
		bc.mutex.Lock()
		timestamp := time.Now().Format(time.RFC3339)
		blockHash := fmt.Sprintf("%x", sha256.Sum256([]byte(fmt.Sprintf("%d%s", bc.BlockHeight, timestamp))))
		txCount := len(bc.Transactions)
		blockHeight := bc.BlockHeight
		bc.BlockHeight++
		bc.mutex.Unlock()

		// Add logs after releasing the mutex to avoid deadlock
		bc.addLog("BLOCK", fmt.Sprintf("Block %d: Hash %s", blockHeight, blockHash))
		bc.addLog("BLOCK", fmt.Sprintf("  Timestamp: %s", timestamp))
		bc.addLog("BLOCK", fmt.Sprintf("  Transactions: %d", txCount))
		bc.addLog("BLOCK", "  Gas Used: "+strconv.FormatInt(500000+(blockHeight*1000), 10))
		bc.addLog("BLOCK", "  Validator: crice-validator-1")
		bc.addLog("BLOCK", "  Chain: crice-1")

		time.Sleep(6 * time.Second)
	}
}

func statusHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	// Get block height safely
	var blockHeight int64
	blockchain.mutex.RLock()
	blockHeight = blockchain.BlockHeight - 1
	blockchain.mutex.RUnlock()

	response := map[string]interface{}{
		"result": map[string]interface{}{
			"node_info": map[string]interface{}{
				"network": "crice-1",
				"id":      "crice-node-1",
				"moniker": "crice-validator",
			},
			"sync_info": map[string]interface{}{
				"latest_block_height": strconv.FormatInt(blockHeight, 10),
				"latest_block_time":   time.Now().Format(time.RFC3339),
				"catching_up":         false,
			},
		},
	}

	json.NewEncoder(w).Encode(response)
}

func balanceHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		http.Error(w, "Invalid address", http.StatusBadRequest)
		return
	}

	address := pathParts[3]
	crice, nori := blockchain.GetUserBalance(address)

	response := map[string]interface{}{
		"balances": []map[string]interface{}{
			{"denom": "urice", "amount": strconv.FormatFloat(crice*1000000, 'f', 0, 64)},
			{"denom": "unori", "amount": strconv.FormatFloat(nori*1000000, 'f', 0, 64)},
		},
		"pagination": map[string]interface{}{
			"next_key": nil,
			"total":    "2",
		},
	}

	json.NewEncoder(w).Encode(response)
}

func usersHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	blockchain.mutex.RLock()
	users := make([]*User, 0, len(blockchain.Users))
	for _, user := range blockchain.Users {
		users = append(users, user)
	}
	blockchain.mutex.RUnlock()

	response := map[string]interface{}{
		"users": users,
	}

	json.NewEncoder(w).Encode(response)
}

func logsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	blockchain.mutex.RLock()
	logs := make([]LogEntry, len(blockchain.Logs))
	copy(logs, blockchain.Logs)
	blockchain.mutex.RUnlock()

	// Reverse to show newest first
	for i, j := 0, len(logs)-1; i < j; i, j = i+1, j-1 {
		logs[i], logs[j] = logs[j], logs[i]
	}

	response := map[string]interface{}{
		"logs": logs,
	}

	json.NewEncoder(w).Encode(response)
}

func transferHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var txData map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&txData); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	fromAddr, _ := txData["from"].(string)
	toAddr, _ := txData["to"].(string)
	amount, _ := txData["amount"].(float64)
	token, _ := txData["token"].(string)

	success, result := blockchain.TransferTokens(fromAddr, toAddr, amount, token)

	if success {
		// Get block height safely
		var blockHeight int64
		blockchain.mutex.RLock()
		blockHeight = blockchain.BlockHeight
		blockchain.mutex.RUnlock()

		response := map[string]interface{}{
			"result": map[string]interface{}{
				"check_tx":   map[string]interface{}{"code": 0},
				"deliver_tx": map[string]interface{}{"code": 0},
				"hash":       result,
				"height":     strconv.FormatInt(blockHeight, 10),
			},
		}
		json.NewEncoder(w).Encode(response)
	} else {
		response := map[string]interface{}{
			"error": result,
		}
		json.NewEncoder(w).Encode(response)
	}
}

func main() {
	// Start block production in background
	go blockchain.StartBlockProduction()

	// Setup routes
	http.HandleFunc("/status", statusHandler)
	http.HandleFunc("/bank/balances/", balanceHandler)
	http.HandleFunc("/users", usersHandler)
	http.HandleFunc("/logs", logsHandler)
	http.HandleFunc("/broadcast_tx_commit", transferHandler)

	blockchain.addLog("START", "🚀 REAL ChainRice Blockchain Server Started!")
	blockchain.addLog("INFO", "📊 RPC API: http://localhost:26657")
	blockchain.addLog("INFO", "🗄️ Database: In-memory with real users")
	blockchain.addLog("INFO", "👥 Users: alice, bob, charlie, diana, eve")
	blockchain.addLog("INFO", "💎 CRICE Token: urice")
	blockchain.addLog("INFO", "🪙 NORI Token: unori")
	blockchain.addLog("INFO", "📦 Block production: Every 6 seconds")

	log.Fatal(http.ListenAndServe(":26657", nil))
}
