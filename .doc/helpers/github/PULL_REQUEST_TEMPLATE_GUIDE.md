# 🔀 Pull Request Template Guide

> Complete guide to creating excellent pull requests in Rice Monorepo

---

## 📋 Table of Contents

- [Overview](#overview)
- [PR Template Structure](#pr-template-structure)
- [Section-by-Section Guide](#section-by-section-guide)
- [PR Best Practices](#pr-best-practices)
- [Example Pull Requests](#example-pull-requests)
- [Review Process](#review-process)
- [Common Mistakes](#common-mistakes)
- [For Reviewers](#for-reviewers)

---

## 🎯 Overview

A well-written pull request makes code review faster, easier, and more effective. Our PR template ensures all necessary
information is captured consistently.

**Benefits:**

- ✅ Faster review cycles
- ✅ Fewer clarification questions
- ✅ Better code quality
- ✅ Clear change history
- ✅ Easier troubleshooting later

**Official Documentation**:
[About pull request templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)

---

## 📝 PR Template Structure

Our template has 10 main sections:

1. **Description** - What & why
2. **Type of Change** - Classification
3. **Component(s) Affected** - Scope
4. **Testing** - Verification
5. **Checklist** - Quality gates
6. **Breaking Changes** - API changes
7. **Performance Impact** - Metrics
8. **Security Considerations** - Safety
9. **Deployment Notes** - Operations
10. **Additional Context** - Extras

---

## 📖 Section-by-Section Guide

### 1. Description

#### What does this PR do?

**Purpose**: One-sentence summary

**Good Examples:**

```markdown
Adds real-time WebSocket notifications to the backend service
```

```markdown
Fixes database connection pool exhaustion under high load
```

```markdown
Refactors authentication middleware for better testability
```

**Bad Examples:**

```markdown
Various fixes and improvements Updates Changes
```

#### Why is this change needed?

**Purpose**: Provide context and motivation

**Good Example:**

```markdown
Users currently have to manually refresh to see new notifications, resulting in poor UX and delayed response times. This
implements real-time push notifications via WebSockets, reducing notification latency from 30s (polling interval) to <
1s.
```

**Bad Example:**

```markdown
Because it's better To improve things
```

#### Related Issues

**Purpose**: Link to context

**Format:**

```markdown
- Fixes #123
- Closes #456
- Related to #789
```

**Why Link Issues?**

- ✅ Closes issues automatically on merge
- ✅ Provides full context
- ✅ Creates audit trail
- ✅ Helps with release notes

---

### 2. Type of Change

**Purpose**: Classify the PR for changelog generation

**Categories:**

#### 🐛 Bug Fix

Non-breaking change that fixes an issue

**Example:** Fixing database connection leak

#### ✨ New Feature

Non-breaking change that adds functionality

**Example:** Adding OAuth authentication

#### 💥 Breaking Change

Fix or feature that breaks existing functionality

**Example:** Changing API response format

#### 📝 Documentation

Changes to documentation only

**Example:** Updating API docs

#### 🎨 Style

Formatting, no code logic change

**Example:** Running prettier on codebase

#### ♻️ Refactor

Code change that neither fixes bug nor adds feature

**Example:** Extracting common logic into utility

#### ⚡ Performance

Code change that improves performance

**Example:** Optimizing database queries

#### ✅ Test

Adding or updating tests

**Example:** Adding integration tests

#### 🔧 Chore

Updating build tasks, configs, etc.

**Example:** Updating dependencies

#### 🔒 Security

Security-related improvements or fixes

**Example:** Fixing XSS vulnerability

**Semantic Versioning Impact:**

```
🐛 Bug Fix          → Patch (1.0.x)
✨ New Feature      → Minor (1.x.0)
💥 Breaking Change  → Major (x.0.0)
📝 Documentation    → No version bump
🎨 Style            → No version bump
```

---

### 3. Component(s) Affected

**Purpose**: Identify scope for code owners and reviewers

**Mark all that apply:**

```markdown
- [x] Backend - Database Service (Go)
- [x] Backend - Token Chain (Go/Cosmos)
- [ ] Backend - Rust Smart Contracts
- [ ] Backend - Solidity Smart Contracts
- [ ] Frontend - Web (TypeScript)
```

**Why This Matters:**

- Routes to correct reviewers
- Helps with release notes
- Identifies integration points
- Informs testing requirements

---

### 4. Testing

#### How has this been tested?

**Purpose**: Demonstrate due diligence

**Good Example:**

```markdown
- [x] Unit tests - Added 15 new tests, all pass
- [x] Integration tests - Tested with live database
- [x] E2E tests - Added Playwright test for login flow
- [x] Manual testing - Tested on Chrome, Firefox, Safari
- [ ] Load testing - Not applicable for this change
```

**Provide Specifics:**

```markdown
## Test Coverage

Unit Tests:

- ✅ TestWebSocketConnection
- ✅ TestReconnectionLogic
- ✅ TestMessageFormatting
- ✅ TestAuthenticationFlow

Integration Tests:

- ✅ TestWebSocketWithRedis
- ✅ TestMultipleConnections
- ✅ TestConnectionCleanup

Manual Testing Scenarios:

1. Connect from multiple browser tabs → ✅ All receive messages
2. Disconnect network → ✅ Auto-reconnects
3. Send 1000 rapid messages → ✅ No message loss
4. Connect 100 concurrent clients → ✅ Performance acceptable
```

#### Test Configuration

**Purpose**: Document test environment

**Template:**

```markdown
- **OS**: Ubuntu 22.04
- **Runtime versions**:
  - Go: 1.22.0
  - Python: 3.12.1
  - Node.js: 20.11.0
- **Browser**: Chrome 120
- **Database**: PostgreSQL 16
```

#### Test Evidence

**Purpose**: Show it works

**Include:**

````markdown
## Test Results

```bash
$ go test -v ./...
=== RUN   TestWebSocketConnection
--- PASS: TestWebSocketConnection (0.12s)
=== RUN   TestReconnection
--- PASS: TestReconnection (0.45s)
...
PASS
coverage: 87.3% of statements
```
````

## Screenshots

Before: [Image showing old behavior]

After: [Image showing new behavior]

## Video Demo

[Link to Loom/YouTube video]

````

---

### 5. Checklist

#### Code Quality

**Purpose**: Ensure basic standards

```markdown
- [x] My code follows the project's style guidelines
- [x] I have performed a self-review of my own code
- [x] I have commented my code, particularly in hard-to-understand areas
- [x] My code is formatted with the appropriate formatters
- [x] I have run linters and fixed all issues
- [x] I have removed debug code, console.logs, and commented-out code
````

**Self-Review Questions:**

- Is the code readable?
- Are variable names descriptive?
- Is the logic clear?
- Are edge cases handled?
- Is error handling appropriate?
- Are there TODO comments that should be addressed?

#### Testing

```markdown
- [x] I have added tests that prove my fix is effective or that my feature works
- [x] New and existing unit tests pass locally with my changes
- [x] All integration tests pass
- [x] I have tested on multiple environments/browsers (if applicable)
```

#### Documentation

```markdown
- [x] I have updated relevant documentation (README, API docs, architecture docs)
- [x] I have added/updated code comments where necessary
- [x] I have updated the CHANGELOG.md (if applicable)
- [x] I have added/updated examples or usage instructions
- [x] I have updated relevant OpenAPI/Swagger documentation (if applicable)
```

**Documentation Checklist:**

- README updates for new features
- API documentation for new endpoints
- Architecture docs for design changes
- Migration guides for breaking changes
- Inline code comments for complex logic
- OpenAPI/Swagger specs updated

#### Dependencies

```markdown
- [x] I have updated dependency lock files
- [x] All new dependencies are necessary and justified
- [x] I have verified that dependencies have acceptable licenses
- [x] I have checked for security vulnerabilities in dependencies
```

**Dependency Review:**

- Why is this dependency needed?
- Is there a lighter alternative?
- Is it actively maintained?
- What's the license?
- Are there known vulnerabilities?

#### Performance & Security

```markdown
- [x] My changes don't introduce performance regressions
- [x] I have considered security implications of my changes
- [x] I have not committed secrets, API keys, or sensitive information
- [x] I have sanitized user inputs and validated data
- [x] I have followed security best practices (OWASP guidelines)
```

**Security Considerations:**

- Input validation
- Output encoding
- Authentication checks
- Authorization checks
- SQL injection prevention
- XSS prevention
- CSRF protection
- Secret management

---

### 6. Breaking Changes

**Purpose**: Document API/behavior changes

**When to Fill This Section:**

- Public API changes
- Database schema changes
- Configuration format changes
- Behavior changes that affect users
- Dependency version jumps

**Template:**

````markdown
### What breaks?

The authentication API response format has changed:

Old:

```json
{
  "token": "abc123",
  "user": {...}
}
```
````

New:

```json
{
  "access_token": "abc123",
  "refresh_token": "xyz789",
  "expires_in": 3600,
  "user": {...}
}
```

### Why is this necessary?

OAuth 2.0 compliance requires specific token field names. This change makes our API compatible with standard OAuth
clients.

### Migration Guide

#### Update Client Code

Before:

```typescript
const token = response.token;
```

After:

```typescript
const token = response.access_token;
const refreshToken = response.refresh_token;
```

#### Update Tests

Update all tests that check authentication responses to use new field names.

#### Backward Compatibility

For 1 release cycle (v2.0), we'll support both formats:

- v2.0: Returns both `token` (deprecated) and `access_token`
- v2.1: Removes `token` field

### Deprecation Timeline

- v2.0 (2024-03-01): New format introduced, old format deprecated
- v2.1 (2024-06-01): Old format removed

````

---

### 7. Performance Impact

**Purpose**: Quantify performance changes

**Template:**
```markdown
## Benchmark Results

### Before
- Response time: 250ms (p50), 500ms (p95), 1200ms (p99)
- Memory usage: 150MB avg, 300MB peak
- CPU usage: 15% avg, 45% peak
- Throughput: 100 req/s

### After
- Response time: 180ms (p50), 350ms (p95), 800ms (p99)
- Memory usage: 120MB avg, 200MB peak
- CPU usage: 12% avg, 35% peak
- Throughput: 150 req/s

### Improvement
- ✅ 28% faster p50 response time
- ✅ 30% reduction in memory usage
- ✅ 50% improvement in throughput

## Load Test Results

```bash
$ k6 run load-test.js

  execution: local
    scenarios: (100.00%) 1 scenario, 100 max VUs

  checks.........................: 100.00% ✓ 50000 ✗ 0
  http_req_duration..............: avg=180ms min=45ms med=150ms max=2s p(95)=350ms
  http_reqs......................: 50000  150/s

  ✓ All performance targets met
````

````

**When to Include:**
- Algorithm changes
- Database query optimizations
- Caching additions
- Large data processing
- Network operations

**When Not Required:**
- Documentation changes
- Style/formatting changes
- Small bug fixes
- Test-only changes

---

### 8. Security Considerations

**Purpose**: Demonstrate security awareness

**Template:**
```markdown
## Security Analysis

- [x] This PR does not introduce security vulnerabilities
- [x] I have run security scans (trivy, gitleaks, etc.)
- [x] I have followed OWASP security guidelines
- [x] I have considered common vulnerabilities

## Attack Vectors Considered

1. **SQL Injection**
   - Using parameterized queries throughout
   - No string concatenation for SQL

2. **XSS (Cross-Site Scripting)**
   - All user input is escaped
   - Using DOMPurify for HTML sanitization

3. **CSRF (Cross-Site Request Forgery)**
   - CSRF tokens on all state-changing operations
   - SameSite cookie attribute set

4. **Authentication Bypass**
   - All endpoints require valid JWT
   - Token expiration enforced
   - Refresh token rotation implemented

## Mitigations Implemented

- Input validation on all user-provided data
- Output encoding for all displayed content
- Rate limiting on sensitive endpoints
- Audit logging for all authentication attempts
````

---

### 9. Deployment Notes

**Purpose**: Inform operations team

**Template:**

````markdown
## Prerequisites

- [ ] Database migrations required
  ```sql
  ALTER TABLE users ADD COLUMN last_login TIMESTAMP;
  ```
````

- [ ] Configuration changes required

  ```yaml
  # Add to config.yml
  websocket:
    enabled: true
    port: 8080
    max_connections: 1000
  ```

- [ ] Environment variables to add

  ```bash
  WEBSOCKET_REDIS_URL=redis://localhost:6379
  WEBSOCKET_JWT_SECRET=<generate-secret>
  ```

- [ ] Infrastructure changes required
  - Open firewall port 8080 for WebSocket
  - Add Redis instance for pub/sub

## Deployment Steps

1. **Backup database**

   ```bash
   pg_dump mydb > backup-$(date +%Y%m%d).sql
   ```

2. **Run migrations**

   ```bash
   ./migrate up
   ```

3. **Update configuration**

   ```bash
   kubectl apply -f config/websocket-config.yml
   ```

4. **Deploy new version**

   ```bash
   kubectl rollout restart deployment/backend
   ```

5. **Verify deployment**

   ```bash
   curl https://api.example.com/health
   kubectl logs -f deployment/backend
   ```

## Rollback Plan

If issues occur:

1. **Revert deployment**

   ```bash
   kubectl rollout undo deployment/backend
   ```

2. **Rollback migrations** (if needed)

   ```bash
   ./migrate down 1
   ```

3. **Restore configuration**

   ```bash
   kubectl apply -f config/previous-config.yml
   ```

## Post-Deployment Verification

- [ ] Check health endpoints: `curl /health`
- [ ] Verify logs for errors: `kubectl logs`
- [ ] Check metrics dashboards
- [ ] Test WebSocket connections
- [ ] Monitor error rates for 24 hours

````

---

### 10. Additional Context

**Purpose**: Provide extra helpful information

**What to Include:**

#### Screenshots/Videos
```markdown
## Visual Changes

### Before
![Old UI](before.png)

### After
![New UI](after.png)

### Demo Video
[Watch full demo](https://www.loom.com/share/abc123)
````

#### Related PRs

```markdown
## Related Work

- Depends on #123 (must merge first)
- Blocks #456 (can't merge until this is done)
- Related to #789 (similar changes)
```

#### External References

```markdown
## References

- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Design Doc](https://docs.google.com/document/d/abc123)
- [Figma Mockup](https://figma.com/file/abc123)
```

#### Future Improvements

```markdown
## Known Limitations / Future Work

- Currently only supports text messages (binary support planned for v2.1)
- No message persistence (will add in #999)
- Single Redis instance (clustering planned for v3.0)
```

---

## 🎯 PR Best Practices

### Size & Scope

#### ✅ DO: Keep PRs Small

**Good PR:**

```
Files changed: 5
Lines added: 200
Lines deleted: 150
Commits: 3
```

**Benefits:**

- Faster reviews
- Easier to understand
- Lower risk
- Simpler rollback

#### ❌ DON'T: Create Massive PRs

**Bad PR:**

```
Files changed: 50
Lines added: 5,000
Lines deleted: 3,000
Commits: 47
```

**Problems:**

- Review fatigue
- Miss important details
- High risk
- Difficult rollback

**Rule of Thumb:**

- **< 200 lines**: Quick review
- **200-500 lines**: Standard review
- **> 500 lines**: Consider splitting

### Commit Hygiene

#### Use Conventional Commits

```bash
feat(auth): add OAuth2 authentication
fix(db): resolve connection pool leak
docs(api): update authentication guide
test(auth): add OAuth integration tests
refactor(api): extract validation logic
perf(db): optimize user query
```

**Format:**

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructure
- `perf`: Performance
- `test`: Tests
- `chore`: Maintenance

#### Atomic Commits

Each commit should be a logical unit:

```bash
# Good
git commit -m "feat(auth): add OAuth config"
git commit -m "feat(auth): implement OAuth flow"
git commit -m "test(auth): add OAuth tests"

# Bad
git commit -m "work in progress"
git commit -m "fix stuff"
git commit -m "more changes"
```

### Draft PRs

Use draft PRs for work-in-progress:

```bash
# Create draft PR
gh pr create --draft --title "WIP: Add OAuth"

# Convert to ready
gh pr ready
```

**When to Use:**

- Early feedback needed
- Showing progress
- Collaboration
- Complex changes

---

## 📚 Example Pull Requests

### Example 1: Bug Fix

**Title:** `fix(db): resolve connection pool exhaustion`

````markdown
## Description

### What does this PR do?

Fixes database connection pool exhaustion that occurs after ~1000 requests.

### Why is this change needed?

Connections were not being properly released back to the pool, causing new requests to timeout after the pool was
exhausted.

### Related Issues

- Fixes #123

## Type of Change

- [x] 🐛 Bug fix

## Component(s) Affected

- [x] Backend - Database Service (Go)

## Testing

- [x] Unit tests - Added TestConnectionPooling
- [x] Integration tests - Load tested with 10,000 requests
- [x] Manual testing - Monitored connection pool metrics

### Test Results

```bash
$ go test -v ./database
=== RUN   TestConnectionPooling
--- PASS: TestConnectionPooling (5.23s)

$ k6 run load-test.js
✓ 10000 requests completed
✓ No connection timeouts
✓ Average response time: 45ms
```
````

## Root Cause

The defer statement was inside a loop, causing connections to only be released after the entire loop completed rather
than after each iteration.

### Before

```go
for _, user := range users {
    conn := pool.Get()
    defer conn.Close() // ❌ Deferred until loop ends
    // ...
}
```

### After

```go
for _, user := range users {
    func() {
        conn := pool.Get()
        defer conn.Close() // ✅ Released immediately
        // ...
    }()
}
```

## Performance Impact

- Memory usage reduced from 300MB to 150MB
- No more connection timeouts
- Response time improved 20%

````

### Example 2: New Feature

**Title:** `feat(notifications): add real-time WebSocket notifications`

```markdown
## Description

### What does this PR do?
Implements real-time push notifications using WebSockets.

### Why is this change needed?
Users currently have to manually refresh to see new notifications. This
provides instant updates, improving UX and reducing server load from polling.

### Related Issues
- Implements #456
- Related to #789

## Type of Change
- [x] ✨ New feature

## Component(s) Affected
- [x] Backend - Database Service (Go)
- [x] Frontend - Web (TypeScript)

## Technical Details

### Architecture
- WebSocket server in Go using gorilla/websocket
- Redis pub/sub for multi-instance scaling
- JWT authentication on connection
- Automatic reconnection with exponential backoff

### API Design

**Connection:**
````

ws://api.example.com/notifications?token=<jwt>

````

**Message Format:**
```json
{
  "type": "notification",
  "id": "notif_123",
  "title": "Build Complete",
  "body": "PR #456 build succeeded",
  "timestamp": "2024-01-15T10:30:00Z"
}
````

## Testing

- [x] Unit tests - 15 new tests
- [x] Integration tests - Redis integration
- [x] E2E tests - Playwright WebSocket test
- [x] Load tests - 1000 concurrent connections

### Test Results

- ✅ Message delivery < 100ms
- ✅ Automatic reconnection works
- ✅ 1000 concurrent users supported
- ✅ Memory usage acceptable (< 10MB per 100 users)

## Documentation Updates

- Updated API documentation
- Added WebSocket setup guide
- Created architecture diagram
- Added troubleshooting section

````

---

## 🔍 Review Process

### Timeline

1. **PR Created** → Code owners notified
2. **CI Checks** → Automated tests run (< 30 min)
3. **Initial Review** → Reviewer assigned (< 2 business days)
4. **Feedback** → Changes requested or approved
5. **Updates** → Author addresses feedback
6. **Re-review** → Reviewer checks updates (< 1 business day)
7. **Approval** → Ready to merge
8. **Merge** → Squash and merge to main

### Review Checklist

Reviewers check:
- [ ] Code is readable and maintainable
- [ ] Logic is correct
- [ ] Edge cases handled
- [ ] Tests are comprehensive
- [ ] Documentation is updated
- [ ] No security issues
- [ ] Performance is acceptable
- [ ] Follows project conventions

---

## ⚠️ Common Mistakes

### 1. Vague Descriptions

**❌ Bad:**
```markdown
Description: Updates
````

**✅ Good:**

```markdown
Description: Adds OAuth2 authentication flow with Google and GitHub providers
```

### 2. Missing Tests

**❌ Bad:**

```markdown
Testing: Looks good to me
```

**✅ Good:**

```markdown
Testing:

- Added 12 unit tests
- Manual testing on Chrome, Firefox
- Load tested with 1000 concurrent users
```

### 3. Ignoring Template

**❌ Bad:**

```markdown
Here's my change, please merge
```

**✅ Good:**

```markdown
[Complete all template sections]
```

### 4. Too Many Changes

**❌ Bad:**

```
Files changed: 87
+5,432 −3,221
```

**✅ Good:**

```
Files changed: 8
+243 −178
```

### 5. Unclear Title

**❌ Bad:**

```
Update stuff
Fix
Changes
```

**✅ Good:**

```
fix(auth): resolve JWT token expiration bug
feat(api): add pagination to users endpoint
docs(readme): update installation instructions
```

---

## 📚 Additional Resources

### Official Documentation

- [Creating a PR](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)
- [PR Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)
- [Code Review Best Practices](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)

### Guides

- [Google's Engineering Practices](https://google.github.io/eng-practices/review/)
- [The Art of the Pull Request](https://hackernoon.com/the-art-of-pull-requests-6f0f099850f9)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)

---

<div align="center">

**Ready to Create Your PR?**

[Create Pull Request](../../compare) · [View PR Template](../PULL_REQUEST_TEMPLATE.md) ·
[Contributing Guide](../../blob/main/.doc/docs/CONTRIBUTING.md)

</div>
