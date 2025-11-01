# Subscription Status Update - Payment Status Based

## Overview
Updated the search_users_api.php to determine subscription status based on the `payment_status` column from the payments table instead of just checking if payment exists.

## Changes Made

### Payment Status Logic

#### Before:
- Checked if `payment.amount` exists
- If payment exists → Show as subscribed
- If no payment → Show as not subscribed

#### After:
- Checks `payment.payment_status` column
- **If "captured"** → Show as subscribed with payment date
- **If "pending"** → Show as not subscribed (pending payment)
- **If NULL or other** → Show as inactive

## Implementation Details

### 1. Database Query Update
Added `payment_status` column to the SELECT query:

```php
SELECT 
    // ... other fields
    p.payment_status as payment_status
FROM users u
LEFT JOIN payments p ON u.unique_id = p.unique_id
```

### 2. Subscription Status Logic

```php
$paymentStatus = strtolower($user['payment_status'] ?? '');

if ($paymentStatus === 'captured') {
    // Payment successful - Check expiry date
    if (end_date > now) {
        $subscriptionStatus = 'active';
    } else {
        $subscriptionStatus = 'expired';
    }
} elseif ($paymentStatus === 'pending') {
    // Payment pending - Not subscribed
    $subscriptionStatus = 'pending';
} else {
    // No payment or other status
    $subscriptionStatus = 'inactive';
}
```

### 3. Payment Info Display

**For Captured Payments**:
```json
{
  "subscriptionType": "01/11/2024",
  "paymentStatus": "success",
  "paymentDate": "2024-11-01 14:30:25",
  "amount": "999",
  "expiryDate": "2025-11-01 14:30:25"
}
```

**For Pending Payments**:
```json
{
  "subscriptionType": "pending",
  "paymentStatus": "pending",
  "paymentDate": "2024-11-01 14:30:25",
  "amount": "999",
  "expiryDate": null
}
```

**For No Payment**:
```json
null
```

### 4. Filter Updates

Subscription filters now check `payment_status`:

```php
// Active subscription filter
if ($filterSubscription === 'active') {
    $sql .= " AND p.payment_status = 'captured' AND p.end_at > NOW()";
}

// Expired subscription filter
elseif ($filterSubscription === 'expired') {
    $sql .= " AND p.payment_status = 'captured' AND p.end_at <= NOW()";
}

// Inactive subscription filter
elseif ($filterSubscription === 'inactive') {
    $sql .= " AND (p.payment_status IS NULL OR p.payment_status != 'captured')";
}
```

## Payment Status Values

### Captured
- **Meaning**: Payment successfully processed
- **Subscription Status**: Active (if not expired)
- **Display**: Shows subscription date (DD/MM/YYYY format)
- **Example**: "01/11/2024"

### Pending
- **Meaning**: Payment initiated but not completed
- **Subscription Status**: Pending
- **Display**: Shows "pending"
- **Example**: "pending"

### Other/NULL
- **Meaning**: No payment or failed payment
- **Subscription Status**: Inactive
- **Display**: No payment info shown
- **Example**: null

## User Response Format

```json
{
  "id": "12345",
  "tmid": "TM012345",
  "name": "John Doe",
  "subscriptionStatus": "active",
  "paymentInfo": {
    "subscriptionType": "01/11/2024",
    "paymentStatus": "success",
    "paymentDate": "2024-11-01 14:30:25",
    "amount": "999",
    "expiryDate": "2025-11-01 14:30:25"
  }
}
```

## Subscription Status Values

| payment_status | end_date | Result Status |
|----------------|----------|---------------|
| captured | > NOW() | active |
| captured | <= NOW() | expired |
| pending | any | pending |
| NULL | any | inactive |
| other | any | inactive |

## Benefits

✅ **Accurate Status**: Only shows subscribed when payment is actually captured  
✅ **Pending Handling**: Distinguishes between pending and inactive  
✅ **Date Display**: Shows actual payment date for captured payments  
✅ **Filter Support**: Filters work correctly with payment status  
✅ **Backward Compatible**: Handles NULL values gracefully  

## Testing

### Test Cases

1. **Captured Payment (Active)**:
   - payment_status = 'captured'
   - end_at > NOW()
   - Expected: subscriptionStatus = 'active'

2. **Captured Payment (Expired)**:
   - payment_status = 'captured'
   - end_at <= NOW()
   - Expected: subscriptionStatus = 'expired'

3. **Pending Payment**:
   - payment_status = 'pending'
   - Expected: subscriptionStatus = 'pending'

4. **No Payment**:
   - payment_status = NULL
   - Expected: subscriptionStatus = 'inactive'

### SQL Test Queries

```sql
-- Check payment status distribution
SELECT payment_status, COUNT(*) as count
FROM payments
GROUP BY payment_status;

-- Find users with captured payments
SELECT u.name, u.unique_id, p.payment_status, p.created_at, p.end_at
FROM users u
LEFT JOIN payments p ON u.unique_id = p.unique_id
WHERE p.payment_status = 'captured';

-- Find users with pending payments
SELECT u.name, u.unique_id, p.payment_status, p.created_at
FROM users u
LEFT JOIN payments p ON u.unique_id = p.unique_id
WHERE p.payment_status = 'pending';
```

## Migration Notes

### Database Schema
No schema changes required. The `payment_status` column should already exist in the payments table.

If the column doesn't exist, add it:
```sql
ALTER TABLE payments 
ADD COLUMN payment_status VARCHAR(50) NULL 
AFTER amount;
```

### Data Migration
Update existing payments if needed:
```sql
-- Set captured for successful payments
UPDATE payments 
SET payment_status = 'captured' 
WHERE amount IS NOT NULL 
  AND end_at IS NOT NULL 
  AND payment_status IS NULL;
```

## Summary

The subscription status now accurately reflects the payment status from the payments table. Users with "captured" payments are shown as subscribed with their payment date, while users with "pending" payments are shown as not subscribed. This provides a more accurate representation of subscription status and helps telecallers identify which users have actually completed their payments.

**Status**: ✅ Complete and Ready to Use!
