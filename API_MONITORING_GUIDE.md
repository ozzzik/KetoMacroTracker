# API Usage Monitoring Guide

## The Challenge

With a **hardcoded API key** in your app, you **cannot monitor individual users** because:
- All requests appear to come from the same API key
- USDA API doesn't provide per-user analytics
- You can't distinguish between different app users

## What We've Implemented

### 1. **Client-Side Usage Tracking** ✅
- Tracks all API requests locally on each device
- Logs success/failure, response times, rate limits
- Stores last 1000 events per device
- **Location**: `Services/APIUsageTracker.swift`

### 2. **Rate Limit Detection** ✅
- Automatically detects HTTP 429 (rate limit exceeded)
- Falls back to OpenFoodFacts silently
- Logs rate limit events for monitoring

### 3. **Usage Statistics View** ✅
- View in Profile → Data Export → "API Usage Statistics"
- Shows:
  - Total USDA requests (last 24 hours)
  - Success/failure counts
  - Rate limit events
  - Average response time
  - OpenFoodFacts usage
- Export usage data as JSON

## How to Monitor (Current Limitations)

### ❌ What You CAN'T Do:
- See which specific users are making requests
- Track usage across all users in real-time
- Get aggregate statistics from all users
- Know if one user is consuming all the quota

### ✅ What You CAN Do:

#### Option 1: User-Reported Data
- Users can export their usage data
- They can share it with you for analysis
- **Not practical for large-scale monitoring**

#### Option 2: Console Logs (Development Only)
- Check Xcode console for rate limit warnings
- Look for: `⚠️ USDA API Rate Limit Reached (429)`
- **Only works during development/testing**

#### Option 3: Backend Proxy (Recommended for Production)
Create a backend service that:
- Proxies all API requests
- Tracks usage per user/device
- Rotates API keys as needed
- Provides analytics dashboard
- Manages rate limits centrally

## Recommended Solution: Backend Proxy

For production apps with many users, you should:

1. **Create a backend API** (Node.js, Python, etc.)
2. **Proxy requests** through your server
3. **Track usage** per user/device ID
4. **Rotate keys** if you hit limits
5. **Add caching** to reduce API calls
6. **Monitor** with analytics dashboard

### Example Architecture:
```
App → Your Backend → USDA API
     ↓
  Analytics DB
     ↓
  Dashboard
```

## Current Implementation Benefits

Even with limitations, the current tracking helps:
- **Debug issues**: See if rate limits are being hit
- **User support**: Users can export data to help diagnose problems
- **Development**: Monitor your own usage during testing
- **Planning**: Understand usage patterns before scaling

## Next Steps

1. **For MVP/Initial Release**: Current implementation is fine
2. **For Scale**: Plan backend proxy when you have 100+ active users
3. **Monitor**: Check console logs and user reports
4. **Optimize**: Add caching, reduce unnecessary requests

## Accessing Usage Stats

1. Open the app
2. Go to **Profile** tab
3. Scroll to **Data Export** section
4. Tap **"API Usage Statistics"**
5. View stats or export data

The stats show **your device's usage only**, not all users combined.

