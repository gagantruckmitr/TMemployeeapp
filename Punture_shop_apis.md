# Puncture Profile Completion API Documentation

These APIs are used by Field Agents (Margdarshak) to complete the profile of a Puncture Shop.

**Base URL:** `/api/margdarshak`  
**Authentication:** Bearer Token (Field Agent)

---

## 1. Save Puncture Business Info
**Endpoint:** `POST /puncture/business-info`

**Description:** Saves basic business details of the Puncture shop.

**Parameters:**
| Field | Type | Required | Description |
|---|---|---|---|
| `puncture_user_id` | Integer | Yes | The User ID of the Puncture shop (created via add-puncture OTP) |
| `puncture_name` | String | Yes | Name of the Puncture Shop |
| `owner_name` | String | Yes | Name of the Owner |
| `mobile` | String | Yes | 10-digit Mobile Number |
| `email` | String | No | Email Address |
| `year_established` | String | No | Year of establishment |
| `puncture_type` | String | Yes | Type of Puncture Shop |

**Response:**
```json
{
    "success": true,
    "message": "Business info saved successfully",
    "puncture": { ... }
}
```

---

## 2. Save Puncture Location
**Endpoint:** `POST /puncture/location`

**Description:** Saves location coordinates and address.

**Parameters:**
| Field | Type | Required | Description |
|---|---|---|---|
| `puncture_user_id` | Integer | Yes | User ID of the Puncture shop |
| `full_address` | String | Yes | Complete text address |
| `landmark` | String | No | Landmark info |
| `state_id` | Integer | Yes | State ID (from states table) |
| `district` | String | No | District Name |
| `pincode` | String | Yes | 6-digit Pincode |
| `latitude` | Numeric | Yes | GPS Latitude |
| `longitude` | Numeric | Yes | GPS Longitude |
| `location_source` | String | Yes | "Pinned via GPS" or "Manual pin on map" |

**Response:**
```json
{
    "success": true,
    "message": "Location saved successfully",
    "location": { ... }
}
```

---

## 3. Save Puncture Operation Info
**Endpoint:** `POST /puncture/operation`

**Description:** Saves operating hours.

**Parameters:**
| Field | Type | Required | Description |
|---|---|---|---|
| `puncture_user_id` | Integer | Yes | User ID of the Puncture shop |
| `opening_time` | Time | No | e.g. "09:00:00" |
| `closing_time` | Time | No | e.g. "21:00:00" |
| `is_24x7` | Boolean | No | 1 if 24x7, else 0 |

**Response:**
```json
{
    "success": true,
    "message": "Operation info saved successfully",
    "operation": { ... }
}
```

---

## 4. Save Puncture Services
**Endpoint:** `POST /puncture/services`

**Description:** Saves services offered by the shop.

**Parameters:**
| Field | Type | Required | Description |
|---|---|---|---|
| `puncture_user_id` | Integer | Yes | User ID of the Puncture shop |
| *dynamic_fields* | Boolean | No | Send service fields as boolean (1/0). E.g. `tyre_repair`, `air_filling`, `mechanic` etc. matching the database columns. |

**Response:**
```json
{
    "success": true,
    "message": "Services saved successfully",
    "services": { ... }
}
```

---

## 5. Save Puncture Photos
**Endpoint:** `POST /puncture/photos`

**Description:** Uploads photos of the shop.

**Parameters:**
| Field | Type | Required | Description |
|---|---|---|---|
| `puncture_user_id` | Integer | Yes | User ID of the Puncture shop |
| `category` | String | Yes | Category of photo (e.g. "Front View", "Inside View") |
| `image_url[]` | File Array | Yes | Array of image files (jpg, png, webp) |
| `upload_date` | Date | No | Date of upload |

**Response:**
```json
{
    "success": true,
    "message": "Photos uploaded successfully",
    "photos": [ ... ]
}
```

---

## 6. Get Puncture Shop Details
**Endpoint:** `GET /puncture/details`

**Description:** Fetches full profile details of a Puncture shop. Used when viewing a shop from the territory list.

**Parameters:**
*(Provide exactly one of the following)*
| Field | Type | Description |
|---|---|---|
| `user_id` | Integer | The User ID of the Puncture shop |
| `unique_id` | String | The Unique ID of the Puncture shop |

**Response:**
```json
{
    "status": true,
    "message": "Puncture details fetched successfully",
    "data": {
        "user_info": {
            "id": 123,
            "name": "Shop Name",
            "drivers_count": 5,
            ...
        },
        "business_info": { ... },
        "location": { ... },
        "operation": { ... },
        "services": { ... },
        "photos": {
            "Front View": { "count": 1, "images": [...] }
        },
        "profile_status": {
            "has_business_info": true,
            "has_location": true,
            ...
        }
    }
}
```
