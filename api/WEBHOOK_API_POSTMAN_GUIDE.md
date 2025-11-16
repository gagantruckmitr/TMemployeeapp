# Webhook API - Postman Testing Guide

## Base URL
```
http://192.168.29.149/api/webhook_api.php
```
or
```
http://localhost/api/webhook_api.php
```

---

## 📥 GET REQUESTS

### 1. Get All Webhooks
**Method:** `GET`  
**Endpoint:** `http://192.168.29.149/api/webhook_api.php?action=list`

**Query Parameters:**
- `action` = `list` (required)
- `limit` = `100` (optional, default: 100)
- `offset` = `0` (optional, default: 0)

**Example:**
```
GET http://192.168.29.149/api/webhook_api.php?action=list&limit=10&offset=0
```

**Response:**
```json
{
  "success": true,
  "message": "Webhooks retrieved successfully",
  "data": {
    "webhooks": [...],
    "count": 10,
    "total": 50,
    "limit": 10,
    "offset": 0
  }
}
```

---

### 2. Get Single Webhook by ID
**Method:** `GET`  
**Endpoint:** `http://192.168.29.149/api/webhook_api.php?action=get&id=1`

**Query Parameters:**
- `action` = `get` (required)
- `id` = `1` (required - webhook ID)

**Example:**
```
GET http://192.168.29.149/api/webhook_api.php?action=get&id=1
```

**Response:**
```json
{
  "success": true,
  "message": "Webhook retrieved successfully",
  "data": {
    "id": 1,
    "client": "test_client",
    "call_type": "inbound",
    "Linkedid": "LINK123456",
    "extension_no": "1001",
    "did": "9876543210",
    "caller_id": "1234567890",
    "ACD": "ACD001",
    "recfile": "https://example.com/recordings/call123.mp3",
    "exten_ring_time": "2024-01-15 10:30:00",
    "exten_ans_time": "2024-01-15 10:30:05",
    "durn": 120,
    "billsec": 115,
    "disposition": "ANSWERED",
    "action": "completed",
    "start_time": "2024-01-15 10:30:00",
    "acd_durn": 5,
    "acd_time": "5",
    "end_time": "2024-01-15 10:32:00",
    "dtmf": "1",
    "agent_disconnect": 0,
    "transfer": 0,
    "feedback": "Call completed successfully",
    "conf": 0,
    "endcall": 1,
    "created_at": "2024-01-15 10:32:00"
  }
}
```

---

### 3. Get Webhooks Filtered by Client
**Method:** `GET`  
**Endpoint:** `http://192.168.29.149/api/webhook_api.php?action=list&client=test_client`

**Query Parameters:**
- `action` = `list` (required)
- `client` = `test_client` (optional filter)

**Example:**
```
GET http://192.168.29.149/api/webhook_api.php?action=list&client=test_client&limit=20
```

---

### 4. Get Webhooks Filtered by Call Type
**Method:** `GET`  
**Endpoint:** `http://192.168.29.149/api/webhook_api.php?action=list&call_type=inbound`

**Query Parameters:**
- `action` = `list` (required)
- `call_type` = `inbound` or `outbound` (optional filter)

**Example:**
```
GET http://192.168.29.149/api/webhook_api.php?action=list&call_type=inbound
```

---

### 5. Get Webhooks Filtered by Caller ID
**Method:** `GET`  
**Endpoint:** `http://192.168.29.149/api/webhook_api.php?action=list&caller_id=1234567890`

**Query Parameters:**
- `action` = `list` (required)
- `caller_id` = `1234567890` (optional filter)

**Example:**
```
GET http://192.168.29.149/api/webhook_api.php?action=list&caller_id=1234567890
```

---

### 6. Get Webhooks Filtered by Disposition
**Method:** `GET`  
**Endpoint:** `http://192.168.29.149/api/webhook_api.php?action=list&disposition=ANSWERED`

**Query Parameters:**
- `action` = `list` (required)
- `disposition` = `ANSWERED`, `NO ANSWER`, `BUSY`, etc. (optional filter)

**Example:**
```
GET http://192.168.29.149/api/webhook_api.php?action=list&disposition=ANSWERED&limit=50
```

---

### 7. Get Webhooks with Multiple Filters
**Method:** `GET`  
**Endpoint:** `http://192.168.29.149/api/webhook_api.php?action=list&client=test_client&call_type=inbound&disposition=ANSWERED`

**Query Parameters:**
- `action` = `list` (required)
- `client` = `test_client` (optional)
- `call_type` = `inbound` (optional)
- `disposition` = `ANSWERED` (optional)
- `limit` = `10` (optional)
- `offset` = `0` (optional)

**Example:**
```
GET http://192.168.29.149/api/webhook_api.php?action=list&client=test_client&call_type=inbound&disposition=ANSWERED&limit=10
```

---

## 📤 POST REQUEST

### Create New Webhook
**Method:** `POST`  
**Endpoint:** `http://192.168.29.149/api/webhook_api.php`

**Headers:**
```
Content-Type: application/json
```

**Body (JSON):**

#### Full Example (All Fields):
```json
{
  "client": "test_client",
  "call_type": "inbound",
  "Linkedid": "LINK123456",
  "extension_no": "1001",
  "did": "9876543210",
  "caller_id": "1234567890",
  "ACD": "ACD001",
  "recfile": "https://example.com/recordings/call123.mp3",
  "exten_ring_time": "2024-01-15 10:30:00",
  "exten_ans_time": "2024-01-15 10:30:05",
  "durn": 120,
  "billsec": 115,
  "disposition": "ANSWERED",
  "action": "completed",
  "start_time": "2024-01-15 10:30:00",
  "acd_durn": 5,
  "acd_time": "5",
  "end_time": "2024-01-15 10:32:00",
  "dtmf": "1",
  "agent_disconnect": 0,
  "transfer": 0,
  "feedback": "Call completed successfully",
  "conf": 0,
  "endcall": 1
}
```

#### Minimal Example (Required/Common Fields):
```json
{
  "client": "my_client",
  "call_type": "inbound",
  "caller_id": "9876543210",
  "disposition": "ANSWERED",
  "durn": 60,
  "billsec": 55,
  "start_time": "2024-01-15 14:30:00",
  "end_time": "2024-01-15 14:31:00"
}
```

#### Outbound Call Example:
```json
{
  "client": "outbound_client",
  "call_type": "outbound",
  "Linkedid": "OUT789012",
  "extension_no": "1002",
  "caller_id": "9988776655",
  "disposition": "NO ANSWER",
  "durn": 30,
  "billsec": 0,
  "start_time": "2024-01-15 15:00:00",
  "end_time": "2024-01-15 15:00:30",
  "agent_disconnect": 1,
  "endcall": 1
}
```

#### Call with Recording:
```json
{
  "client": "recording_client",
  "call_type": "inbound",
  "caller_id": "1122334455",
  "recfile": "https://recordings.example.com/call_20240115_103000.mp3",
  "disposition": "ANSWERED",
  "durn": 180,
  "billsec": 175,
  "start_time": "2024-01-15 10:30:00",
  "end_time": "2024-01-15 10:33:00",
  "feedback": "Customer satisfied with service"
}
```

**Success Response:**
```json
{
  "success": true,
  "message": "Webhook created successfully",
  "data": {
    "id": 1,
    "client": "test_client",
    "call_type": "inbound",
    "Linkedid": "LINK123456",
    "extension_no": "1001",
    "did": "9876543210",
    "caller_id": "1234567890",
    "ACD": "ACD001",
    "recfile": "https://example.com/recordings/call123.mp3",
    "exten_ring_time": "2024-01-15 10:30:00",
    "exten_ans_time": "2024-01-15 10:30:05",
    "durn": 120,
    "billsec": 115,
    "disposition": "ANSWERED",
    "action": "completed",
    "start_time": "2024-01-15 10:30:00",
    "acd_durn": 5,
    "acd_time": "5",
    "end_time": "2024-01-15 10:32:00",
    "dtmf": "1",
    "agent_disconnect": 0,
    "transfer": 0,
    "feedback": "Call completed successfully",
    "conf": 0,
    "endcall": 1,
    "created_at": "2024-01-15 10:32:00"
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Invalid JSON data"
}
```

---

## 📋 All Available Fields

| Field Name | Data Type | Description | Example |
|------------|-----------|-------------|---------|
| `id` | bigint | Auto-increment ID | 1 |
| `client` | varchar(50) | Client identifier | "test_client" |
| `call_type` | varchar(20) | Type of call | "inbound" or "outbound" |
| `Linkedid` | varchar(255) | Linked call ID | "LINK123456" |
| `extension_no` | varchar(50) | Extension number | "1001" |
| `did` | varchar(50) | Direct Inward Dialing | "9876543210" |
| `caller_id` | varchar(50) | Caller's phone number | "1234567890" |
| `ACD` | varchar(50) | Automatic Call Distribution | "ACD001" |
| `recfile` | text | Recording file URL | "https://example.com/rec.mp3" |
| `exten_ring_time` | datetime | Extension ring time | "2024-01-15 10:30:00" |
| `exten_ans_time` | datetime | Extension answer time | "2024-01-15 10:30:05" |
| `durn` | int(11) | Call duration in seconds | 120 |
| `billsec` | int(11) | Billable seconds | 115 |
| `disposition` | varchar(50) | Call disposition | "ANSWERED", "NO ANSWER", "BUSY" |
| `action` | varchar(50) | Action taken | "completed" |
| `start_time` | datetime | Call start time | "2024-01-15 10:30:00" |
| `acd_durn` | int(11) | ACD duration | 5 |
| `acd_time` | varchar(50) | ACD time | "5" |
| `end_time` | datetime | Call end time | "2024-01-15 10:32:00" |
| `dtmf` | varchar(50) | DTMF input | "1" |
| `agent_disconnect` | tinyint(1) | Agent disconnected (0/1) | 0 |
| `transfer` | tinyint(1) | Call transferred (0/1) | 0 |
| `feedback` | text | Call feedback | "Call completed successfully" |
| `conf` | tinyint(1) | Conference call (0/1) | 0 |
| `endcall` | tinyint(1) | Call ended (0/1) | 1 |
| `created_at` | timestamp | Record creation time | "2024-01-15 10:32:00" |

---

## 🧪 Quick Test in Postman

### Test 1: Create a Webhook (POST)
1. Open Postman
2. Create new request
3. Set method to `POST`
4. URL: `http://192.168.29.149/api/webhook_api.php`
5. Go to Headers tab, add:
   - Key: `Content-Type`
   - Value: `application/json`
6. Go to Body tab, select `raw` and `JSON`
7. Paste this:
```json
{
  "client": "postman_test",
  "call_type": "inbound",
  "caller_id": "9999888877",
  "disposition": "ANSWERED",
  "durn": 90,
  "billsec": 85,
  "start_time": "2024-01-15 16:00:00",
  "end_time": "2024-01-15 16:01:30",
  "feedback": "Test from Postman"
}
```
8. Click Send

### Test 2: Get All Webhooks (GET)
1. Create new request
2. Set method to `GET`
3. URL: `http://192.168.29.149/api/webhook_api.php?action=list`
4. Click Send

### Test 3: Get Single Webhook (GET)
1. Create new request
2. Set method to `GET`
3. URL: `http://192.168.29.149/api/webhook_api.php?action=get&id=1`
4. Click Send

### Test 4: Filter by Disposition (GET)
1. Create new request
2. Set method to `GET`
3. URL: `http://192.168.29.149/api/webhook_api.php?action=list&disposition=ANSWERED&limit=10`
4. Click Send

---

## 🔍 Common Dispositions
- `ANSWERED` - Call was answered
- `NO ANSWER` - Call was not answered
- `BUSY` - Line was busy
- `FAILED` - Call failed
- `CONGESTION` - Network congestion

---

## ⚠️ Notes
- All datetime fields should be in format: `YYYY-MM-DD HH:MM:SS`
- Boolean fields (agent_disconnect, transfer, conf, endcall) accept `0` or `1`
- Integer fields (durn, billsec, acd_durn) should be numbers without quotes
- The `id` and `created_at` fields are auto-generated, don't include them in POST requests
