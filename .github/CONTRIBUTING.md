# 🤝 Contributing to rice-dev

## Guidelines for contributing to the rice-dev unified development environment

## 📋 Table of Contents

- [Getting Started](#-getting-started)
- [Development Workflow](#-development-workflow)
- [Code Standards](#-code-standards)
- [Testing Requirements](#-testing-requirements)
- [Pull Request Process](#-pull-request-process)
- [Environment Guidelines](#-environment-guidelines)
- [Documentation Standards](#-documentation-standards)

## 🚀 Getting Started

### Prerequisites

1. **Nix Package Manager**

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://nixos.org/nix/install | sh
   source ~/.nix-profile/etc/profile.d/nix.sh
   ```

2. **Git**

   ```bash
   git --version
   ```

3. **Bazel** (optional, managed by Nix)

   ```bash
   nix develop .#bazel-dev
   ```

### Initial Setup

1. **Fork and Clone**

   ```bash
   git clone https://github.com/your-username/rice-dev.git
   cd rice-dev
   ```

2. **Enter Development Environment**

   ```bash
   nix develop
   ```

3. **Verify Setup**

   ```bash
   ./test_nix_integration.sh
   ```

## 🔄 Development Workflow

### Branch Strategy

- **main**: Production-ready code
- **development**: Integration branch
- **feature/\***: New features
- **fix/\***: Bug fixes
- **docs/\***: Documentation updates

### Commit Convention

Use conventional commits format:

```text
type(scope): description

[optional body]

[optional footer]
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

**Examples:**

```text
feat(go): add Cosmos SDK integration
fix(python): resolve FastAPI dependency conflict
docs(readme): update quick start guide
```

### Development Process

1. **Create Feature Branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**

   - Follow code standards
   - Update tests
   - Update documentation

3. **Test Changes**

   ```bash
   ./test_nix_integration.sh
   bazel test //...
   ```

4. **Commit Changes**

   ```bash
   git add .
   git commit -m "feat(scope): your changes"
   ```

5. **Push and Create PR**

   ```bash
   git push origin feature/your-feature-name
   ```

## 📝 Code Standards

### Nix Configuration

- **flake.nix**: Use consistent naming for shells
- **Dependencies**: Pin specific versions when possible
- **Documentation**: Add comments for complex configurations

```nix
# Example shell definition
go-backend = pkgs.mkShell {
  name = "go-backend";
  buildInputs = with pkgs; [
    go
    gopls
    gotools
    # ... other dependencies
  ];
  shellHook = ''
    echo "🚀 Go backend development environment"
    go version
  '';
};
```

### Bazel Rules

- **File Naming**: Use descriptive names (`go_toolchain.bzl`)
- **Function Naming**: Use snake_case
- **Documentation**: Add docstrings for all functions

```python
def _nix_go_toolchain_impl(ctx):
    """Implementation for nix_go_toolchain rule.

    Creates a Bazel rule that provides Go toolchain from Nix shell.
    """
    # Implementation details...
```

### Shell Scripts

- **Shebang**: Always use `#!/usr/bin/env bash`
- **Error Handling**: Use `set -euo pipefail`
- **Documentation**: Add comments for complex logic

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script description
echo "Starting integration test..."
```

## 🧪 Testing Requirements

### Automated Testing

All changes must pass:

1. **Integration Test**

   ```bash
   ./test_nix_integration.sh
   ```

2. **Bazel Tests**

   ```bash
   bazel test //...
   ```

3. **Shell Validation**

   ```bash
   # Test each shell
   nix develop .#shell-name --command echo "Shell works"
   ```

### Manual Testing

- **New Shells**: Test all functionality
- **Dependencies**: Verify package availability
- **Integration**: Test Bazel integration
- **Documentation**: Verify all links work

### Test Coverage

- **New Features**: Must include tests
- **Bug Fixes**: Must include regression tests
- **Documentation**: Must be tested for accuracy

## 🔀 Pull Request Process

### Before Submitting

1. **Run Tests**

   ```bash
   ./test_nix_integration.sh
   bazel test //...
   ```

2. **Check Documentation**

   - Update README.md if needed
   - Update ARCHITECTURE.md if needed
   - Update CONTRIBUTING.md if needed

3. **Code Review**
   - Self-review your changes
   - Check for typos
   - Verify functionality

### PR Requirements

1. **Title**: Use conventional commit format
2. **Description**: Explain what and why
3. **Tests**: All tests must pass
4. **Documentation**: Update if needed
5. **Breaking Changes**: Clearly mark and explain

### PR Template

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (please describe)

## Testing

- [ ] Integration tests pass
- [ ] Bazel tests pass
- [ ] Manual testing completed
- [ ] Documentation updated

## Breaking Changes

- [ ] No breaking changes
- [ ] Breaking changes (explain below)

## Additional Notes

Any additional information for reviewers
```

## 🌍 Environment Guidelines

### Adding New Development Environments

1. **Update flake.nix**

   ```nix
   new-environment = pkgs.mkShell {
     name = "new-environment";
     buildInputs = with pkgs; [
       # Add dependencies
     ];
     shellHook = ''
       echo "🚀 New environment ready"
     '';
   };
   ```

2. **Update Documentation**

   - Add to README.md
   - Add to ARCHITECTURE.md
   - Update test script

3. **Test Integration**

   ```bash
   nix develop .#new-environment
   ./test_nix_integration.sh
   ```

### Modifying Existing Environments

1. **Backward Compatibility**: Maintain existing functionality
2. **Documentation**: Update relevant docs
3. **Testing**: Verify all existing tests pass
4. **Migration**: Provide migration guide if needed

### Dependency Management

- **Version Pinning**: Pin specific versions when possible
- **Security**: Keep dependencies updated
- **Compatibility**: Test with different versions
- **Documentation**: Document version requirements

## 📚 Documentation Standards

### README.md

- **Quick Start**: Clear, step-by-step instructions
- **Examples**: Working code examples
- **Troubleshooting**: Common issues and solutions
- **Links**: Working links to other docs

### ARCHITECTURE.md

- **Overview**: High-level architecture
- **Components**: Detailed component descriptions
- **Diagrams**: Visual representations where helpful
- **Technical Details**: Implementation specifics

### CONTRIBUTING.md

- **Process**: Clear contribution process
- **Standards**: Code and documentation standards
- **Examples**: Code examples for standards
- **Templates**: PR and issue templates

### Code Documentation

- **Functions**: Docstrings for all functions
- **Complex Logic**: Inline comments
- **Examples**: Usage examples where helpful
- **API**: Document all public APIs

## 🐛 Bug Reports

### Before Reporting

1. **Check Issues**: Search existing issues
2. **Test Latest**: Use latest version
3. **Reproduce**: Create minimal reproduction case

### Bug Report Template

```markdown
## Bug Description

Clear description of the bug

## Steps to Reproduce

1. Step one
2. Step two
3. Step three

## Expected Behavior

What should happen

## Actual Behavior

What actually happens

## Environment

- OS: [e.g., Ubuntu 20.04]
- Nix version: [e.g., 2.31.2]
- Shell: [e.g., bash]

## Additional Context

Any other relevant information
```

## 💡 Feature Requests

### Before Requesting

1. **Check Roadmap**: Review existing roadmap
2. **Search Issues**: Check for similar requests
3. **Consider Alternatives**: Are there workarounds?

### Feature Request Template

```markdown
## Feature Description

Clear description of the feature

## Use Case

Why is this feature needed?

## Proposed Solution

How should this feature work?

## Alternatives Considered

What other approaches were considered?

## Additional Context

Any other relevant information
```

## 🏆 Recognition

Contributors will be recognized in:

- **README.md**: Contributors section
- **Release Notes**: Feature acknowledgments
- **Documentation**: Credit for significant contributions

## 📞 Getting Help

- **Issues**: GitHub Issues for bugs and features
- **Discussions**: GitHub Discussions for questions
- **Documentation**: Check existing documentation first
- **Community**: Join our community channels

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

## Thank you for contributing to rice-dev! 🚀
