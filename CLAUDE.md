# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Finn** - AI-powered family budget assistant

This is a Flutter mobile application for family budget management with:
- Dual-repository workflow (development + production)
- Build flavors for parallel installation (dev + production apps)
- Shared budget tracking and expense management
- AI-powered budgeting assistant (Finn)

## Workflow Commands

The project uses slash commands in `.claude/commands/speckit.*` for the development workflow:

| Command | Purpose |
|---------|---------|
| `/speckit.specify` | Create feature specification from natural language description |
| `/speckit.clarify` | Ask clarification questions about underspecified areas in spec |
| `/speckit.plan` | Generate technical implementation plan from specification |
| `/speckit.tasks` | Generate dependency-ordered task list from plan |
| `/speckit.implement` | Execute tasks defined in tasks.md |
| `/speckit.analyze` | Cross-artifact consistency analysis |
| `/speckit.checklist` | Generate custom checklist for feature |
| `/speckit.taskstoissues` | Convert tasks to GitHub issues |
| `/speckit.constitution` | Create/update project principles |

## Custom Workflow Skill

### `/dev-workflow` - Development & Release Management

Custom skill for managing the development lifecycle:
- **Daily commits**: Commit and push changes to test repository
- **Production releases**: Version bumping, tagging, and deployment to production
- **Build flavors**: Managing dev and production app installations
- **Hotfix workflow**: Emergency production fixes
- **Semantic versioning**: MAJOR.MINOR.PATCH+BUILD management

**Quick reference**: See `WORKFLOW.md` in project root
**Full documentation**: `.claude/commands/dev-workflow.md`

Use this skill when you need guidance on Git workflow, versioning, or releases.

## Workflow Sequence

```
/speckit.specify → /speckit.clarify (optional) → /speckit.plan → /speckit.tasks → /speckit.implement
```

## Repository Setup

**Development Repository** (origin):
- Organization: `ecologicaleaving`
- Repository: `finn`
- Branch: `test` (main development branch)
- URL: https://github.com/ecologicaleaving/finn

**Production Repository** (production):
- Organization: `80-20Solutions`
- Repository: `finn`
- Branch: `master` (stable releases only)
- URL: https://github.com/80-20Solutions/finn
- Visibility: Public

## Build Flavors

The project uses Android flavors for parallel app installation:

- **Production**: `com.ecologicaleaving.fin` - App name: "Fin"
- **Dev**: `com.ecologicaleaving.fin.dev` - App name: "Fin Dev"

Configuration files:
- `android/app/build.gradle` - Flavor definitions
- `android/app/src/main/AndroidManifest.xml` - App label placeholder
- `android/app/src/dev/res/values/strings.xml` - Dev flavor strings

## Directory Structure

- `.specify/templates/` - Templates for spec, plan, tasks, and checklists
- `.specify/memory/constitution.md` - Project principles and constraints (customize per project)
- `.specify/scripts/powershell/` - Helper scripts for workflow commands
- `.claude/commands/` - Slash command definitions
- `WORKFLOW.md` - Quick reference for development workflow

## Key Scripts

Run from repository root:

```powershell
# Create new feature branch and spec file
.specify/scripts/powershell/create-new-feature.ps1 -Json "feature description"

# Setup plan workflow
.specify/scripts/powershell/setup-plan.ps1 -Json

# Check prerequisites before tasks/implement
.specify/scripts/powershell/check-prerequisites.ps1 -Json

# Update agent context after planning
.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude
```

## Feature Development Pattern

Each feature creates:
- `specs/<number>-<short-name>/spec.md` - Feature specification
- `specs/<number>-<short-name>/plan.md` - Technical plan
- `specs/<number>-<short-name>/tasks.md` - Implementation tasks
- `specs/<number>-<short-name>/checklists/` - Validation checklists
- Optional: `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

## Task Format

Tasks in tasks.md follow strict format:
```
- [ ] T001 [P] [US1] Description with file path
```
- `T001` - Sequential task ID
- `[P]` - Parallelizable marker (optional)
- `[US1]` - User story reference (required for story phases)
