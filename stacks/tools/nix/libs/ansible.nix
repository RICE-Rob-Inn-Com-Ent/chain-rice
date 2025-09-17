{ pkgs }:

{
  packages = with pkgs; [
    # Ansible core
    ansible
    ansible-core
    ansible-lint
    
    # Ansible collections and utilities
    ansible-navigator
    
    # Python packages for Ansible
    python3Packages.ansible
    python3Packages.paramiko  # SSH connections
    python3Packages.jinja2    # Templating
    python3Packages.pyyaml    # YAML parsing
    python3Packages.netaddr   # Network address manipulation
    python3Packages.dnspython # DNS lookups
    
    # Infrastructure tools commonly used with Ansible
    openssh
    sshpass  # Password-based SSH (for initial setup)
    
    # Cloud provider tools
    python3Packages.boto3     # AWS SDK
    python3Packages.azure-mgmt-core  # Azure SDK
    python3Packages.google-cloud-storage  # GCP SDK
    
    # Container and orchestration
    kubectl
    kubernetes-helm
    
    # Monitoring and logging
    python3Packages.prometheus-client
    
    # Text processing and utilities
    jq
    yq
    gnused
    gnugrep
    
    # File and archive handling
    rsync
    unzip
    tar
    gzip
    
    # Network utilities
    curl
    wget
    netcat
    nmap
    
    # System utilities
    htop
    tree
    git
  ];
  
  envVars = {
    # Ansible configuration
    ANSIBLE_CONFIG = "$PWD/infrastructure/ansible/ansible.cfg";
    ANSIBLE_INVENTORY = "$PWD/infrastructure/ansible/inventory";
    ANSIBLE_ROLES_PATH = "$PWD/infrastructure/ansible/roles";
    ANSIBLE_COLLECTIONS_PATH = "$PWD/infrastructure/ansible/collections";
    
    # Ansible behavior
    ANSIBLE_HOST_KEY_CHECKING = "False";  # For development
    ANSIBLE_STDOUT_CALLBACK = "yaml";
    ANSIBLE_GATHER_FACTS = "smart";
    ANSIBLE_TIMEOUT = "30";
    
    # ChainRice specific Ansible settings
    CHAINRICE_ANSIBLE_ROOT = "$PWD/infrastructure/ansible";
    ANSIBLE_VAULT_PASSWORD_FILE = "$PWD/infrastructure/ansible/.vault_pass";
    
    # SSH configuration
    ANSIBLE_SSH_PIPELINING = "True";
    ANSIBLE_SSH_CONTROL_PATH = "/tmp/ansible-ssh-%%h-%%p-%%r";
    
    # Performance settings
    ANSIBLE_FORKS = "10";
    ANSIBLE_POLL_INTERVAL = "2";
    
    # Logging
    ANSIBLE_LOG_PATH = "$PWD/infrastructure/ansible/ansible.log";
    
    # Python interpreter
    ANSIBLE_PYTHON_INTERPRETER = "auto_silent";
    
    # Development settings
    ANSIBLE_DISPLAY_SKIPPED_HOSTS = "False";
    ANSIBLE_DISPLAY_OK_HOSTS = "False";
  };
  
  shellHook = ''
    echo "🤖 Ansible ${pkgs.ansible.version} with automation tools"
    echo "   • Ansible Lint for playbook validation"
    echo "   • Cloud provider SDKs included"
    echo "   • SSH and networking tools ready"
    echo "   • Kubernetes integration available"
    
    # Create Ansible directory structure if it doesn't exist
    mkdir -p infrastructure/ansible/{playbooks,roles,group_vars,host_vars,collections,inventory}
    
    # Check for Ansible configuration
    if [ -f "infrastructure/ansible/ansible.cfg" ]; then
      echo "📁 Ansible configuration found"
    else
      echo "📝 Creating basic Ansible configuration..."
      cat > infrastructure/ansible/ansible.cfg << EOF
[defaults]
inventory = inventory
roles_path = roles
collections_path = collections
host_key_checking = False
stdout_callback = yaml
gathering = smart
timeout = 30
forks = 10

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
EOF
    fi
    
    # Create basic inventory if it doesn't exist
    if [ ! -f "infrastructure/ansible/inventory/hosts.yml" ]; then
      echo "📋 Creating basic inventory structure..."
      mkdir -p infrastructure/ansible/inventory
      cat > infrastructure/ansible/inventory/hosts.yml << EOF
all:
  children:
    chainrice:
      children:
        blockchain:
          hosts:
            blockchain-node-1:
              ansible_host: localhost
              ansible_port: 22
        api:
          hosts:
            api-server-1:
              ansible_host: localhost
              ansible_port: 22
        frontend:
          hosts:
            frontend-server-1:
              ansible_host: localhost
              ansible_port: 22
EOF
    fi
    
    # Install Ansible collections if requirements file exists
    if [ -f "infrastructure/ansible/requirements.yml" ]; then
      echo "📦 Installing Ansible collections..."
      ansible-galaxy collection install -r infrastructure/ansible/requirements.yml
    fi
    
    # Aliases for common Ansible operations
    alias ap='ansible-playbook'
    alias a='ansible'
    alias ai='ansible-inventory'
    alias av='ansible-vault'
    alias al='ansible-lint'
    alias ag='ansible-galaxy'
    alias ac='ansible-config'
    alias ad='ansible-doc'
    
    # ChainRice specific aliases
    alias chainrice-deploy='ansible-playbook infrastructure/ansible/playbooks/deploy.yml'
    alias chainrice-setup='ansible-playbook infrastructure/ansible/playbooks/setup.yml'
    alias chainrice-status='ansible all -m ping'
  '';
}
