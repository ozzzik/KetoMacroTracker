# GitHub Pages Setup for Privacy Policy

## How You Set Up `https://ozzzik.github.io/ket/privacy-policy.html`

You likely:
1. Created a repository named `ket`
2. Enabled GitHub Pages in repository settings
3. Put `privacy-policy.html` in the repository root
4. Set GitHub Pages to deploy from the `main` branch

The URL format is: `https://[username].github.io/[repository-name]/[filename]`

## Setting Up GitHub Pages for KetoMacroTracker

### Step 1: Enable GitHub Pages

1. Go to your repository: `https://github.com/ozzzik/KetoMacroTracker`
2. Click **Settings** (in the repository navigation bar)
3. Scroll down to **Pages** (in the left sidebar)
4. Under **Source**:
   - Select **Deploy from a branch**
   - **Branch**: Select `main` (or `master` if that's your default)
   - **Folder**: Select `/ (root)` 
5. Click **Save**

### Step 2: Verify File Location

Your `privacy-policy.html` should be in the **root** of your repository:
```
KetoMacroTracker/
├── privacy-policy.html  ← Should be here
├── README.md
├── LICENSE
└── ...
```

✅ The file is already in the correct location!

### Step 3: Wait for GitHub Pages to Build

After enabling GitHub Pages:
- GitHub will build your site (usually takes 1-2 minutes)
- You'll see a message: "Your site is live at https://ozzzik.github.io/KetoMacroTracker/"
- The privacy policy will be available at: `https://ozzzik.github.io/KetoMacroTracker/privacy-policy.html`

### Step 4: Update ProfileView

Once GitHub Pages is enabled, update the Privacy Policy link in `ProfileView.swift`:

```swift
Link(destination: URL(string: "https://ozzzik.github.io/KetoMacroTracker/privacy-policy.html")!) {
```

This is cleaner than the GitHub blob URL and provides a better mobile experience.

## Alternative: Using a `docs` Folder

If you prefer to use a `docs` folder (like some projects do):

1. Create a `docs` folder in your repository root
2. Move `privacy-policy.html` to `docs/privacy-policy.html`
3. In GitHub Pages settings, select **Folder**: `/docs`
4. The URL will be the same: `https://ozzzik.github.io/KetoMacroTracker/privacy-policy.html`

## Current Status

Your privacy policy is accessible at:
- **GitHub web view**: `https://github.com/ozzzik/KetoMacroTracker/blob/main/privacy-policy.html` ✅ (works now)
- **GitHub Pages**: `https://ozzzik.github.io/KetoMacroTracker/privacy-policy.html` (will work after enabling Pages)

## Quick Steps Summary

1. ✅ Repository exists: `ozzzik/KetoMacroTracker`
2. ✅ File exists: `privacy-policy.html` in root
3. ⏳ Enable GitHub Pages in repository settings
4. ⏳ Wait for build (1-2 minutes)
5. ✅ Update ProfileView URL to GitHub Pages URL

That's it! After enabling GitHub Pages, your privacy policy will be accessible at the clean URL just like your `ket` repository.


