# GitHub Actions Workflows

This directory contains GitHub Actions workflows for CI/CD of the MobileDesignSystem library.

## Workflows

### `ci.yml` - Continuous Integration
Runs on every push and pull request to `main` and `develop` branches.

**What it does:**
- Builds the Swift Package using `swift build`
- Runs tests using `swift test`
- Builds the package with Xcode for multiple iOS simulators
- Attempts to build the example app (if it exists)
- Runs SwiftLint (if available)

**Matrix Strategy:**
- Tests on iPhone 15 and iPhone 15 Pro simulators

### `build-example.yml` - Example App Build
Runs when example app files change or can be manually triggered.

**What it does:**
- Resolves package dependencies
- Builds the example app for multiple devices
- Archives build artifacts

**Matrix Strategy:**
- Tests on iPhone 15 and iPad Pro (12.9-inch) simulators

### `release.yml` - Release Build
Runs when a new release is created or can be manually triggered.

**What it does:**
- Builds the package in release configuration
- Runs tests
- Creates a release archive
- Uploads artifacts

## Usage

### Running CI Locally

To test the CI workflow locally, you can use [act](https://github.com/nektos/act):

```bash
# Install act (macOS)
brew install act

# Run the CI workflow
act push

# Run a specific workflow
act workflow_dispatch -W .github/workflows/build-example.yml
```

### Manual Workflow Dispatch

You can manually trigger workflows from the GitHub Actions tab:
1. Go to Actions tab in your repository
2. Select the workflow you want to run
3. Click "Run workflow"
4. Select branch and fill in any required inputs

## Requirements

- macOS latest runner (required for iOS builds)
- Xcode (automatically available on GitHub-hosted macOS runners)
- Swift Package Manager

## Notes

- The workflows skip code signing for CI builds (`CODE_SIGNING_REQUIRED=NO`)
- Package dependencies are resolved before building
- Build artifacts are cached to speed up subsequent builds
- Example app builds are optional and won't fail the CI if the app doesn't exist
