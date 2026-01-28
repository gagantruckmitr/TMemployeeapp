import 'package:flutter_riverpod/flutter_riverpod.dart';

// Driver data model
class Driver {
  final String id;
  final String name;
  final String phone;
  final String maskedPhone;
  final String sourceShop;
  final String shopType;
  final String onboardingStatus;
  final String kycStatus;
  final int profileCompletion;
  final TeleStatus teleStatus;
  final Subscription subscription;
  final Earnings earnings;
  final String addedDate;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.maskedPhone,
    required this.sourceShop,
    required this.shopType,
    required this.onboardingStatus,
    required this.kycStatus,
    required this.profileCompletion,
    required this.teleStatus,
    required this.subscription,
    required this.earnings,
    required this.addedDate,
  });

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      maskedPhone: map['maskedPhone'] ?? '',
      sourceShop: map['sourceShop'] ?? '',
      shopType: map['shopType'] ?? '',
      onboardingStatus: map['onboardingStatus'] ?? '',
      kycStatus: map['kycStatus'] ?? '',
      profileCompletion: map['profileCompletion'] ?? 0,
      teleStatus: TeleStatus.fromMap(map['teleStatus'] ?? {}),
      subscription: Subscription.fromMap(map['subscription'] ?? {}),
      earnings: Earnings.fromMap(map['earnings'] ?? {}),
      addedDate: map['addedDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'maskedPhone': maskedPhone,
      'sourceShop': sourceShop,
      'shopType': shopType,
      'onboardingStatus': onboardingStatus,
      'kycStatus': kycStatus,
      'profileCompletion': profileCompletion,
      'teleStatus': teleStatus.toMap(),
      'subscription': subscription.toMap(),
      'earnings': earnings.toMap(),
      'addedDate': addedDate,
    };
  }
}

class TeleStatus {
  final bool contacted;
  final String? lastCallDate;
  final String? outcome;
  final String? nextFollowUp;
  final String? telecaller;

  TeleStatus({
    required this.contacted,
    this.lastCallDate,
    this.outcome,
    this.nextFollowUp,
    this.telecaller,
  });

  factory TeleStatus.fromMap(Map<String, dynamic> map) {
    return TeleStatus(
      contacted: map['contacted'] ?? false,
      lastCallDate: map['lastCallDate'],
      outcome: map['outcome'],
      nextFollowUp: map['nextFollowUp'],
      telecaller: map['telecaller'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contacted': contacted,
      'lastCallDate': lastCallDate,
      'outcome': outcome,
      'nextFollowUp': nextFollowUp,
      'telecaller': telecaller,
    };
  }
}

class Subscription {
  final String status;
  final String? plan;
  final String? expiryDate;

  Subscription({required this.status, this.plan, this.expiryDate});

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      status: map['status'] ?? 'never_subscribed',
      plan: map['plan'],
      expiryDate: map['expiryDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'status': status, 'plan': plan, 'expiryDate': expiryDate};
  }
}

class Earnings {
  final bool eligible;
  final int amount;
  final String? reason;

  Earnings({required this.eligible, required this.amount, this.reason});

  factory Earnings.fromMap(Map<String, dynamic> map) {
    return Earnings(
      eligible: map['eligible'] ?? false,
      amount: map['amount'] ?? 0,
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'eligible': eligible, 'amount': amount, 'reason': reason};
  }
}

// State class for drivers
class DriversState {
  final List<Driver> drivers;
  final bool isLoading;
  final String? error;
  final String selectedSource;
  final String selectedSubscription;
  final String searchQuery;

  DriversState({
    this.drivers = const [],
    this.isLoading = false,
    this.error,
    this.selectedSource = 'all',
    this.selectedSubscription = 'all',
    this.searchQuery = '',
  });

  DriversState copyWith({
    List<Driver>? drivers,
    bool? isLoading,
    String? error,
    String? selectedSource,
    String? selectedSubscription,
    String? searchQuery,
  }) {
    return DriversState(
      drivers: drivers ?? this.drivers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedSource: selectedSource ?? this.selectedSource,
      selectedSubscription: selectedSubscription ?? this.selectedSubscription,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Driver> get filteredDrivers {
    var filtered = drivers.where((driver) {
      if (selectedSource != 'all' && driver.shopType != selectedSource)
        return false;
      if (selectedSubscription != 'all' &&
          driver.subscription.status != selectedSubscription)
        return false;

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!driver.name.toLowerCase().contains(query) &&
            !driver.sourceShop.toLowerCase().contains(query) &&
            !driver.phone.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort(
      (a, b) =>
          DateTime.parse(b.addedDate).compareTo(DateTime.parse(a.addedDate)),
    );
    return filtered;
  }

  List<Driver> getDriversForTab(int tabIndex) {
    final drivers = filteredDrivers;
    switch (tabIndex) {
      case 1:
        return drivers.where((d) => !d.teleStatus.contacted).toList();
      case 2:
        return drivers.where((d) => d.teleStatus.contacted).toList();
      case 3:
        return drivers.where((d) => d.subscription.status == 'active').toList();
      default:
        return drivers;
    }
  }

  bool get hasActiveFilters =>
      selectedSource != 'all' || selectedSubscription != 'all';
}

// Notifier for drivers state
class DriversNotifier extends StateNotifier<DriversState> {
  DriversNotifier() : super(DriversState());

  Future<void> loadDrivers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final driverMaps = [
        {
          'id': '1',
          'name': 'Rajesh Kumar',
          'phone': '+91 98765 43210',
          'maskedPhone': '+91 98765 •••10',
          'sourceShop': 'Sharma Dhaba',
          'shopType': 'dhaba',
          'onboardingStatus': 'completed',
          'kycStatus': 'verified',
          'profileCompletion': 100,
          'teleStatus': {
            'contacted': true,
            'lastCallDate': '2024-01-25',
            'outcome': 'interested',
            'nextFollowUp': null,
            'telecaller': 'Priya Sharma',
          },
          'subscription': {
            'status': 'active',
            'plan': 'Premium Monthly',
            'expiryDate': '2024-02-15',
          },
          'earnings': {'eligible': true, 'amount': 10, 'reason': null},
          'addedDate': '2024-01-20',
        },
        {
          'id': '2',
          'name': 'Suresh Patel',
          'phone': '+91 87654 32109',
          'maskedPhone': '+91 87654 •••09',
          'sourceShop': 'Quick Fix Puncture',
          'shopType': 'puncture',
          'onboardingStatus': 'pending',
          'kycStatus': 'pending',
          'profileCompletion': 60,
          'teleStatus': {
            'contacted': false,
            'lastCallDate': null,
            'outcome': null,
            'nextFollowUp': '2024-01-27',
            'telecaller': null,
          },
          'subscription': {
            'status': 'trial',
            'plan': 'Trial',
            'expiryDate': '2024-01-29',
          },
          'earnings': {
            'eligible': false,
            'amount': 0,
            'reason': 'Profile incomplete',
          },
          'addedDate': '2024-01-22',
        },
        {
          'id': '3',
          'name': 'Amit Singh',
          'phone': '+91 76543 21098',
          'maskedPhone': '+91 76543 •••98',
          'sourceShop': 'Highway Dhaba',
          'shopType': 'dhaba',
          'onboardingStatus': 'completed',
          'kycStatus': 'verified',
          'profileCompletion': 100,
          'teleStatus': {
            'contacted': true,
            'lastCallDate': '2024-01-24',
            'outcome': 'not_interested',
            'nextFollowUp': '2024-01-30',
            'telecaller': 'Rahul Kumar',
          },
          'subscription': {
            'status': 'expired',
            'plan': 'Basic Monthly',
            'expiryDate': '2024-01-15',
          },
          'earnings': {'eligible': true, 'amount': 10, 'reason': null},
          'addedDate': '2024-01-18',
        },
        {
          'id': '4',
          'name': 'Vikram Yadav',
          'phone': '+91 65432 10987',
          'maskedPhone': '+91 65432 •••87',
          'sourceShop': 'Sharma Dhaba',
          'shopType': 'dhaba',
          'onboardingStatus': 'completed',
          'kycStatus': 'verified',
          'profileCompletion': 100,
          'teleStatus': {
            'contacted': true,
            'lastCallDate': '2024-01-26',
            'outcome': 'follow_up',
            'nextFollowUp': '2024-01-28',
            'telecaller': 'Priya Sharma',
          },
          'subscription': {
            'status': 'never_subscribed',
            'plan': null,
            'expiryDate': null,
          },
          'earnings': {'eligible': true, 'amount': 10, 'reason': null},
          'addedDate': '2024-01-19',
        },
        {
          'id': '5',
          'name': 'Manoj Verma',
          'phone': '+91 99887 76655',
          'maskedPhone': '+91 99887 •••55',
          'sourceShop': 'National Highway Dhaba',
          'shopType': 'dhaba',
          'onboardingStatus': 'completed',
          'kycStatus': 'verified',
          'profileCompletion': 100,
          'teleStatus': {
            'contacted': true,
            'lastCallDate': '2024-01-26',
            'outcome': 'interested',
            'nextFollowUp': null,
            'telecaller': 'Amit Singh',
          },
          'subscription': {
            'status': 'active',
            'plan': 'Super Premium',
            'expiryDate': '2024-06-01',
          },
          'earnings': {'eligible': true, 'amount': 25, 'reason': null},
          'addedDate': '2024-01-05',
        },
        {
          'id': '6',
          'name': 'Deepak Sharma',
          'phone': '+91 88776 65544',
          'maskedPhone': '+91 88776 •••44',
          'sourceShop': 'Tire King Puncture',
          'shopType': 'puncture',
          'onboardingStatus': 'pending',
          'kycStatus': 'pending',
          'profileCompletion': 45,
          'teleStatus': {
            'contacted': false,
            'lastCallDate': null,
            'outcome': null,
            'nextFollowUp': '2024-01-28',
            'telecaller': null,
          },
          'subscription': {
            'status': 'never_subscribed',
            'plan': null,
            'expiryDate': null,
          },
          'earnings': {'eligible': false, 'amount': 0, 'reason': 'KYC pending'},
          'addedDate': '2024-01-26',
        },
        {
          'id': '7',
          'name': 'Ravi Tiwari',
          'phone': '+91 77665 54433',
          'maskedPhone': '+91 77665 •••33',
          'sourceShop': 'Sharma Dhaba',
          'shopType': 'dhaba',
          'onboardingStatus': 'completed',
          'kycStatus': 'verified',
          'profileCompletion': 100,
          'teleStatus': {
            'contacted': true,
            'lastCallDate': '2024-01-23',
            'outcome': 'not_reachable',
            'nextFollowUp': '2024-01-29',
            'telecaller': 'Priya Sharma',
          },
          'subscription': {
            'status': 'active',
            'plan': 'Standard Monthly',
            'expiryDate': '2024-02-10',
          },
          'earnings': {'eligible': true, 'amount': 10, 'reason': null},
          'addedDate': '2024-01-08',
        },
        {
          'id': '8',
          'name': 'Sanjay Gupta',
          'phone': '+91 66554 43322',
          'maskedPhone': '+91 66554 •••22',
          'sourceShop': 'Express Puncture Works',
          'shopType': 'puncture',
          'onboardingStatus': 'completed',
          'kycStatus': 'verified',
          'profileCompletion': 95,
          'teleStatus': {
            'contacted': true,
            'lastCallDate': '2024-01-25',
            'outcome': 'interested',
            'nextFollowUp': null,
            'telecaller': 'Rahul Kumar',
          },
          'subscription': {
            'status': 'trial',
            'plan': 'Trial Premium',
            'expiryDate': '2024-01-31',
          },
          'earnings': {'eligible': true, 'amount': 10, 'reason': null},
          'addedDate': '2024-01-24',
        },
      ];

      final drivers = driverMaps.map((m) => Driver.fromMap(m)).toList();
      state = state.copyWith(drivers: drivers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSourceFilter(String source) {
    state = state.copyWith(selectedSource: source);
  }

  void setSubscriptionFilter(String subscription) {
    state = state.copyWith(selectedSubscription: subscription);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedSource: 'all',
      selectedSubscription: 'all',
      searchQuery: '',
    );
  }
}

// Providers
final driversProvider = StateNotifierProvider<DriversNotifier, DriversState>((
  ref,
) {
  return DriversNotifier();
});
