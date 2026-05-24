// Command rice-kit (optional): Back2 can build this target for version output and self-tests.
// Library users import github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src instead.
//
// Build from kit module root: go build -o rice-kit ./src/cmd/rice-kit

package main

import (
	"context"
	"fmt"
	"os"
	"time"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
)

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "version", "-v", "--version":
			printVersion()
			return
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	k, err := kit.NewKit()
	if err != nil {
		fmt.Fprintln(os.Stderr, "kit.NewKit:", err)
		os.Exit(1)
	}
	defer func() { _ = k.Close(context.Background()) }()

	if err := kit.SanityCheck(k); err != nil {
		fmt.Fprintln(os.Stderr, "sanity check:", err)
		os.Exit(1)
	}

	_, _ = fmt.Fprintf(os.Stdout, "rice kit %s: ok\n", kit.Version)
	_ = ctx
}

func printVersion() {
	fmt.Printf("version: %s\nbuild_time: %s\ngit_commit: %s\n", kit.Version, kit.BuildTime, kit.GitCommit)
}
