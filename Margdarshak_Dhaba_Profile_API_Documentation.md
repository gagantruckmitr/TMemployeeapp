# Margdarshak (Field Agent) - Dhaba Profile Completion API Documentation

## Overview
These APIs allow Field Agents (Margdarshak) to complete Dhaba profiles on behalf of Dhaba owners. All requests require authentication via Sanctum token and must include `dhaba_user_id` in the request body.

**Base URL:** `{your_domain}/api/margdarshak/dhaba/`

**Authentication:** Bearer Token (Sanctum)

**Common Header:**
```
Authorization: Bearer {sanctum_token}
Content-Type: application/json
```

For file uploads (photos):
```
Authorization: Bearer {sanctum_token}
Content-Type: multipart/form-data
```

---

## 1. Save Business Info

**Endpoint:** `POST /api/margdarshak/dhaba/business-info`

**Description:** Save or update basic business information for a Dhaba.

### Request Body
```json
{
  "dhaba_user_id": 123,
  "dhaba_name": "Highway Dhaba",
  "owner_name": "Rajesh Kumar",
  "mobile": "9876543210",
  "email": "rajesh@example.com",
  "year_established": "2015",
  "dhaba_type": "Highway Dhaba"
}
```

### Field Validations
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| dhaba_user_id | integer | Yes | Must exist in users table with role='dhaba' |
| dhaba_name | string | Yes | Max 255 characters |
| owner_name | string | Yes | Max 255 characters |
| mobile | string | Yes | Exactly 10 digits |
| email | string | No | Valid email format |
| year_established | string | No | - |
| dhaba_type | string | Yes | - |

### Success Response (200)
```json
{
  "success": true,
  "message": "Business info saved successfully",
  "dhaba": {
    "id": 45,
    "user_id": 123,
    "unique_id": "DH123456",
    "dhaba_name": "Highway Dhaba",
    "owner_name": "Rajesh Kumar",
    "mobile": "9876543210",
    "email": "rajesh@example.com",
    "year_established": "2015",
    "dhaba_type": "Highway Dhaba",
    "status": 1,
    "created_at": "2026-01-31T07:30:00.000000Z",
    "updated_at": "2026-01-31T07:30:00.000000Z"
  }
}
```

### Error Response (404)
```json
{
  "success": false,
  "message": "Dhaba user not found or invalid role"
}
```

---

## 2. Save Location

**Endpoint:** `POST /api/margdarshak/dhaba/location`

**Description:** Save or update location details for a Dhaba.

### Request Body
```json
{
  "dhaba_user_id": 123,
  "full_address": "NH-44, Near Toll Plaza, Karnal",
  "landmark": "Opposite HP Petrol Pump",
  "state_id": 10,
  "district": "Karnal",
  "pincode": "132001",
  "latitude": 29.6857,
  "longitude": 76.9905,
  "location_source": "Pinned via GPS"
}
```

### Field Validations
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| dhaba_user_id | integer | Yes | Must exist in users table |
| full_address | string | Yes | - |
| landmark | string | No | - |
| state_id | integer | Yes | Must exist in states table |
| district | string | No | - |
| pincode | string | Yes | Exactly 6 digits |
| latitude | numeric | Yes | Valid latitude |
| longitude | numeric | Yes | Valid longitude |
| location_source | string | Yes | Either "Pinned via GPS" or "Manual pin on map" |

### Success Response (200)
```json
{
  "success": true,
  "message": "Location saved successfully",
  "location": {
    "id": 12,
    "user_id": 123,
    "unique_id": "DH123456",
    "full_address": "NH-44, Near Toll Plaza, Karnal",
    "landmark": "Opposite HP Petrol Pump",
    "state_id": 10,
    "district": "Karnal",
    "pincode": "132001",
    "latitude": 29.6857,
    "longitude": 76.9905,
    "location_source": "Pinned via GPS",
    "created_at": "2026-01-31T07:30:00.000000Z",
    "updated_at": "2026-01-31T07:30:00.000000Z"
  }
}
```

---

## 3. Save Operation Details

**Endpoint:** `POST /api/margdarshak/dhaba/operation`

**Description:** Save or update operational details for a Dhaba.

### Request Body
```json
{
  "dhaba_user_id": 123,
  "opening_time": "06:00",
  "closing_time": "23:00",
  "is_24x7": false,
  "peak_hours": "12:00-15:00, 19:00-22:00",
  "avg_wait_time": "15-20 minutes"
}
```

### Field Validations
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| dhaba_user_id | integer | Yes | Must exist in users table |
| opening_time | string | No | Time format |
| closing_time | string | No | Time format |
| is_24x7 | boolean | No | true/false |
| peak_hours | string | No | - |
| avg_wait_time | string | No | - |

### Success Response (200)
```json
{
  "success": true,
  "message": "Operation info saved successfully",
  "operation": {
    "id": 8,
    "user_id": 123,
    "unique_id": "DH123456",
    "opening_time": "06:00",
    "closing_time": "23:00",
    "is_24x7": 0,
    "peak_hours": "12:00-15:00, 19:00-22:00",
    "avg_wait_time": "15-20 minutes",
    "created_at": "2026-01-31T07:30:00.000000Z",
    "updated_at": "2026-01-31T07:30:00.000000Z"
  }
}
```

---

## 4. Save Facilities

**Endpoint:** `POST /api/margdarshak/dhaba/facilities`

**Description:** Save or update facility information for a Dhaba.

### Request Body
```json
{
  "dhaba_user_id": 123,
  "sitting_facility": true,
  "clean_restrooms": true,
  "drinking_water": true,
  "parking_small": true,
  "parking_large": true,
  "sleeping_area": false,
  "washing_area": true,
  "electric_point": true,
  "cctv": true,
  "security_staff": false,
  "wheel_alignment": false,
  "mechanic": true
}
```

### Field Validations
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| dhaba_user_id | integer | Yes | Must exist in users table |
| sitting_facility | boolean | No | true/false |
| clean_restrooms | boolean | No | true/false |
| drinking_water | boolean | No | true/false |
| parking_small | boolean | No | true/false |
| parking_large | boolean | No | true/false |
| sleeping_area | boolean | No | true/false |
| washing_area | boolean | No | true/false |
| electric_point | boolean | No | true/false |
| cctv | boolean | No | true/false |
| security_staff | boolean | No | true/false |
| wheel_alignment | boolean | No | true/false |
| mechanic | boolean | No | true/false |

### Success Response (200)
```json
{
  "success": true,
  "message": "Facilities saved successfully",
  "facilities": {
    "id": 15,
    "user_id": 123,
    "unique_id": "DH123456",
    "sitting_facility": 1,
    "clean_restrooms": 1,
    "drinking_water": 1,
    "parking_small": 1,
    "parking_large": 1,
    "sleeping_area": 0,
    "washing_area": 1,
    "electric_point": 1,
    "cctv": 1,
    "security_staff": 0,
    "wheel_alignment": 0,
    "mechanic": 1,
    "created_at": "2026-01-31T07:30:00.000000Z",
    "updated_at": "2026-01-31T07:30:00.000000Z"
  }
}
```

---

## 5. Save Food Details

**Endpoint:** `POST /api/margdarshak/dhaba/food`

**Description:** Save or update food offerings for a Dhaba.

### Request Body
```json
{
  "dhaba_user_id": 123,
  "food_type": ["Veg", "Non-Veg"],
  "special_dishes": "Butter Chicken, Dal Makhani, Tandoori Roti",
  "meal_breakfast": true,
  "meal_lunch": true,
  "meal_dinner": true,
  "meal_night": false,
  "avg_price_range": "₹100-₹300"
}
```

### Field Validations
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| dhaba_user_id | integer | Yes | Must exist in users table |
| food_type | array | Yes | Each item must be "Veg", "Non-Veg", or "Both" |
| special_dishes | string | No | - |
| meal_breakfast | boolean | No | true/false |
| meal_lunch | boolean | No | true/false |
| meal_dinner | boolean | No | true/false |
| meal_night | boolean | No | true/false |
| avg_price_range | string | No | - |

### Success Response (200)
```json
{
  "success": true,
  "message": "Food details saved successfully",
  "food": {
    "id": 9,
    "user_id": 123,
    "unique_id": "DH123456",
    "dhaba_id": 45,
    "food_type": "Veg,Non-Veg",
    "special_dishes": "Butter Chicken, Dal Makhani, Tandoori Roti",
    "meal_breakfast": 1,
    "meal_lunch": 1,
    "meal_dinner": 1,
    "meal_night": 0,
    "avg_price_range": "₹100-₹300",
    "created_at": "2026-01-31T07:30:00.000000Z",
    "updated_at": "2026-01-31T07:30:00.000000Z"
  }
}
```

### Error Response (400)
```json
{
  "success": false,
  "message": "Dhaba business info must be saved first"
}
```

---

## 6. Save Photos

**Endpoint:** `POST /api/margdarshak/dhaba/photos`

**Description:** Upload photos for a Dhaba.

**Content-Type:** `multipart/form-data`

### Request Body (Form Data)
```
dhaba_user_id: 123
category: "Exterior"
image_url[0]: <file>
image_url[1]: <file>
upload_date: "2026-01-31" (optional)
```

### Field Validations
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| dhaba_user_id | integer | Yes | Must exist in users table |
| category | string | Yes | Max 255 characters |
| image_url | array | Yes | Min 1 file, each file: jpeg/png/jpg/webp, max 5MB |
| upload_date | date | No | Valid date format |

### Categories (Suggested)
- Exterior
- Interior
- Kitchen
- Food Items
- Parking Area
- Facilities

### Success Response (201)
```json
{
  "success": true,
  "message": "Photos uploaded successfully",
  "photos": [
    {
      "id": 34,
      "user_id": 123,
      "unique_id": "DH123456",
      "dhaba_id": 45,
      "category": "Exterior",
      "image_url": "http://yourdomain.com/storage/dhaba_photos/xyz123.jpg",
      "ordering_priority": 0,
      "upload_date": "2026-01-31T07:30:00.000000Z",
      "created_at": "2026-01-31T07:30:00.000000Z",
      "updated_at": "2026-01-31T07:30:00.000000Z"
    },
    {
      "id": 35,
      "user_id": 123,
      "unique_id": "DH123456",
      "dhaba_id": 45,
      "category": "Exterior",
      "image_url": "http://yourdomain.com/storage/dhaba_photos/abc456.jpg",
      "ordering_priority": 1,
      "upload_date": "2026-01-31T07:30:00.000000Z",
      "created_at": "2026-01-31T07:30:00.000000Z",
      "updated_at": "2026-01-31T07:30:00.000000Z"
    }
  ]
}
```

### Error Response (404)
```json
{
  "success": false,
  "message": "Dhaba business info not found"
}
```

---

## 7. Save Banking Details

**Endpoint:** `POST /api/margdarshak/dhaba/banking`

**Description:** Save or update banking details for a Dhaba.

### Request Body
```json
{
  "dhaba_user_id": 123,
  "account_holder_name": "Rajesh Kumar",
  "bank_name": "State Bank of India",
  "account_number": "1234567890",
  "ifsc_code": "SBIN0001234"
}
```

### Field Validations
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| dhaba_user_id | integer | Yes | Must exist in users table |
| account_holder_name | string | Yes | - |
| bank_name | string | Yes | - |
| account_number | string | Yes | - |
| ifsc_code | string | Yes | - |

### Success Response (200)
```json
{
  "success": true,
  "message": "Banking details saved successfully",
  "banking": {
    "id": 18,
    "user_id": 123,
    "unique_id": "DH123456",
    "account_holder_name": "Rajesh Kumar",
    "bank_name": "State Bank of India",
    "account_number": "1234567890",
    "ifsc_code": "SBIN0001234",
    "created_at": "2026-01-31T07:30:00.000000Z",
    "updated_at": "2026-01-31T07:30:00.000000Z"
  }
}
```

---

## 8. Save Engagement Settings

**Endpoint:** `POST /api/margdarshak/dhaba/engagement`

**Description:** Save or update engagement preferences for a Dhaba.

### Request Body
```json
{
  "dhaba_user_id": 123,
  "allow_call": true,
  "allow_messages": true,
  "allow_promotions": false
}
```

### Field Validations
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| dhaba_user_id | integer | Yes | Must exist in users table |
| allow_call | boolean | No | true/false |
| allow_messages | boolean | No | true/false |
| allow_promotions | boolean | No | true/false |

### Success Response (200)
```json
{
  "success": true,
  "message": "Engagement settings saved successfully",
  "engagement": {
    "id": 7,
    "user_id": 123,
    "unique_id": "DH123456",
    "dhaba_id": 45,
    "allow_call": 1,
    "allow_messages": 1,
    "allow_promotions": 0,
    "created_at": "2026-01-31T07:30:00.000000Z",
    "updated_at": "2026-01-31T07:30:00.000000Z"
  }
}
```

### Error Response (404)
```json
{
  "success": false,
  "message": "Dhaba profile not found"
}
```

---

## 9. Get Dhaba Profile

**Endpoint:** `GET /api/margdarshak/dhaba/profile?dhaba_user_id=123`

**Description:** Retrieve complete Dhaba profile with all related information.

### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| dhaba_user_id | integer | Yes | ID of the Dhaba user |

### Success Response (200)
```json
{
  "success": true,
  "dhaba": {
    "id": 45,
    "user_id": 123,
    "unique_id": "DH123456",
    "dhaba_name": "Highway Dhaba",
    "owner_name": "Rajesh Kumar",
    "mobile": "9876543210",
    "email": "rajesh@example.com",
    "year_established": "2015",
    "dhaba_type": "Highway Dhaba",
    "status": 1,
    "created_at": "2026-01-31T07:30:00.000000Z",
    "updated_at": "2026-01-31T07:30:00.000000Z",
    "dhaba_location": {
      "id": 12,
      "user_id": 123,
      "unique_id": "DH123456",
      "full_address": "NH-44, Near Toll Plaza, Karnal",
      "landmark": "Opposite HP Petrol Pump",
      "state_id": 10,
      "district": "Karnal",
      "pincode": "132001",
      "latitude": 29.6857,
      "longitude": 76.9905,
      "location_source": "Pinned via GPS",
      "created_at": "2026-01-31T07:30:00.000000Z",
      "updated_at": "2026-01-31T07:30:00.000000Z"
    },
    "dhaba_operation": {
      "id": 8,
      "user_id": 123,
      "unique_id": "DH123456",
      "opening_time": "06:00",
      "closing_time": "23:00",
      "is_24x7": 0,
      "peak_hours": "12:00-15:00, 19:00-22:00",
      "avg_wait_time": "15-20 minutes",
      "created_at": "2026-01-31T07:30:00.000000Z",
      "updated_at": "2026-01-31T07:30:00.000000Z"
    },
    "dhaba_facility": {
      "id": 15,
      "user_id": 123,
      "unique_id": "DH123456",
      "sitting_facility": 1,
      "clean_restrooms": 1,
      "drinking_water": 1,
      "parking_small": 1,
      "parking_large": 1,
      "sleeping_area": 0,
      "washing_area": 1,
      "electric_point": 1,
      "cctv": 1,
      "security_staff": 0,
      "wheel_alignment": 0,
      "mechanic": 1,
      "created_at": "2026-01-31T07:30:00.000000Z",
      "updated_at": "2026-01-31T07:30:00.000000Z"
    },
    "dhaba_food": {
      "id": 9,
      "user_id": 123,
      "unique_id": "DH123456",
      "dhaba_id": 45,
      "food_type": "Veg,Non-Veg",
      "special_dishes": "Butter Chicken, Dal Makhani, Tandoori Roti",
      "meal_breakfast": 1,
      "meal_lunch": 1,
      "meal_dinner": 1,
      "meal_night": 0,
      "avg_price_range": "₹100-₹300",
      "created_at": "2026-01-31T07:30:00.000000Z",
      "updated_at": "2026-01-31T07:30:00.000000Z"
    },
    "dhaba_photos": [
      {
        "id": 34,
        "user_id": 123,
        "unique_id": "DH123456",
        "dhaba_id": 45,
        "category": "Exterior",
        "image_url": "http://yourdomain.com/storage/dhaba_photos/xyz123.jpg",
        "ordering_priority": 0,
        "upload_date": "2026-01-31T07:30:00.000000Z",
        "created_at": "2026-01-31T07:30:00.000000Z",
        "updated_at": "2026-01-31T07:30:00.000000Z"
      }
    ],
    "foreman_bank_detail": {
      "id": 18,
      "user_id": 123,
      "unique_id": "DH123456",
      "account_holder_name": "Rajesh Kumar",
      "bank_name": "State Bank of India",
      "account_number": "1234567890",
      "ifsc_code": "SBIN0001234",
      "created_at": "2026-01-31T07:30:00.000000Z",
      "updated_at": "2026-01-31T07:30:00.000000Z"
    },
    "dhaba_engagement_setting": {
      "id": 7,
      "user_id": 123,
      "unique_id": "DH123456",
      "dhaba_id": 45,
      "allow_call": 1,
      "allow_messages": 1,
      "allow_promotions": 0,
      "created_at": "2026-01-31T07:30:00.000000Z",
      "updated_at": "2026-01-31T07:30:00.000000Z"
    }
  }
}
```

### Response When No Profile Exists (200)
```json
{
  "success": true,
  "message": "User exists but no dhaba profile found",
  "user": {
    "id": 123,
    "name": "Rajesh Kumar",
    "mobile": "9876543210",
    "role": "dhaba",
    "unique_id": "DH123456"
  },
  "dhaba": null
}
```

### Error Response (404)
```json
{
  "success": false,
  "message": "Dhaba user not found"
}
```

---

## Common Error Responses

### 401 Unauthorized
```json
{
  "message": "Unauthenticated."
}
```

### 422 Validation Error
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "dhaba_name": [
      "The dhaba name field is required."
    ],
    "mobile": [
      "The mobile must be 10 digits."
    ]
  }
}
```

### 500 Server Error
```json
{
  "success": false,
  "message": "Failed to save [resource]",
  "error": "Detailed error message"
}
```

---

## Implementation Notes

### 1. **Sequential Flow**
Follow this order when creating a new Dhaba profile:
1. Business Info (Required first)
2. Location
3. Operation
4. Facilities
5. Food (Requires Business Info to be saved first)
6. Photos (Requires Business Info to be saved first)
7. Banking
8. Engagement (Requires Business Info to be saved first)

### 2. **Authentication**
- All requests require a valid Sanctum token from the Field Agent login
- Token should be included in the `Authorization` header as `Bearer {token}`

### 3. **File Uploads**
- For photo uploads, use `multipart/form-data` content type
- Maximum file size: 5MB per image
- Supported formats: JPEG, PNG, JPG, WEBP
- Multiple images can be uploaded in a single request

### 4. **Data Persistence**
- All save endpoints use `updateOrCreate`, so they can be called multiple times
- Existing data will be updated if the record exists
- New records will be created if they don't exist

### 5. **Error Handling**
- Always check the `success` field in the response
- Handle validation errors (422) by displaying field-specific error messages
- Handle 404 errors when the Dhaba user is not found
- Implement retry logic for 500 errors

### 6. **Mobile Implementation Tips**
- Store `dhaba_user_id` locally after creating/selecting a Dhaba
- Implement form validation on the client side to match server-side rules
- Show progress indicators during file uploads
- Cache the profile data locally and sync when online
- Implement offline mode with queue for pending requests

---

## Example Usage (JavaScript/React Native)

### Login and Get Token
```javascript
const login = async (mobile, password) => {
  const response = await fetch('http://yourdomain.com/api/margdarshak/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ mobile, password })
  });
  const data = await response.json();
  return data.token; // Store this token
};
```

### Save Business Info
```javascript
const saveBusinessInfo = async (token, dhabaUserId, businessData) => {
  const response = await fetch('http://yourdomain.com/api/margdarshak/dhaba/business-info', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      dhaba_user_id: dhabaUserId,
      ...businessData
    })
  });
  return await response.json();
};
```

### Upload Photos
```javascript
const uploadPhotos = async (token, dhabaUserId, category, imageFiles) => {
  const formData = new FormData();
  formData.append('dhaba_user_id', dhabaUserId);
  formData.append('category', category);
  
  imageFiles.forEach((file, index) => {
    formData.append(`image_url[${index}]`, file);
  });

  const response = await fetch('http://yourdomain.com/api/margdarshak/dhaba/photos', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
      // Don't set Content-Type, browser will set it with boundary
    },
    body: formData
  });
  return await response.json();
};
```

### Get Complete Profile
```javascript
const getDhabaProfile = async (token, dhabaUserId) => {
  const response = await fetch(
    `http://yourdomain.com/api/margdarshak/dhaba/profile?dhaba_user_id=${dhabaUserId}`,
    {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    }
  );
  return await response.json();
};
```

---

## Testing with Postman/cURL

### cURL Example - Save Business Info
```bash
curl -X POST http://yourdomain.com/api/margdarshak/dhaba/business-info \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "dhaba_user_id": 123,
    "dhaba_name": "Highway Dhaba",
    "owner_name": "Rajesh Kumar",
    "mobile": "9876543210",
    "email": "rajesh@example.com",
    "year_established": "2015",
    "dhaba_type": "Highway Dhaba"
  }'
```

### cURL Example - Upload Photos
```bash
curl -X POST http://yourdomain.com/api/margdarshak/dhaba/photos \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "dhaba_user_id=123" \
  -F "category=Exterior" \
  -F "image_url[0]=@/path/to/image1.jpg" \
  -F "image_url[1]=@/path/to/image2.jpg"
```

---

## Support & Contact
For any issues or questions regarding these APIs, please contact the development team.

**Last Updated:** January 31, 2026
