# TestFlight CI/CD Setup Guide

This guide explains how to configure automated TestFlight deployments for Growfolio iOS.

## Overview

The TestFlight workflow (`testflight.yml`) automatically builds and uploads your app to TestFlight when:
- A version tag is pushed (e.g., `v1.0.0`)
- Manually triggered via GitHub Actions

## Required Secrets

Add these secrets in **Settings → Secrets and variables → Actions**:

### App Store Connect API

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_KEY_ID` | Your API Key ID (e.g., `ABC123DEFG`) |
| `APP_STORE_CONNECT_ISSUER_ID` | Your Issuer ID (UUID format) |
| `APP_STORE_CONNECT_KEY` | Contents of your `.p8` API key file |

**How to get these:**
1. Go to [App Store Connect → Users and Access → Keys](https://appstoreconnect.apple.com/access/api)
2. Click "+" to create a new key
3. Name it "GitHub Actions" and select "App Manager" role
4. Download the `.p8` file (only available once!)
5. Copy the Key ID and Issuer ID from the page

### Code Signing

| Secret | Description |
|--------|-------------|
| `APPLE_TEAM_ID` | Your Apple Developer Team ID (10 characters) |
| `IOS_DISTRIBUTION_CERTIFICATE_P12` | Base64-encoded distribution certificate |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password for the .p12 file |
| `IOS_PROVISIONING_PROFILE_APPSTORE` | Base64-encoded App Store provisioning profile |
| `PROVISIONING_PROFILE_NAME` | Name of your provisioning profile |

**How to create the certificate:**

```bash
# Export from Keychain Access, then encode:
base64 -i Certificates.p12 | pbcopy
# Paste into IOS_DISTRIBUTION_CERTIFICATE_P12 secret
```

**How to create the provisioning profile:**

```bash
# Download from Apple Developer Portal, then encode:
base64 -i Growfolio_AppStore.mobileprovision | pbcopy
# Paste into IOS_PROVISIONING_PROFILE_APPSTORE secret
```

### Optional: Slack Notifications

| Secret | Description |
|--------|-------------|
| `SLACK_WEBHOOK_URL` | Incoming webhook URL for deployment notifications |

## Usage

### Automatic Deployment (Tags)

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

This will:
1. Build the app with version `1.0.0`
2. Increment the build number
3. Upload to TestFlight
4. Create a GitHub release

### Manual Deployment

1. Go to **Actions → TestFlight Deployment**
2. Click **Run workflow**
3. Select version bump type:
   - `build` - Only increment build number (1.0.0 build 1 → 1.0.0 build 2)
   - `patch` - Increment patch version (1.0.0 → 1.0.1)
   - `minor` - Increment minor version (1.0.0 → 1.1.0)
   - `major` - Increment major version (1.0.0 → 2.0.0)

## Troubleshooting

### "Code signing not configured"

Ensure all certificate secrets are properly base64 encoded:
```bash
base64 -i YourCertificate.p12 | tr -d '\n'
```

### "App Store Connect API key not configured"

1. Verify the `.p8` file contents are complete (including `-----BEGIN/END PRIVATE KEY-----`)
2. Check that Key ID and Issuer ID are correct

### "No matching provisioning profile"

1. Ensure the provisioning profile is for App Store distribution
2. Verify it matches your bundle ID (`com.growfolio.app`)
3. Check it's not expired

### Build number conflicts

If TestFlight rejects due to duplicate build numbers:
1. Manually increment `CURRENT_PROJECT_VERSION` in `project.yml`
2. Commit and push
3. Re-run the workflow

## Local Testing

Test the build locally before pushing:

```bash
# Install dependencies
brew install xcodegen
xcodegen generate

# Build archive (without signing)
xcodebuild archive \
  -project Growfolio.xcodeproj \
  -scheme Growfolio \
  -configuration Release \
  -archivePath build/Growfolio.xcarchive \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO
```

## Security Notes

- Never commit certificates or API keys to the repository
- Rotate API keys periodically
- Use environment-specific provisioning profiles
- Consider using [Fastlane Match](https://docs.fastlane.tools/actions/match/) for team certificate management
