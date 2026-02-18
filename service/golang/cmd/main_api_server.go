//go:build api_server

package cmd

import "../../cmd/github.com/chainrice/rice/backend/app"

func main() {
	app.RunAPIServer()
}

