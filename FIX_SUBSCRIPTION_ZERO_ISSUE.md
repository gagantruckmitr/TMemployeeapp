# Fix Subscription Zero Issue

## Problem
The telecaller dashboard is showing 0 subscriptions even after implementing the new subscription logic from `subscription.php`.

## Root Cause
The new subscription logic uses the `call_logs` table instead of `call_hit` table, but there may be:
1. No data in the `call_logs` table
2. No matching records between `call_logs` and `payments` tables
3. Payment `created_at` timestamps are before call `call_time`

## Solution Steps

### Step 1: Check Current Data
Run the debug script to see what data exists:
```
http://your-domain/api/debug_subscription_data.php
```

This will show:
- How many records are in `call_logs` table
- How many captured payments exist
- Whether there are any matching records
- Available telecaller IDs

### Step 2: Create Test Data (if needed)
If no matching data exists, create test subscription data:
```
http://your-domain/api/create_test_subscription_data_call_logs.php
```

This will:
- Find or create a test telecaller in `admins` table
- Find or create a test driver in `users` table
- Create a call record in `call_logs` table
- Create a payment record that occurred AFTER the call
- Verify the subscription is tracked correctly

### Step 3: Test the APIs
After creating test data, test the APIs:

**Stats API:**
```
http://your-domain/api/telecaller_subscription_stats_api.php?user_id=TELECALLER_ID
```

**Subscriptions List API:**
```
http://your-domain/api/telecaller_subscriptions_api.php?user_id=TELECALLER_ID&period=all
```

**Direct Test:**
```
http://your-domain/api/test_subscription_direct.php
```

### Step 4: Verify in App
1. Login to the app with the telecaller ID from test data
2. Check the dashboard - should show subscription count
3. Tap on "My Subscriptions" to see the detailed list

## Technical Details

### Database Schema Requirements

**call_logs table must have:**
- `id` - Primary key
- `user_id` - Driver who was called (matches with payments.user_id)
- `caller_id` - Telecaller who made the call (matches with admins.id)
- `call_time` - When the call was made (DATETIME)
- `call_status` - Status of the call
- `call_duration` - Duration in seconds
- `driver_name` - Driver's name (optional, falls back to users.name)
- `user_number` - Driver's phone (optional, falls back to users.mobile)

**payments table must have:**
- `id` - Primary key
- `user_id` - Driver who made payment (matches with call_logs.user_id)
- `amount` - Payment amount
- `payment_status` - Must be 'captured' for subscriptions
- `payment_id` - Razorpay payment ID
- `payment_type` - Type of payment
- `plan_id` - Subscription plan ID
- `start_at` - Subscription start (Unix timestamp)
- `end_at` - Subscription end (Unix timestamp)
- `created_at` - Payment creation time (DATETIME)

### Matching Logic

A subscription is attributed to a telecaller when:
1. `call_logs.user_id` = `payments.user_id` (same driver)
2. `payments.payment_status` = 'captured' (successful payment)
3. `payments.created_at` > `call_logs.call_time` (payment after call)
4. `call_logs.caller_id` = telecaller's ID

### API Endpoints

**1. Subscription Stats API**
- **File:** `api/telecaller_subscription_stats_api.php`
- **Purpose:** Provides summary statistics for dashboard
- **Parameters:** `user_id` (telecaller ID)
- **Returns:** Total, today, week, month subscriptions and revenue

**2. Subscriptions List API**
- **File:** `api/telecaller_subscriptions_api.php`
- **Purpose:** Provides detailed list of subscriptions
- **Parameters:** `user_id` (telecaller ID), `period` (all/today/week/month)
- **Returns:** Full subscription details with driver info

## Common Issues

### Issue 1: No data in call_logs
**Solution:** Ensure calls are being logged to `call_logs` table, not just `call_hit`

### Issue 2: Payment created_at is before call_time
**Solution:** This is expected if driver subscribed before being called. Only payments AFTER calls are attributed.

### Issue 3: user_id mismatch
**Solution:** Ensure `call_logs.user_id` matches `payments.user_id` (both should be the driver's ID from users table)

### Issue 4: Payment status not 'captured'
**Solution:** Only successful payments with status='captured' are counted as subscriptions

### Issue 5: caller_id is NULL
**Solution:** Ensure `call_logs.caller_id` is populated with the telecaller's ID from admins table

## Verification Checklist

- [ ] `call_logs` table has records
- [ ] `payments` table has records with status='captured'
- [ ] `call_logs.user_id` matches `payments.user_id`
- [ ] `payments.created_at` is after `call_logs.call_time`
- [ ] `call_logs.caller_id` is populated
- [ ] API returns correct data when tested directly
- [ ] Dashboard shows subscription count
- [ ] Subscriptions screen shows detailed list

## Testing Scripts

All testing scripts are in the `api/` folder:
- `debug_subscription_data.php` - Check current data state
- `create_test_subscription_data_call_logs.php` - Create test data
- `test_subscription_direct.php` - Direct API testing
- `test_telecaller_subscriptions.php` - Comprehensive API testing

## Support

If issues persist after following these steps:
1. Check the debug script output for specific errors
2. Verify database table structures match requirements
3. Check API error logs for detailed error messages
4. Ensure timezone settings are consistent across database and PHP
