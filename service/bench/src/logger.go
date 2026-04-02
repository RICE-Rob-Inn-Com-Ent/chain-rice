package bench

// TODO:
// [ ] implement zap logger setup:
//     NewLogger(level string) *zap.Logger
//     level from RICE_LOG_LEVEL env var (default: info)
//     format: JSON in Docker, console in dev
//     RICE_LOG_FORMAT=json|console controls format
// [ ] implement OTel bridge:
//     otelzap.New(logger) — bridges zap into OTel trace context
//     every zap log gets trace_id, span_id injected
// [ ] implement sensitive field masking:
//     zap.Field masker for: password, token, api_key, secret
//     RICE_LOG_MASK_FIELDS controls which fields to mask
// [ ] implement request logger middleware:
//     LogRequest(logger) fiber.Handler
//     logs: method, path, status, duration, trace_id

import (
	"os"

	"go.opentelemetry.io/contrib/bridges/otelzap"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// NewProductionLogger is a standard zap production configuration (JSON to stderr).
func NewProductionLogger() (*zap.Logger, error) {
	return zap.NewProduction()
}

// NewDevelopmentLogger is verbose console output for local debugging.
func NewDevelopmentLogger() (*zap.Logger, error) {
	return zap.NewDevelopment()
}

// NewZapWithOTelCore tees structured logs to stderr and to OpenTelemetry Logs (otelzap bridge).
// Requires a configured global log.LoggerProvider if you export logs via OTLP.
func NewZapWithOTelCore(serviceName string, level zapcore.LevelEnabler, otelOpts ...otelzap.Option) *zap.Logger {
	encCfg := zap.NewProductionEncoderConfig()
	encCfg.EncodeTime = zapcore.ISO8601TimeEncoder
	enc := zapcore.NewJSONEncoder(encCfg)
	stderr := zapcore.Lock(os.Stderr)
	console := zapcore.NewCore(enc, stderr, level)
	otelCore := otelzap.NewCore(serviceName, otelOpts...)
	return zap.New(zapcore.NewTee(console, otelCore), zap.AddCaller())
}
