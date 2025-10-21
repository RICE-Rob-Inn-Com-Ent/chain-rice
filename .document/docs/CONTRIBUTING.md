# 🤝 Contributing to Rice-Mono

Thank you for your interest in contributing to Rice-Mono! This document provides guidelines and instructions for contributing to our enterprise polyglot monorepo.

---

## 📋 Table of Contents

- [Getting Started](#-getting-started)
- [Development Workflow](#-development-workflow)
- [Code Standards](#-code-standards)
- [Testing Requirements](#-testing-requirements)
- [Pull Request Process](#-pull-request-process)
- [Documentation Guidelines](#-documentation-guidelines)

---

## 🚀 Getting Started

### Prerequisites

1. **Bazel** - Build system

   ```bash
   # Install Bazel
   # See: https://bazel.build/install

   # Verify installation
   bazel version
   ```

2. **Language-Specific Tools**

   See the relevant helper guides:

   - Python: [helpers/PYTHON.md](../helpers/PYTHON.md)
   - Rust: [helpers/RUST.md](../helpers/RUST.md)
   - Node.js: [helpers/NODE.md](../helpers/NODE.md)
   - Others: Check [../helpers/](../helpers/)

3. **Git**

   ```bash
   git --version
   ```

### Initial Setup

1. **Fork and Clone**

   ```bash
   git clone https://github.com/your-username/rice-mono.git
   cd rice-mono
   ```

2. **Verify Setup**

   ```bash
   # Build everything
   bazel build //...

   # Run tests
   bazel test //...
   ```

---

## 🔄 Development Workflow

### Branch Strategy

````text
main (production)
  ↑
develop (integration)
  ↑
feature/* (development)
hotfix/* (emergency fixes)
release/* (release preparation)
```text

- **main**: Production-ready code (protected)
- **develop**: Integration branch for features
- **feature/\***: New feature development
- **fix/\***: Bug fixes
- **hotfix/\***: Emergency production fixes
- **docs/\***: Documentation updates

### Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>): <subject>

[optional body]

[optional footer]
````

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes
- `build`: Build system changes

**Scopes:**

- `backend`: Backend services
- `bots`: Python bots
- `frontend`: Frontend applications
- `proto`: Protocol buffers
- `infra`: Infrastructure
- `docs`: Documentation
- `bazel`: Build system

**Examples:**

```bash
feat(backend): add user authentication endpoint
fix(bots): resolve OpenAI API timeout issue
docs(helpers): update Python guide
refactor(frontend): improve component structure
```

### Development Process

1. **Create Feature Branch**

   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

1. **Make Changes**

   - Follow code standards (see below)
   - Write tests for new code
   - Update documentation as needed

1. **Test Changes**

   ```bash
   # Run all tests
   bazel test //...

   # Run specific component tests
   bazel test //bots/...
   bazel test //backend/contract/rust/...

   # Language-specific tests
   cd bots/ && poetry run pytest
   cd backend/contract/rust/ && cargo test
   ```

1. **Commit Changes**

   ```bash
   git add .
   git commit -m "feat(scope): your changes"
   ```

1. **Push and Create PR**

   ```bash
   git push origin feature/your-feature-name
   ```

   Then create a Pull Request on GitHub

---

## 📝 Code Standards

### General Principles

1. **Clarity over cleverness** - Write clear, readable code
2. **Test coverage** - Write tests for new features
3. **Documentation** - Document public APIs and complex logic
4. **Type safety** - Use type systems where available
5. **Error handling** - Handle errors gracefully

### Python (Bots)

- Follow [PEP 8](https://pep8.org/)
- Use type hints
- Use `ruff` for linting
- Use `black` for formatting
- See [helpers/PYTHON.md](../helpers/PYTHON.md)

```python
from typing import Optional

def process_data(data: dict, option: Optional[str] = None) -> dict:
    """Process data with optional configuration.

    Args:
        data: Input data dictionary
        option: Optional processing option

    Returns:
        Processed data dictionary
    """
    # Implementation
    return processed_data
```

### Rust (Backend/Contracts)

- Follow official [Rust style guide](https://doc.rust-lang.org/1.0.0/style/)
- Use `cargo fmt` for formatting
- Use `cargo clippy` for linting
- Add doc comments for public APIs
- See [helpers/RUST.md](../helpers/RUST.md)

```rust
/// Process transaction data.
///
/// # Arguments
/// * `data` - Transaction data
/// * `validate` - Whether to validate before processing
///
/// # Returns
/// Result with processed transaction or error
pub fn process_transaction(
    data: TransactionData,
    validate: bool,
) -> Result<ProcessedTx, Error> {
    // Implementation
}
```

### TypeScript/JavaScript (Frontend)

- Follow [Airbnb style guide](https://github.com/airbnb/javascript)
- Use ESLint for linting
- Use Prettier for formatting
- Use TypeScript for type safety
- See [helpers/NODE.md](../helpers/NODE.md)

```typescript
interface User {
  id: string;
  name: string;
  email: string;
}

/**
 * Fetch user by ID
 * @param id - User ID
 * @returns User object or null
 */
async function fetchUser(id: string): Promise<User | null> {
  // Implementation
}
```

### Solidity (Smart Contracts)

- Follow [Solidity style guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- Use Hardhat for testing
- Add NatSpec comments
- Security first approach
- See [helpers/SOLIDITY.md](../helpers/SOLIDITY.md)

```solidity
/// @notice Process token transfer
/// @param to Recipient address
/// @param amount Transfer amount
/// @return success Whether transfer succeeded
function transfer(
    address to,
    uint256 amount
) public returns (bool success) {
    // Implementation
}
```

### Protocol Buffers

- Use proto3 syntax
- Add comments to all messages and fields
- Follow naming conventions
- Version packages (v1, v2)
- See [helpers/PROTO.md](../helpers/PROTO.md)

```protobuf
syntax = "proto3";

package rice.auth.v1;

// User authentication request
message LoginRequest {
  // User email address
  string email = 1;

  // User password
  string password = 2;
}
```

---

## 🧪 Testing Requirements

### Unit Tests

All new features must include unit tests:

```bash
# Python
cd bots/
poetry run pytest

# Rust
cd backend/contract/rust/
cargo test

# Node.js
cd frontend/node/
npm test

# Solidity
cd backend/contract/solidity/
npx hardhat test
```

### Integration Tests

Complex features should include integration tests:

```bash
# Python integration tests
poetry run pytest integration/

# Backend integration tests
bazel test //backend/...
```

### Coverage Requirements

- **Unit tests**: > 80% coverage for new code
- **Critical paths**: 100% coverage
- **Bug fixes**: Must include regression tests

### Running Tests

```bash
# All tests
bazel test //...

# Specific component
bazel test //bots/...
bazel test //backend/contract/rust/...

# With coverage
cd bots/ && poetry run pytest --cov

# CI mode
bazel test --config=ci //...
```

---

## 🔀 Pull Request Process

### Before Submitting

1. **Run Tests**

   ```bash
   bazel test //...
   ```

1. **Format Code**

   ```bash
   # Python
   cd bots/ && poetry run black .

   # Rust
   cd backend/contract/rust/ && cargo fmt

   # Node.js
   cd frontend/node/ && npm run format
   ```

1. **Lint Code**

   ```bash
   # Python
   poetry run ruff check .

   # Rust
   cargo clippy

   # Node.js
   npm run lint
   ```

1. **Update Documentation**

   - Update relevant helper guides
   - Add/update code comments
   - Update CHANGELOG.md if needed

### PR Requirements

1. **Title**: Use conventional commit format
2. **Description**: Explain what and why
3. **Tests**: All tests must pass
4. **Documentation**: Update relevant docs
5. **Breaking Changes**: Clearly marked and explained
6. **Review**: Address reviewer comments

### PR Template

```markdown
## Description

Brief description of changes and motivation

## Type of Change

- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to break)
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement

## Testing

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Added tests for new features

## Documentation

- [ ] Updated relevant helper guides
- [ ] Added code comments
- [ ] Updated CHANGELOG.md
- [ ] Added/updated README sections

## Breaking Changes

- [ ] No breaking changes
- [ ] Breaking changes (describe below)

## Additional Notes

Any additional context for reviewers

## Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests added/updated
- [ ] All tests pass
```

---

## 📚 Documentation Guidelines

### Helper Guides

When updating helper guides in `helpers/`:

1. **Consistency**: Follow existing format
2. **Examples**: Include working code examples
3. **Commands**: Test all command examples
4. **Links**: Verify all links work

### Code Documentation

- **Python**: Use docstrings
- **Rust**: Use doc comments (`///`)
- **TypeScript**: Use JSDoc comments
- **Solidity**: Use NatSpec comments

### README Updates

Update the main README.md when:

- Adding new major features
- Changing project structure
- Updating technology stack

---

## 🐛 Bug Reports

### Before Reporting

1. Check existing issues
2. Use latest version
3. Create minimal reproduction case

### Bug Report Template

`````markdown
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

- OS: [e.g., Ubuntu 22.04]
- Bazel version: [e.g., 7.0.0]
- Language version: [e.g., Python 3.11]

## Additional Context

Any other relevant information

````text

---

## 💡 Feature Requests

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
```text

---

## 🏆 Recognition

Contributors are recognized in:

- README.md contributors section
- Release notes
- Documentation credits

---

## 📞 Getting Help

- **Build issues**: Check [helpers/BAZEL.md](../helpers/BAZEL.md)
- **Language-specific**: Check relevant helper guide
- **Questions**: Open a GitHub Discussion
- **Bugs**: Open a GitHub Issue

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

## Code of Conduct

Please read our [CODE_OF_CONDUCT](CODE_OF_CONDUCT) before contributing.

---

**Thank you for contributing to Rice-Mono!** 🚀

For detailed development guides, see the [helpers/](../helpers/) directory.
