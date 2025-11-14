import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/smart_calling_models.dart';
import '../../models/toll_free_models.dart';
import '../config/api_config.dart';
import 'real_auth_service.dart';

class TollFreeService {
  TollFreeService._();

  static final TollFreeService instance = TollFreeService._();

  Future<TollFreeContactDetail?> search(String query) async {
    final token = await RealAuthService.instance.getAuthToken();
    final currentUser = RealAuthService.instance.currentUser;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/toll_free_search_api.php',
    ).replace(queryParameters: {'query': query});

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (currentUser != null) 'auth_user_id': currentUser.id,
    };

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        throw Exception('Request failed with status ${response.statusCode}');
      }

      final Map<String, dynamic> body = json.decode(response.body);
      if (body.containsKey('user') && body['user'] is Map<String, dynamic>) {
        return _mapUserToDetail(body['user'] as Map<String, dynamic>);
      }

      return null;
    } catch (error) {
      throw Exception('Unable to fetch toll free contact: $error');
    }
  }

  TollFreeContactDetail _mapUserToDetail(Map<String, dynamic> json) {
    final stateDetail = json['state_detail'] as Map<String, dynamic>?;
    final payment = json['latest_successful_payment'] as Map<String, dynamic>?;
    final profileCompletion =
        json['profile_completion'] ?? json['driver_completion'];
    final registrationDate = json['Created_at'] ?? json['created_at'];

    final driver = DriverContact(
      id: json['id']?.toString() ?? '',
      tmid: json['unique_id']?.toString() ?? 'TM000000',
      name: json['name']?.toString() ?? 'Unknown Driver',
      company: json['job_placement']?.toString() ?? '',
      phoneNumber: json['mobile']?.toString() ?? '',
      state:
          stateDetail?['name']?.toString() ??
          json['states']?.toString() ??
          'Unknown',
      subscriptionStatus: _mapPaymentStatusToSubscription(payment),
      status: CallStatus.connected,
      lastFeedback: null,
      lastCallTime: null,
      remarks: null,
      paymentInfo: _mapPaymentToInfo(payment),
      registrationDate: _parseDate(registrationDate),
      profileCompletion:
          profileCompletion != null
              ? ProfileCompletion.fromPercentageString(
                profileCompletion.toString(),
              )
              : ProfileCompletion.fromPercentageString('0%'),
    );

    final callInfo = json['call'] as Map<String, dynamic>? ?? {};

    return TollFreeContactDetail(
      driver: driver,
      email: json['email']?.toString(),
      language: json['user_lang']?.toString(),
      stateName: stateDetail?['name']?.toString(),
      profileCompletionLabel: profileCompletion?.toString(),
      latestPayment: _mapPaymentToDetail(payment),
      appliedJobs: TollFreeJobApplication.listFromJson(json['applied_jobs']),
      canCall: callInfo['can_call'] == true,
      callLabel: callInfo['label']?.toString(),
      callEndpoint: callInfo['endpoint']?.toString(),
      callPayload: (callInfo['payload'] as Map?)?.cast<String, dynamic>(),
      rawUserData: Map<String, dynamic>.from(json),
    );
  }

  SubscriptionStatus _mapPaymentStatusToSubscription(
    Map<String, dynamic>? payment,
  ) {
    if (payment == null) return SubscriptionStatus.inactive;

    final status = payment['payment_status']?.toString().toLowerCase();
    if (status == 'captured' || status == 'success' || status == 'paid') {
      return SubscriptionStatus.active;
    }
    if (status == 'pending') return SubscriptionStatus.pending;
    return SubscriptionStatus.inactive;
  }

  PaymentInfo _mapPaymentToInfo(Map<String, dynamic>? payment) {
    if (payment == null) return PaymentInfo.none();

    final detail = _mapPaymentToDetail(payment);
    return PaymentInfo(
      subscriptionType: detail?.method,
      paymentStatus: _mapDetailStatus(detail?.paymentStatus),
      paymentDate: detail?.createdAt,
      amount: detail?.amount,
      expiryDate: detail?.expiryDate,
    );
  }

  TollFreePaymentDetail? _mapPaymentToDetail(Map<String, dynamic>? payment) {
    if (payment == null) return null;

    final statusString = payment['payment_status']?.toString().toLowerCase();

    final status = () {
      switch (statusString) {
        case 'captured':
          return TollFreePaymentStatus.captured;
        case 'success':
          return TollFreePaymentStatus.success;
        case 'pending':
          return TollFreePaymentStatus.pending;
        case 'failed':
        case 'cancelled':
          return TollFreePaymentStatus.failed;
        default:
          return TollFreePaymentStatus.unknown;
      }
    }();

    Map<String, dynamic>? rawDetails;
    final detailsString = payment['payment_details'];
    if (detailsString is String && detailsString.isNotEmpty) {
      try {
        rawDetails = jsonDecode(detailsString) as Map<String, dynamic>;
      } catch (_) {
        rawDetails = null;
      }
    }

    return TollFreePaymentDetail(
      orderId: payment['order_id']?.toString(),
      paymentId: payment['payment_id']?.toString(),
      amount: payment['amount']?.toString(),
      method: payment['payment_type']?.toString(),
      paymentStatus: status,
      startDate: _parseDate(payment['start_at']),
      createdAt: _parseDate(payment['created_at']),
      expiryDate: _parseDate(payment['end_at']),
      rawDetails: rawDetails,
    );
  }

  PaymentStatus _mapDetailStatus(TollFreePaymentStatus? status) {
    switch (status) {
      case TollFreePaymentStatus.captured:
      case TollFreePaymentStatus.success:
        return PaymentStatus.success;
      case TollFreePaymentStatus.pending:
        return PaymentStatus.pending;
      case TollFreePaymentStatus.failed:
        return PaymentStatus.failed;
      case TollFreePaymentStatus.unknown:
      case null:
        return PaymentStatus.none;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value * 1000,
        isUtc: true,
      ).toLocal();
    }

    if (value is String) {
      final normalized =
          value.contains('T') ? value : value.replaceAll(' ', 'T');
      return DateTime.tryParse(normalized);
    }

    return null;
  }
}
