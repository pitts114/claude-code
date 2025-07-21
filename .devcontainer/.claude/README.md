# Claude Code Commands

This directory contains custom Claude Code slash commands and configurations for the microservices demo project.

## Directory Structure

```
.claude/
├── README.md              # This file
└── commands/
    └── work-on-issue.md   # GitHub issue-to-PR workflow command
```

## Available Commands

### `/work-on-issue` - GitHub Issue to Pull Request Workflow
**File**: `commands/work-on-issue.md`

Automates the complete development workflow from GitHub issue analysis to pull request creation:

- **Issue Analysis**: Parses GitHub issues for requirements and affected services
- **Service Detection**: Identifies which microservices (users, auth, notifications, ui, gateway) need changes
- **Bottom-Up Development**: Implements features in logical dependency order
- **Test-Driven**: Runs tests after each development chunk
- **Atomic Commits**: Creates meaningful commits with conventional format
- **Pull Request**: Auto-creates PR with comprehensive template

**Usage Examples**:
```bash
/work-on-issue #123
/work-on-issue https://github.com/owner/repo/issues/123
/work-on-issue --project "Microservices Demo" --status "Todo"
```

## Integration with CLAUDE.md

These workflows integrate with the project's `CLAUDE.md` file to understand:
- Service-specific test commands
- Linting and type checking commands
- Build processes
- Branch naming conventions
- Commit message formats

## Adding New Commands

1. Create a new `.md` file in the `commands/` directory
2. Document the command syntax and behavior
3. Update this README with the new command
4. Add any necessary configuration to the main `CLAUDE.md` file

## Microservices Architecture Support

All commands are designed specifically for this microservices architecture:
- **UUID-first database design**
- **Event-driven communication via Kafka**
- **Rails fat model, thin controller patterns**
- **React + Redux Toolkit + TypeScript frontend**
- **API Gateway routing patterns**
- **Cross-service dependency management**