//go:build graphql_server

package cmd

import "../../cmd/github.com/chainrice/rice/backend/app"

func main() {
	app.RunGraphQLServer()
}

