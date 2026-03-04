# 🎫 Issue Templates Guide

> Complete guide to using issue templates in Rice Monorepo

---

## 📋 Table of Contents

- [Overview](#overview)
- [Available Templates](#available-templates)
- [Bug Report Template](#bug-report-template)
- [Feature Request Template](#feature-request-template)
- [Question Template](#question-template)
- [Template Configuration](#template-configuration)
- [Best Practices](#best-practices)
- [For Maintainers](#for-maintainers)

---

## 🎯 Overview

Issue templates streamline the process of reporting bugs, requesting features, and asking questions. They ensure all
necessary information is collected upfront, leading to faster resolution times.

**Benefits:**

- ✅ Structured information collection
- ✅ Reduced back-and-forth for clarifications
- ✅ Consistent issue format
- ✅ Automatic labeling and assignment
- ✅ Better searchability

**Official Documentation**:
[About issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)

---

## 📝 Available Templates

### Template Selection

When creating a new issue, you'll see:

![Issue Template Selection](https://docs.github.com/assets/cb-27105/images/help/issues/issue-template-chooser.png)

| Template               | Use When                                | Labels Applied                |
| ---------------------- | --------------------------------------- | ----------------------------- |
| 🐛 **Bug Report**      | Something isn't working correctly       | `bug`, `needs-triage`         |
| ✨ **Feature Request** | Suggesting a new feature or enhancement | `enhancement`, `needs-triage` |
| ❓ **Question**        | Asking for help or clarification        | `question`                    |

### Quick Access Links

- [Report a Bug](../../issues/new?template=bug-report.yml)
- [Request a Feature](../../issues/new?template=feature-request.yml)
- [Ask a Question](../../issues/new?template=question.yml)

---

## 🐛 Bug Report Template

### Purpose

Report bugs, errors, unexpected behavior, or regressions.

### When to Use

- Application crashes or freezes
- Features not working as documented
- Error messages appearing
- Performance degradation
- Security vulnerabilities (use Security tab for serious issues)

### Required Information

#### 1. Component Selection

Choose the affected component:

- Backend services (Go)
- Smart contracts (Rust/Solidity)
- Frontend applications (TypeScript/Dart)
- Bots and AI (Python)
- Infrastructure
- CI/CD
- Documentation

#### 2. Severity Level

**Critical**: System unusable, data loss, security issue

- Examples: Complete system crash, data corruption, exposed secrets

**High**: Major functionality broken, workaround exists

- Examples: Payment processing fails, authentication broken

**Medium**: Feature not working as expected

- Examples: UI glitch, incorrect calculation with workaround

**Low**: Minor issue, cosmetic problem

- Examples: Typo, alignment issue, minor UX improvement

#### 3. Description

Provide a clear, concise description of the bug.

**Good Example:**

```
When I try to authenticate using OAuth, the application crashes with a
500 error and returns "Internal Server Error" without additional details.
```

**Bad Example:**

```
Login doesn't work
```

#### 4. Steps to Reproduce

List exact steps to reproduce the bug.

**Good Example:**

```
1. Navigate to https://app.example.com/login
2. Click "Login with Google"
3. Complete Google OAuth flow
4. Application redirects to /callback
5. Error 500 appears
```

**Bad Example:**

```
Just try to login
```

#### 5. Expected vs Actual Behavior

**Expected Behavior:**

```
After completing OAuth, user should be redirected to the dashboard
with a success message.
```

**Actual Behavior:**

```
Application shows a 500 error page with no error message.
```

#### 6. Environment Information

Provide complete environment details:

```yaml
OS: Ubuntu 22.04 LTS
Architecture: x86_64
Component Version: backend v1.2.3
Language/Runtime:
  Go: 1.22.0
  Node.js: 20.11.0
Browser: Chrome 120.0.6099.129
Container Runtime: Docker 24.0.7
```

#### 7. Logs and Error Messages

Include relevant logs:

```bash
2024-01-15T10:30:45Z ERROR Failed to validate OAuth token
  error="invalid signature"
  user_id="user_123"
  provider="google"
  stack_trace="
    main.handleOAuthCallback (/app/auth/oauth.go:45)
    main.main (/app/main.go:123)
  "
```

**Tips:**

- Use `bazel build --verbose_failures` for build errors
- Include full stack traces
- Redact sensitive information (API keys, passwords, personal data)

### Optional Sections

#### Screenshots/Videos

Visual evidence helps immensely. Include:

- Error messages
- Console output
- Network tab
- Application state

#### Workaround

If you've found a temporary fix:

```
Workaround: Using the API directly with curl works correctly.
The issue seems specific to the web UI.
```

#### Regression Information

If this worked previously:

- Last working version: `v1.1.0`
- First broken version: `v1.2.0`
- Related PR: #123

### Example Bug Report

````markdown
## Component

Backend - Database Service (Go)

## Severity

High - Major functionality broken, workaround exists

## Description

Database connection pool exhausts after ~1000 requests, causing subsequent requests to timeout. Issue appears after
running for 2-3 hours under load.

## Steps to Reproduce

1. Deploy backend service v1.2.3
2. Configure with PostgreSQL database
3. Run load test: `k6 run load-test.js`
4. After ~1000 requests, new requests start timing out
5. Restart service to temporarily fix

## Expected Behavior

Connection pool should release connections properly and handle sustained load.

## Actual Behavior

After ~1000 requests:

- New database queries timeout after 30s
- Logs show "connection pool exhausted"
- CPU usage remains normal (~10%)
- Memory usage steady (~200MB)

## Environment

- OS: Ubuntu 22.04
- Go: 1.22.0
- PostgreSQL: 16.1
- Deployment: Kubernetes 1.28

## Logs

```go
2024-01-15T12:45:23Z WARN Connection pool near capacity count=48 max=50
2024-01-15T12:45:25Z ERROR Failed to acquire connection
  error="connection pool exhausted"
  wait_time="30s"
2024-01-15T12:45:25Z ERROR Request failed
  endpoint="/api/users"
  error="context deadline exceeded"
```
````

## Configuration

```yaml
database:
  max_connections: 50
  max_idle: 10
  connection_lifetime: 5m
  idle_timeout: 5m
```

## Workaround

Restarting the service every 2 hours temporarily resolves the issue.

## Additional Context

This issue started appearing after upgrading from v1.1.0 to v1.2.0. Possibly related to PR #456 which changed connection
pool management.

```

---

## ✨ Feature Request Template

### Purpose

Propose new features, enhancements, or improvements.

### When to Use

- New functionality needed
- Existing feature improvements
- Developer experience enhancements
- Performance optimizations
- Security improvements
- Better documentation

### Required Information

#### 1. Problem Statement

Describe the problem you're trying to solve.

**Good Example:**
```

Currently, users have to manually refresh the page to see new notifications. This creates a poor user experience,
especially for time-sensitive updates like chat messages or system alerts.

```

**Bad Example:**
```

Add notifications

```

#### 2. Proposed Solution

Detail your proposed solution.

**Good Example:**
```

Implement real-time notifications using WebSockets:

1. Backend: WebSocket server for bidirectional communication
2. Frontend: WebSocket client with automatic reconnection
3. Notification service: Queue and dispatch system
4. UI: Toast notifications with sound/vibration options

Technical approach:

- Use gorilla/websocket for Go server
- Native WebSocket API on frontend
- Redis pub/sub for multi-instance scaling
- Protocol: JSON messages with type/payload structure

```

#### 3. Alternatives Considered

Show you've thought through options:

```

1. Server-Sent Events (SSE) Pros: Simpler than WebSockets, browser support Cons: One-way only, less flexible
2. Polling (every 30 seconds) Pros: Simple to implement, works everywhere Cons: Higher server load, battery drain,
   latency
3. Long Polling Pros: Works with old browsers Cons: Higher latency than WebSockets

```

#### 4. User Stories

Describe how users will interact:

```

- As a developer, I want to receive real-time build notifications so that I can quickly respond to CI failures

- As a team member, I want to see when someone mentions me in comments so that I can respond promptly

- As an admin, I want to broadcast system alerts to all users so that they're aware of maintenance windows

```

#### 5. Acceptance Criteria

Define what "done" means:

```

- [ ] User receives notifications in real-time (< 1s latency)
- [ ] Notifications persist across browser tabs
- [ ] Auto-reconnection if connection drops
- [ ] Performance impact < 1% CPU, < 10MB memory
- [ ] Works on all supported browsers (Chrome, Firefox, Safari, Edge)
- [ ] Notification preferences saved per user
- [ ] Documentation updated with WebSocket setup
- [ ] Integration tests cover reconnection scenarios
- [ ] Load testing shows no degradation with 1000+ concurrent users

```

### Optional Sections

#### Technical Details

```

API Design:

WebSocket Connection: ws://api.example.com/notifications?token=<auth_token>

Message Format: { "type": "notification", "payload": { "id": "notif_123", "title": "Build Failed", "body": "PR #456
build failed on main branch", "timestamp": "2024-01-15T10:30:00Z", "priority": "high", "actions": [ {"label": "View
Build", "url": "/builds/123"} ] } }

```

#### Mockups/Wireframes

Attach visual designs or link to Figma/Excalidraw.

#### Impact Assessment

```

- User Impact: All users benefit from real-time updates
- Performance Impact: Minimal (< 1% overhead)
- Maintenance Impact: Low, using standard protocols
- Breaking Changes: None, purely additive feature

```

---

## ❓ Question Template

### Purpose

Ask questions, seek clarification, or start discussions.

### When to Use

- Getting started with the project
- Understanding architecture decisions
- Seeking best practices advice
- Troubleshooting issues
- Documentation clarification

### Required Information

#### 1. Category Selection

- **Getting Started**: Setup and installation
- **Development**: Building and developing
- **Architecture**: Design decisions
- **Best Practices**: Effective usage
- **Configuration**: How to configure
- **Deployment**: Production deployment
- **Troubleshooting**: Something isn't working
- **Documentation**: Clarification needed

#### 2. Your Question

Be specific and clear:

**Good Example:**
```

How do I configure the backend database service to use PostgreSQL instead of MySQL? I've looked at the configuration
files but I'm not sure which values need to be changed for my production deployment.

```

**Bad Example:**
```

How does database work?

```

#### 3. Context

Provide context about what you're trying to accomplish:

```

I'm deploying the backend service to AWS ECS and my company requires PostgreSQL for compliance reasons. I've
successfully deployed with MySQL in my dev environment, but need to switch to PostgreSQL for production.

```

#### 4. What You've Tried

Show your research effort:

```

- Read the database configuration documentation
- Tried changing DB_TYPE=postgres in .env file
- Searched for "postgres" in the codebase
- Looked at docker-compose.yml examples
- Found database connection code but unsure about migration files

````

### Example Question

```markdown
## Category
Configuration - How to configure

## Component
Backend - Database Service (Go)

## Question
How do I configure the backend to connect to an external PostgreSQL
database cluster instead of the default MySQL database?

## Context
I'm deploying to production on AWS ECS and need to:
- Connect to AWS RDS PostgreSQL 16
- Use connection pooling for performance
- Enable SSL/TLS for security
- Support database migrations
- Handle read replicas for scaling

My production environment:
- AWS ECS Fargate
- AWS RDS PostgreSQL 16 (Multi-AZ)
- Private VPC networking
- AWS Secrets Manager for credentials

## What I've Tried
1. Read `.backend/db/README.md` documentation
2. Changed `DB_TYPE=postgres` in `.env` file
3. Updated connection string format:
````

DATABASE_URL=postgres://user:pass@host:5432/dbname?sslmode=require # pragma: allowlist secret

```
4. Application starts but fails with "relation does not exist" errors
5. Unsure if migrations are running or if schema is different for PostgreSQL

## Expected Outcome
Successfully connect to PostgreSQL with:
- Automatic schema migrations on startup
- Connection pooling (max 50 connections)
- SSL/TLS enabled
- Health checks working
- Read replica support (optional)

## Environment
- Go: 1.22.0
- PostgreSQL: 16.1 (AWS RDS)
- Docker: 24.0.7
- Deployment: AWS ECS Fargate

## Additional Info
I found the database configuration in `.backend/db/config.go` but
I'm not sure if there are PostgreSQL-specific settings needed beyond
the connection string.

Related files I've looked at:
- `.backend/db/migrations/`
- `.backend/db/connection.go`
- `docker-compose.yml`
```

---

## ⚙️ Template Configuration

### Configuration File

Location: `.github/issue_template/config.yml`

```yaml
blank_issues_enabled: false

contact_links:
  - name: 💬 GitHub Discussions
    url: https://github.com/mrDinkelman/rice-mono/discussions
    about: Community discussions and Q&A

  - name: 📚 Documentation
    url: https://github.com/mrDinkelman/rice-mono/tree/main/.doc/docs
    about: Complete project documentation

  - name: 🔒 Security Vulnerability
    url: https://github.com/mrDinkelman/rice-mono/security/advisories/new
    about: Report security issues privately
```

**Official Docs**:
[Configuring issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-request-templates/configuring-issue-templates-for-your-repository)

### Template Files

Templates are YAML files with structured forms:

```yaml
name: Template Name
description: Template description
title: "[PREFIX] "
labels: ["label1", "label2"]
assignees: ["username"]

body:
  - type: dropdown
    id: component
    attributes:
      label: Component
      options:
        - Option 1
        - Option 2
    validations:
      required: true

  - type: textarea
    id: description
    attributes:
      label: Description
      placeholder: Enter details here
    validations:
      required: true
```

### Form Elements

| Type         | Purpose                  | Required |
| ------------ | ------------------------ | -------- |
| `markdown`   | Static text/instructions | No       |
| `textarea`   | Multi-line input         | Optional |
| `input`      | Single-line input        | Optional |
| `dropdown`   | Selection list           | Optional |
| `checkboxes` | Multiple selections      | Optional |

---

## 🎯 Best Practices

### For Issue Reporters

#### ✅ DO

- **Search first**: Look for existing similar issues
- **Be specific**: Provide exact steps and details
- **Include context**: Explain what you're trying to accomplish
- **Add evidence**: Screenshots, logs, error messages
- **Follow up**: Respond to questions from maintainers
- **Update status**: Comment if you find a solution
- **Be respectful**: Maintain a professional, friendly tone

#### ❌ DON'T

- **Don't duplicate**: Check for existing issues first
- **Don't be vague**: "It doesn't work" isn't helpful
- **Don't omit details**: Missing info delays resolution
- **Don't include secrets**: Redact API keys, passwords, tokens
- **Don't spam**: Bumping issues repeatedly
- **Don't demand**: Be patient and respectful

### Writing Great Issues

#### Bad Issue Example

```
Title: bug

Description: login doesnt work help

No additional information provided.
```

**Problems:**

- Vague title
- No component specified
- No steps to reproduce
- No environment information
- No logs or error messages
- Unclear what "doesn't work" means

#### Good Issue Example

```
Title: [BUG] OAuth authentication fails with 500 error after successful Google login

Component: Backend - Authentication Service
Severity: High

Description:
Users cannot authenticate using Google OAuth. After completing the Google
login flow successfully, the callback handler returns HTTP 500 with error
"failed to validate token signature".

Steps to Reproduce:
1. Go to https://app.example.com/login
2. Click "Login with Google"
3. Complete Google OAuth consent screen
4. Redirected to /auth/callback?code=...
5. Application returns 500 error

Expected: User logs in and sees dashboard
Actual: 500 error page displayed

Environment:
- Backend v1.2.3
- Go 1.22.0
- Deployed on Kubernetes 1.28
- Google OAuth App ID: 123456789

Logs:
[timestamp] ERROR Failed to validate OAuth token
  error="invalid signature"
  provider="google"
  user_email="user@example.com"

This worked in v1.1.0 and broke after PR #456 was merged.

Workaround: Using username/password authentication works fine.
```

---

## 👨‍💼 For Maintainers

### Triaging Issues

#### 1. Initial Review

- Read the issue completely
- Verify all required information is present
- Check for duplicates
- Add appropriate labels

#### 2. Label Strategy

| Label              | Meaning             | Action                     |
| ------------------ | ------------------- | -------------------------- |
| `needs-triage`     | Awaiting review     | Review within 48h          |
| `needs-info`       | Missing information | Request details            |
| `duplicate`        | Already reported    | Close, link to original    |
| `wontfix`          | Not addressing      | Close, explain why         |
| `good-first-issue` | Beginner-friendly   | Encourage new contributors |
| `help-wanted`      | Community help      | Broadcast availability     |

#### 3. Priority Assignment

```
P0-critical:  Security, data loss, system down
P1-high:      Major functionality broken
P2-medium:    Feature improvement, minor bugs
P3-low:       Nice-to-have, cosmetic issues
```

#### 4. Response Templates

**Request More Information:**

```markdown
Thank you for reporting this issue! To help us investigate, could you please provide:

1. Complete error logs (with sensitive information redacted)
2. Steps to reproduce the issue
3. Your environment details (OS, versions, etc.)

Once we have this information, we can investigate further.
```

**Duplicate Issue:**

```markdown
Thank you for reporting! This issue is a duplicate of #123.

Please subscribe to that issue for updates. Closing this as duplicate.
```

**Cannot Reproduce:**

```markdown
Thank you for the report. I've attempted to reproduce this issue with the steps provided, but haven't been able to
replicate the problem.

Could you provide additional details:

- Exact version you're using
- Any custom configuration
- Full error logs

This will help us identify the root cause.
```

### Modifying Templates

#### 1. Local Testing

Edit template files and test locally:

```bash
# No special testing needed - GitHub will validate YAML on push
```

#### 2. Deployment

```bash
git add .github/issue_template/
git commit -m "feat: improve bug report template"
git push origin main
```

Changes take effect immediately.

#### 3. Version Control

- Track all changes in git
- Document major template changes in CHANGELOG
- Notify community of significant changes

---

## 📚 Additional Resources

### Official Documentation

- [About issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
- [Creating issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
- [Issue template syntax](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
- [GitHub Community Guidelines](https://docs.github.com/en/site-policy/github-terms/github-community-guidelines)

### Example Templates

- [GitHub's issue templates](https://github.com/github/.github)
- [Microsoft's templates](https://github.com/microsoft/.github)
- [Awesome issue templates](https://github.com/devspace/awesome-github-templates)

---

## 💡 Tips for Success

### For First-Time Contributors

1. **Read the contributing guide**: [CONTRIBUTING.md](../../blob/main/.doc/docs/CONTRIBUTING.md)
2. **Check existing issues**: Someone may have already reported it
3. **Use the right template**: Bug? Feature? Question?
4. **Be patient**: Maintainers are volunteers
5. **Stay engaged**: Respond to follow-up questions

### For Experienced Users

1. **Help triage**: Review and comment on issues
2. **Improve templates**: Suggest improvements
3. **Mentor newcomers**: Help new contributors
4. **Document solutions**: Share what worked
5. **Submit PRs**: Turn issues into fixes

---

<div align="center">

**Questions about issue templates?**

[Ask in Discussions](../../discussions) · [View Examples](../../issues?q=is%3Aissue)

</div>
