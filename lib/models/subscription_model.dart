class TelecallerSubscription {
  final int callLogId;
  final int driverId;
  final String driverName;
  final String driverMobile;
  final String driverTmid;
  final int telecallerId;
  final String telecallerName;
  final DateTime callTime;
  final String callStatus;
  final int callDuration;
  final int paymentId;
  final DateTime paymentCreatedAt;
  final DateTime paymentStartTime;
  final DateTime? paymentEndTime;
  final int minutesAfterCall;
  final double amount;
  final String razorpayPaymentId;
  final String paymentStatus;
  final String paymentType;
  final String? planId;
  final int subscriptionDays;

  TelecallerSubscription({
    required this.callLogId,
    required this.driverId,
    required this.driverName,
    required this.driverMobile,
    required this.driverTmid,
    required this.telecallerId,
    required this.telecallerName,
    required this.callTime,
    required this.callStatus,
    required this.callDuration,
    required this.paymentId,
    required this.paymentCreatedAt,
    required this.paymentStartTime,
    this.paymentEndTime,
    required this.minutesAfterCall,
    required this.amount,
    required this.razorpayPaymentId,
    required this.paymentStatus,
    required this.paymentType,
    this.planId,
    required this.subscriptionDays,
  });

  factory TelecallerSubscription.fromJson(Map<String, dynamic> json) {
    try {
      return TelecallerSubscription(
        callLogId: int.parse(json['call_log_id']?.toString() ?? '0'),
        driverId: int.parse(json['driver_id']?.toString() ?? '0'),
        driverName: json['driver_name'] ?? 'Unknown',
        driverMobile: json['driver_mobile'] ?? '',
        driverTmid: json['driver_tmid'] ?? '',
        telecallerId: int.parse(json['telecaller_id']?.toString() ?? '0'),
        telecallerName: json['telecaller_name'] ?? '',
        callTime: json['call_time'] != null 
            ? DateTime.parse(json['call_time']) 
            : DateTime.now(),
        callStatus: json['call_status'] ?? '',
        callDuration: int.parse(json['call_duration']?.toString() ?? '0'),
        paymentId: int.parse(json['payment_id']?.toString() ?? '0'),
        paymentCreatedAt: DateTime.parse(json['payment_created_at']),
        paymentStartTime: DateTime.parse(json['payment_start_time']),
        paymentEndTime: json['payment_end_time'] != null 
            ? DateTime.parse(json['payment_end_time']) 
            : null,
        minutesAfterCall: int.parse(json['minutes_after_call']?.toString() ?? '0'),
        amount: double.parse(json['amount']?.toString() ?? '0'),
        razorpayPaymentId: json['razorpay_payment_id'] ?? '',
        paymentStatus: json['payment_status'] ?? '',
        paymentType: json['payment_type'] ?? '',
        planId: json['plan_id'],
        subscriptionDays: int.parse(json['subscription_days']?.toString() ?? '0'),
      );
    } catch (e) {
      print('❌ Error parsing TelecallerSubscription: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
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
