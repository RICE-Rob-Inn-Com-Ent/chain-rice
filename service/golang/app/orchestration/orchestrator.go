package orchestration

import (
	"fmt"
	"os/exec"
	"strings"

	"go.uber.org/zap"
)

// Service represents a Docker service configuration
type Service struct {
	Name        string
	Image       string
	Container   string
	Ports       []PortMapping
	Environment map[string]string
	Volumes     []VolumeMapping
	Networks    []string
	Profiles    []string
	DependsOn   []string
	Restart     string
	Command     []string
	CapAdd      []string
	HealthCheck *HealthCheck
	Description string
}

// PortMapping represents port configuration
type PortMapping struct {
	Host      string
	Container string
	Protocol  string
}

// VolumeMapping represents volume configuration
type VolumeMapping struct {
	Host      string
	Container string
	ReadOnly  bool
}

// HealthCheckConfig represents health check configuration
type HealthCheckConfig struct {
	Test        []string
	Interval    string
	Timeout     string
	Retries     int
	StartPeriod string
}

// HealthCheck represents a health check configuration
type HealthCheck = HealthCheckConfig

// Orchestrator manages Docker services
type Orchestrator struct {
	logger   *zap.SugaredLogger
	services map[string]*Service
	network  string
}

// NewOrchestrator creates a new service orchestrator
func NewOrchestrator(logger *zap.SugaredLogger, network string) *Orchestrator {
	return &Orchestrator{
		logger:   logger,
		services: make(map[string]*Service),
		network:  network,
	}
}

// RegisterService registers a service
func (o *Orchestrator) RegisterService(service *Service) {
	o.services[service.Name] = service
}

// GetService returns a service by name
func (o *Orchestrator) GetService(name string) (*Service, error) {
	service, ok := o.services[name]
	if !ok {
		return nil, fmt.Errorf("service %s not found", name)
	}
	return service, nil
}

// ListServices returns all registered services
func (o *Orchestrator) ListServices() []*Service {
	services := make([]*Service, 0, len(o.services))
	for _, service := range o.services {
		services = append(services, service)
	}
	return services
}

// GetServicesByProfile returns services matching a profile
func (o *Orchestrator) GetServicesByProfile(profile string) []*Service {
	var result []*Service
	for _, service := range o.services {
		for _, p := range service.Profiles {
			if p == profile {
				result = append(result, service)
				break
			}
		}
	}
	return result
}

// StartService starts a Docker container for a service
func (o *Orchestrator) StartService(name string) error {
	service, err := o.GetService(name)
	if err != nil {
		return err
	}

	o.logger.Infof("Starting service: %s (%s)", service.Name, service.Description)

	args := []string{"run", "-d", "--name", service.Container}

	if service.Restart != "" {
		args = append(args, "--restart", service.Restart)
	}

	for _, network := range service.Networks {
		args = append(args, "--network", network)
	}

	for _, port := range service.Ports {
		portStr := port.Host + ":" + port.Container
		if port.Protocol != "tcp" {
			portStr += "/" + port.Protocol
		}
		args = append(args, "-p", portStr)
	}

	for key, value := range service.Environment {
		args = append(args, "-e", key+"="+value)
	}

	for _, volume := range service.Volumes {
		volStr := volume.Host + ":" + volume.Container
		if volume.ReadOnly {
			volStr += ":ro"
		}
		args = append(args, "-v", volStr)
	}

	for _, cap := range service.CapAdd {
		args = append(args, "--cap-add", cap)
	}

	args = append(args, service.Image)

	if len(service.Command) > 0 {
		args = append(args, service.Command...)
	}

	cmd := exec.Command("docker", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		if strings.Contains(string(output), "already exists") {
			o.logger.Infof("Container %s already exists, starting it...", service.Container)
			return o.execDocker("start", service.Container)
		}
		return fmt.Errorf("failed to start service %s: %v\nOutput: %s", name, err, string(output))
	}

	o.logger.Infof("✅ Service %s started successfully", name)
	return nil
}

// StopService stops a Docker container
func (o *Orchestrator) StopService(name string) error {
	service, err := o.GetService(name)
	if err != nil {
		return err
	}

	o.logger.Infof("Stopping service: %s", service.Name)
	return o.execDocker("stop", service.Container)
}

// RemoveService removes a Docker container
func (o *Orchestrator) RemoveService(name string) error {
	service, err := o.GetService(name)
	if err != nil {
		return err
	}

	o.logger.Infof("Removing service: %s", service.Name)
	return o.execDocker("rm", "-f", service.Container)
}

// StartProfile starts all services in a profile
func (o *Orchestrator) StartProfile(profile string) error {
	services := o.GetServicesByProfile(profile)
	o.logger.Infof("Starting profile: %s (%d services)", profile, len(services))

	for _, service := range services {
		for _, dep := range service.DependsOn {
			if err := o.StartService(dep); err != nil {
				o.logger.Warnf("Failed to start dependency %s: %v", dep, err)
			}
		}
	}

	for _, service := range services {
		if err := o.StartService(service.Name); err != nil {
			o.logger.Errorf("Failed to start service %s: %v", service.Name, err)
		}
	}

	return nil
}

// StopProfile stops all services in a profile
func (o *Orchestrator) StopProfile(profile string) error {
	services := o.GetServicesByProfile(profile)
	o.logger.Infof("Stopping profile: %s (%d services)", profile, len(services))

	for _, service := range services {
		if err := o.StopService(service.Name); err != nil {
			o.logger.Warnf("Failed to stop service %s: %v", service.Name, err)
		}
	}

	return nil
}

// execDocker executes a docker command
func (o *Orchestrator) execDocker(args ...string) error {
	cmd := exec.Command("docker", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("docker %s failed: %v\nOutput: %s", strings.Join(args, " "), err, string(output))
	}
	return nil
}
