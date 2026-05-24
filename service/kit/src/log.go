package kit

import "log/slog"

// Logger returns the process-wide default slog.Logger ([slog.SetDefault]).
// Libraries such as [database] use this for consistent logging with [NewKit].
func Logger() *slog.Logger {
	return slog.Default()
}
