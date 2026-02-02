# Margdarshak Backend Specification

## Overview
This document outlines the complete backend requirements for the Margdarshak (Field Agent) feature in the TruckMitr application. The Margdarshak system enables field agents to manage shops (dhabas and puncture shops), onboard drivers, track earnings, and manage their territory.

## Database Schema

### 1. Margdarshak Users Table
```sql
CREATE TABLE margdarshak_users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    mobile VARCHAR(15) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('field_agent', 'supervisor', 'admin') DEFAULT 'field_agent',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    profile_image VARCHAR(500),
    join_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_employee_id (employee_id),
    INDEX idx_mobile (mobile),
    INDEX idx_status (status)
);
```

### 2. Territory Management Table
```sql
CREATE TABLE margdarshak_territories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    margdarshak_id BIGINT NOT NULL,
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    pincode_ranges JSON, -- Array of pincode ranges
    gps_boundaries JSON, -- Geofence coordinates
    status ENUM('active', 'inactive') DEFAULT 'active',
    assigned_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (margdarshak_id) REFERENCES margdarshak_users(id) ON DELETE CASCADE,
    INDEX idx_margdarshak_id (margdarshak_id),
    INDEX idx_state_district (state, district),
    INDEX idx_status (status)
);
```

### 3. Shops Management Table
```sql
CREATE TABLE margdarshak_shops (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    margdarshak_id BIGINT NOT NULL,
    shop_name VARCHAR(255) NOT NULL,
    shop_type ENUM('dhaba', 'puncture') NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    owner_mobile VARCHAR(15) NOT NULL,
    owner_mobile_verified BOOLEAN DEFAULT FALSE,
    address TEXT NOT NULL,
    district VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(10),
    landmark VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    services JSON, -- Array of services offered
    operating_hours JSON, -- {opening: "06:00", closing: "22:00"}
    photos JSON, -- Array of photo URLs
    status ENUM('pending', 'approved', 'rejected', 'inactive') DEFAULT 'pending',
    approval_date TIMESTAMP NULL,
    approved_by BIGINT NULL,
    rejection_reason TEXT NULL,
    source ENUM('manual', 'auto') DEFAULT 'manual',
    consent_given BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (margdarshak_id) REFERENCES margdarshak_users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES margdarshak_users(id) ON DELETE SET NULL,
    INDEX idx_margdarshak_id (margdarshak_id),
    INDEX idx_shop_type (shop_type),
    INDEX idx_status (status),
    INDEX idx_district (district),
    INDEX idx_location (latitude, longitude),
    INDEX idx_owner_mobile (owner_mobile)
);
```

### 4. Drivers Management Table
```sql
CREATE TABLE margdarshak_drivers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    margdarshak_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    driver_id BIGINT, -- Reference to main drivers table
    driver_unique_id VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    mobile VARCHAR(15) NOT NULL,
    masked_mobile VARCHAR(15), -- For privacy (e.g., "98765***10")
    source_shop VARCHAR(255) NOT NULL,
    shop_type ENUM('dhaba', 'puncture') NOT NULL,
    kyc_status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    kyc_documents JSON, -- Array of document URLs
    profile_completion INT DEFAULT 0, -- Percentage
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (margdarshak_id) REFERENCES margdarshak_users(id) ON DELETE CASCADE,
    FOREIGN KEY (shop_id) REFERENCES margdarshak_shops(id) ON DELETE CASCADE,
    INDEX idx_margdarshak_id (margdarshak_id),
    INDEX idx_shop_id (shop_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_mobile (mobile),
    INDEX idx_kyc_status (kyc_status)
);
```

### 5. Telecaller Activity Table
```sql
CREATE TABLE margdarshak_tele_activity (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    driver_id BIGINT NOT NULL,
    telecaller_id BIGINT,
    telecaller_name VARCHAR(255),
    contacted BOOLEAN DEFAULT FALSE,
    last_call_date DATE,
    call_outcome ENUM('interested', 'not_interested', 'follow_up', 'not_reachable'),
    call_notes TEXT,
    follow_up_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (driver_id) REFERENCES margdarshak_drivers(id) ON DELETE CASCADE,
    INDEX idx_driver_id (driver_id),
    INDEX idx_telecaller_id (telecaller_id),
    INDEX idx_contacted (contacted),
    INDEX idx_call_outcome (call_outcome)
);
```

### 6. Subscription Management Table
```sql
CREATE TABLE margdarshak_subscriptions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    driver_id BIGINT NOT NULL,
    plan_name VARCHAR(255),
    status ENUM('active', 'expired', 'trial', 'never_subscribed') DEFAULT 'never_subscribed',
    start_date DATE,
    end_date DATE,
    amount DECIMAL(10, 2),
    payment_method VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (driver_id) REFERENCES margdarshak_drivers(id) ON DELETE CASCADE,
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status),
    INDEX idx_end_date (end_date)
);
```

### 7. Earnings Management Table
```sql
CREATE TABLE margdarshak_earnings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    margdarshak_id BIGINT NOT NULL,
    driver_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL DEFAULT 10.00,
    earning_type ENUM('driver_onboarding', 'subscription_bonus', 'referral') DEFAULT 'driver_onboarding',
    status ENUM('eligible', 'pending', 'paid', 'cancelled') DEFAULT 'eligible',
    eligibility_criteria JSON, -- Conditions met for earning
    earned_date DATE NOT NULL,
    verification_date DATE,
    payment_date DATE,
    payment_method VARCHAR(100),
    transaction_id VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (margdarshak_id) REFERENCES margdarshak_users(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES margdarshak_drivers(id) ON DELETE CASCADE,
    FOREIGN KEY (shop_id) REFERENCES margdarshak_shops(id) ON DELETE CASCADE,
    INDEX idx_margdarshak_id (margdarshak_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status),
    INDEX idx_earned_date (earned_date),
    INDEX idx_payment_date (payment_date)
);
```

### 8. Payout Requests Table
```sql
CREATE TABLE margdarshak_payouts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    margdarshak_id BIGINT NOT NULL,
    payout_id VARCHAR(50) UNIQUE NOT NULL, -- PO001, PO002, etc.
    amount DECIMAL(10, 2) NOT NULL,
    eligible_earnings_ids JSON, -- Array of earning IDs included
    bank_details JSON, -- Bank/UPI details at time of request
    status ENUM('requested', 'processing', 'paid', 'failed', 'cancelled') DEFAULT 'requested',
    request_date DATE NOT NULL,
    processing_date DATE,
    payment_date DATE,
    payment_method ENUM('bank_transfer', 'upi') NOT NULL,
    transaction_id VARCHAR(255),
    failure_reason TEXT,
    processed_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (margdarshak_id) REFERENCES margdarshak_users(id) ON DELETE CASCADE,
    INDEX idx_margdarshak_id (margdarshak_id),
    INDEX idx_payout_id (payout_id),
    INDEX idx_status (status),
    INDEX idx_request_date (request_date)
);
```

### 9. Bank Details Table
```sql
CREATE TABLE margdarshak_bank_details (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    margdarshak_id BIGINT NOT NULL,
    account_holder_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(50),
    ifsc_code VARCHAR(20),
    bank_name VARCHAR(255),
    upi_id VARCHAR(255),
    is_primary BOOLEAN DEFAULT TRUE,
    verified BOOLEAN DEFAULT FALSE,
    verification_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (margdarshak_id) REFERENCES margdarshak_users(id) ON DELETE CASCADE,
    INDEX idx_margdarshak_id (margdarshak_id),
    INDEX idx_account_number (account_number),
    INDEX idx_upi_id (upi_id)
);
```

### 10. Shop Check-ins Table
```sql
CREATE TABLE margdarshak_shop_checkins (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    margdarshak_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    purpose ENUM('visit', 'onboarding', 'support', 'maintenance', 'other') NOT NULL,
    distance_meters INT, -- Distance from shop when checking in
    selfie_image VARCHAR(500),
    shop_image VARCHAR(500),
    notes TEXT,
    checkin_latitude DECIMAL(10, 8),
    checkin_longitude DECIMAL(11, 8),
    checkin_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (margdarshak_id) REFERENCES margdarshak_users(id) ON DELETE CASCADE,
    FOREIGN KEY (shop_id) REFERENCES margdarshak_shops(id) ON DELETE CASCADE,
    INDEX idx_margdarshak_id (margdarshak_id),
    INDEX idx_shop_id (shop_id),
    INDEX idx_checkin_time (checkin_time),
    INDEX idx_purpose (purpose)
);
```

### 11. Activity Logs Table
```sql
CREATE TABLE margdarshak_activity_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    margdarshak_id BIGINT NOT NULL,
    activity_type ENUM('shop_added', 'driver_onboarded', 'shop_approved', 'payout_requested', 'checkin_completed') NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    related_id BIGINT, -- ID of related entity (shop_id, driver_id, etc.)
    related_type VARCHAR(50), -- 'shop', 'driver', 'payout', etc.
    metadata JSON, -- Additional activity data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (margdarshak_id) REFERENCES margdarshak_users(id) ON DELETE CASCADE,
    INDEX idx_margdarshak_id (margdarshak_id),
    INDEX idx_activity_type (activity_type),
    INDEX idx_created_at (created_at),
    INDEX idx_related (related_type, related_id)
);
```

## API Endpoints

### Authentication APIs

#### 1. Login
```
POST /api/margdarshak/auth/login
Content-Type: application/json

Request:
{
    "mobile": "9876543210",
    "password": "password123"
}

Response:
{
    "success": true,
    "data": {
        "user": {
            "id": 1,
            "employee_id": "MG001",
            "name": "Rajesh Kumar",
            "email": "rajesh@truckmitr.com",
            "mobile": "9876543210",
            "role": "field_agent",
            "status": "active",
            "profile_image": "https://...",
            "join_date": "2024-01-01"
        },
        "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
        "expires_at": "2024-02-01T00:00:00Z"
    }
}
```

#### 2. Logout
```
POST /api/margdarshak/auth/logout
Authorization: Bearer {token}

Response:
{
    "success": true,
    "message": "Logged out successfully"
}
```

### Dashboard APIs

#### 3. Dashboard Statistics
```
GET /api/margdarshak/dashboard/stats
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": {
        "territory": {
            "state": "Maharashtra",
            "districts": 3
        },
        "shops": {
            "total": 45,
            "dhabas": 28,
            "puncture": 17,
            "pending": 5
        },
        "drivers": {
            "today": 12,
            "week": 78,
            "month": 234,
            "total": 1456
        },
        "earnings": {
            "today": 120,
            "week": 780,
            "month": 2340,
            "pending": 450
        }
    }
}
```

#### 4. Recent Activities
```
GET /api/margdarshak/dashboard/activities?limit=10
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": [
        {
            "id": 1,
            "title": "New driver added via Sharma Dhaba",
            "description": "Driver Suresh Kumar onboarded",
            "activity_type": "driver_onboarded",
            "created_at": "2024-01-25T10:30:00Z",
            "metadata": {
                "driver_name": "Suresh Kumar",
                "shop_name": "Sharma Dhaba"
            }
        }
    ]
}
```

### Shop Management APIs

#### 5. Add Shop
```
POST /api/margdarshak/shops
Authorization: Bearer {token}
Content-Type: multipart/form-data

Request:
{
    "shop_name": "Sharma Dhaba",
    "shop_type": "dhaba",
    "owner_name": "Rajesh Sharma",
    "owner_mobile": "9876543210",
    "address": "NH-48, Pune-Mumbai Highway",
    "district": "Pune",
    "state": "Maharashtra",
    "pincode": "411001",
    "landmark": "Near Katraj Tunnel",
    "latitude": 18.4386,
    "longitude": 73.8370,
    "services": ["Food Service", "Parking", "Restroom"],
    "operating_hours": {
        "opening": "06:00",
        "closing": "22:00"
    },
    "photos": [file1, file2, file3], // Multipart files
    "consent_given": true
}

Response:
{
    "success": true,
    "data": {
        "id": 1,
        "shop_name": "Sharma Dhaba",
        "status": "pending",
        "message": "Shop submitted for approval"
    }
}
```

#### 6. Get Shops List
```
GET /api/margdarshak/shops?filter=all&page=1&limit=20
Authorization: Bearer {token}

Query Parameters:
- filter: all|dhaba|puncture|pending|approved|rejected
- page: Page number (default: 1)
- limit: Items per page (default: 20)
- search: Search term

Response:
{
    "success": true,
    "data": {
        "shops": [
            {
                "id": 1,
                "shop_name": "Sharma Dhaba",
                "shop_type": "dhaba",
                "owner_name": "Rajesh Sharma",
                "owner_mobile": "9876543210",
                "address": "NH-48, Pune-Mumbai Highway",
                "district": "Pune",
                "status": "approved",
                "drivers_count": 23,
                "added_date": "2024-01-15",
                "source": "manual",
                "photos": ["url1", "url2"]
            }
        ],
        "pagination": {
            "current_page": 1,
            "total_pages": 3,
            "total_items": 45,
            "per_page": 20
        }
    }
}
```

#### 7. Update Shop
```
PUT /api/margdarshak/shops/{shop_id}
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
    "shop_name": "Updated Dhaba Name",
    "services": ["Food Service", "Parking", "Restroom", "ATM"],
    "operating_hours": {
        "opening": "05:30",
        "closing": "23:00"
    }
}

Response:
{
    "success": true,
    "data": {
        "id": 1,
        "message": "Shop updated successfully"
    }
}
```

### Driver Management APIs

#### 8. Get Drivers List
```
GET /api/margdarshak/drivers?tab=all&page=1&limit=20
Authorization: Bearer {token}

Query Parameters:
- tab: all|new|connected|subscribers
- page: Page number
- limit: Items per page
- search: Search term
- source_filter: all|dhaba|puncture
- subscription_filter: all|active|trial|expired|never_subscribed

Response:
{
    "success": true,
    "data": {
        "drivers": [
            {
                "id": 1,
                "name": "Suresh Kumar",
                "mobile": "98765***10",
                "source_shop": "Sharma Dhaba",
                "shop_type": "dhaba",
                "kyc_status": "verified",
                "profile_completion": 85,
                "tele_status": {
                    "contacted": true,
                    "last_call_date": "2024-01-25",
                    "outcome": "interested",
                    "telecaller": "Agent 1"
                },
                "subscription": {
                    "status": "active",
                    "plan": "Premium Plan",
                    "expiry_date": "2024-02-25"
                },
                "earnings": {
                    "eligible": true,
                    "amount": 10
                }
            }
        ],
        "pagination": {
            "current_page": 1,
            "total_pages": 12,
            "total_items": 234,
            "per_page": 20
        }
    }
}
```

#### 9. Get Driver Details
```
GET /api/margdarshak/drivers/{driver_id}
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": {
        "driver": {
            "id": 1,
            "name": "Suresh Kumar",
            "mobile": "9876543210",
            "driver_unique_id": "TM123456",
            "source_shop": "Sharma Dhaba",
            "shop_type": "dhaba",
            "kyc_status": "verified",
            "profile_completion": 85,
            "created_at": "2024-01-15T10:30:00Z"
        },
        "tele_activity": {
            "contacted": true,
            "last_call_date": "2024-01-25",
            "outcome": "interested",
            "telecaller_name": "Agent 1",
            "call_notes": "Interested in job opportunities"
        },
        "subscription": {
            "status": "active",
            "plan": "Premium Plan",
            "start_date": "2024-01-25",
            "end_date": "2024-02-25",
            "amount": 299
        },
        "earnings": {
            "eligible": true,
            "amount": 10,
            "earned_date": "2024-01-15"
        }
    }
}
```

### Earnings Management APIs

#### 10. Get Earnings Summary
```
GET /api/margdarshak/earnings/summary
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": {
        "summary": {
            "total_earnings": 2340,
            "eligible_earnings": 1890,
            "pending_verification": 450,
            "paid_earnings": 1440,
            "this_month": 780,
            "this_week": 120,
            "today": 30
        },
        "eligible_drivers": 189,
        "total_drivers": 234,
        "earnings_per_driver": 10,
        "payout_threshold": 500,
        "next_payout_date": "2024-02-01"
    }
}
```

#### 11. Get Recent Earnings
```
GET /api/margdarshak/earnings/recent?limit=10
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": [
        {
            "id": 1,
            "driver_name": "Rajesh Kumar",
            "shop_name": "Sharma Dhaba",
            "amount": 10,
            "earning_type": "driver_onboarding",
            "status": "eligible",
            "earned_date": "2024-01-25"
        }
    ]
}
```

#### 12. Request Payout
```
POST /api/margdarshak/earnings/payout/request
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
    "amount": 500,
    "payment_method": "upi",
    "bank_details": {
        "upi_id": "rajesh@paytm",
        "account_holder_name": "Rajesh Kumar"
    }
}

Response:
{
    "success": true,
    "data": {
        "payout_id": "PO001",
        "amount": 500,
        "status": "requested",
        "estimated_processing_time": "2-3 business days"
    }
}
```

#### 13. Get Payout History
```
GET /api/margdarshak/earnings/payout/history?page=1&limit=10
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": {
        "payouts": [
            {
                "id": 1,
                "payout_id": "PO001",
                "amount": 500,
                "status": "paid",
                "payment_method": "upi",
                "request_date": "2024-01-15",
                "payment_date": "2024-01-17",
                "transaction_id": "TXN123456789"
            }
        ],
        "pagination": {
            "current_page": 1,
            "total_pages": 2,
            "total_items": 15,
            "per_page": 10
        }
    }
}
```

### Territory Management APIs

#### 14. Get Territory Info
```
GET /api/margdarshak/territory
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": {
        "state": "Maharashtra",
        "districts": [
            {
                "name": "Pune",
                "shops_count": 18,
                "drivers_count": 456,
                "status": "active"
            },
            {
                "name": "Mumbai",
                "shops_count": 15,
                "drivers_count": 623,
                "status": "active"
            }
        ],
        "auto_assignment_rules": [
            "Shops added via main app in your districts are auto-linked to you",
            "GPS geofence matching for accurate assignment",
            "Pin code mapping for backup assignment"
        ]
    }
}
```

### Profile Management APIs

#### 15. Get Profile
```
GET /api/margdarshak/profile
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": {
        "user": {
            "id": 1,
            "employee_id": "MG001",
            "name": "Rajesh Kumar",
            "email": "rajesh@truckmitr.com",
            "mobile": "9876543210",
            "role": "field_agent",
            "join_date": "2024-01-01",
            "profile_image": "https://..."
        },
        "territory": {
            "state": "Maharashtra",
            "districts": ["Pune", "Mumbai", "Nashik"]
        },
        "stats": {
            "total_shops": 45,
            "total_drivers": 234,
            "total_earnings": 2340,
            "active_days": 25
        },
        "bank_details": {
            "account_holder_name": "Rajesh Kumar",
            "account_number": "****1234",
            "bank_name": "HDFC Bank",
            "ifsc_code": "HDFC0001234",
            "upi_id": "rajesh@paytm",
            "verified": true
        }
    }
}
```

#### 16. Update Bank Details
```
PUT /api/margdarshak/profile/bank-details
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
    "account_holder_name": "Rajesh Kumar",
    "account_number": "12345678901234",
    "ifsc_code": "HDFC0001234",
    "bank_name": "HDFC Bank",
    "upi_id": "rajesh@paytm"
}

Response:
{
    "success": true,
    "data": {
        "message": "Bank details updated successfully",
        "verification_required": true
    }
}
```

### Shop Check-in APIs

#### 17. Shop Check-in
```
POST /api/margdarshak/shops/{shop_id}/checkin
Authorization: Bearer {token}
Content-Type: multipart/form-data

Request:
{
    "purpose": "visit",
    "distance_meters": 50,
    "notes": "Regular visit to check driver onboarding",
    "checkin_latitude": 18.4386,
    "checkin_longitude": 73.8370,
    "selfie_image": file1, // Multipart file
    "shop_image": file2    // Multipart file
}

Response:
{
    "success": true,
    "data": {
        "checkin_id": 1,
        "shop_name": "Sharma Dhaba",
        "checkin_time": "2024-01-25T14:30:00Z",
        "message": "Successfully checked in to shop"
    }
}
```

#### 18. Get Check-in History
```
GET /api/margdarshak/checkins?page=1&limit=20&shop_id=1
Authorization: Bearer {token}

Response:
{
    "success": true,
    "data": {
        "checkins": [
            {
                "id": 1,
                "shop_name": "Sharma Dhaba",
                "purpose": "visit",
                "distance_meters": 50,
                "notes": "Regular visit",
                "checkin_time": "2024-01-25T14:30:00Z",
                "selfie_image": "https://...",
                "shop_image": "https://..."
            }
        ],
        "pagination": {
            "current_page": 1,
            "total_pages": 3,
            "total_items": 25,
            "per_page": 20
        }
    }
}
```

### Utility APIs

#### 19. Upload File
```
POST /api/margdarshak/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

Request:
{
    "file": file, // Multipart file
    "type": "shop_photo|selfie|document"
}

Response:
{
    "success": true,
    "data": {
        "url": "https://storage.truckmitr.com/margdarshak/photos/123456.jpg",
        "filename": "123456.jpg",
        "size": 1024000
    }
}
```

#### 20. Send OTP
```
POST /api/margdarshak/otp/send
Content-Type: application/json

Request:
{
    "mobile": "9876543210",
    "purpose": "shop_owner_verification"
}

Response:
{
    "success": true,
    "data": {
        "message": "OTP sent successfully",
        "expires_in": 300
    }
}
```

#### 21. Verify OTP
```
POST /api/margdarshak/otp/verify
Content-Type: application/json

Request:
{
    "mobile": "9876543210",
    "otp": "123456",
    "purpose": "shop_owner_verification"
}

Response:
{
    "success": true,
    "data": {
        "verified": true,
        "message": "Mobile number verified successfully"
    }
}
```

## Business Logic Requirements

### 1. Earnings Calculation
- **Driver Onboarding**: ₹10 per driver successfully onboarded
- **Eligibility Criteria**:
  - Driver must complete profile (minimum 80%)
  - Driver must be KYC verified
  - Driver must be linked to approved shop
  - No duplicate earnings for same driver

### 2. Payout Rules
- **Minimum Threshold**: ₹500
- **Processing Time**: 2-3 business days
- **Payment Methods**: UPI, Bank Transfer
- **Verification**: Bank details must be verified before payout

### 3. Shop Approval Workflow
- **Auto-approval**: Not implemented initially
- **Manual Review**: All shops require admin approval
- **Approval Criteria**:
  - Valid GPS coordinates
  - Minimum 2 photos
  - Owner mobile verification
  - Complete address details

### 4. Territory Assignment
- **GPS-based**: Primary assignment method
- **Pincode-based**: Fallback method
- **Manual Override**: Admin can reassign

### 5. Driver Privacy
- **Mobile Masking**: Show only first 3 and last 2 digits
- **Data Access**: Only assigned Margdarshak can view full details
- **Consent**: Required for data collection

## Security Requirements

### 1. Authentication
- JWT tokens with 30-day expiry
- Role-based access control
- Session management

### 2. Data Protection
- Encrypt sensitive data (mobile numbers, bank details)
- HTTPS only for all API calls
- Input validation and sanitization

### 3. File Upload Security
- File type validation
- Size limits (max 5MB per image)
- Virus scanning
- Secure storage with CDN

### 4. API Rate Limiting
- 100 requests per minute per user
- Separate limits for file uploads (10 per minute)

## Performance Requirements

### 1. Response Times
- Dashboard APIs: < 2 seconds
- List APIs: < 3 seconds
- File uploads: < 10 seconds

### 2. Database Optimization
- Proper indexing on frequently queried columns
- Query optimization for large datasets
- Connection pooling

### 3. Caching Strategy
- Redis for session management
- Cache dashboard statistics (5-minute TTL)
- CDN for static assets

## Monitoring and Analytics

### 1. Key Metrics
- Daily active Margdarshaks
- Shops added per day
- Drivers onboarded per day
- Earnings generated
- Payout processing time

### 2. Error Tracking
- API error rates
- Failed file uploads
- Authentication failures
- Database connection issues

### 3. Business Intelligence
- Territory performance reports
- Margdarshak productivity metrics
- Shop approval rates
- Driver conversion rates

## Integration Requirements

### 1. Main TruckMitr App
- Driver data synchronization
- Shop auto-assignment
- Subscription status updates

### 2. Payment Gateway
- UPI payments
- Bank transfer processing
- Transaction status updates

### 3. SMS/WhatsApp Service
- OTP delivery
- Notification alerts
- Status updates

### 4. File Storage
- AWS S3 or similar
- CDN integration
- Backup and recovery

This comprehensive backend specification covers all aspects of the Margdarshak feature based on the Flutter app analysis. The database schema, API endpoints, and business logic are designed to support the complete functionality shown in the mobile application.