# Subscription KPI - Today Count Fix

## Problem
The subscription KPI in the dashboard was showing period-based data (today/week/month/all) instead of always showing TODAY's subscriptions. Additionally, the dashboard was using different logic than the subscriptions screen:
- Dashboard API used `call_logs` table (subscriptions where telecaller made a call before payment)
- Subscriptions screen API used `assigned_to` field (subscriptions where user is assigned to telecaller)

## Solution

### 1. Dashboard Logic Update
**File:** `lib/features/telecaller/dashboard_page.dart`

Changed the subscription KPI to ALWAYS show today's subscriptions:

```dart
// Before: Used period-based switch statement
switch (_selectedPeriod) {
  case 'today':
    _totalSubscriptions = subscriptionStats?.todaySubscriptions ?? 0;
    _totalRevenue = subscriptionStats?.todayRevenue ?? 0.0;
    break;
  // ... other cases
}

// After: Always show TODAY's subscriptions
_totalSubscriptions = subscriptionStats?.todaySubscriptions ?? 0;
_totalRevenue = subscriptionStats?.todayRevenue ?? 0.0;
```

### 2. API Logic Alignment
**File:** `api/telecaller_subscription_stats_api.php`

Updated to use the SAME logic as the subscriptions screen (based on `assigned_to` field):

```sql
-- Before: Used call_logs table
FROM payments p
WHERE p.payment_status = 'captured'
AND EXISTS (
    SELECT 1 FROM call_logs cl
    WHERE cl.user_id = p.user_id
    AND cl.caller_id = [telecaller_id]
    AND cl.created_at < p.created_at
)

-- After: Uses assigned_to field (same as subscriptions screen)
FROM users u
JOIN payments p ON u.id = p.user_id
WHERE u.assigned_to = [telecaller_id]
AND p.payment_status = 'captured'
```

## Result
✅ Dashboard subscription KPI now shows TODAY's subscriptions count and revenue
✅ Dashboard and subscriptions screen use the SAME logic (assigned_to field)
✅ Data is consistent across both screens

## Testing
1. Open the dashboard - subscription KPI should show today's count
2. Tap on subscription KPI - opens subscriptions screen
3. In subscriptions screen, select "Today" tab
4. Verify the count matches the dashboard KPI

## Files Modified
- `lib/features/telecaller/dashboard_page.dart` - Lines 147-154
- `api/telecaller_subscription_stats_api.php` - Lines 30-44, 54-66
