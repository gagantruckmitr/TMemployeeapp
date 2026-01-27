class TelecallerSubscription {
  final int assignedTo;
  final String paymentUniqueId;
  final String userName;
  final double amount;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime updatedAt;

  TelecallerSubscription({
    required this.assignedTo,
    required this.paymentUniqueId,
    required this.userName,
    required this.amount,
    required this.startAt,
    required this.endAt,
    required this.updatedAt,
  });

  /// Factory for Laravel API response
  /// API: https://development.truckmitr.com/api/telehead/reports/assigned-to-wise-summary/
  factory TelecallerSubscription.fromLaravelJson(Map<String, dynamic> json) {
    try {
      // start_at and end_at are Unix timestamps
      final startAtTimestamp = int.parse(json['start_at']?.toString() ?? '0');
      final endAtTimestamp = int.parse(json['end_at']?.toString() ?? '0');
      
      return TelecallerSubscription(
        assignedTo: int.parse(json['assigned_to']?.toString() ?? '0'),
        paymentUniqueId: json['payment_unique_id'] ?? '',
        userName: json['user_name'] ?? 'Unknown',
        amount: double.parse(json['amount']?.toString() ?? '0'),
        startAt: DateTime.fromMillisecondsSinceEpoch(startAtTimestamp * 1000),
        endAt: DateTime.fromMillisecondsSinceEpoch(endAtTimestamp * 1000),
        updatedAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing TelecallerSubscription from Laravel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Getters for backward compatibility with UI
  String get driverName => userName;
  String get driverTmid => paymentUniqueId;
  DateTime get paymentStartTime => updatedAt; // Use updated_at for payment date/time display
  DateTime? get paymentEndTime => endAt;
  String get paymentStatus => 'PAID';
  String get paymentType => 'Online';
}

class SubscriptionStats {
  final int totalSubscriptions;
  final double totalRevenue;
  final int todaySubscriptions;
  final double todayRevenue;
  final int weekSubscriptions;
  final double weekRevenue;
  final int monthSubscriptions;
  final double monthRevenue;
  final List<RecentSubscription> recentSubscriptions;

  SubscriptionStats({
    required this.totalSubscriptions,
    required this.totalRevenue,
    required this.todaySubscriptions,
    required this.todayRevenue,
    required this.weekSubscriptions,
    required this.weekRevenue,
    required this.monthSubscriptions,
    required this.monthRevenue,
    required this.recentSubscriptions,
  });

  factory SubscriptionStats.fromJson(Map<String, dynamic> json) {
    return SubscriptionStats(
      totalSubscriptions: json['total_subscriptions'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      todaySubscriptions: json['today_subscriptions'] ?? 0,
      todayRevenue: (json['today_revenue'] ?? 0).toDouble(),
      weekSubscriptions: json['week_subscriptions'] ?? 0,
      weekRevenue: (json['week_revenue'] ?? 0).toDouble(),
      monthSubscriptions: json['month_subscriptions'] ?? 0,
      monthRevenue: (json['month_revenue'] ?? 0).toDouble(),
      recentSubscriptions: (json['recent_subscriptions'] as List?)
              ?.map((e) => RecentSubscription.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RecentSubscription {
  final int paymentId;
  final double amount;
  final DateTime paymentTime;
  final String driverName;
  final String driverTmid;

  RecentSubscription({
    required this.paymentId,
    required this.amount,
    required this.paymentTime,
    required this.driverName,
    required this.driverTmid,
  });

  factory RecentSubscription.fromJson(Map<String, dynamic> json) {
    return RecentSubscription(
      paymentId: int.parse(json['payment_id'].toString()),
      amount: double.parse(json['amount'].toString()),
      paymentTime: DateTime.parse(json['payment_time']),
      driverName: json['driver_name'] ?? 'Unknown',
      driverTmid: json['driver_tmid'] ?? '',
    );
  }
}
