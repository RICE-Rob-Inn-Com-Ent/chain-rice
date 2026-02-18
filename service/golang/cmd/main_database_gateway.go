//go:build database_gateway

package cmd

import "../../cmd/github.com/chainrice/rice/backend/app"

func main() {
	app.RunDatabaseRouter()
}
