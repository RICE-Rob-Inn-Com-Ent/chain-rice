package main

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"time"
)

// azure-lab is a lightweight helper that leans on the Azure CLI (`az`)
// so that we don't need to pull in heavy SDK dependencies just for training labs.
//
// It demonstrates:
//   - checking the current signed-in account
//   - listing resource groups in the subscription
//
// Requirements:
//   - `az` must be installed (provided by the devcontainer features)
//   - `az login` should be executed beforehand (use dedicated training profile)
func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	fmt.Println("[azure-lab] Using Azure CLI for basic account and resource group info")

	accountJSON, err := runAz(ctx, "account", "show", "--output", "json")
	if err != nil {
		log.Fatalf("[azure-lab] az account show failed: %v", err)
	}

	fmt.Println("[azure-lab] Current account (az account show):")
	fmt.Println(indent(accountJSON, "  "))

	rgJSON, err := runAz(ctx, "group", "list", "--output", "json")
	if err != nil {
		log.Fatalf("[azure-lab] az group list failed: %v", err)
	}

	fmt.Println("[azure-lab] Resource groups (az group list):")
	fmt.Println(indent(rgJSON, "  "))

	fmt.Println("[azure-lab] Tip: use this tool in labs together with Terraform / Bicep deployments.")
}

func runAz(ctx context.Context, args ...string) (string, error) {
	if _, err := exec.LookPath("az"); err != nil {
		return "", fmt.Errorf("az CLI not found in PATH: %w", err)
	}

	cmd := exec.CommandContext(ctx, "az", args...)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return "", err
	}
	return out.String(), nil
}

func indent(s, prefix string) string {
	lines := bytes.Split([]byte(s), []byte("\n"))
	var buf bytes.Buffer
	for _, line := range lines {
		if len(line) == 0 {
			continue
		}
		buf.WriteString(prefix)
		buf.Write(line)
		buf.WriteByte('\n')
	}
	return buf.String()
}

