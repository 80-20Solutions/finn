# Development Workflow & Release Management

A comprehensive workflow for managing development, testing, and production releases with multi-repository setup and build flavors.

## When to Use This Skill

Use this skill when you need to:
- Commit and push changes to the test/development repository
- Create a new release and push to production
- Manage version numbers (semantic versioning)
- Work with development and production build flavors
- Create release notes and changelogs

## Project Configuration

This workflow assumes the following setup:
- **Development Repository**: `origin` remote (e.g., ecologicaleaving/finn)
- **Production Repository**: `production` remote (e.g., 80-20Solutions/finn)
- **Test Branch**: `test` (main development branch)
- **Production Branch**: `master` (stable releases only)
- **Build Flavors**: `dev` and `production` (for parallel app installation)

## Workflow Instructions

You are helping manage a Flutter project with a dual-repository setup:
- Development work happens on the `test` branch and is pushed to the `origin` remote
- Production releases are pushed to the `production` remote on the `master` branch
- The project uses Android build flavors to allow dev and production apps to coexist

### 1. Development Workflow (Daily Work)

When the user wants to commit and push development changes:

1. **Check Current State**:
   ```bash
   git status
   git branch
   ```

2. **Stage and Commit Changes**:
   ```bash
   git add .
   git commit -m "descriptive message

   Detailed description if needed.

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

3. **Push to Development Repository**:
   ```bash
   # If on feature branch, push feature branch
   git push origin <branch-name>

   # If ready to merge to test
   git checkout test
   git merge <branch-name>
   git push origin test
   ```

4. **Test with Dev Flavor**:
   ```bash
   flutter run --flavor dev -d <device-id>
   ```

### 2. Release Workflow (Production Deploy)

When the user wants to create a production release:

1. **Verify Test Branch is Stable**:
   - Ensure all tests pass
   - Verify functionality with dev flavor
   - Review changelog and release notes

2. **Update Version Number**:
   - Read `pubspec.yaml` to get current version
   - Ask user for new version number (follow semantic versioning: MAJOR.MINOR.PATCH)
   - Update version in `pubspec.yaml`:
     ```yaml
     version: 1.2.0+10
     # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
     ```

3. **Create Release Commit**:
   ```bash
   git add pubspec.yaml
   git commit -m "chore: bump version to X.Y.Z

   Release notes:
   - Feature/fix summary
   - Breaking changes (if any)

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

4. **Tag the Release**:
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z - Brief description"
   git push origin vX.Y.Z
   ```

5. **Push to Production**:
   ```bash
   # Push test branch to production master
   git push production test:master

   # Push tags to production
   git push production --tags
   ```

6. **Create GitHub Release** (optional):
   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z - Release Title" --notes "Release notes"
   ```

### 3. Version Numbering Guide

Follow semantic versioning (SemVer):
- **MAJOR** (1.0.0): Breaking changes, incompatible API changes
- **MINOR** (0.1.0): New features, backwards-compatible
- **PATCH** (0.0.1): Bug fixes, backwards-compatible
- **BUILD** (+10): Build number, increment for each build

Examples:
- `1.0.0+1` - Initial release
- `1.1.0+2` - Added new feature
- `1.1.1+3` - Fixed bug
- `2.0.0+4` - Breaking change

### 4. Build Flavors

The project has two flavors for parallel installation:

**Production Flavor** (stable app):
```bash
# Run production app
flutter run --flavor production -d <device-id>

# Build production APK
flutter build apk --flavor production --release
```

**Dev Flavor** (testing app):
```bash
# Run dev app (for daily testing)
flutter run --flavor dev -d <device-id>

# Build dev APK
flutter build apk --flavor dev --debug
```

Properties:
- **Production**: Package `com.ecologicaleaving.fin`, name "Fin"
- **Dev**: Package `com.ecologicaleaving.fin.dev`, name "Fin Dev"

### 5. Hotfix Workflow

For urgent production fixes:

1. Create hotfix branch from production master:
   ```bash
   git fetch production
   git checkout -b hotfix/description production/master
   ```

2. Make fixes and test thoroughly

3. Bump PATCH version in `pubspec.yaml`

4. Commit and merge to both test and production:
   ```bash
   git checkout test
   git merge hotfix/description
   git push origin test

   git push production hotfix/description:master
   ```

## Repository Structure

```
origin (ecologicaleaving/finn)
├── test (main development branch)
├── feature/* (feature branches)
└── hotfix/* (hotfix branches)

production (80-20Solutions/finn)
└── master (stable releases only)
```

## Important Notes

- ⚠️ **Never push directly to production/master** without testing on test branch first
- ⚠️ **Always use dev flavor** for daily development and testing
- ⚠️ **Production flavor is for stable releases** - users have this installed
- 💡 **Semantic versioning** helps users understand update significance
- 💡 **Tags mark releases** and allow rollback if needed
- 💡 **Two apps can coexist** on the same device during development

## Quick Command Reference

```bash
# Daily development
flutter run --flavor dev -d <device-id>
git add . && git commit -m "message"
git push origin test

# Create release
# 1. Update version in pubspec.yaml
# 2. Commit version bump
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
git push production test:master

# Build for release
flutter build apk --flavor production --release

# Check configuration
git remote -v
git branch -a
flutter devices
```

## Examples

### Example 1: Daily Development

```
User: "Commit these changes and push to test"

Claude: Runs git status, stages changes, creates commit with descriptive message,
pushes to origin/test, confirms success.
```

### Example 2: Production Release

```
User: "Create a new release v1.2.0"

Claude:
1. Reads current version from pubspec.yaml
2. Updates version to 1.2.0+X (incrementing build number)
3. Creates release commit
4. Creates git tag v1.2.0
5. Pushes tag to origin
6. Pushes test branch to production/master
7. Confirms release is live
```

### Example 3: Testing Dev vs Production

```
User: "Install both dev and production apps to test"

Claude:
1. Builds and installs dev flavor: flutter run --flavor dev
2. Builds and installs production flavor: flutter run --flavor production
3. Confirms both apps are visible on device with different names
```

## Troubleshooting

### Remote URLs Changed
If repository was renamed:
```bash
git remote set-url origin https://github.com/new-org/new-name.git
git remote set-url production https://github.com/prod-org/new-name.git
```

### Flavors Not Working
Verify configuration:
- Check `android/app/build.gradle` for `productFlavors`
- Check `android/app/src/main/AndroidManifest.xml` for `${appName}` placeholder
- Verify `android/app/src/dev/res/values/strings.xml` exists

### Version Conflicts
If version number conflicts occur, manually edit `pubspec.yaml` and ensure
format is correct: `version: X.Y.Z+BUILD`
