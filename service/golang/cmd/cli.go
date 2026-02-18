//go:build services_cli

package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
	"go.uber.org/zap"

	"github.com/chainrice/rice/backend/app"
	"github.com/chainrice/rice/backend/app/helpers"
	"github.com/chainrice/rice/backend/app/services"
)

var (
	servicesLogger *zap.SugaredLogger
	servicesOrch   *app.Orchestrator
)

func main() {
	RunServicesCLI()
}

// RunServicesCLI starts the services CLI
func RunServicesCLI() {
	zapLogger, _ := zap.NewDevelopment()
	defer zapLogger.Sync()
	servicesLogger = zapLogger.Sugar()

	network := helpers.GetEnv("DOCKER_NETWORK", "crice")
	servicesOrch = app.NewOrchestrator(servicesLogger, network)

	// Register all services
	services.RegisterDataServices(servicesOrch, network)
	services.RegisterAnalyticsServices(servicesOrch, network)
	services.RegisterInfrastructureServices(servicesOrch, network)

	rootCmd := &cobra.Command{
		Use:   "services",
		Short: "Manage Docker services from docker-compose.stack.yml",
		Long:  "Service orchestrator for managing all infrastructure services programmatically in Go",
	}

	listCmd := &cobra.Command{
		Use:   "list",
		Short: "List all available services",
		Run:   runList,
	}
	listCmd.Flags().StringP("profile", "p", "", "Filter by profile")

	startCmd := &cobra.Command{
		Use:   "start [service-name]",
		Short: "Start a service or profile",
		Run:   runStart,
	}
	startCmd.Flags().StringP("profile", "p", "", "Start all services in a profile")

	stopCmd := &cobra.Command{
		Use:   "stop [service-name]",
		Short: "Stop a service or profile",
		Run:   runStop,
	}
	stopCmd.Flags().StringP("profile", "p", "", "Stop all services in a profile")

	removeCmd := &cobra.Command{
		Use:   "remove [service-name]",
		Short: "Remove a service container",
		Run:   runRemove,
	}

	statusCmd := &cobra.Command{
		Use:   "status [service-name]",
		Short: "Check status of a service",
		Run:   runStatus,
	}

	rootCmd.AddCommand(listCmd, startCmd, stopCmd, removeCmd, statusCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func runList(cmd *cobra.Command, args []string) {
	profile, _ := cmd.Flags().GetString("profile")

	if profile != "" {
		services := servicesOrch.GetServicesByProfile(profile)
		fmt.Printf("\n📦 Services in profile '%s' (%d):\n\n", profile, len(services))
		for _, svc := range services {
			printService(svc)
		}
	} else {
		services := servicesOrch.ListServices()
		fmt.Printf("\n📦 All Services (%d):\n\n", len(services))
		for _, svc := range services {
			printService(svc)
		}
	}
}

func runStart(cmd *cobra.Command, args []string) {
	profile, _ := cmd.Flags().GetString("profile")

	if profile != "" {
		if err := servicesOrch.StartProfile(profile); err != nil {
			servicesLogger.Fatalf("Failed to start profile: %v", err)
		}
		fmt.Printf("✅ Started profile: %s\n", profile)
	} else if len(args) > 0 {
		serviceName := args[0]
		if err := servicesOrch.StartService(serviceName); err != nil {
			servicesLogger.Fatalf("Failed to start service: %v", err)
		}
		fmt.Printf("✅ Started service: %s\n", serviceName)
	} else {
		fmt.Fprintf(os.Stderr, "Error: specify a service name or use --profile flag\n")
		os.Exit(1)
	}
}

func runStop(cmd *cobra.Command, args []string) {
	profile, _ := cmd.Flags().GetString("profile")

	if profile != "" {
		if err := servicesOrch.StopProfile(profile); err != nil {
			servicesLogger.Fatalf("Failed to stop profile: %v", err)
		}
		fmt.Printf("🛑 Stopped profile: %s\n", profile)
	} else if len(args) > 0 {
		serviceName := args[0]
		if err := servicesOrch.StopService(serviceName); err != nil {
			servicesLogger.Fatalf("Failed to stop service: %v", err)
		}
		fmt.Printf("🛑 Stopped service: %s\n", serviceName)
	} else {
		fmt.Fprintf(os.Stderr, "Error: specify a service name or use --profile flag\n")
		os.Exit(1)
	}
}

func runRemove(cmd *cobra.Command, args []string) {
	if len(args) == 0 {
		fmt.Fprintf(os.Stderr, "Error: specify a service name\n")
		os.Exit(1)
	}

	serviceName := args[0]
	if err := servicesOrch.RemoveService(serviceName); err != nil {
		servicesLogger.Fatalf("Failed to remove service: %v", err)
	}
	fmt.Printf("🗑️  Removed service: %s\n", serviceName)
}

func runStatus(cmd *cobra.Command, args []string) {
	if len(args) == 0 {
		services := servicesOrch.ListServices()
		fmt.Printf("\n📊 Service Status:\n\n")
		for _, svc := range services {
			status := getContainerStatus(svc.Container)
			fmt.Printf("  %-30s %s\n", svc.Name+":", status)
		}
	} else {
		serviceName := args[0]
		service, err := servicesOrch.GetService(serviceName)
		if err != nil {
			servicesLogger.Fatalf("Service not found: %v", err)
		}
		status := getContainerStatus(service.Container)
		fmt.Printf("\n📊 Status of %s:\n", serviceName)
		fmt.Printf("  Container: %s\n", service.Container)
		fmt.Printf("  Status:    %s\n", status)
		fmt.Printf("  Image:     %s\n", service.Image)
		if len(service.Ports) > 0 {
			fmt.Printf("  Ports:     ")
			for i, port := range service.Ports {
				if i > 0 {
					fmt.Printf(", ")
				}
				fmt.Printf("%s:%s", port.Host, port.Container)
			}
			fmt.Printf("\n")
		}
	}
}

func printService(svc *app.Service) {
	fmt.Printf("  %-20s %s\n", svc.Name+":", svc.Description)
	fmt.Printf("    Container: %s\n", svc.Container)
	fmt.Printf("    Image:     %s\n", svc.Image)
	if len(svc.Ports) > 0 {
		fmt.Printf("    Ports:     ")
		for i, port := range svc.Ports {
			if i > 0 {
				fmt.Printf(", ")
			}
			fmt.Printf("%s:%s", port.Host, port.Container)
		}
		fmt.Printf("\n")
	}
	if len(svc.Profiles) > 0 {
		fmt.Printf("    Profiles:  %v\n", svc.Profiles)
	}
	fmt.Printf("\n")
}

func getContainerStatus(containerName string) string {
	cmd := exec.Command("docker", "ps", "-a", "--filter", "name="+containerName, "--format", "{{.Status}}")
	output, err := cmd.Output()
	if err != nil {
		return "unknown"
	}
	status := string(output)
	if status == "" {
		return "not running"
	}
	return strings.TrimSpace(status)
}
