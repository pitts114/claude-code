# `/work-on-issue` - GitHub Issue to Pull Request Workflow

## ⚠️ MANDATORY WORKFLOW - YOU MUST FOLLOW THIS EXACTLY

### 🛑 STOP: Before Starting Development

**YOU MUST COMPLETE THESE STEPS IN ORDER:**

1. **IMMEDIATELY Create and Checkout Feature Branch**
   ```bash
   # Pull latest changes from master before creating branch
   git pull origin master
   
   # Create and checkout new branch (replace 123, users, profile-validation with actual values)
   git checkout -b feature/issue-123-users-profile-validation
   ```
   - Example branch: `feature/issue-123-users-profile-validation`

2. **CONFIRM Branch Setup**
   - Run `git branch --show-current` to verify you're on the feature branch
   - DO NOT proceed if branch creation failed
   - DO NOT work on master/main branch

3. **Plan Your Commit Strategy**
   - Use format: `feat(service): description for issue #{number}`
   - Make atomic commits for each logical step
   - Include tests with each implementation commit

**❌ DO NOT START DEVELOPMENT UNTIL ALL ABOVE STEPS ARE COMPLETE**

## Overview
This document defines the `/work-on-issue` slash command for Claude Code that automates the complete GitHub issue-to-PR workflow for the microservices demo project.

## Command Syntax

### Basic Usage
```
/work-on-issue #123
/work-on-issue https://github.com/owner/repo/issues/123
/work-on-issue --project "Microservices Demo" --status "Todo"
```

### Advanced Options
```
/work-on-issue #123 --branch-prefix feature/ --service users --draft
/work-on-issue #123 --no-tests --assign-me
```

## 🚀 COMMAND SIMPLIFICATION GUIDELINES

**CRITICAL: Write Commands Directly - NO Environment Variables**

❌ **NEVER DO THIS - Complex variable chains:**
```bash
# DON'T DO THIS - Too complex and hard to read
OWNER="username" && ISSUE_NUMBER="123" && PROJECT_LIST=$(gh project list --owner $OWNER) && PROJECT_NUMBER=$(echo "$PROJECT_LIST" | grep "microservices-demo" | awk '{print $1}') && ITEM_DATA=$(gh project item-list $PROJECT_NUMBER --owner $OWNER --format json | jq ".items[] | select(.content.number == $ISSUE_NUMBER)") && ITEM_ID=$(echo "$ITEM_DATA" | jq -r '.id')
```

❌ **ALSO AVOID - Even simple environment variables:**
```bash
# DON'T DO THIS EITHER - Still using variables
ITEM_ID=$(gh project item-list 2 --owner pitts114 --format json | jq -r ".items[] | select(.content.number == 123) | .id")
gh project item-edit --project-id PVT_kwHOATGsKs4A-OnP --id $ITEM_ID --field-id PVTSSF_lAHOATGsKs4A-OnPzgxsgik --single-select-option-id 47fc9ee4
```

✅ **DO THIS - Write commands directly with actual values:**
```bash
# Step 1: Discover which projects the issue belongs to
gh issue view 123 --repo pitts114/microservices-demo --json projectItems

# Step 2: Map project titles to project numbers
gh project list --owner pitts114

# Step 3: Update status in each project (example for "users service" project)
gh project item-list 2 --owner pitts114 --format json | jq -r ".items[] | select(.content.number == 123) | .id"
gh project item-edit --project-id PVT_kwHOATGsKs4A-OnP --id PVTI_lAHOATGsKs4A-OnPzgcvkiU --field-id PVTSSF_lAHOATGsKs4A-OnPzgxsgik --single-select-option-id 47fc9ee4
```

**MANDATORY Principles:**
- **NO environment variables** - Write actual values directly in commands
- **NO variable assignments** - Don't use `ITEM_ID=`, `OWNER=`, etc.
- **NO command chaining** - Don't use `&&` to chain variable assignments
- **USE actual values** - Replace placeholders like `123` with real issue numbers
- **COPY-PASTE approach** - Run command, copy output, paste into next command
- **MULTI-PROJECT support** - Always check which projects an issue belongs to and update ALL of them

## Command Flow

### 1. Issue Analysis Phase
- Fetch issue details using `gh issue view #123 --json title,body,labels,assignees,milestone,projectItems`
- **Detect Project Management Tool:**
  - Check for GitHub Projects v2 in `projectItems`
  - Look for Linear issue URL patterns in body/comments
  - Search for Jira ticket references
  - Fall back to GitHub issue-only workflow if no project detected
- Parse issue body for:
  - Acceptance criteria
  - Technical requirements
  - Affected services (users, auth, notifications, ui, gateway)
  - Breaking changes indicators
  - Dependencies and related issues
- **Extract Project Context:**
  - Current issue status in project
  - Project board configuration
  - Custom field values (priority, service tags, etc.)
  - Required status transition permissions

### 2. Status Update to "In Progress" (FIRST ACTION)
**🛑 CRITICAL: This MUST be the first action before any development work**

#### GitHub Projects v2 (Multi-Project Support)
**Dynamically discover and update ALL projects the issue belongs to:**

```bash
# Step 1: Find which projects this issue belongs to (replace 123 with actual issue number)
gh issue view 123 --repo pitts114/microservices-demo --json projectItems

# Step 2: Get project numbers and IDs for all projects
gh project list --owner pitts114

# Step 3: For each project the issue is on, update status to "In Progress"
# Example: If issue is on "users service" project (number 2, ID PVT_kwHOATGsKs4A-OnP)

# 3a: Get the item ID for this issue in the "users service" project
gh project item-list 2 --owner pitts114 --format json | jq -r ".items[] | select(.content.number == 123) | .id"

# 3b: Update to "In Progress" (paste actual item ID from 3a)
gh project item-edit --project-id PVT_kwHOATGsKs4A-OnP --id PVTI_lAHOATGsKs4A-OnPzgcvkiU --field-id PVTSSF_lAHOATGsKs4A-OnPzgxsgik --single-select-option-id 47fc9ee4

# Step 4: Repeat steps 3a-3b for each additional project the issue belongs to
# Example: If also on "Arbius Command Center" project (number 1, ID PVT_kwHOATGsKs4A9RTZ)

# 4a: Get item ID for this issue in the "Arbius Command Center" project
gh project item-list 1 --owner pitts114 --format json | jq -r ".items[] | select(.content.number == 123) | .id"

# 4b: Update to "In Progress" in that project (get field/option IDs for that project first)
gh project field-list 1 --owner pitts114 --format json | jq '.fields[] | select(.name == "Status")'
# Then use the appropriate IDs for that project's status update
```

**Known Project Information (for quick reference):**
- **"users service" project**: Number `2`, ID `PVT_kwHOATGsKs4A-OnP`, Status Field `PVTSSF_lAHOATGsKs4A-OnPzgxsgik`, "In Progress" `47fc9ee4`
- **"Arbius Command Center" project**: Number `1`, ID `PVT_kwHOATGsKs4A9RTZ` (get field/option IDs as needed)
- **Owner**: `pitts114` (or your GitHub username)

**Important**: Always run Steps 1-2 above to confirm which projects your specific issue belongs to, as issues can be on multiple projects or new projects may be added.

#### Quick Reference Commands
```bash
# Get field/option IDs for any project (replace PROJECT_NUMBER with actual project number)
gh project field-list PROJECT_NUMBER --owner pitts114 --format json | jq '.fields[] | select(.name == "Status")'

# Example: Get "In Review" option ID for "users service" project (number 2)
gh project field-list 2 --owner pitts114 --format json | jq '.fields[] | select(.name == "Status") | .options[] | select(.name == "In Review") | .id'

# Example: Get "In Progress" option ID for "Arbius Command Center" project (number 1)
gh project field-list 1 --owner pitts114 --format json | jq '.fields[] | select(.name == "Status") | .options[] | select(.name == "In Progress") | .id'
```

#### Error Handling for Status Update
- **If project not found**: Continue with GitHub issue-only workflow
- **If issue not in project**: Add issue to project first, then update status
- **If permission denied**: Display manual update instructions
- **If field/option IDs wrong**: Re-fetch project configuration

### 3. Service Detection
Based on issue content and labels, determine affected services:
- **Users Service**: Profile management, user data, UUID handling
- **Auth Service**: Authentication, JWT, password management
- **Notifications Service**: Event-driven notifications, preferences
- **UI Service**: React components, Redux state, TypeScript
- **Gateway**: Routing, middleware, CORS
- **Kafka**: Event streaming, topic management

### 4. Project Context Integration
- Read CLAUDE.md for project-specific commands
- Identify test frameworks per service:
  - Rails: `rails test` or `rspec`
  - React: `npm test` or `yarn test`
  - Linting: `rubocop`, `npm run lint`
  - Type checking: `npm run type-check`

### 5. Branch Strategy
Create feature branch for isolated development:

```bash
# Pull latest changes from master before creating branch
git pull origin master

# Create and checkout new branch (replace 123, users, profile-validation with actual values)
git checkout -b feature/issue-123-users-profile-validation

# Verify setup
git branch --show-current
```

**Important: `-b` Flag Explained:**
- **`-b flag`**: Creates a new branch AND checks it out in one command
- **Without `-b`**: Git expects the branch to already exist (causes "fatal: invalid reference" error)
- **Starting Point**: New branch is created from current HEAD (typically master/main)
- **Safe Creation**: Prevents the common error of trying to checkout non-existent branches

**Branch Benefits:**
- **Clean Isolation**: Each issue has its own dedicated branch
- **No Context Switching**: Work stays isolated to the feature branch
- **Safe Experimentation**: Main branch remains untouched
- **Container Isolation**: Since we're working in a container, there's no need for multiple working directories

**Examples:**
- `feature/issue-123-users-profile-validation`
- `feature/issue-124-auth-jwt-refresh`
- `feature/issue-125-ui-notification-settings`

**Error Handling:**
```bash
# Handle existing branch by adding timestamp
if git show-ref --verify --quiet refs/heads/feature/issue-123-users-profile-validation; then
    git checkout -b feature/issue-123-users-profile-validation-$(date +%s)
else
    git checkout -b feature/issue-123-users-profile-validation
fi

# STOP if branch creation fails
if [ $? -ne 0 ]; then
    echo "❌ FATAL: Branch creation failed. Cannot proceed safely."
    echo "Check if you have uncommitted changes or branch name conflicts."
    exit 1
fi
```

- **Note**: Status was already updated to "In Progress" in Step 2
- **Important**: ALL development work must happen on the feature branch

### 6. Development Workflow (Bottom-Up Approach)

**🔧 BRANCH DEVELOPMENT**: All development commands below assume you are working on the feature branch created in Step 5. Commands like `cd users && rails test` will work exactly the same since you're in the same repository.

## 🚨 CRITICAL: TESTS AND IMPLEMENTATION MUST BE COMMITTED TOGETHER

**❌ NEVER SEPARATE IMPLEMENTATION AND TESTS INTO DIFFERENT COMMITS**

**✅ CORRECT PATTERN - Implementation + Tests in Same Commit:**
- Model + Model Tests = 1 commit
- Controller + Controller Tests = 1 commit
- Component + Component Tests = 1 commit
- Service + Service Tests = 1 commit

**❌ INCORRECT PATTERN - Separate Commits:**
- ~~Commit 1: Create model~~
- ~~Commit 2: Write model tests~~ ← **NEVER DO THIS**

**⚠️ WHY THIS MATTERS:**
- Ensures every commit has working, tested code
- Prevents broken intermediate states
- Makes code review easier
- Follows atomic commit principles
- Maintains project quality standards

**📝 IMPLEMENTATION RULE:** When you write ANY implementation code (models, controllers, components, services), you MUST write and include the corresponding tests in the SAME commit. No exceptions.

#### A. Rails CRUD Feature Development Steps

**🔒 MANDATORY CHECKLIST - Complete in Order:**

**Foundation Layer (Database & Domain)**
1. **Migration & Model Creation WITH Tests (SINGLE COMMIT)**
   - [ ] Create database migration with UUID primary key
   - [ ] Create Active Record model with validations
   - [ ] **IMMEDIATELY write model unit tests** (same commit as model)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(users): add user profile migration, model, and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Migration + Model + Model Tests = 1 commit (never separate)

2. **Model Logic & Relationships WITH Tests (SINGLE COMMIT)**
   - [ ] Add associations and scopes
   - [ ] Implement business logic methods
   - [ ] Add model callbacks for Kafka events
   - [ ] **IMMEDIATELY update and expand model tests** (same commit as logic changes)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(users): add profile validation, callbacks, and expanded tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Logic Changes + Updated Tests = 1 commit (never separate)

**🛑 CHECKPOINT: Foundation Layer Complete**
**YOU MUST VERIFY:**
- [ ] All database migrations run successfully
- [ ] All model tests pass
- [ ] All commits follow the proper format
- [ ] Code is working on the feature branch

**Service Layer (Business Logic)**
3. **Service Objects WITH Tests (SINGLE COMMIT) - if complex**
   - [ ] Create service objects for complex operations
   - [ ] **IMMEDIATELY write service object tests** (same commit as service)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(users): add profile update service and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Service + Service Tests = 1 commit (never separate)

**API Layer (HTTP Interface)**
4. **Controller & Basic Actions WITH Tests (SINGLE COMMIT)**
   - [ ] Create controller with CRUD actions
   - [ ] Add parameter validation
   - [ ] **IMMEDIATELY write controller unit tests** (same commit as controller)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(users): add profile controller, actions, and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Controller + Controller Tests = 1 commit (never separate)

5. **Serializers & Views WITH Tests (SINGLE COMMIT)**
   - [ ] Add JSON serializers/views
   - [ ] Handle error responses
   - [ ] **IMMEDIATELY write serializer tests** (same commit as serializers)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(users): add profile serializers, error handling, and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Serializers + Serializer Tests = 1 commit (never separate)

**Integration Layer**
6. **Integration Tests (SEPARATE COMMIT - Tests Whole API)**
   - [ ] Write API endpoint integration tests
   - [ ] Test full request/response cycle
   - [ ] Test error scenarios
   - [ ] Run integration tests to ensure they pass
   - [ ] **COMMIT**: `test(users): add profile API integration tests for issue #123`
   - [ ] **VERIFY**: All tests still pass after commit
   - [ ] **✅ NOTE**: Integration tests can be separate since they test the entire API, not a specific component

7. **Kafka Event Integration WITH Tests (SINGLE COMMIT)**
   - [ ] Implement event publishing in models/controllers
   - [ ] **IMMEDIATELY write event publishing tests** (same commit)
   - [ ] Verify event schema
   - [ ] Test consumer integration
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(users): add profile event publishing and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Event Publishing + Event Tests = 1 commit (never separate)

#### B. React Feature Development Steps
**State Management Layer (Foundation)**
1. **Redux Feature Slice WITH Tests (SINGLE COMMIT)**
   - [ ] Create RTK slice with actions/reducers
   - [ ] Define TypeScript interfaces
   - [ ] **IMMEDIATELY write slice unit tests** (same commit as slice)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(ui): add profile redux slice and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Redux Slice + Slice Tests = 1 commit (never separate)

2. **API Integration WITH Tests (SINGLE COMMIT)**
   - [ ] Create RTK Query endpoints
   - [ ] Add API type definitions
   - [ ] **IMMEDIATELY write API integration tests** (same commit as API code)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(ui): add profile API endpoints and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: API Endpoints + API Tests = 1 commit (never separate)

**Component Layer (UI Foundation)**
3. **Base Components WITH Tests (SINGLE COMMIT)**
   - [ ] Create reusable UI components
   - [ ] Add TypeScript props interfaces
   - [ ] **IMMEDIATELY write component unit tests** (same commit as components)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(ui): add profile form components and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Components + Component Tests = 1 commit (never separate)

4. **Container Components WITH Tests (SINGLE COMMIT)**
   - [ ] Create components that connect to Redux
   - [ ] Add state management logic
   - [ ] **IMMEDIATELY write integration tests** (same commit as containers)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(ui): add profile container components and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Container + Container Tests = 1 commit (never separate)

**Application Layer (Integration)**
5. **Route Integration WITH Tests (SINGLE COMMIT)**
   - [ ] Add routes to React Router
   - [ ] Connect to navigation
   - [ ] Add route guards/permissions
   - [ ] **IMMEDIATELY write route tests** (same commit as routes)
   - [ ] Run tests to ensure they pass
   - [ ] **COMMIT**: `feat(ui): add profile routes, navigation, and tests for issue #123`
   - [ ] **VERIFY**: Tests still pass after commit
   - [ ] **⚠️ CRITICAL**: Routes + Route Tests = 1 commit (never separate)

6. **End-to-End Integration (SEPARATE COMMIT - Tests Whole Feature)**
   - [ ] Write E2E tests
   - [ ] Test full user workflows
   - [ ] Test error scenarios
   - [ ] Run E2E tests to ensure they pass
   - [ ] **COMMIT**: `test(ui): add profile E2E tests for issue #123`
   - [ ] **VERIFY**: All tests still pass after commit
   - [ ] **✅ NOTE**: E2E tests can be separate since they test the entire feature, not a specific component

#### C. Microservices Cross-Service Features
**Service Dependency Order**
1. **Downstream Services First** (Data providers)
   - Users Service (identity, profiles)
   - Auth Service (credentials, tokens)
   - Notifications Service (preferences)

2. **Upstream Services Second** (Data consumers)
   - Gateway (routing, middleware)
   - UI (frontend integration)

**Cross-Service Integration Steps**
1. **Service A Changes** (Provider)
   - Database changes
   - API changes
   - Event schema updates
   - **Commit**: `feat(users): add profile export API for issue #123`

2. **Event Schema Updates**
   - Update Kafka event definitions
   - Test event publishing
   - **Commit**: `feat(events): update profile event schema for issue #123`

3. **Service B Changes** (Consumer)
   - Update event consumers
   - Handle new event types
   - **Commit**: `feat(notifications): handle profile events for issue #123`

4. **Gateway Updates**
   - Add new routes
   - Update middleware
   - **Commit**: `feat(gateway): add profile routes for issue #123`

5. **Frontend Integration**
   - Update UI to use new APIs
   - Add new features
   - **Commit**: `feat(ui): integrate profile updates for issue #123`

#### D. Dependency Management Rules
**Always Develop Bottom-Up**
- Database migrations before models
- Models before controllers
- Controllers before views
- Backend APIs before frontend integration
- Individual services before cross-service integration

**Testing at Each Layer**
- Unit tests for each component
- Integration tests for API endpoints
- E2E tests for complete workflows
- Never commit failing tests

## 🚨 COMMIT STRATEGY - ABSOLUTELY CRITICAL

**❌ NEVER SEPARATE IMPLEMENTATION AND TESTS INTO DIFFERENT COMMITS**

**✅ MANDATORY COMMIT PATTERN:**
- **One logical change + its tests = ONE commit**
- **Implementation code + test code = ALWAYS SAME COMMIT**
- **Working, tested code at every single commit**
- **Clear commit messages with issue reference**

**📋 SPECIFIC REQUIREMENTS:**
- [ ] **Model changes**: Model + Model Tests = 1 commit
- [ ] **Controller changes**: Controller + Controller Tests = 1 commit
- [ ] **Component changes**: Component + Component Tests = 1 commit
- [ ] **Service changes**: Service + Service Tests = 1 commit
- [ ] **API changes**: API code + API Tests = 1 commit

**🚫 ABSOLUTELY FORBIDDEN:**
- ~~Commit 1: Create implementation~~
- ~~Commit 2: Add tests~~ ← **NEVER DO THIS!**

**✅ CORRECT EXAMPLES:**
- `feat(users): add user profile model and tests for issue #123`
- `feat(ui): add profile form component and tests for issue #124`
- `feat(auth): add JWT service and tests for issue #125`

**❌ INCORRECT EXAMPLES:**
- ~~`feat(users): add user profile model for issue #123`~~ (missing tests)
- ~~`test(users): add user profile tests for issue #123`~~ (tests separate from implementation)

### 7. Testing Strategy
- **Unit Tests**: Models, controllers, components
- **Integration Tests**: API endpoints, Kafka events
- **Type Tests**: TypeScript compilation
- **End-to-End**: Full workflow through gateway

### 8. Commit Strategy
- Use conventional commits with issue reference
- Format: `feat(users): add profile validation for issue #123`
- Atomic commits per logical chunk
- Include service name in scope

### 9. Pull Request Creation & Status Automation
- **Create PR with Descriptive Title**: Generate title based on what the changes actually do, not just the issue reference
  ```bash
  # Step 1: Review commit history to understand what was implemented
  git log --oneline feature/issue-123-users-profile-validation

  # Step 2: Create PR with simple, clear title (examples below)
  # Instead of: "feat(users): add profile validation for issue #123"
  # Use simple titles like:

  # For user profile features:
  gh pr create --title "Create UserProfile model" --body "Closes #123"

  # For authentication features:
  gh pr create --title "Add JWT refresh tokens" --body "Closes #124"

  # For notification features:
  gh pr create --title "Add notification preferences" --body "Closes #125"

  # For bug fixes:
  gh pr create --title "Fix user session persistence" --body "Closes #126"

  # For performance improvements:
  gh pr create --title "Optimize user profile queries" --body "Closes #127"

  # For UI/UX changes:
  gh pr create --title "Redesign settings page" --body "Closes #128"
  ```

#### PR Title Guidelines
**🎯 KEEP IT SIMPLE - Focus on the main action and entity:**
- "Create UserProfile model"
- "Add JWT refresh tokens"
- "Fix notification memory leak"
- "Optimize user search"
- "Add dark mode toggle"

**❌ DON'T - Be overly detailed or technical:**
- ~~"Add user profile management with email validation and UUID support"~~ (too verbose)
- ~~"Implement JWT refresh token rotation with secure storage"~~ (too much detail)
- ~~"Fix memory leak in notification consumer with buffer optimization"~~ (implementation details)

**❌ ALSO DON'T - Just reference the issue:**
- "feat(users): changes for issue #123"
- "Fix issue #124"
- "Implement feature from issue #125"

**📝 Simple Title Crafting Process:**
1. **Review commits**: `git log --oneline feature/issue-123-users-profile-validation`
2. **Identify main entity**: What is the primary thing being created/changed? (Model, Component, Service, etc.)
3. **Use simple action verbs**: Create, Add, Fix, Update, Remove
4. **Keep it short**: Focus on action + entity only (e.g., "Create UserProfile model")
5. **Avoid technical details**: Save implementation details for the PR description
6. **Aim for brevity**: 2-4 words ideal, under 50 characters maximum

**💡 Where to put technical details:**
- **Title**: "Create UserProfile model"
- **Description**: "Creates UserProfile model with UUID primary key, email/phone validations, and event publishing callbacks. Includes comprehensive test coverage for all validations and business logic."

**Simple Examples by Service:**
- **Users**: "Create UserProfile model", "Add data export"
- **Auth**: "Add refresh tokens", "Add password reset"
- **Notifications**: "Add push notifications", "Add preferences API"
- **UI**: "Redesign dashboard", "Add loading states"
- **Gateway**: "Add rate limiting", "Add CORS support"

- **Update Status to "In Review" (Multi-Project Support):**
  ```bash
  # Step 1: Check which projects this issue belongs to (same as during setup)
  gh issue view 123 --repo pitts114/microservices-demo --json projectItems

  # Step 2: For each project the issue is on, update status to "In Review"
  # Example: If issue is on "users service" project (number 2)

  # 2a: Get the item ID for this issue in "users service" project
  gh project item-list 2 --owner pitts114 --format json | jq -r ".items[] | select(.content.number == 123) | .id"

  # 2b: Get "In Review" option ID for "users service" project (if not known)
  gh project field-list 2 --owner pitts114 --format json | jq '.fields[] | select(.name == "Status") | .options[] | select(.name == "In Review") | .id'

  # 2c: Update to "In Review" status (paste actual IDs from 2a and 2b)
  gh project item-edit --project-id PVT_kwHOATGsKs4A-OnP --id PVTI_lAHOATGsKs4A-OnPzgcvkiU --field-id PVTSSF_lAHOATGsKs4A-OnPzgxsgik --single-select-option-id be68dd99

  # Step 3: Repeat 2a-2c for each additional project the issue belongs to
  # Example: If also on "Arbius Command Center" project (number 1)

  # 3a: Get item ID for "Arbius Command Center" project
  gh project item-list 1 --owner pitts114 --format json | jq -r ".items[] | select(.content.number == 123) | .id"

  # 3b: Get field/option IDs for that project and update status accordingly
  ```
- **Link PR to Issue**: Use "Closes #123" in PR body for automatic linking
- **Verification**: `gh pr view` to confirm PR creation and check project status

#### Branch Management After PR Creation
**⚠️ DO NOT automatically delete the feature branch after PR creation**

The feature branch should remain available for:
- **PR Feedback**: Address review comments and suggestions
- **Additional Changes**: Manual edits or improvements
- **Testing**: Verify changes work as expected
- **Iterative Development**: Make follow-up commits

#### Manual Branch Cleanup (When PR is merged/closed)
Only clean up branches when completely done with the issue:

```bash
# Manual cleanup after PR is merged and no more changes needed
git checkout main  # Return to main branch
git branch -d feature/issue-123-users-profile-validation

# Or force cleanup if needed
git branch -D feature/issue-123-users-profile-validation
```

### 10. GitHub Comment Formatting (MANDATORY)

**🤖💬 CRITICAL: All Claude Code comments MUST start with robot and speech bubble emojis**

When Claude Code posts ANY comment, PR description, or message via the `gh` CLI, it MUST begin with `🤖💬` to indicate it's an automated comment from Claude Code.

**Examples:**
```bash
# PR creation
gh pr create --title "Create UserProfile model" --body "🤖💬 Closes #123

This PR implements the UserProfile model with comprehensive validation..."

# PR comments
gh pr comment 123 --body "🤖💬 Tests are now passing. Ready for review."

# Issue comments
gh issue comment 123 --body "🤖💬 Working on this issue. Status updated to In Progress."
```

**Why This Matters:**
- Clearly identifies when Claude Code is commenting vs human users
- Maintains transparency in automated workflows
- Helps with debugging and understanding who made which changes
- Professional indication of AI assistance

**MANDATORY Rule:** EVERY comment, PR description, and message posted via `gh` CLI must start with `🤖💬`

### 11. Pull Request Template
```markdown
🤖💬 ## Summary
Closes #123

[Brief description of what this PR accomplishes - should match the PR title]

## Changes Made
- [Specific technical changes implemented]
- [Database migrations and schema updates]
- [New API endpoints or modifications]
- [Kafka event schema changes]
- [UI/UX improvements]
- [Performance optimizations]
- [Bug fixes and stability improvements]

## Services Affected
- [ ] Users Service
- [ ] Auth Service
- [ ] Notifications Service
- [ ] UI (React)
- [ ] Gateway
- [ ] Kafka

## Test Results
- ✅ Unit tests pass
- ✅ Integration tests pass
- ✅ Type checking passes
- ✅ Linting passes
- ✅ E2E tests pass

## Database Changes
- [ ] Migrations included
- [ ] UUID constraints maintained
- [ ] Indexes updated

## Kafka Changes
- [ ] Event schema updated
- [ ] Consumer/producer tested
- [ ] Partitioning maintained

## Project Status
- ✅ Issue moved to "In Review"
- ✅ All automations completed successfully

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Error Handling

### Common Issues
- **UUID Validation**: Ensure all IDs are proper UUIDs
- **Service Communication**: Verify Gateway routing
- **Event Schema**: Validate Kafka event structure
- **Type Safety**: Fix TypeScript compilation errors
- **Database Constraints**: Handle UUID foreign key constraints
- **Project Management API Failures**: Handle status update failures gracefully
- **Authentication Issues**: Missing or invalid API tokens for project tools
- **Permission Errors**: Insufficient permissions to update issue status
- **Branch Creation Failures**: Handle naming conflicts or git errors
- **Branch Name Collisions**: Multiple attempts to create same branch name
- **Stale Branch References**: Cleanup after forced removals or conflicts

### Recovery Strategies
- Rollback to previous commit if tests fail
- Rebase branch if conflicts arise
- Retry with different approach if implementation fails
- Create sub-issues for complex problems

#### Branch-Specific Error Recovery

**Branch Creation Failures - STOP EXECUTION:**
```bash
# If branch creation fails, DO NOT proceed with development
if ! git checkout -b $BRANCH_NAME; then
    echo "❌ FATAL: Branch creation failed. Cannot proceed safely."
    echo "Check for uncommitted changes or naming conflicts."
    echo ""
    echo "Required actions:"
    echo "1. Check git status: git status"
    echo "2. Stash uncommitted changes: git stash"
    echo "3. Check existing branches: git branch -a"
    echo "4. Retry branch creation after resolving issues"
    exit 1
fi
```

**Branch Name Collision Resolution:**
```bash
# Handle existing branch with unique suffix
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    BRANCH_NAME="${BRANCH_NAME}-$(date +%s)"
    echo "Branch collision, using unique name: $BRANCH_NAME"
fi
```

**Stale Branch Cleanup:**
```bash
# Clean up old feature branches before creating new ones
git branch -D $(git branch | grep "feature/issue-" | head -5) 2>/dev/null || true

# Remove remote tracking branches that no longer exist
git remote prune origin
```

**Prerequisites Check:**
- **Git Status**: Ensure working directory is clean
- **Git Version**: Standard git checkout functionality
- **Repository State**: No uncommitted changes blocking branch creation

### Project Management Error Handling
- **API Token Validation**: Check token validity before attempting status updates
- **Permission Verification**: Ensure user has write access to project/board
- **Graceful Degradation**: Continue with development workflow even if status automation fails
- **Manual Fallback Instructions**: Provide clear steps for manual status updates
- **Retry Logic**: Implement exponential backoff for transient API failures
- **Error Reporting**: Log detailed error information for debugging

### Specific GitHub Projects v2 Troubleshooting
**Common Error: "invalid number: PVT_kwDOBdX4b84AAW_U"**
- **Cause**: Using project ID instead of project number in `gh project field-list`
- **Fix**: Use the numeric project number (first column from `gh project list`)
- **Correct**: `gh project field-list 2 --owner USERNAME`
- **Incorrect**: `gh project field-list PVT_kwHOATGsKs4A-OnP --owner USERNAME`

**Common Error: "project-id must be provided"**
- **Cause**: Missing `--project-id` parameter in `gh project item-edit`
- **Fix**: Always include `--project-id` with the full project ID (PVT_xxx format)
- **Correct**: `gh project item-edit --project-id PVT_kwHOATGsKs4A-OnP --id ITEM_ID ...`

**Issue Not Found in Project**
- **Check**: Verify issue is actually added to the project
- **Fix**: Add to project first: `gh project item-add PROJECT_NUMBER --owner USERNAME --content-id ISSUE_NODE_ID`
- **Get Issue Node ID**: `gh issue view ISSUE_NUMBER --json id --jq '.id'`

**Status Field Options**
- **Common Names**: "Todo", "In Progress", "In Review", "Done"
- **Case Sensitive**: Must match exactly
- **Get Options**: `gh project field-list PROJECT_NUMBER --owner USERNAME --format json | jq '.fields[] | select(.name == "Status") | .options'`

### Fallback Procedures
If project management automation fails:
1. **Continue Development**: Don't block the development workflow
2. **Display Manual Instructions**: Show user exactly how to update status manually
3. **Log Error Details**: Capture error for later debugging
4. **Verify at End**: Check status was updated during final verification phase

**Manual Status Update Instructions:**
```bash
# GitHub Projects v2
echo "Please manually move issue #123 to 'In Progress' in the project board"
echo "Project URL: https://github.com/users/USERNAME/projects/PROJECT_NUMBER"

# Linear
echo "Please update issue status to 'In Progress' in Linear"
echo "Issue URL: https://linear.app/TEAM/issue/ISSUE_ID"

# Jira
echo "Please transition issue to 'In Progress' in Jira"
echo "Issue URL: $JIRA_BASE_URL/browse/$ISSUE_KEY"
```

## Integration Points

### CLAUDE.md Requirements
```markdown
## GitHub Issue Workflow
- **Test Commands**:
  - Users: `cd users && rails test`
  - Auth: `cd auth && rails test`
  - Notifications: `cd notifications && rails test`
  - UI: `cd ui && npm test`
- **Lint Commands**:
  - Rails: `rubocop`
  - React: `npm run lint`
- **Type Check**: `cd ui && npm run type-check`
- **Branch Prefix**: `feature/`
- **Services**: users, auth, notifications, ui, gateway
```

### Project Management Integration

#### Configuration Setup
**Environment Variables Required:**
```bash
# GitHub Projects v2 (recommended)
export GITHUB_PROJECT_ID="PVT_kwDOExample"
export GITHUB_PROJECT_STATUS_FIELD="Status"
export GITHUB_PROJECT_IN_PROGRESS_VALUE="In Progress"
export GITHUB_PROJECT_IN_REVIEW_VALUE="In Review"

# Alternative: Linear
export LINEAR_API_KEY="lin_api_xxx"
export LINEAR_TEAM_ID="TEAM"

# Alternative: Jira
export JIRA_API_TOKEN="xxx"
export JIRA_BASE_URL="https://company.atlassian.net"
export JIRA_PROJECT_KEY="PROJ"
```

#### Automatic Status Management
- **"In Progress"**: Triggered when feature branch is created
- **"In Review"**: Triggered when pull request is created
- **Error Handling**: Falls back to manual instructions if automation fails
- **Verification**: Confirms status changes were successful

#### Supported Project Management Tools
1. **GitHub Projects v2** (Primary)
   - Uses `gh project` commands
   - Integrates with issue metadata
   - Supports custom field mapping

2. **Linear**
   - REST API integration
   - Team-based workflow support
   - Status transition automation

3. **Jira**
   - REST API with authentication
   - Custom workflow support
   - Transition ID mapping

## Command Implementation

The slash command will be implemented as a Claude Code workflow that:
1. Analyzes the GitHub issue and detects project management integration
2. Creates a comprehensive todo list with status automation checkpoints
3. Executes the development workflow with automatic status updates
4. Provides real-time progress updates including project status changes
5. Handles errors and provides recovery options for both code and project management

## Project Management Implementation Examples

### GitHub Projects v2 Setup
```bash
# Get project information
gh project list --owner OWNER

# Get project field IDs
gh project field-list PROJECT_ID

# Get status field options
gh project field-list PROJECT_ID --format json | jq '.fields[] | select(.name == "Status") | .options'

# Update issue status (used in automation)
gh project item-edit --id $ITEM_ID --field-id $STATUS_FIELD_ID --single-select-option-id $OPTION_ID
```

### Linear Integration Setup
```bash
# Get team information
curl -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -d '{"query": "{ teams { nodes { id name states { nodes { id name } } } } }"}'

# Update issue status (used in automation)
curl -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -d '{"query": "mutation { issueUpdate(id: \"$ISSUE_ID\", input: {stateId: \"$STATE_ID\"}) { success issue { state { name } } } }"}'
```

### Jira Integration Setup
```bash
# Get project information
curl -X GET "$JIRA_BASE_URL/rest/api/3/project/$PROJECT_KEY" \
  -H "Authorization: Bearer $JIRA_API_TOKEN"

# Get available transitions for an issue
curl -X GET "$JIRA_BASE_URL/rest/api/3/issue/$ISSUE_KEY/transitions" \
  -H "Authorization: Bearer $JIRA_API_TOKEN"

# Transition issue status (used in automation)
curl -X POST "$JIRA_BASE_URL/rest/api/3/issue/$ISSUE_KEY/transitions" \
  -H "Authorization: Bearer $JIRA_API_TOKEN" \
  -d '{"transition": {"id": "$TRANSITION_ID"}}'
```

## Practical Examples

### Example 1: Rails CRUD Feature (CORRECT PATTERN)
**Issue**: "Add user profile management with email validation"
**Service**: Users
**✅ CORRECT Commits (Implementation + Tests Together):**
1. `feat(users): add user profile migration, model, and tests for issue #123`
   - Migration + Model + Model Tests in ONE commit
2. `feat(users): add profile validation, callbacks, and expanded tests for issue #123`
   - Model Logic + Updated Model Tests in ONE commit
3. `feat(users): add profile controller, actions, and tests for issue #123`
   - Controller + Controller Tests in ONE commit
4. `feat(users): add profile serializers, error handling, and tests for issue #123`
   - Serializers + Serializer Tests in ONE commit
5. `test(users): add profile API integration tests for issue #123`
   - Integration tests (separate - tests whole API)
6. `feat(users): add profile event publishing and tests for issue #123`
   - Event Publishing + Event Tests in ONE commit

**❌ INCORRECT Pattern (What NOT To Do):**
~~1. `feat(users): add user profile migration for issue #123`~~
~~2. `feat(users): add user profile model for issue #123`~~
~~3. `test(users): add user profile model tests for issue #123`~~ ← **NEVER SEPARATE LIKE THIS**

### Example 2: React Feature (CORRECT PATTERN)
**Issue**: "Add notification preferences UI with toggle switches"
**Service**: UI
**✅ CORRECT Commits (Implementation + Tests Together):**
1. `feat(ui): add notification preferences redux slice and tests for issue #124`
   - Redux Slice + Slice Tests in ONE commit
2. `feat(ui): add notification API endpoints and tests for issue #124`
   - API Endpoints + API Tests in ONE commit
3. `feat(ui): add toggle switch components and tests for issue #124`
   - Components + Component Tests in ONE commit
4. `feat(ui): add notification preferences container and tests for issue #124`
   - Container + Container Tests in ONE commit
5. `feat(ui): add preferences routes, navigation, and tests for issue #124`
   - Routes + Route Tests in ONE commit
6. `test(ui): add notification preferences E2E tests for issue #124`
   - E2E tests (separate - tests whole feature)

**❌ INCORRECT Pattern (What NOT To Do):**
~~1. `feat(ui): add redux slice for issue #124`~~
~~2. `test(ui): add redux slice tests for issue #124`~~ ← **NEVER SEPARATE LIKE THIS**

### Example 3: Cross-Service Feature (CORRECT PATTERN)
**Issue**: "Send welcome email when user signs up"
**Services**: Auth, Users, Notifications
**✅ CORRECT Commits (Implementation + Tests Together):**
1. `feat(users): add user creation event publishing and tests for issue #125`
   - Event Publishing + Event Publishing Tests in ONE commit
2. `feat(events): update user event schema and tests for welcome emails for issue #125`
   - Schema Updates + Schema Tests in ONE commit
3. `feat(notifications): add welcome email handler and tests for issue #125`
   - Email Handler + Handler Tests in ONE commit
4. `feat(auth): integrate user creation events in sign-up and tests for issue #125`
   - Integration Code + Integration Tests in ONE commit
5. `test(integration): add welcome email flow E2E tests for issue #125`
   - E2E tests (separate - tests whole flow across services)

**❌ INCORRECT Pattern (What NOT To Do):**
~~1. `feat(users): add event publishing for issue #125`~~
~~2. `test(users): add event publishing tests for issue #125`~~ ← **NEVER SEPARATE LIKE THIS**

## Edge Cases and Error Handling

### Test Failures
- **Strategy**: Fix failing tests before proceeding to next step
- **Rollback**: Revert to previous working commit if unfixable
- **Alternative**: Create simpler implementation that passes tests

### UUID Constraint Violations
- **Detection**: Check for integer IDs in migrations/models
- **Fix**: Update to use UUID primary keys
- **Validation**: Ensure proper `references` in migrations

### Event Schema Conflicts
- **Detection**: Kafka consumer errors or schema mismatches
- **Fix**: Update event schemas gradually with backward compatibility
- **Testing**: Verify both old and new consumers work

### Cross-Service Dependencies
- **Detection**: API call failures between services
- **Strategy**: Implement provider service changes first
- **Validation**: Test service integration after each change

### TypeScript Compilation Errors
- **Detection**: Run `npm run type-check` after each React commit
- **Fix**: Update type definitions and interfaces
- **Validation**: Ensure strict type safety maintained

## 🎯 FINAL MANDATORY WORKFLOW SUMMARY

**YOU MUST COMPLETE THESE STEPS FOR EVERY ISSUE:**

### Phase 1: Setup (REQUIRED)
- [ ] **FIRST**: Update issue status to "In Progress" on ALL projects (replace 123 with actual issue number):
  ```bash
  # Step 1: Discover which projects this issue belongs to
  gh issue view 123 --repo pitts114/microservices-demo --json projectItems

  # Step 2: Get project numbers/IDs
  gh project list --owner pitts114

  # Step 3: For EACH project the issue is on, update status to "In Progress"
  # Example for "users service" project:
  gh project item-list 2 --owner pitts114 --format json | jq -r ".items[] | select(.content.number == 123) | .id"
  gh project item-edit --project-id PVT_kwHOATGsKs4A-OnP --id PVTI_lAHOATGsKs4A-OnPzgcvkiU --field-id PVTSSF_lAHOATGsKs4A-OnPzgxsgik --single-select-option-id 47fc9ee4

  # Repeat for each additional project the issue belongs to
  ```
- [ ] Verify status update succeeded before proceeding
- [ ] Create and checkout feature branch (replace 123, users, profile-validation with actual values):
  ```bash
  git pull origin master
  git checkout -b feature/issue-123-users-profile-validation
  ```
- [ ] Confirm you're on feature branch (not master/main)
- [ ] Understand the issue requirements completely

### Phase 2: Development (REQUIRED)
- [ ] Follow bottom-up development (database → models → controllers → views)
- [ ] Make atomic commits with proper format: `feat(service): description for issue #{number}`
- [ ] Include tests with each implementation
- [ ] Verify tests pass before each commit
- [ ] Never commit failing tests

### Phase 3: Completion (REQUIRED)
- [ ] All tests pass (unit, integration, E2E)
- [ ] Code follows project conventions
- [ ] All commits are properly formatted
- [ ] Push feature branch to remote
- [ ] Create pull request with descriptive title that explains what the changes do
- [ ] Use proper PR template with detailed change summary

### Phase 4: Verification (REQUIRED)
- [ ] PR description references the issue: `Closes #{number}`
- [ ] All CI checks pass
- [ ] **Verify Project Status Updates (ALL Projects):**
  - [ ] Issue was successfully moved to "In Progress" on ALL projects when branch was created
  - [ ] Issue was successfully moved to "In Review" on ALL projects when PR was created
  - [ ] If automation failed, manual status updates were completed on all relevant project boards
  - [ ] ALL project boards reflect current status accurately
  - [ ] Check each project the issue belongs to: `gh issue view 123 --repo pitts114/microservices-demo --json projectItems`
- [ ] Code review completed
- [ ] Branch merged and cleaned up
- [ ] **Final Status Verification**: Issue automatically moves to "Done" when PR is merged (if configured)

**❌ NEVER:**
- Work directly on master/main branch
- Commit failing tests
- Skip the feature branch creation step
- Work directly on master/main without creating a feature branch
- Use incorrect commit message format
- Create commits without tests
- Work on master/main instead of the feature branch

This workflow ensures consistent, high-quality implementations that follow the project's microservices architecture and maintain code quality standards.
