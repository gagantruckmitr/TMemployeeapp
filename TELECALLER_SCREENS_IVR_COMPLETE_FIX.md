# Telecaller Screens IVR Complete Fix

## Problem
IVR calls from telecaller screens (Call History and Callback Requests) were showing "User not logged in" error, while manual calls worked fine.

## Root Cause
The app uses two separate authentication systems:
1. **RealAuthService** - Legacy auth system (stores user in memory)
2. **Phase2AuthService** - New auth system (stores user in SharedPreferences)

When users log in via RealAuthService, the Phase2AuthService doesn't have the user data. The `EasyGoIVRCallHelper` internally uses `Phase2AuthService.getCurrentUser()`, which returns null, causing the "User not logged in" error.

## Solution

### 1. Callback Requests Screen
**File:** `lib/features/telecaller/callback_requests/callback_requests_screen.dart`

**Changes:**
- Added imports for IVR functionality
- Replaced direct phone dialer with call type selection dialog
- Implemented both manual and IVR call handling
- Used Phase2AuthService for authentication

**Code:**
```dart
// Added imports
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/phase2_auth_service.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/easygo_ivr_call_helper.dart';

// Updated _callDriver method
Future<void> _callDriver(CallbackRequest request) async {
  try {
    // Show call type selection dialog
    final callType = await showDialog<String>(
      context: context,
      builder: (context) => CallTypeSelectionDialog(
        driverName: request.userName,
      ),
    );

    if (callType == null) return;

    // Get user from Phase2AuthService
    final user = await Phase2AuthService.getCurrentUser();
    if (user == null) {
      // Show error
      return;
    }

    if (callType == 'manual') {
      // Handle manual call
    } else if (callType == 'easygo_ivr') {
      // Handle IVR call
      await EasyGoIVRCallHelper.initiateCall(...);
    }
  } catch (error) {
    // Handle error
  }
}
```

### 2. Telecaller Call History Screen
**File:** `lib/features/telecaller/screens/call_history_screen.dart`

**Changes:**
- Added Phase2User model import
- Implemented user data syncing between auth services
- Creates Phase2User from RealAuthService data when needed

**Code:**
```dart
// Added import
import '../../../models/phase2_user_model.dart';

// Updated _makeCall method
Future<void> _makeCall() async {
  try {
    // Check both auth services
    final currentUser = RealAuthService.instance.currentUser;
    Phase2User? phase2User = await Phase2AuthService.getCurrentUser();
    
    // Sync user data if RealAuth has it but Phase2Auth doesn't
    if (currentUser != null && phase2User == null) {
      print('🔄 Syncing user from RealAuthService to Phase2AuthService');
      phase2User = Phase2User(
        id: int.tryParse(currentUser.id) ?? 0,
        name: currentUser.name,
        mobile: currentUser.mobile,
        email: currentUser.email,
        role: currentUser.role,
        tcFor: '',
        createdAt: DateTime.now().toIso8601String(),
      );
    }
    
    // Continue with call logic...
  }
}
```

## How It Works

### Callback Requests Screen
```
User clicks call button
         ↓
Show CallTypeSelectionDialog
         ↓
Get user from Phase2AuthService
         ↓
    ┌────┴────┐
    ↓         ↓
Manual Call   IVR Call
    ↓         ↓
Direct       EasyGoIVRCallHelper
Dialer       (has Phase2User)
    ↓         ↓
   ✅        ✅
```

### Telecaller Call History Screen
```
User clicks call button
         ↓
Check RealAuthService
         ↓
Check Phase2AuthService
         ↓
If RealAuth has user but Phase2Auth doesn't
         ↓
Create Phase2User from RealAuth data
         ↓
Show CallTypeSelectionDialog
         ↓
    ┌────┴────┐
    ↓         ↓
Manual Call   IVR Call
    ↓         ↓
Works with   EasyGoIVRCallHelper
RealAuth     (has Phase2User)
    ↓         ↓
   ✅        ✅