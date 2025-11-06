# TruckMitr Phase 2 - World-Class Matchmaking & Smart Calling System

A production-ready, enterprise-grade Flutter application for TruckMitr's Phase 2 matchmaking system. Features AI-powered automatic matching between transporters and truck drivers, advanced animations, glassmorphism effects, and real-time analytics.

## Features

### 🏠 Dashboard
- Real-time statistics (Jobs, Matches, Calls)
- Recent activity feed
- Smart Call button with animated pulse effect
- Clean, professional UI with custom color palette

### ☎️ Smart Calling
- **Driver View**: Browse and call drivers with detailed profiles
- **Transporter View**: Manage job postings and applicants
- Match suggestions with scoring algorithm
- Live call bar with controls
- Call feedback system

### 📊 Analytics
- Job posts over time (line chart)
- Match conversion funnel (bar chart)
- Calls made by day (activity chart)
- Match success rate (donut chart)
- Period filters (Week/Month/Year)

## Color Palette

- **Dark Gray** `#4A4A4A` - Headings, icons, primary text
- **Soft Gray** `#CBCBCB` - Secondary text, dividers, borders
- **Off White** `#FFFEF3` - Page background
- **Slate Blue** `#6D8196` - Primary accent (buttons, highlights, charts)

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code

### Installation

1. Navigate to the phase_2 directory:
```bash
cd phase_2
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Demo Credentials
- **Email**: admin@truckmitr.com
- **Password**: admin123

## Project Structure

```
phase_2/
├── lib/
│   ├── core/
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       └── app_theme.dart
│   ├── features/
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── widgets/
│   │   ├── smart_calling/
│   │   │   ├── smart_calling_screen.dart
│   │   │   └── widgets/
│   │   └── analytics/
│   │       ├── analytics_screen.dart
│   │       └── widgets/
│   ├── models/
│   │   └── dummy_data.dart
│   └── main.dart
└── pubspec.yaml
```

## Key Components

### Reusable Widgets
- `StatCard` - KPI display cards
- `DriverCard` - Driver profile cards
- `TransporterJobCard` - Job posting cards
- `SmartCallButton` - Animated call button
- `ActivityFeedItem` - Activity timeline items
- `ChartCard` - Analytics chart containers
- `MatchSuggestionsModal` - Match scoring modal
- `CallBar` - Active call control bar

### Screens
- `LoginScreen` - Authentication
- `DashboardScreen` - Main overview
- `SmartCallingScreen` - Driver/Transporter calling interface
- `AnalyticsScreen` - Data visualization

## Dummy Data

The app uses realistic Indian context data:
- **Drivers**: Ramesh Kumar, Santosh Yadav, Arjun Patel, Vijay Singh
- **Transporters**: Gupta Logistics, Bansal Transport, Sharma Freight
- **Routes**: Pune → Ahmedabad, Delhi → Jaipur, Mumbai → Indore
- **TMIDs**: TM234DRRJ424, TM234TRUP345, etc.

## Testing

Once testing is complete, merge this to the main app by:
1. Copying the phase_2 folder structure
2. Integrating with existing authentication
3. Connecting to real APIs
4. Updating navigation routes

## Design Principles

- **Premium & Minimal**: Clean white backgrounds with soft blue/gray accents
- **Professional**: Poppins typography, 16px rounded corners, soft shadows
- **Smooth Animations**: Micro-interactions on buttons, toggles, and charts
- **Responsive**: Mobile-first with tablet support
- **Clarity**: Emphasis on spacing and visual balance

## Next Steps

- [ ] Connect to backend APIs
- [ ] Implement real-time call integration
- [ ] Add push notifications
- [ ] Integrate with MyOperator
- [ ] Add offline support
- [ ] Implement user preferences
- [ ] Add multi-language support

## License

Proprietary - TruckMitr © 2024
