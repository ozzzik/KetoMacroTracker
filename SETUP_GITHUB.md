# Setting Up GitHub Repository

## Option 1: Using GitHub Web Interface (Recommended)

1. Go to https://github.com/new
2. Create a new repository:
   - **Repository name**: `KetoMacroTracker`
   - **Description**: "A comprehensive iOS app for tracking keto macros and managing your ketogenic diet journey"
   - **Visibility**: Choose Public or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
3. Click "Create repository"
4. Copy the repository URL (it will look like: `https://github.com/yourusername/KetoMacroTracker.git`)

5. Then run these commands in your terminal:
   ```bash
   cd /Users/ohardoon/KetoMacroTracker
   git remote add origin https://github.com/yourusername/KetoMacroTracker.git
   git branch -M main
   git push -u origin main
   ```

## Option 2: Using GitHub CLI (if you install it)

1. Install GitHub CLI:
   ```bash
   brew install gh
   gh auth login
   ```

2. Create the repository:
   ```bash
   cd /Users/ohardoon/KetoMacroTracker
   gh repo create KetoMacroTracker --public --source=. --remote=origin --push
   ```

## After Setup

Your repository will be available at:
`https://github.com/yourusername/KetoMacroTracker`

Make sure to:
- ✅ Keep `APIKeys.plist` in `.gitignore` (already configured)
- ✅ Never commit sensitive API keys
- ✅ Update the README.md with your actual license if needed





