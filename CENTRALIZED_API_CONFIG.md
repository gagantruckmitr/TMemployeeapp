# Centralized API Configuration

## ✅ Problem Solved!

Previously, changing the domain from `development.truckmitr.com` to `truckmitr.com` required updating **dozens of files** across the entire codebase. Now, **changing the domain requires updating only ONE line!**

## 🎯 Single Point of Control

**File:** `lib/core/config/api_config.dart`

**Change this ONE line to update the entire app:**

```dart
static const String domain = 'truckmitr.com';  // ← Change only this!
```

## 🔄 How It Works

All URLs are now dynamically generated from the base domain:

```dart
class ApiConfig {
  // 🎯 SINGLE SOURCE OF TRUTH
  static const String domain = 'truckmitr.com';
  
  // 🔗 All URLs auto-generated from domain
  static const String laravelApiBase = 'https://$domain/api/telehead';
  static const String storageBase = 'https://$domain/storage/app/public';
  static const String taskSuiteBase = 'https://tasksuite.$domain/backend/public/api';
  
  // 📧 Email addresses auto-generated
  static const String hrEmail = 'hr@$domain';
  static const String commandCentreEmail = 'harneet.kaur@$domain';
}
```

## 🚀 Benefits

1. **Single Change**: Update domain in one place
2. **No More Hardcoded URLs**: All URLs use centralized config
3. **Environment Switching**: Easy to switch between dev/staging/prod
4. **Maintainable**: No more hunting through dozens of files
5. **Error-Free**: No risk of missing URLs during updates

## 📁 Files Updated

- ✅ All service files now import and use `ApiConfig`
- ✅ All hardcoded URLs replaced with dynamic references
- ✅ Email addresses centralized
- ✅ Helper methods for common URL patterns

## 🔧 Usage Examples

```dart
// Before (hardcoded - BAD)
final url = 'https://truckmitr.com/api/telehead/login';

// After (centralized - GOOD)
final url = ApiConfig.loginApi;

// Or using helper methods
final url = ApiConfig.getLaravelApiUrl('custom-endpoint');
```

## 🎉 Result

**Domain change now requires updating exactly 1 line of code instead of 50+ files!**