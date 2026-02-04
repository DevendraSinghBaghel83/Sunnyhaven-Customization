# Sunnyhaven Customizations - AL-Go for GitHub

## 🚀 AL-Go CI/CD Setup Complete

This project has been configured with **AL-Go for GitHub** for automated CI/CD workflows.

---

## 📁 Project Structure

```
Sunnyhaven Customization/
├── .AL-Go/
│   └── settings.json           # Project-level settings
├── .github/
│   ├── AL-Go-Settings.json     # Repository settings
│   └── workflows/
│       ├── CICD.yml                    # Main CI/CD pipeline
│       ├── CreateRelease.yml           # Create GitHub releases
│       ├── CreateOnlineDevEnv.yml      # Create BC online dev environment
│       ├── IncrementVersionNumber.yml  # Version management
│       ├── PublishToEnvironment.yml    # Manual deployment
│       ├── PullRequestHandler.yml      # PR builds
│       └── UpdateAlGoSystemFiles.yml   # Update AL-Go files
├── SRC/
│   ├── Codeunit/               # Business logic
│   ├── Table/                  # Data models
│   ├── Page/                   # UI Pages
│   └── ...
└── app.json                    # BC App manifest
```

---

## ⚙️ GitHub Setup (Required Steps)

### Step 1: Push to GitHub Repository

```powershell
# Create new GitHub repository first, then:
git remote add github https://github.com/YOUR_ORG/Sunnyhaven-Customization.git
git push -u github main
```

### Step 2: Configure GitHub Secrets

Go to **GitHub Repository → Settings → Secrets and variables → Actions** and add:

| Secret Name | Description | Format |
|------------|-------------|--------|
| `LICENSEFILEURL` | BC License file URL | `https://...` |
| `Development_AUTHCONTEXT` | Dev environment auth | JSON (see below) |
| `Production_AUTHCONTEXT` | Prod environment auth | JSON (see below) |
| `GHTOKENWORKFLOW` | PAT with workflow permissions | Token string |

#### AuthContext JSON Format (Service-to-Service):

```json
{
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "your-client-secret",
  "environmentName": "YourEnvironmentName"
}
```

### Step 3: Configure GitHub Environments

Go to **GitHub Repository → Settings → Environments** and create:

1. **Development**
   - Add protection rules (optional)
   - Add `Development_AUTHCONTEXT` secret

2. **Production**
   - ✅ Require reviewers
   - ✅ Only allow `main` branch
   - Add `Production_AUTHCONTEXT` secret

---

## 🔄 Workflows Explained

### 1. CI/CD (`CICD.yml`)
- **Triggers**: Push to `main`, `release/*`, `feature/*` branches
- **Actions**: Build → Test → Deploy to Development
- **Artifacts**: Uploads `.app` files to GitHub

### 2. Create Release (`CreateRelease.yml`)
- **Manual trigger**
- Creates GitHub release with version tag
- Uploads compiled apps to release

### 3. Pull Request Build (`PullRequestHandler.yml`)
- **Triggers**: PR to `main` branch
- Validates code compiles without errors
- Posts build status to PR

### 4. Publish to Environment (`PublishToEnvironment.yml`)
- **Manual trigger**
- Deploy specific version to any environment

### 5. Update AL-Go System Files (`UpdateAlGoSystemFiles.yml`)
- **Manual trigger**
- Updates workflows to latest AL-Go version

### 6. Increment Version Number (`IncrementVersionNumber.yml`)
- **Manual trigger**
- Updates version in `app.json` and settings

### 7. Create Online Dev Environment (`CreateOnlineDevEnv.yml`)
- **Manual trigger**
- Creates BC sandbox environment via Admin Center API

---

## 🇦🇺 Country/Region

This project is configured for **Australia (au)**. To change:

1. Edit `.github/AL-Go-Settings.json` → `"country": "au"`
2. Edit `.AL-Go/settings.json` → `"country": "au"`

---

## 📋 Version Strategy

- **Strategy 0** (GitHub Run Number)
- Format: `Major.Minor.Build.Revision`
- Build = GitHub workflow run number
- Update via "Increment Version Number" workflow

---

## 🔗 Useful Links

- [AL-Go for GitHub Documentation](https://github.com/microsoft/AL-Go/blob/main/README.md)
- [AL-Go Workshop](https://aka.ms/algoworkshop)
- [AL-Go Settings Reference](https://github.com/microsoft/AL-Go/blob/main/Scenarios/settings.md)
- [Business Central Admin Center API](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/administration-center-api)

---

## 🆘 Troubleshooting

### Build Fails - Container Issues
```yaml
# In .github/AL-Go-Settings.json, try:
"useCompilerFolder": true
```

### Missing Dependencies
```yaml
# In .AL-Go/settings.json, add:
"installApps": [
  "https://url-to-dependency.app"
]
```

### Deployment Fails
1. Verify `AUTHCONTEXT` secret format
2. Check environment name matches exactly
3. Ensure Azure AD app has proper permissions

---

## 📊 Current Configuration

| Setting | Value |
|---------|-------|
| Type | PTE (Per-Tenant Extension) |
| Country | Australia (au) |
| Version | 1.0 |
| Runners | windows-latest |
| Code Analyzers | CodeCop, UICop, PTECop |

---

*Configured with AL-Go for GitHub v6.1*
