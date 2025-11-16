# Telecaller Subscriptions Integration

## Overview
This document describes the integration of subscription tracking logic from `subscription.php` into the telecaller's subscriptions screen. The system now tracks subscriptions based on matching `call_logs.user_id` with `payments.user_id`, crediting the telecaller who made the call that led to the subscription.

## Changes Made

### 1. API Updates (`api/telecaller_subscriptions_api.php`)

**Previous Logic:**
- Used `call_hit` table
- Matched payments between `call_time` and `updated_at`

**New Logic (from `subscription.php`):**
- Uses `call_logs` table
- Matches `call_logs.user_id` with `payments.user_id`
- Credits telecaller when payment `created_at` is after `call_time`
- Filters by `payment_status = 'captured'`

**Key Features:**
- Tracks which telecaller's call led to each subscription
- Calculates time between call and subscription (minutes_after_call)
- Provides subscription duration in days
- Supports period filtering (all, today, week, month)
- Returns comprehensive statistics

**API Response Structure:**
```json
{
  "success": true,
  "data": {
    "total_subscriptions": 10,
    "total_revenue": 5000.00,
    "avg_subscription_value": 500.00,
    "subscriptions": [
      {
        "call_log_id": 123,
        "driver_id": 456,
        "driver_name": "John Doe",
        "driver_mobile": "9876543210",
        "driver_tmid": "TM12345",
        "telecaller_id": 1,
        "telecaller_name": "Agent Smith",
        "call_time": "2024-01-15 10:30:00",
        "call_status": "completed",
        "call_duration": 180,
        "payment_id": 789,
        "payment_created_at": "2024-01-15 11:00:00",
        "payment_start_time": "2024-01-15 11:00:00",
        "payment_end_time": "2024-02-15 11:00:00",
        "minutes_after_call": 30,
        "amount": 500.00,
        "razorpay_payment_id": "pay_xyz123",
        "payment_status": "captured",
        "payment_type": "subscription",
        "plan_id": "plan_abc",
        "subscription_days": 31
      }
    ],
    "subscriptions_by_date": [
      {
        "subscription_date": "2024-01-15",
        "count": 3,
        "daily_revenue": 1500.00
      }
    ],
    "period": "all"
  }
}
```

### 2. Model Updates (`lib/models/subscription_model.dart`)

**Updated `TelecallerSubscription` class:**
- Changed from `call_hit_id` to `call_log_id`
- Added `driverId`, `telecallerName`
- Added `callStatus`, `callDuration`
- Added `paymentCreatedAt`, `minutesAfterCall`
- Added `razorpayPaymentId`, `paymentType`
- Added `subscriptionDays`
- Removed `assignedTo`, `callUpdatedAt`

### 3. UI Updates (`lib/features/telecaller/subscriptions/subscriptions_screen.dart`)

**Enhanced Subscription Card Display:**
- Shows driver information (name, TMID, phone)
- Displays subscription amount prominently
- Shows call time and subscription time
- Displays time elapsed between call and subscription
- Shows subscription duration in days
- Displays subscription validity period
- Shows call duration and status

**New Features:**
- Better visual hierarchy with color-coded info chips
- More detailed subscription information
- Improved layout for better readability
- Added call duration formatting helper

### 4. Testing (`api/test_telecaller_subscriptions.php`)

Created comprehensive test file to verify:
- All subscriptions retrieval
- Period-based filtering (today, week, month)
- Database query validation
- Response structure verification

## Database Schema

### Tables Used:

**call_logs:**
- `id` - Call log identifier
- `user_id` - Driver who was called
- `caller_id` - Telecaller who made the call
- `call_time` - When the call was made
- `call_status` - Status of the call
- `call_duration` - Duration in seconds
- `driver_name` - Driver's name
- `user_number` - Driver's phone number

**payments:**
- `id` - Payment identifier
- `user_id` - Driver who made payment
- `amount` - Payment amount
- `payment_status` - Status (captured, failed, etc.)
- `payment_id` - Razorpay payment ID
- `payment_type` - Type of payment
- `plan_id` - Subscription plan ID
- `start_at` - Subscription start timestamp (Unix)
- `end_at` - Subscription end timestamp (Unix)
- `created_at` - Payment creation time

**users:**
- `id` - User identifier
- `name` - User's name
- `mobile` - User's mobile number
- `unique_id` - User's TMID

**admins:**
- `id` - Admin/Telecaller identifier
- `name` - Telecaller's name

## How It Works

1. **Call Tracking:**
   - When a telecaller calls a driver, it's logged in `call_logs` table
   - Records: telecaller ID, driver ID, call time, duration, status

2. **Subscription Matching:**
   - When a driver subscribes, payment is recorded in `payments` table
   - System matches `call_logs.user_id` with `payments.user_id`
   - Only counts if payment `created_at` > call `call_time`
   - Only includes payments with status = 'captured'

3. **Credit Attribution:**
   - Telecaller who made the call gets credit for the subscription
   - Tracks how long after the call the subscription happened
   - Calculates subscription duration and validity

4. **Dashboard Display:**
   - Shows all subscriptions credited to the telecaller
   - Filters by period (all, today, week, month)
   - Displays comprehensive statistics
   - Shows detailed information for each subscription

## API Endpoints

### Get Telecaller Subscriptions
```
GET /api/telecaller_subscriptions_api.php
```

**Parameters:**
- `user_id` (required) - Telecaller ID
- `period` (optional) - Filter period: 'all', 'today', 'week', 'month'

**Example:**
```
/api/telecaller_subscriptions_api.php?user_id=1&period=week
```

## Testing

Run the test file to verify the integration:
```
http://your-domain/api/test_telecaller_subscriptions.php
```

The test will:
1. Fetch all subscriptions for a telecaller
2. Test period-based filtering
3. Verify database queries
4. Display sample records

## Benefits

1. **Accurate Attribution:** Credits the right telecaller for subscriptions
2. **Performance Tracking:** Shows which calls lead to subscriptions
3. **Time Analysis:** Tracks conversion time from call to subscription
4. **Comprehensive Stats:** Provides detailed analytics for telecallers
5. **Better Motivation:** Telecallers can see direct results of their calls

## Notes

- Only 'captured' payments are counted as subscriptions
- Payment must occur after the call to be attributed
- System handles multiple calls to same driver (credits most recent call before payment)
- Subscription duration is calculated from payment start/end timestamps
- All times are in server timezone (ensure consistency)

## Future Enhancements

Potential improvements:
- Add conversion rate metrics (calls vs subscriptions)
- Show subscription renewal tracking
- Add commission calculation based on subscriptions
- Implement leaderboard for top performers
- Add push notifications for new subscriptions
- Export subscription reports
