package data

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	_ "github.com/lib/pq"
)

// PostgresConfig holds PostgreSQL connection configuration
type PostgresConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	Database string
	SSLMode  string
	MaxConns int
	MinConns int
}

// PostgresDefaultConfig returns default PostgreSQL configuration
func PostgresDefaultConfig() PostgresConfig {
	return PostgresConfig{
		Host:     "localhost",
		Port:     5432,
		User:     "postgres",
		Password: "postgres",
		Database: "postgres",
		SSLMode:  "disable",
		MaxConns: 25,
		MinConns: 5,
	}
}

// PostgresFromEnv creates config from environment variables
func PostgresFromEnv() PostgresConfig {
	config := PostgresDefaultConfig()

	if dbURL := os.Getenv("DATABASE_URL"); dbURL != "" {
		if parsed, err := postgresParseDatabaseURL(dbURL); err == nil {
			config = parsed
		} else {
			log.Printf("Warning: Failed to parse DATABASE_URL, using individual env vars: %v", err)
		}
	}

	if host := os.Getenv("POSTGRES_HOST"); host != "" {
		config.Host = host
	}
	if portStr := os.Getenv("POSTGRES_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err == nil {
			config.Port = port
		}
	}
	if user := os.Getenv("POSTGRES_USER"); user != "" {
		config.User = user
	}
	if password := os.Getenv("POSTGRES_PASSWORD"); password != "" {
		config.Password = password
	}
	if db := os.Getenv("POSTGRES_DB"); db != "" {
		config.Database = db
	}
	if sslMode := os.Getenv("POSTGRES_SSLMODE"); sslMode != "" {
		config.SSLMode = sslMode
	}
	if maxConnsStr := os.Getenv("POSTGRES_MAX_CONNS"); maxConnsStr != "" {
		if maxConns, err := strconv.Atoi(maxConnsStr); err == nil {
			config.MaxConns = maxConns
		}
	}
	if minConnsStr := os.Getenv("POSTGRES_MIN_CONNS"); minConnsStr != "" {
		if minConns, err := strconv.Atoi(minConnsStr); err == nil {
			config.MinConns = minConns
		}
	}

	return config
}

func postgresParseDatabaseURL(urlStr string) (PostgresConfig, error) {
	config := PostgresDefaultConfig()

	if len(urlStr) < 11 || urlStr[:11] != "postgresql://" {
		return config, fmt.Errorf("invalid database URL format")
	}
	urlStr = urlStr[11:]

	var userPass, hostPort, db, params string
	parts := splitOnce(urlStr, "@")
	if len(parts) == 2 {
		userPass = parts[0]
		hostPort = parts[1]
	} else {
		hostPort = urlStr
	}

	if userPass != "" {
		upParts := splitOnce(userPass, ":")
		if len(upParts) == 2 {
			config.User = upParts[0]
			config.Password = upParts[1]
		} else {
			config.User = userPass
		}
	}

	slashIdx := -1
	questionIdx := -1
	for i, c := range hostPort {
		if c == '/' && slashIdx == -1 {
			slashIdx = i
		}
		if c == '?' && questionIdx == -1 {
			questionIdx = i
		}
	}

	if questionIdx != -1 {
		params = hostPort[questionIdx+1:]
		hostPort = hostPort[:questionIdx]
	}

	if slashIdx != -1 {
		db = hostPort[slashIdx+1:]
		hostPort = hostPort[:slashIdx]
	}

	if db != "" {
		config.Database = db
	}

	hpParts := splitOnce(hostPort, ":")
	if len(hpParts) == 2 {
		config.Host = hpParts[0]
		if port, err := strconv.Atoi(hpParts[1]); err == nil {
			config.Port = port
		}
	} else {
		config.Host = hostPort
	}

	if params != "" {
		if sslMode := extractParam(params, "sslmode"); sslMode != "" {
			config.SSLMode = sslMode
		}
	}

	return config, nil
}

// PostgresConnection wraps the sql.DB with additional functionality
type PostgresConnection struct {
	*sql.DB
	config PostgresConfig
}

// PostgresNewConnection creates a new PostgreSQL connection
func PostgresNewConnection(config PostgresConfig) (*PostgresConnection, error) {
	connStr := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.Host,
		config.Port,
		config.User,
		config.Password,
		config.Database,
		config.SSLMode,
	)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	db.SetMaxOpenConns(config.MaxConns)
	db.SetMaxIdleConns(config.MinConns)
	db.SetConnMaxLifetime(time.Hour)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &PostgresConnection{
		DB:     db,
		config: config,
	}, nil
}

// Close closes the database connection
func (db *PostgresConnection) Close() error {
	return db.DB.Close()
}

// HealthCheck performs a health check on the database
func (db *PostgresConnection) HealthCheck(ctx context.Context) error {
	return db.PingContext(ctx)
}

// Transaction executes a function within a database transaction
func (db *PostgresConnection) Transaction(ctx context.Context, fn func(*sql.Tx) error) error {
	// #region agent log
	if logFile, err := os.OpenFile("/home/mrDinkelman/rice-mono/.cursor/debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err == nil {
		logData, _ := json.Marshal(map[string]interface{}{"sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "postgres.go:210", "message": "Transaction start", "data": map[string]interface{}{"ctxNil": ctx == nil, "fnNil": fn == nil, "ctxDone": func() bool { if ctx != nil { return ctx.Err() != nil } else { return false } }()}, "timestamp": time.Now().UnixNano() / 1e6})
		logFile.WriteString(string(logData) + "\n")
		logFile.Close()
	}
	// #endregion

	if ctx == nil {
		return fmt.Errorf("context cannot be nil")
	}

	if fn == nil {
		return fmt.Errorf("transaction function cannot be nil")
	}

	// Check context cancellation before starting transaction
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("context cancelled before transaction: %w", err)
	}

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		// #region agent log
		if logFile, err2 := os.OpenFile("/home/mrDinkelman/rice-mono/.cursor/debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err2 == nil {
			logData, _ := json.Marshal(map[string]interface{}{"sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "postgres.go:230", "message": "BeginTx failed", "data": map[string]interface{}{"error": err.Error()}, "timestamp": time.Now().UnixNano() / 1e6})
			logFile.WriteString(string(logData) + "\n")
			logFile.Close()
		}
		// #endregion
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	// Use named return to properly handle error in defer
	var txErr error
	defer func() {
		if p := recover(); p != nil {
			// #region agent log
			if logFile, err2 := os.OpenFile("/home/mrDinkelman/rice-mono/.cursor/debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err2 == nil {
				logData, _ := json.Marshal(map[string]interface{}{"sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "postgres.go:240", "message": "Transaction panic", "data": map[string]interface{}{"panic": fmt.Sprintf("%v", p)}, "timestamp": time.Now().UnixNano() / 1e6})
				logFile.WriteString(string(logData) + "\n")
				logFile.Close()
			}
			// #endregion
			if rollbackErr := tx.Rollback(); rollbackErr != nil {
				log.Printf("Failed to rollback transaction after panic: %v", rollbackErr)
			}
			panic(p)
		} else if txErr != nil {
			// #region agent log
			if logFile, err2 := os.OpenFile("/home/mrDinkelman/rice-mono/.cursor/debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err2 == nil {
				logData, _ := json.Marshal(map[string]interface{}{"sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "postgres.go:250", "message": "Transaction error, rolling back", "data": map[string]interface{}{"error": txErr.Error()}, "timestamp": time.Now().UnixNano() / 1e6})
				logFile.WriteString(string(logData) + "\n")
				logFile.Close()
			}
			// #endregion
			if rollbackErr := tx.Rollback(); rollbackErr != nil {
				log.Printf("Failed to rollback transaction: %v (original error: %v)", rollbackErr, txErr)
			}
		} else {
			// #region agent log
			if logFile, err2 := os.OpenFile("/home/mrDinkelman/rice-mono/.cursor/debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err2 == nil {
				logData, _ := json.Marshal(map[string]interface{}{"sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "postgres.go:260", "message": "Transaction committing", "data": map[string]interface{}{}, "timestamp": time.Now().UnixNano() / 1e6})
				logFile.WriteString(string(logData) + "\n")
				logFile.Close()
			}
			// #endregion
			if commitErr := tx.Commit(); commitErr != nil {
				// #region agent log
				if logFile, err2 := os.OpenFile("/home/mrDinkelman/rice-mono/.cursor/debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err2 == nil {
					logData, _ := json.Marshal(map[string]interface{}{"sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "postgres.go:265", "message": "Transaction commit failed", "data": map[string]interface{}{"error": commitErr.Error()}, "timestamp": time.Now().UnixNano() / 1e6})
					logFile.WriteString(string(logData) + "\n")
					logFile.Close()
				}
				// #endregion
				txErr = fmt.Errorf("failed to commit transaction: %w", commitErr)
			}
		}
	}()

	// #region agent log
	if logFile, err := os.OpenFile("/home/mrDinkelman/rice-mono/.cursor/debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err == nil {
		logData, _ := json.Marshal(map[string]interface{}{"sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "postgres.go:275", "message": "Before executing transaction function", "data": map[string]interface{}{}, "timestamp": time.Now().UnixNano() / 1e6})
		logFile.WriteString(string(logData) + "\n")
		logFile.Close()
	}
	// #endregion

	txErr = fn(tx)

	// #region agent log
	if logFile, err := os.OpenFile("/home/mrDinkelman/rice-mono/.cursor/debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err == nil {
		logData, _ := json.Marshal(map[string]interface{}{"sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "postgres.go:285", "message": "After executing transaction function", "data": map[string]interface{}{"error": txErr != nil, "errorMsg": func() string { if txErr != nil { return txErr.Error() } else { return "" } }()}, "timestamp": time.Now().UnixNano() / 1e6})
		logFile.WriteString(string(logData) + "\n")
		logFile.Close()
	}
	// #endregion

	return txErr
}

// GetConfig returns the connection configuration
func (db *PostgresConnection) GetConfig() PostgresConfig {
	return db.config
}

// PostgresKeeper manages PostgreSQL connections and operations
type PostgresKeeper struct {
	conn *PostgresConnection
}

// PostgresNewKeeper creates a new PostgreSQL keeper
func PostgresNewKeeper(config PostgresConfig) (*PostgresKeeper, error) {
	conn, err := PostgresNewConnection(config)
	if err != nil {
		return nil, err
	}

	log.Printf("Connected to PostgreSQL database: %s", config.Database)

	return &PostgresKeeper{
		conn: conn,
	}, nil
}

// GetConnection returns the underlying database connection
func (k *PostgresKeeper) GetConnection() *PostgresConnection {
	return k.conn
}

// HealthCheck performs a health check
func (k *PostgresKeeper) HealthCheck(ctx context.Context) error {
	return k.conn.HealthCheck(ctx)
}

// Close closes the connection
func (k *PostgresKeeper) Close() error {
	log.Println("Closing PostgreSQL connection")
	return k.conn.Close()
}
