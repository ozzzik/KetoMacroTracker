# How to Contact Apple Developer Support for Icon Issue

## Step-by-Step Guide

### Step 1: Go to Apple Developer Support

1. **Open your web browser**
2. **Go to**: https://developer.apple.com/contact/
3. **Sign in** with your Apple Developer account (same account you use for App Store Connect)

### Step 2: Select Issue Type

1. **Under "What can we help you with?"**, select:
   - **"App Store Connect"** (from the dropdown or list)
2. **Under "What's your issue about?"**, select:
   - **"Technical Issue"** or **"App Store Connect Issue"**

### Step 3: Fill Out the Form

**You'll need to provide:**

1. **App Information:**
   - **App Name**: KetoMacroTracker
   - **App ID**: `com.whio.KetoMacroTracker`
   - **Bundle ID**: `com.whio.KetoMacroTracker`

2. **Issue Description:**
   Copy and paste this (or use as a template):

   ```
   App icon is not appearing in App Store Connect, even though it's properly included in the app binary.

   Issue Details:
   - App icon is visible in Xcode asset catalog
   - App icon file (AppIcon-1024.png) exists and is valid (1024x1024, PNG, no alpha)
   - Assets.car in archive is 589KB (confirms icon is compiled into binary)
   - Multiple builds have been uploaded to App Store Connect
   - Build processing completes successfully
   - However, App Store Connect shows placeholder/grid icon instead of actual app icon
   - StoreKit subscription purchase dialogs also show placeholder icon

   Verification:
   - Icon is properly configured in Assets.xcassets/AppIcon.appiconset/
   - Contents.json correctly references AppIcon-1024.png as "ios-marketing"
   - Info.plist has CFBundleIconName = "AppIcon"
   - Build settings: ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
   - Archive contains Assets.car (589KB) confirming icon is included

   This appears to be an App Store Connect auto-extraction issue, as the icon is correctly included in the binary but not being extracted during processing.

   Most recent build number: [INSERT YOUR BUILD NUMBER HERE]
   ```

3. **Attachments:**
   - **Screenshot 1**: App Store Connect showing placeholder icon (next to app name)
   - **Screenshot 2**: Xcode asset catalog showing your actual icon
   - **Screenshot 3** (optional): Archive showing Assets.car size (589KB)

### Step 4: Submit the Request

1. **Review your information**
2. **Click "Submit"** or "Send"
3. **You'll receive a confirmation email** with a ticket number

### Step 5: Follow Up

- **Check your email** for Apple's response (usually within 1-2 business days)
- **Reply to their email** if they ask for additional information
- **They may ask you to**:
  - Upload a new build
  - Provide additional screenshots
  - Wait for their backend team to investigate

## Alternative: Feedback Assistant

If the web form doesn't work, you can also use Feedback Assistant:

1. **Go to**: https://feedbackassistant.apple.com/
2. **Sign in** with your Apple ID
3. **Click "+" to create new feedback**
4. **Select**: "App Store Connect" or "Developer Tools"
5. **Fill out similar information** as above

## What to Include in Your Report

### Essential Information:
- ✅ App ID: `com.whio.KetoMacroTracker`
- ✅ Issue: Icon not auto-extracting from binary
- ✅ Verification: Assets.car is 589KB (icon is included)
- ✅ Build number: [Your most recent build]
- ✅ Screenshot: App Store Connect showing placeholder

### Technical Details (Optional but Helpful):
- Icon file: AppIcon-1024.png (1024x1024, PNG, RGB, no alpha)
- Asset catalog: Assets.xcassets/AppIcon.appiconset/
- Info.plist: CFBundleIconName = "AppIcon"
- Build setting: ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
- Archive verification: Assets.car = 589KB

## Expected Response Time

- **Initial response**: 1-2 business days
- **Resolution**: Usually within 3-5 business days
- **Complex issues**: May take longer

## What Apple Will Likely Do

1. **Verify the issue** on their end
2. **Check your app record** in their system
3. **Manually trigger icon extraction** if possible
4. **Update your app record** with the icon
5. **Follow up** with you to confirm it's resolved

## Tips for Success

1. **Be specific**: Include all the verification details
2. **Include screenshots**: Visual proof helps
3. **Be patient**: They handle many requests
4. **Follow up**: If no response in 3 days, reply to the ticket

## Quick Link

**Direct link to contact form**: https://developer.apple.com/contact/

**Select**: App Store Connect → Technical Issue
