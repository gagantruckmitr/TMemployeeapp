# Subscription KPI Logic

## Overview
The Subscription KPI in Performance Analytics tracks subscriptions that resulted from a telecaller's calls.

## Logic
A subscription is counted when:
1. **Call Made**: Telecaller made a call to a user (recorded in `call_logs`)
2. **Payment Captured**: User made a payment with `payment_status = 'captured'`
3. **Timing**: Payment `created_at` is AFTER the call `created_at`
4. **Match**: `call_logs.user_id` matches `payments.user_id`

## SQL Query
```sql
SELECT COUNT(DISTINCT p.id) as subscription_count
FROM call_logs cl
JOIN payments p ON cl.user_id = p.user_id
WHERE cl.caller_id = ?
AND p.payment_status = 'captured'
AND p.created_at > cl.created_at
```

## Key Points
- ✅ Credits the telecaller who made the call that led to subscription
- ✅ Only counts captured payments (successful transactions)
- ✅ Ensures payment happened after the call (causal relationship)
- ✅ Uses DISTINCT to avoid counting duplicate payments
- ✅ Same logic as `api/subscription.php` for consistency

## Example Scenario
```
1. Telecaller (ID: 5) calls User (ID: 123) on 2024-01-15 10:00 AM
2. User subscribes and payment is captured on 2024-01-15 11:30 AM
3. ✅ This subscription is credited to Telecaller ID: 5
```

## Not Counted
- ❌ Payments with status other than 'captured' (failed, pending, etc.)
- ❌ Payments made before the call
- ❌ Users who subscribed without being called by this telecaller

## Testing
Run the test script to verify:
```
your-domain/api/test_subscription_kpi.php
```

This will show:
- Subscription status distribution
- Subscriptions by telecaller
- API response with subscription count

## Related Files
- `api/telecaller_analytics_api.php` - Analytics API with subscription KPI
- `api/subscription.php` - Admin subscriptions tracking (same logic)
- `lib/features/telecaller/performance_analytics_page.dart` - UI display
