# API Keys Setup

This project uses API keys that should **NOT** be committed to version control.

## Setup Instructions

1. **Copy the example file:**
   ```bash
   cp xproject/KetoMacroTracker/KetoMacroTracker/Services/APIKeys.plist.example xproject/KetoMacroTracker/KetoMacroTracker/Services/APIKeys.plist
   ```

2. **Edit `APIKeys.plist` and add your API key:**
   - Open `xproject/KetoMacroTracker/KetoMacroTracker/Services/APIKeys.plist`
   - Replace `YOUR_USDA_API_KEY_HERE` with your actual USDA API key
   - Get your API key from: https://fdc.nal.usda.gov/api-key-signup.html

3. **Verify `.gitignore`:**
   - The `APIKeys.plist` file is already in `.gitignore`
   - It will NOT be committed to Git

## For App Store Distribution

The app will work with the hardcoded fallback key if `APIKeys.plist` is not found. However, for production:

1. **Option 1:** Use `APIKeys.plist` (recommended)
   - Add the file to your Xcode project
   - Make sure it's included in the app bundle
   - The key will be in the app but not in source control

2. **Option 2:** Use a backend proxy (best for scale)
   - Move API calls to your own server
   - Rotate keys as needed
   - Better rate limit management

## Rate Limits

- **USDA API:** 1,000 requests per hour per IP/API key
- **OpenFoodFacts:** No rate limit (public API)

The app automatically falls back to OpenFoodFacts if USDA rate limit is reached.

## Monitoring

### Client-Side Tracking
The app tracks API usage locally on each device. View statistics:
- Go to **Profile** → **Data Export** → **API Usage Statistics**
- See requests, success rates, rate limit events
- Export usage data as JSON

### Console Logs
Rate limit errors are logged to the console with:
- `⚠️ USDA API Rate Limit Reached (429)`
- `📊 Rate limit monitoring: USDA API has reached 1000 requests/hour limit`

### Limitations
**You cannot monitor other users' usage** with a hardcoded key. All requests appear from the same API key. For production scale, consider a backend proxy (see `API_MONITORING_GUIDE.md`).

