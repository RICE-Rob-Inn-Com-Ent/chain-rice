# 🎭 Ansible Automation Guide

Complete guide for using Ansible automation in the Rice-Mono project.

## 📋 Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [Playbooks](#playbooks)
- [Roles](#roles)
- [Inventory Management](#inventory-management)
- [Variables](#variables)
- [Common Tasks](#common-tasks)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

Our Ansible setup provides:

- **Infrastructure Automation** - Server provisioning and configuration
- **Application Deployment** - Automated app deployment workflows
- **Configuration Management** - Centralized configuration control
- **Security Hardening** - Automated security best practices
- **Multi-Environment Support** - Dev, Staging, Production

---

## 📁 Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── playbooks/              # Automation playbooks
│   ├── site.yml           # Master playbook
│   ├── prepare-systems.yml
│   ├── setup-kubernetes.yml
│   ├── deploy-applications.yml
│   └── health-check.yml
├── roles/                  # Reusable roles
│   ├── common/
│   ├── docker/
│   ├── kubernetes/
│   └── monitoring/
├── inventory/             # Environment inventories
│   ├── dev/
│   ├── staging/
│   └── prod/
├── group_vars/           # Group variables
│   ├── all.yml
│   ├── web.yml
│   ├── database.yml
│   └── kubernetes.yml
├── host_vars/           # Host-specific variables
├── templates/           # Jinja2 templates
└── requirements.yml     # Ansible dependencies
```

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd ansible
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install kubernetes.core
```

### 2. Configure Inventory

Edit inventory files for your environment:

```bash
vim inventory/dev/hosts.yml
```

### 3. Run Playbooks

```bash
# Deploy everything
ansible-playbook playbooks/site.yml -i inventory/dev/

# Deploy specific component
ansible-playbook playbooks/setup-kubernetes.yml -i inventory/dev/

# Dry run (check mode)
ansible-playbook playbooks/site.yml -i inventory/dev/ --check
```

---

## 📚 Playbooks

### Master Playbook (site.yml)

Orchestrates the entire infrastructure deployment:

```bash
ansible-playbook playbooks/site.yml -i inventory/dev/
```

### Available Playbooks

| Playbook                   | Description            | Tags            |
| -------------------------- | ---------------------- | --------------- |
| `site.yml`                 | Master playbook (all)  | all             |
| `prepare-systems.yml`      | System preparation     | prepare, base   |
| `security-hardening.yml`   | Security configuration | security        |
| `install-docker.yml`       | Docker installation    | docker          |
| `setup-kubernetes.yml`     | K8s cluster setup      | kubernetes, k8s |
| `deploy-database.yml`      | Database deployment    | database, db    |
| `configure-webservers.yml` | Web server config      | web, nginx      |
| `setup-cache.yml`          | Cache layer setup      | cache, redis    |
| `deploy-monitoring.yml`    | Monitoring stack       | monitoring      |
| `deploy-applications.yml`  | App deployment         | app, deploy     |
| `health-check.yml`         | System health check    | health          |

### Using Tags

Run specific parts of playbooks:

```bash
# Only security tasks
ansible-playbook playbooks/site.yml --tags security

# Skip monitoring
ansible-playbook playbooks/site.yml --skip-tags monitoring

# Multiple tags
ansible-playbook playbooks/site.yml --tags "prepare,docker,k8s"
```

---

## 🎭 Roles

Reusable Ansible roles for common tasks.

### Available Roles

#### Common Role

Base system configuration:

```bash
ansible-playbook -i inventory/dev/ playbooks/prepare-systems.yml
```

#### Docker Role

Docker installation and configuration:

```bash
ansible-playbook -i inventory/dev/ playbooks/install-docker.yml
```

#### Kubernetes Role

Complete K8s cluster setup:

```bash
ansible-playbook -i inventory/dev/ playbooks/setup-kubernetes.yml
```

### Creating New Roles

```bash
# Initialize new role
ansible-galaxy init roles/my-role

# Role structure
roles/my-role/
├── defaults/        # Default variables
├── files/          # Static files
├── handlers/       # Event handlers
├── meta/           # Role metadata
├── tasks/          # Main tasks
├── templates/      # Jinja2 templates
├── tests/          # Test playbooks
└── vars/           # Role variables
```

---

## 📦 Inventory Management

### Dynamic vs Static

**Static Inventory** (current):

```yaml
# inventory/dev/hosts.yml
all:
  children:
    web:
      hosts:
        web01.dev.rice-mono.local:
          ansible_host: 10.0.1.10
```

**Dynamic Inventory** (AWS example):

```bash
# Use AWS EC2 plugin
ansible-playbook -i aws_ec2.yml playbooks/site.yml
```

### Inventory Patterns

```bash
# All hosts
ansible all -m ping

# Specific group
ansible web -m ping

# Pattern matching
ansible 'web*' -m ping

# Multiple groups
ansible 'web:database' -m ping

# Exclude hosts
ansible 'all:!database' -m ping

# Intersection
ansible 'web:&dev' -m ping
```

### Environment-Specific Inventories

```bash
# Development
ansible-playbook playbooks/site.yml -i inventory/dev/

# Staging
ansible-playbook playbooks/site.yml -i inventory/staging/

# Production
ansible-playbook playbooks/site.yml -i inventory/prod/
```

---

## 🔧 Variables

### Variable Precedence (Low to High)

1. Role defaults (`roles/*/defaults/main.yml`)
2. Inventory file/group vars
3. Inventory group_vars
4. Inventory host_vars
5. Playbook group_vars
6. Playbook host_vars
7. Host facts
8. Registered variables
9. Set_facts
10. Play vars
11. Play vars_prompt
12. Play vars_files
13. Role vars
14. Block vars
15. Task vars
16. Extra vars (`-e`)

### Using Variables

**In Playbooks:**

```yaml
- name: Use variable
  debug:
    msg: "Environment is {{ environment }}"
```

**In Templates:**

```jinja2
# templates/config.j2
server_name: {{ domain }}
port: {{ app_port }}
```

**Command Line:**

```bash
ansible-playbook playbooks/site.yml -e "environment=prod"
```

### Encrypting Secrets

```bash
# Create encrypted file
ansible-vault create group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml

# Run playbook with vault
ansible-playbook playbooks/site.yml --ask-vault-pass

# Use vault password file
ansible-playbook playbooks/site.yml --vault-password-file ~/.vault_pass
```

---

## 📝 Common Tasks

### Deploy New Application

```bash
# Full deployment
ansible-playbook playbooks/deploy-applications.yml -i inventory/dev/

# Specific app
ansible-playbook playbooks/deploy-applications.yml -i inventory/dev/ -e "app_name=backend"

# With version
ansible-playbook playbooks/deploy-applications.yml -i inventory/dev/ -e "backend_version=v1.2.3"
```

### Update Configuration

```bash
# Update web servers
ansible-playbook playbooks/configure-webservers.yml -i inventory/dev/

# Specific host
ansible-playbook playbooks/configure-webservers.yml -i inventory/dev/ --limit web01
```

### Run Ad-Hoc Commands

```bash
# Check connectivity
ansible all -i inventory/dev/ -m ping

# Run command
ansible web -i inventory/dev/ -m command -a "uptime"

# Install package
ansible all -i inventory/dev/ -m apt -a "name=htop state=present" --become

# Copy file
ansible all -i inventory/dev/ -m copy -a "src=/local/file dest=/remote/file"

# Service management
ansible web -i inventory/dev/ -m service -a "name=nginx state=restarted" --become
```

### Gather Facts

```bash
# Gather all facts
ansible all -i inventory/dev/ -m setup

# Specific facts
ansible all -i inventory/dev/ -m setup -a "filter=ansible_distribution*"

# Save facts to file
ansible all -i inventory/dev/ -m setup --tree /tmp/facts
```

---

## ✅ Best Practices

### 1. Idempotency

Always write idempotent playbooks:

```yaml
# ✅ Good - Idempotent
- name: Ensure nginx is installed
  apt:
    name: nginx
    state: present

# ❌ Bad - Not idempotent
- name: Install nginx
  command: apt-get install nginx
```

### 2. Use Roles

Organize tasks into reusable roles:

```yaml
# ✅ Good
- name: Configure web server
  include_role:
    name: nginx

# ❌ Bad
- name: Configure web server
  # 50 tasks here...
```

### 3. Variable Organization

Keep variables organized and documented:

```yaml
# group_vars/web.yml
---
# Nginx Configuration
nginx_worker_processes: auto
nginx_worker_connections: 4096

# Application
app_port: 8080
app_workers: 4
```

### 4. Error Handling

Handle errors gracefully:

```yaml
- name: Task that might fail
  command: /bin/might-fail
  register: result
  ignore_errors: true

- name: Handle failure
  debug:
    msg: "Previous task failed"
  when: result.failed
```

### 5. Testing

Always test before production:

```bash
# Dry run
ansible-playbook playbooks/site.yml --check

# Limit to test host
ansible-playbook playbooks/site.yml --limit test-server

# Verbose output
ansible-playbook playbooks/site.yml -vvv
```

---

## 🔍 Troubleshooting

### Debug Mode

```bash
# Verbose output
ansible-playbook playbooks/site.yml -v    # Basic
ansible-playbook playbooks/site.yml -vv   # More verbose
ansible-playbook playbooks/site.yml -vvv  # Very verbose
ansible-playbook playbooks/site.yml -vvvv # Connection debug
```

### Common Issues

#### SSH Connection Issues

```bash
# Test SSH connection
ansible all -i inventory/dev/ -m ping

# Use specific key
ansible all -i inventory/dev/ -m ping --private-key ~/.ssh/custom_key

# Ignore host key checking
export ANSIBLE_HOST_KEY_CHECKING=False
```

#### Permission Denied

```bash
# Use sudo
ansible-playbook playbooks/site.yml --become

# Specify sudo user
ansible-playbook playbooks/site.yml --become --become-user=root

# Ask for sudo password
ansible-playbook playbooks/site.yml --become --ask-become-pass
```

#### Module Not Found

```bash
# Install missing collection
ansible-galaxy collection install kubernetes.core

# Install from requirements
ansible-galaxy install -r requirements.yml --force
```

#### Variable Not Defined

```yaml
# Use default filter
- name: Use variable with default
  debug:
    msg: "{{ my_var | default('fallback_value') }}"

# Check if defined
- name: Only run if defined
  debug:
    msg: "{{ my_var }}"
  when: my_var is defined
```

### Debug Tasks

Add debug tasks to troubleshoot:

```yaml
- name: Debug variables
  debug:
    var: hostvars[inventory_hostname]

- name: Debug with message
  debug:
    msg: "Value is {{ my_var }}"

- name: Pause for inspection
  pause:
    prompt: "Check the system state. Press enter to continue"
```

---

## 📚 Additional Resources

### Documentation

- [Ansible Official Docs](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Best Practices Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

### Useful Commands Reference

```bash
# Check syntax
ansible-playbook playbooks/site.yml --syntax-check

# List hosts
ansible-playbook playbooks/site.yml --list-hosts

# List tasks
ansible-playbook playbooks/site.yml --list-tasks

# List tags
ansible-playbook playbooks/site.yml --list-tags

# Start at task
ansible-playbook playbooks/site.yml --start-at-task="Install Docker"

# Step through playbook
ansible-playbook playbooks/site.yml --step
```

---

## 🤝 Contributing

When creating new playbooks:

1. Follow naming convention: `verb-noun.yml`
2. Add appropriate tags
3. Include documentation header
4. Test in dev environment first
5. Update this documentation

---

**For support, see the [main README](../README.md) or contact the DevOps team.**
