# Partner Registration API Integration - Complete ✅

## Summary
Complete implementation of dhaba/puncture partner registration with OTP verification, field locking, and pincode auto-fetch.

## Features Implemented

### ✅ Dual Registration APIs
- Dhaba: `/api/margdarshak/add-dhaba`
- Puncture: `/api/margdarshak/add-puncture`
- Auto-selects correct API based on partner type

### ✅ Bearer Token Authentication
All API calls include Bearer token from logged-in Margdarshak user

### ✅ Field Locking After Verification
Once OTP verified, these fields become read-only:
- Partner Type (Dhaba/Puncture) with lock icon
- Owner Name with lock icon
- State with lock icon
- Phone Number with checkmark + lock icon

### ✅ Pincode Auto-Fetch District
- Enter 6-digit pincode
- Auto-fetches district from postal API
- Shows "Auto-filled" badge
- Green checkmark on success
- Loading indicator while fetching

## User Flow

1. **Select partner type** (Dhaba/Puncture)
2. **Enter owner name**
3. **Select state** from API
4. **Enter mobile** (10 digits)
5. **Click "Send OTP"** → API call
6. **Enter 6-digit OTP**
7. **Verify** → Success with unique ID
8. **Fields locked** ✓
9. **Enter pincode** → District auto-fills ✓
10. Complete remaining tabs

## API Endpoints

- `POST /api/margdarshak/add-dhaba` - Send OTP for dhaba
- `POST /api/margdarshak/add-puncture` - Send OTP for puncture
- `POST /api/verifyOtp` - Verify OTP
- `GET /api/states` - Get states list
- `GET https://api.postalpincode.in/pincode/{pincode}` - Get district

All protected endpoints use Bearer token authentication.

## Files Modified

1. `lib/features/margdarshak/services/margdarshak_api_service.dart`
   - Added getStates()
   - Added sendDhabaRegistrationOtp()
   - Added sendPunctureRegistrationOtp()
   - Added verifyDhabaRegistrationOtp()

2. `lib/features/margdarshak/screens/add_shop/index.dart`
   - Integrated OTP flow for both types
   - Added field locking after verification
   - Added pincode auto-fetch
   - Reordered location fields

## Testing Ready ✅

All features implemented and ready for testing!
