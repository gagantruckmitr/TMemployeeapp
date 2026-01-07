# Social Media Infinite Scroll Pagination

## ✅ Feature Implemented

Added infinite scroll pagination to the Social Media screen - automatically loads more leads when scrolling to the bottom.

## 🔧 Configuration

- **Initial Load**: 20 leads (page 1)
- **Per Page**: 20 leads
- **Auto Load Trigger**: When scrolling within 200px of bottom
- **Loading Indicator**: Shows at bottom while loading more

## 📋 How It Works

### 1. API Parameters
```
GET https://truckmitr.com/api/telehead/social-media-leads?assigned_id=12&page=1&per_page=20
```

**Parameters:**
- `assigned_id` - Telecaller's ID (auto)
- `page` - Current page number (starts at 1)
- `per_page` - Number of leads per page (20)

### 2. User Flow

1. **Initial Load**
   - Opens screen
   - Loads page 1 (20 leads)
   - Displays in list

2. **Scroll to Bottom**
   - User scrolls down
   - When 200px from bottom, triggers load
   - Shows loading spinner at bottom
   - Fetches page 2 (next 20 leads)
   - Appends to existing list

3. **Continue Scrolling**
   - Process repeats for page 3, 4, 5...
   - Stops when no more leads available

4. **Pull to Refresh**
   - Resets to page 1
   - Clears existing leads
   - Reloads fresh data

### 3. State Management

**Pagination State:**
```dart
int _currentPage = 1;          // Current page number
final int _perPage = 20;       // Leads per page
bool _hasMoreLeads = true;     // More pages available?
bool _isLoadingMore = false;   // Currently loading more?
```

**Prevents:**
- ✅ Duplicate loading (checks if already loading)
- ✅ Loading when no more data (checks hasMoreLeads)
- ✅ Loading during initial load (checks isLoadingLeads)

### 4. Scroll Detection

```dart
void _onScroll() {
  // Trigger when 200px from bottom
  if (scrollPosition >= maxScroll - 200) {
    _loadMoreLeads();
  }
}
```

**Optimal Distance**: 200px before bottom ensures smooth loading before user hits the end.

## 🎨 UI Indicators

### Initial Loading
```
┌─────────────────────────┐
│                          │
│   ⟳ Loading...           │
│                          │
└─────────────────────────┘
```

### Loading More (Bottom Spinner)
```
┌─────────────────────────┐
│  [Lead Card 1]          │
│  [Lead Card 2]          │
│  [Lead Card 3]          │
│         ...              │
│  [Lead Card 20]         │
│                          │
│       ⟳                  │  ← Small spinner
│                          │
└─────────────────────────┘
```

### No More Leads
```
┌─────────────────────────┐
│  [Lead Card 1]          │
│  [Lead Card 2]          │
│         ...              │
│  [Last Lead]            │
│                          │
│  (No spinner)            │
└─────────────────────────┘
```

## 📊 Load Behavior

| Scenario | Action | Result |
|----------|--------|--------|
| **First Open** | Load page 1 | Shows 20 leads |
| **Scroll to bottom** | Auto-load page 2 | Adds 20 more (total 40) |
| **Keep scrolling** | Auto-load page 3, 4... | Keeps adding 20 each time |
| **Less than 20 returned** | Stop loading | No more pages |
| **Pull to refresh** | Reset to page 1 | Fresh 20 leads |
| **Already loading** | Skip | Prevents duplicates |

## 🔍 Debug Logs

When loading:
```
🔍 Social Media Service - Page: 1, Per Page: 20
🔍 Social Media Service - Found 20 leads
```

When loading more:
```
🔍 Social Media Service - Page: 2, Per Page: 20
🔍 Social Media Service - Found 20 leads
```

When no more:
```
🔍 Social Media Service - Page: 3, Per Page: 20
🔍 Social Media Service - Found 5 leads  ← Less than 20, stops pagination
```

## ✨ Benefits

1. **Better Performance**
   - Doesn't load all leads at once
   - Faster initial load time
   - Less memory usage

2. **Better UX**
   - Smooth infinite scroll
   - No pagination buttons
   - Auto-loads when needed

3. **Network Efficiency**
   - Loads only what's needed
   - Reduces API calls
   - Saves bandwidth

## 🧪 Testing

1. **Test Initial Load**
   - Open screen
   - Should show 20 leads
   - Check console: "Page: 1, Per Page: 20"

2. **Test Load More**
   - Scroll to bottom
   - Should see spinner appear
   - Should load 20 more leads
   - Check console: "Page: 2, Per Page: 20"

3. **Test No More Data**
   - Keep scrolling until less than 20 returned
   - Spinner should disappear
   - No more loading attempts

4. **Test Pull to Refresh**
   - Pull down from top
   - Should reset to page 1
   - Should reload fresh data

5. **Test During Load**
   - Scroll to bottom while loading
   - Should not trigger duplicate load
   - Only one request at a time

## 🔧 Configuration Options

To change the number of leads per page, modify:

```dart
final int _perPage = 20;  // Change to 10, 30, 50, etc.
```

To change the scroll trigger distance:

```dart
_scrollController.position.maxScrollExtent - 200  // Change 200 to 100, 300, etc.
```

## 📝 Notes

- Works independently on leads tab (history tab unaffected)
- Preserves scroll position when switching tabs
- Automatically resets on pull-to-refresh
- Compatible with existing error handling
- Maintains sort order (newest first)
