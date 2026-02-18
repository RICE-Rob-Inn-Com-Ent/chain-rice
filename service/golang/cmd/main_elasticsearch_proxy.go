//go:build elasticsearch_proxy

package cmd

import "../../cmd/github.com/chainrice/rice/backend/app"

func main() {
	app.RunElasticsearchProxy()
}

