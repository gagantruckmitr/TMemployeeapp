# Job Brief API Documentation

Complete API documentation for `phase2_job_brief_api.php` - handles job brief feedback from telecallers when calling transporters.

## Base URL
```
http://127.0.0.1/api/phase2_job_brief_api.php
```

---

## Table Structure: `job_brief_table`

| Column | Type | Description |
|--------|------|-------------|
| `id` | int(11) | Primary key (auto-increment) |
| `unique_id` | varchar(50) | Transporter TMID (required) |
| `job_id` | varchar(50) | Job ID from jobs table (required) |
| `caller_id` | int(11) | Telecaller ID from admins table |
| `name` | varchar(255) | Transporter name |
| `job_location` | varchar(255) | Job location |
| `route` | text | Route details |
| `vehicle_type` | varchar(100) | Vehicle type required |
| `license_type` | varchar(50) | License type required |
| `experience` | varchar(50) | Experience required |
| `salary_fixed` | decimal(10,2) | Fixed salary amount |
| `salary_variable` | decimal(10,2) | Variable salary amount |
| `esi_pf` | enum('Yes','No') | ESI/PF provided (default: 'No') |
| `food_allowance` | decimal(10,2) | Food allowance amount |
| `trip_incentive` | decimal(10,2) | Trip incentive amount |
| `rehne_ki_suvidha` | enum('Yes','No') | Accommodation provided (default: 'No') |
| `mileage` | varchar(50) | Mileage details |
| `fast_tag_road_kharcha` | enum('Company','Driver') | Who pays for toll/road expenses (default: 'Company') |
| `call_status_feedback` | varchar(100) | Call status feedback |
| `call_recording` | varchar(500) | Call recording URL |
| `closed_job` | tinyint(1) | Job closed flag (0 or 1) |
| `created_at` | timestamp | Record creation time |
| `updated_at` | timestamp | Record update time |

---

## API Endpoints

### 1. Get Table Structure

**Method:** `GET`

**Endpoint:** `?action=get_table_structure`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_table_structure
```

**Response:**
```json
{
  "success": true,
  "message": "Table structure fetched successfully",
  "data": [
    {
      "Field": "id",
      "Type": "int(11)",
      "Null": "NO",
      "Key": "PRI",
      "Default": null,
      "Extra": "auto_increment"
    },
    ...
  ]
}
```

---

### 2. Insert Job Brief

**Method:** `POST`

**Endpoint:** `?action=insert`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=insert
```

**Headers:**
```
Content-Type: application/json
```

**Body (Complete Example):**
```json
{
  "unique_id": "TM000123",
  "job_id": "JOB456",
  "caller_id": 3,
  "name": "ABC Transport",
  "job_location": "Mumbai",
  "route": "Mumbai to Delhi",
  "vehicle_type": "Truck",
  "license_type": "Heavy Vehicle",
  "experience": "5 years",
  "salary_fixed": 25000.00,
  "salary_variable": 5000.00,
  "esi_pf": "Yes",
  "food_allowance": 3000.00,
  "trip_incentive": 2000.00,
  "rehne_ki_suvidha": "Yes",
  "mileage": "10 km/liter",
  "fast_tag_road_kharcha": "Company",
  "call_status_feedback": "Interested",
  "call_recording": "https://example.com/recording.mp3",
  "closed_job": 0
}
```

**Minimal Example (Required Fields Only):**
```json
{
  "unique_id": "TM000123",
  "job_id": "JOB456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Job brief inserted successfully",
  "data": {
    "id": 123,
    "data": {
      "id": 123,
      "unique_id": "TM000123",
      "job_id": "JOB456",
      "caller_id": 3,
      "name": "ABC Transport",
      ...
    }
  }
}
```

---

### 3. Get All Job Briefs

**Method:** `GET`

**Endpoint:** `?action=get_all`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_all
```

**Query Parameters:**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `limit` | integer | Number of records (default: 50) | `limit=20` |
| `offset` | integer | Pagination offset (default: 0) | `offset=0` |
| `job_id` | string | Filter by job ID | `job_id=JOB456` |
| `unique_id` | string | Filter by transporter TMID | `unique_id=TM000123` |
| `caller_id` | integer | Filter by telecaller ID | `caller_id=3` |
| `call_status_feedback` | string | Filter by feedback | `call_status_feedback=Interested` |
| `closed_job` | integer | Filter by closed status (0 or 1) | `closed_job=0` |

**Examples:**

Get all job briefs:
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_all
```

Get job briefs for specific job:
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_all&job_id=JOB456
```

Get job briefs for specific transporter:
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_all&unique_id=TM000123
```

Get job briefs by telecaller:
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_all&caller_id=3
```

Get with pagination:
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_all&limit=10&offset=0
```

Get open jobs only:
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_all&closed_job=0
```

**Response:**
```json
{
  "success": true,
  "message": "Job briefs fetched successfully",
  "data": {
    "data": [
      {
        "id": 123,
        "unique_id": "TM000123",
        "job_id": "JOB456",
        "caller_id": 3,
        "name": "ABC Transport",
        "job_location": "Mumbai",
        "route": "Mumbai to Delhi",
        "vehicle_type": "Truck",
        "license_type": "Heavy Vehicle",
        "experience": "5 years",
        "salary_fixed": "25000.00",
        "salary_variable": "5000.00",
        "esi_pf": "Yes",
        "food_allowance": "3000.00",
        "trip_incentive": "2000.00",
        "rehne_ki_suvidha": "Yes",
        "mileage": "10 km/liter",
        "fast_tag_road_kharcha": "Company",
        "call_status_feedback": "Interested",
        "call_recording": "https://example.com/recording.mp3",
        "closed_job": 0,
        "created_at": "2024-11-20 10:30:00",
        "updated_at": "2024-11-20 10:30:00"
      }
    ],
    "count": 1,
    "total": 150,
    "limit": 50,
    "offset": 0
  }
}
```

---

### 4. Get Job Brief by ID

**Method:** `GET`

**Endpoint:** `?action=get_by_id&id=123`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=get_by_id&id=123
```

**Response:**
```json
{
  "success": true,
  "message": "Job brief fetched successfully",
  "data": {
    "id": 123,
    "unique_id": "TM000123",
    "job_id": "JOB456",
    "caller_id": 3,
    "name": "ABC Transport",
    "job_location": "Mumbai",
    "route": "Mumbai to Delhi",
    "vehicle_type": "Truck",
    "license_type": "Heavy Vehicle",
    "experience": "5 years",
    "salary_fixed": "25000.00",
    "salary_variable": "5000.00",
    "esi_pf": "Yes",
    "food_allowance": "3000.00",
    "trip_incentive": "2000.00",
    "rehne_ki_suvidha": "Yes",
    "mileage": "10 km/liter",
    "fast_tag_road_kharcha": "Company",
    "call_status_feedback": "Interested",
    "call_recording": "https://example.com/recording.mp3",
    "closed_job": 0,
    "created_at": "2024-11-20 10:30:00",
    "updated_at": "2024-11-20 10:30:00"
  }
}
```

---

### 5. Update Job Brief

**Method:** `POST`

**Endpoint:** `?action=update`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=update
```

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "id": 123,
  "call_status_feedback": "Confirmed",
  "salary_fixed": 30000.00,
  "call_recording": "https://example.com/recording_updated.mp3"
}
```

**Note:** You can update any field(s). Only include the fields you want to update.

**Response:**
```json
{
  "success": true,
  "message": "Job brief updated successfully",
  "data": {
    "id": 123
  }
}
```

---

### 6. Delete Job Brief

**Method:** `POST`

**Endpoint:** `?action=delete`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=delete
```

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "id": 123
}
```

**Response:**
```json
{
  "success": true,
  "message": "Job brief deleted successfully",
  "data": {
    "id": 123
  }
}
```

---

## Legacy Endpoints (Backward Compatibility)

### Save Job Brief (Insert or Update)

**Method:** `POST`

**Endpoint:** (no action parameter)

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php
```

**Body:**
```json
{
  "uniqueId": "TM000123",
  "jobId": "JOB456",
  "callerId": 3,
  "name": "ABC Transport",
  ...
}
```

**Note:** Uses camelCase field names. Automatically inserts if record doesn't exist, updates if it does.

---

### Get Job Briefs (Legacy)

**Method:** `GET`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?job_id=JOB456&unique_id=TM000123
```

---

### Get Call History

**Method:** `GET`

**Endpoint:** `?action=history`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=history&unique_id=TM000123&caller_id=3
```

---

### Get Transporters List

**Method:** `GET`

**Endpoint:** `?action=transporters_list`

**URL:**
```
http://127.0.0.1/api/phase2_job_brief_api.php?action=transporters_list&caller_id=3
```

---

## Field Validation

### Enum Fields

**esi_pf:**
- `Yes`
- `No` (default)

**rehne_ki_suvidha:**
- `Yes`
- `No` (default)

**fast_tag_road_kharcha:**
- `Company` (default)
- `Driver`

### Decimal Fields

- `salary_fixed`: decimal(10,2)
- `salary_variable`: decimal(10,2)
- `food_allowance`: decimal(10,2)
- `trip_incentive`: decimal(10,2)

---

## Testing Workflow in Postman

### 1. Check Table Structure
```
GET http://127.0.0.1/api/phase2_job_brief_api.php?action=get_table_structure
```

### 2. Insert Job Brief
```
POST http://127.0.0.1/api/phase2_job_brief_api.php?action=insert
Body: {
  "unique_id": "TM000123",
  "job_id": "JOB456",
  "caller_id": 3,
  "name": "ABC Transport",
  "job_location": "Mumbai",
  "salary_fixed": 25000
}
```

### 3. Get All Job Briefs
```
GET http://127.0.0.1/api/phase2_job_brief_api.php?action=get_all
```

### 4. Get Specific Job Brief
```
GET http://127.0.0.1/api/phase2_job_brief_api.php?action=get_by_id&id=1
```

### 5. Update Job Brief
```
POST http://127.0.0.1/api/phase2_job_brief_api.php?action=update
Body: {
  "id": 1,
  "call_status_feedback": "Confirmed",
  "salary_fixed": 30000
}
```

### 6. Delete Job Brief
```
POST http://127.0.0.1/api/phase2_job_brief_api.php?action=delete
Body: {"id": 1}
```

---

## Error Responses

All errors return this format:
```json
{
  "success": false,
  "message": "Error message here",
  "data": null
}
```

Common errors:
- `Database connection not available` - Database connection issue
- `Invalid JSON data` - Malformed JSON in request body
- `unique_id and job_id are required` - Missing required fields
- `Valid ID is required` - Missing or invalid ID parameter
- `Job brief not found` - Record doesn't exist
- `Method not allowed` - Wrong HTTP method used

---

## Notes

- The API supports both snake_case (database format) and camelCase (legacy format) field names
- All timestamps are in MySQL format: `YYYY-MM-DD HH:MM:SS`
- The API automatically joins with the `users` table to fetch transporter details
- Decimal values should be sent as numbers (not strings) in JSON
- The `closed_job` field is automatically set to 1 when `call_status_feedback` contains "Not a Transporter"
