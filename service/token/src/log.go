package token

import (
	"cosmossdk.io/log"
)

const (
	// RiceTokenLogPrefix is prepended to every message from [NewRiceTokenLogger].
	RiceTokenLogPrefix = "[RICE-TOKEN]"
	loggerModuleTag    = "x/" + ModuleName
)

type prefixedLogger struct {
	inner  log.Logger
	prefix string
}

func (p prefixedLogger) Info(msg string, keyVals ...any) {
	p.inner.Info(p.prefix+msg, keyVals...)
}

func (p prefixedLogger) Warn(msg string, keyVals ...any) {
	p.inner.Warn(p.prefix+msg, keyVals...)
}

func (p prefixedLogger) Error(msg string, keyVals ...any) {
	p.inner.Error(p.prefix+msg, keyVals...)
}

func (p prefixedLogger) Debug(msg string, keyVals ...any) {
	p.inner.Debug(p.prefix+msg, keyVals...)
}

func (p prefixedLogger) With(keyVals ...any) log.Logger {
	return prefixedLogger{inner: p.inner.With(keyVals...), prefix: p.prefix}
}

func (p prefixedLogger) Impl() any {
	return p.inner.Impl()
}

// NewRiceTokenLogger returns a SDK [log.Logger] that prefixes all messages with [RiceTokenLogPrefix]
// and tags the x/token module.
func NewRiceTokenLogger(base log.Logger) log.Logger {
	if base == nil {
		base = log.NewNopLogger()
	}
	child := base.With(log.ModuleKey, loggerModuleTag)
	return prefixedLogger{inner: child, prefix: RiceTokenLogPrefix + " "}
}

// ModuleLogger returns a child logger tagged with the token module (no message prefix).
// Prefer [NewRiceTokenLogger] for the standard SMITH token prefix.
func ModuleLogger(l log.Logger) log.Logger {
	if l == nil {
		return log.NewNopLogger()
	}
	return l.With(log.ModuleKey, loggerModuleTag)
}
