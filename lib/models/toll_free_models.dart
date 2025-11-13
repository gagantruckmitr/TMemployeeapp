import 'smart_calling_models.dart';

class TollFreeContactDetail {
  TollFreeContactDetail({
    required this.driver,
    required this.email,
    required this.language,
    required this.stateName,
    required this.profileCompletionLabel,
    required this.latestPayment,
    required this.appliedJobs,
    required this.canCall,
    required this.callLabel,
    required this.callEndpoint,
    required this.callPayload,
    required this.rawUserData,
  });

  final DriverContact driver;
  final String? email;
  final String? language;
  final String? stateName;
  final String? profileCompletionLabel;
  final TollFreePaymentDetail? latestPayment;
  final List<TollFreeJobApplication> appliedJobs;
  final bool canCall;
  final String? callLabel;
  final String? callEndpoint;
  final Map<String, dynamic>? callPayload;
  final Map<String, dynamic> rawUserData;

  bool get hasActiveSubscription =>
      latestPayment?.paymentStatus == TollFreePaymentStatus.captured ||
      latestPayment?.paymentStatus == TollFreePaymentStatus.success;
}

class TollFreePaymentDetail {
  TollFreePaymentDetail({
    required this.orderId,
    required this.paymentId,
    required this.amount,
    required this.method,
    required this.paymentStatus,
    required this.startDate,
    required this.createdAt,
    required this.expiryDate,
    required this.rawDetails,
  });

  final String? orderId;
  final String? paymentId;
  final String? amount;
  final String? method;
  final TollFreePaymentStatus paymentStatus;
  final DateTime? startDate;
  final DateTime? createdAt;
  final DateTime? expiryDate;
  final Map<String, dynamic>? rawDetails;
}

enum TollFreePaymentStatus { captured, success, pending, failed, unknown }

extension TollFreePaymentStatusExtension on TollFreePaymentStatus {
  String get displayLabel {
    switch (this) {
      case TollFreePaymentStatus.captured:
      case TollFreePaymentStatus.success:
        return 'Captured';
      case TollFreePaymentStatus.pending:
        return 'Pending';
      case TollFreePaymentStatus.failed:
        return 'Failed';
      case TollFreePaymentStatus.unknown:
        return 'Unknown';
    }
  }
}

class TollFreeJobApplication {
  TollFreeJobApplication({
    required this.applicationId,
    required this.jobId,
    required this.transporterId,
    required this.jobTitle,
    required this.location,
    required this.requiredExperience,
    required this.salaryRange,
    required this.licenseType,
    required this.applicationDeadline,
    required this.status,
    required this.createdAt,
    required this.rawJobDetails,
  });

  final String? applicationId;
  final String? jobId;
  final String? transporterId;
  final String? jobTitle;
  final String? location;
  final String? requiredExperience;
  final String? salaryRange;
  final String? licenseType;
  final DateTime? applicationDeadline;
  final String? status;
  final DateTime? createdAt;
  final Map<String, dynamic>? rawJobDetails;

  static List<TollFreeJobApplication> listFromJson(dynamic json) {
    if (json is! List) return [];

    return json
        .whereType<Map>()
        .map(
          (job) => TollFreeJobApplication(
            applicationId: job['id']?.toString(),
            jobId: job['job_details']?['job_id']?.toString(),
            transporterId: job['job_details']?['transporter_id']?.toString(),
            jobTitle: job['job_details']?['job_title']?.toString(),
            location: job['job_details']?['job_location']?.toString(),
            requiredExperience:
                job['job_details']?['Required_Experience']?.toString(),
            salaryRange: job['job_details']?['Salary_Range']?.toString(),
            licenseType: job['job_details']?['Type_of_License']?.toString(),
            applicationDeadline: _parseDate(
              job['job_details']?['Application_Deadline'],
            ),
            status: job['accept_reject_status']?.toString(),
            createdAt: _parseDate(job['created_at']),
            rawJobDetails:
                (job['job_details'] as Map?)?.cast<String, dynamic>(),
          ),
        )
        .toList();
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
    final normalized = value.contains('T') ? value : value.replaceAll(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  return null;
}
