import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/margdarshak_api_service.dart';

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
  final String uniqueId;
  final String referralCode;
  final String city;
  final String stateName;

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
    required this.uniqueId,
    required this.referralCode,
    required this.city,
    required this.stateName,
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
      uniqueId: map['uniqueId'] ?? '',
      referralCode: map['referralCode'] ?? '',
      city: map['city'] ?? '',
      stateName: map['stateName'] ?? '',
    );
  }

  /// Factory method to create Driver from API response
  factory Driver.fromApiMap(Map<String, dynamic> apiMap) {
    // Extract shop info
    final shopInfo = apiMap['shop_info'] ?? {};
    final paymentInfo = apiMap['payment_info'] ?? {};

    // Mask phone number (show last 4 digits)
    final phone = apiMap['mobile']?.toString() ?? '';
    final maskedPhone = phone.length > 4
        ? '******${phone.substring(phone.length - 4)}'
        : phone;

    // Map subscription status
    final subscriptionStatus =
        apiMap['subscription_status']?.toString() ?? 'never_subscribed';
    String mappedStatus;

    if (subscriptionStatus.toLowerCase().contains('active') &&
        subscriptionStatus.toLowerCase().contains('plan')) {
      mappedStatus = 'active';
    } else if (subscriptionStatus.toLowerCase().contains('active')) {
      // Ideally just "Active" means active, but JSON says "Active Plan" vs "Active".
      // Let's assume any "active" string implies active status unless explicit context says otherwise.
      mappedStatus = 'active';
    } else if (subscriptionStatus.toLowerCase().contains('expired')) {
      mappedStatus = 'expired';
    } else if (subscriptionStatus.toLowerCase().contains('trial')) {
      mappedStatus = 'trial';
    } else {
      mappedStatus = 'never_subscribed';
    }

    // Map contact timeline
    final contactTimelineData = apiMap['contact_timeline'];
    bool isContacted = false;
    String? lastCallDate;
    String? outcome;
    String? telecaller;

    if (contactTimelineData is Map) {
      // It's a map (JSON object)
      isContacted = true;
      outcome = contactTimelineData['status']?.toString();
      telecaller = contactTimelineData['assigned_to']?.toString();
      lastCallDate = contactTimelineData['call_time']?.toString();
    } else if (contactTimelineData is String &&
        contactTimelineData != 'Not Contacted') {
      // String but not "Not Contacted" - unexpected but handle gracefully
      isContacted = true;
      outcome = contactTimelineData;
    }

    // Parse dates
    String? expiryDate;
    if (paymentInfo is Map && paymentInfo['end_at'] != null) {
      expiryDate = paymentInfo['end_at'].toString();
    }

    String planAmount = '';
    if (paymentInfo is Map && paymentInfo['amount'] != null) {
      planAmount = '₹${paymentInfo['amount']}';
    }

    return Driver(
      id: apiMap['id']?.toString() ?? '',
      name: apiMap['name']?.toString() ?? '',
      phone: phone,
      maskedPhone: maskedPhone,
      sourceShop: shopInfo['shop_name']?.toString() ?? 'Unknown',
      shopType: shopInfo['type']?.toString() ?? 'unknown',
      onboardingStatus: apiMap['status']?.toString() ?? 'pending',
      kycStatus:
          'pending', // Not provided explicitly as kyc_status, but maybe inferred or default
      profileCompletion:
          int.tryParse(apiMap['profile_completion']?.toString() ?? '0') ?? 0,
      teleStatus: TeleStatus(
        contacted: isContacted,
        lastCallDate: lastCallDate,
        outcome: outcome,
        nextFollowUp: null, // Not in JSON currently
        telecaller: telecaller,
      ),
      subscription: Subscription(
        status: mappedStatus,
        plan: planAmount.isNotEmpty
            ? planAmount
            : (mappedStatus == 'active' ? 'Active Plan' : null),
        expiryDate: expiryDate,
      ),
      earnings: Earnings(
        eligible:
            apiMap['earning_per_user'] != null &&
            (int.tryParse(apiMap['earning_per_user'].toString()) ?? 0) > 0,
        amount:
            int.tryParse(apiMap['earning_per_user']?.toString() ?? '0') ?? 0,
        reason: null, // Logic for reason can be added if needed
      ),
      addedDate:
          apiMap['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      uniqueId: apiMap['unique_id']?.toString() ?? '',
      referralCode: apiMap['referral_code']?.toString() ?? '',
      city: apiMap['city']?.toString() ?? '',
      stateName: apiMap['state_name']?.toString() ?? '',
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
      'uniqueId': uniqueId,
      'referralCode': referralCode,
      'city': city,
      'stateName': stateName,
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
  final _apiService = MargdarshakApiService();

  DriversNotifier() : super(DriversState());

  Future<void> loadDrivers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔵 Loading territory drivers...');

      // Fetch real data from API
      final response = await _apiService.getTerritoryDrivers();

      if (response['status'] == true && response['data'] != null) {
        final driversData = response['data'] as List;
        print('✅ Loaded ${driversData.length} drivers from API');

        // Convert API data to Driver objects
        final drivers = driversData.map((driverMap) {
          return Driver.fromApiMap(driverMap);
        }).toList();

        state = state.copyWith(drivers: drivers, isLoading: false);
      } else {
        throw Exception(response['message'] ?? 'Failed to load drivers');
      }
    } catch (e) {
      print('❌ Failed to load drivers: $e');
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
