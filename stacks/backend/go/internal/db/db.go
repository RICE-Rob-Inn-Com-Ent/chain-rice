package db

type Config struct {
	DSN string
}

// Connect simuluje połączenie z bazą i zwraca prosty opis stanu.
func Connect(cfg Config) (string, error) {
	if cfg.DSN == "" {
		return "", nil
	}
	return "connected:" + cfg.DSN, nil
}
