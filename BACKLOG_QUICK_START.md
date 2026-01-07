# Backlog Feature - Quick Start Guide

## For Users

### How to Use
1. **Login** to the app as a telecaller
2. **View Dashboard** - You'll see the Backlog KPI card showing the count
3. **Tap Backlog KPI** - Opens the backlog screen
4. **View Leads** - See all leads with callback scheduled
5. **Call Lead** - Tap the call button on any card
6. **Select Call Type** - Choose Manual or IVR
7. **Complete Call** - Make the call
8. **Submit Feedback** - Fill in the feedback modal
9. **Done** - Lead is removed from backlog

### What You'll See
- **Profile Avatar** with completion percentage
- **Name and TMID** (tap TMID to copy)
- **Mobile Number**
- **State and Role** (Driver/Transporter)
- **Registration Date**
- **Subscription Status**
- **Assigned Telecaller**
- **Call Button** to initiate call

## For Developers

### Key Files
```
lib/features/telecaller/screens/backlog_screen.dart
lib/features/telecaller/widgets/backlog_contact_card.dart
lib/models/smart_calling_models.dart (fromBacklogJson method)
```

### API Endpoint
```
GET https://truckmitr.com/api/telehead/backlog-leads
Headers:
  - Content-Type: application/json
  - Accept: application/json
  - Authorization: Bearer {token}
```

### Response Check
```dart
// CORRECT ✅
if (data['status'] == true) { ... }

// WRONG ❌
if (data['success'] == true) { ... }
```

### Debug
Check console for logs:
- 🔍 Loading status
- 👤 User info
- 🔑 Token status
- 📡 API response
- ✅ Success/Error

### Common Issues

**"No Backlog" shown but API has data**
- Check: `data['status']` not `data['success']`
- Fixed in current version ✅

**"User not logged in"**
- User needs to login first
- Token might be expired

**"Failed to load backlog"**
- Check network connection
- Verify API is accessible
- Check bearer token is valid

### Testing
```bash
# Test API with curl
curl -X GET "https://truckmitr.com/api/telehead/backlog-leads" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

## Status
✅ **Production Ready**
- All features working
- Error handling complete
- UI polished
- API integration verified
- Bearer token authentication working

## Next Steps
1. Test with real users
2. Monitor for any issues
3. Collect feedback
4. Optimize if needed
