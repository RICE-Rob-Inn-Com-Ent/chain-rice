package shared

import (
	"database/sql"
	"chainrice/shared/database"
)

// InitDB initializes the database connection
func InitDB() (*sql.DB, error) {
	return database.InitDB()
}