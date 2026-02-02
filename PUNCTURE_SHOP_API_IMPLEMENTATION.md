# Puncture Shop API Implementation

## Summary
Added complete API integration for Puncture Shop profile completion in the Margdarshak (Field Agent) module.

## Changes Made

### 1. API Configuration (`lib/core/config/api_config.dart`)

Added 6 new API endpoint constants for puncture shop operations:

```dart
// Margdarshak Puncture Shop Profile Completion APIs
static String get margdarshakPunctureBusinessInfoApi =>
    '$margdarshakApiBase/margdarshak/puncture/business-info';
static String get margdarshakPunctureLocationApi =>
    '$margdarshakApiBase/margdarshak/puncture/location';
static String get margdarshakPunctureOperationApi =>
    '$margdarshakApiBase/margdarshak/puncture/operation';
static String get margdarshakPunctureServicesApi =>
    '$margdarshakApiBase/margdarshak/puncture/services';
static String get margdarshakPuncturePhotosApi =>
    '$margdarshakApiBase/margdarshak/puncture/photos';
static String get margdarshakPunctureDetailsApi =>
    '$margdarshakApiBase/margdarshak/puncture/details';
```

### 2. API Service Methods (`lib/features/margdarshak/services/margdarshak_api_service.dart`)

Added 6 new API methods for puncture shop profile completion:

#### 2.1 Save Business Info
```dart
Future<Map<String, dynamic>> savePunctureBusinessInfo({
  required int punctureUserId,
  required String punctureName,
  required String ownerName,
  required String mobile,
  String? email,
  String? yearEstablished,
  required String punctureType,
})
```

**Endpoint:** `POST /api/margdarshak/puncture/business-info`

**Parameters:**
- `puncture_user_id` (int, required)
- `puncture_name` (string, required)
- `owner_name` (string, required)
- `mobile` (string, required)
- `email` (string, optional)
- `year_established` (string, optional)
- `puncture_type` (string, required)

#### 2.2 Save Location
```dart
Future<Map<String, dynamic>> savePunctureLocation({
  required int punctureUserId,
  required String fullAddress,
  String? landmark,
  required int stateId,
  String? district,
  required String pincode,
  required double latitude,
  required double longitude,
  required String locationSource,
})
```

**Endpoint:** `POST /api/margdarshak/puncture/location`

**Parameters:**
- `puncture_user_id` (int, required)
- `full_address` (string, required)
- `landmark` (string, optional)
- `state_id` (int, required)
- `district` (string, optional)
- `pincode` (string, required)
- `latitude` (double, required)
- `longitude` (double, required)
- `location_source` (string, required)

#### 2.3 Save Operation
```dart
Future<Map<String, dynamic>> savePunctureOperation({
  required int punctureUserId,
  String? openingTime,
  String? closingTime,
  bool? is24x7,
})
```

**Endpoint:** `POST /api/margdarshak/puncture/operation`

**Parameters:**
- `puncture_user_id` (int, required)
- `opening_time` (string, optional) - Format: "HH:mm:ss"
- `closing_time` (string, optional) - Format: "HH:mm:ss"
- `is_24x7` (bool, optional)

#### 2.4 Save Services
```dart
Future<Map<String, dynamic>> savePunctureServices({
  required int punctureUserId,
  bool? tyreRepair,
  bool? airFilling,
  bool? mechanic,
  bool? tyreReplacement,
  bool? wheelBalancing,
  bool? emergencyService,
  bool? tubePatching,
  bool? valveRepair,
  bool? mobileService,
})
```

**Endpoint:** `POST /api/margdarshak/puncture/services`

**Parameters:**
- `puncture_user_id` (int, required)
- `tyre_repair` (bool, optional)
- `air_filling` (bool, optional)
- `mechanic` (bool, optional)
- `tyre_replacement` (bool, optional)
- `wheel_balancing` (bool, optional)
- `emergency_service` (bool, optional)
- `tube_patching` (bool, optional)
- `valve_repair` (bool, optional)
- `mobile_service` (bool, optional)

#### 2.5 Upload Photos
```dart
Future<Map<String, dynamic>> uploadPuncturePhotos({
  required int punctureUserId,
  required String category,
  required List<String> imagePaths,
})
```

**Endpoint:** `POST /api/margdarshak/puncture/photos`

**Parameters:**
- `puncture_user_id` (int, required)
- `category` (string, required) - e.g., "Front View", "Inside View"
- `image_url[]` (file array, required) - Array of image files

**Note:** This is a multipart/form-data request for file uploads.

#### 2.6 Get Puncture Details
```dart
Future<Map<String, dynamic>> getPunctureDetails({
  String? userId,
  String? uniqueId,
})
```

**Endpoint:** `GET /api/margdarshak/puncture/details`

**Query Parameters:**
- `user_id` (string, optional) - Either userId or uniqueId must be provided
- `unique_id` (string, optional)

**Response Structure:**
```json
{
  "status": true,
  "message": "Puncture details fetched successfully",
  "data": {
    "user_info": { ... },
    "business_info": { ... },
    "location": { ... },
    "operation": { ... },
    "services": { ... },
    "photos": { ... },
    "profile_status": { ... }
  }
}
```

## API Documentation Reference

All APIs follow the specification in `Punture_shop_apis.md`:
- Base URL: `/api/margdarshak`
- Authentication: Bearer Token (Field Agent)
- All endpoints return JSON responses with `success` and `message` fields

## Usage Example

```dart
final apiService = MargdarshakApiService();

// 1. Save business info
await apiService.savePunctureBusinessInfo(
  punctureUserId: 123,
  punctureName: "Quick Fix Puncture",
  ownerName: "John Doe",
  mobile: "9876543210",
  email: "john@example.com",
  yearEstablished: "2015",
  punctureType: "Roadside Service",
);

// 2. Save location
await apiService.savePunctureLocation(
  punctureUserId: 123,
  fullAddress: "NH-44, Near Bus Stand",
  landmark: "Opposite Petrol Pump",
  stateId: 5,
  district: "Mumbai",
  pincode: "400001",
  latitude: 19.0760,
  longitude: 72.8777,
  locationSource: "Pinned via GPS",
);

// 3. Save operation hours
await apiService.savePunctureOperation(
  punctureUserId: 123,
  openingTime: "09:00:00",
  closingTime: "21:00:00",
  is24x7: false,
);

// 4. Save services
await apiService.savePunctureServices(
  punctureUserId: 123,
  tyreRepair: true,
  airFilling: true,
  mechanic: true,
  emergencyService: true,
);

// 5. Upload photos
await apiService.uploadPuncturePhotos(
  punctureUserId: 123,
  category: "Front View",
  imagePaths: ["/path/to/image1.jpg", "/path/to/image2.jpg"],
);

// 6. Get puncture details
final details = await apiService.getPunctureDetails(
  userId: "123",
);
```

## Next Steps

To complete the puncture shop integration in the UI:

1. Update `lib/features/margdarshak/screens/add_shop/index.dart` to:
   - Enable puncture shop type selection (currently shows "Coming soon")
   - Add puncture-specific form fields and validation
   - Implement save methods using the new API methods
   - Add service selection UI for puncture services

2. Test the API integration with the backend server

3. Add error handling and user feedback for each API call

## Files Modified

1. `lib/core/config/api_config.dart` - Added 6 API endpoint constants
2. `lib/features/margdarshak/services/margdarshak_api_service.dart` - Added 6 API methods

## Testing

All files have been validated with no syntax errors or diagnostics issues.
