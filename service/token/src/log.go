package token

import (
	"cosmossdk.io/log"
)

const ModuleName = "x/token"

// ModuleLogger returns a child logger tagged with the token module.
func ModuleLogger(l log.Logger) log.Logger {
	if l == nil {
		return log.NewNopLogger()
	}
	return l.With("module", ModuleName)
}
