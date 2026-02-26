/// Model for Con Call History
class ConCallHistoryModel {
  final int id;
  final String uniqueIdTransporter;
  final String uniqueIdDriver;
  final int userIdTransporter;
  final int userIdDriver;
  final int assignedTo;
  final String jobId;
  final String? callStatus;
  final String? callFeedback;
  final String? callRemarks;
  final String? callRecording;
  final String? callDuration;
  final String? activeTime;
  final String matchStatus;
  final String driverName;
  final String transporterName;
  final String createdAt;
  final String updatedAt;
  final String? callType;
  final String driverMobile;

  ConCallHistoryModel({
    required this.id,
    required this.uniqueIdTransporter,
    required this.uniqueIdDriver,
    required this.userIdTransporter,
    required this.userIdDriver,
    required this.assignedTo,
    required this.jobId,
    this.callStatus,
    this.callFeedback,
    this.callRemarks,
    this.callRecording,
    this.callDuration,
    this.activeTime,
    required this.matchStatus,
    required this.driverName,
    required this.transporterName,
    required this.createdAt,
    required this.updatedAt,
    this.callType,
    required this.driverMobile,
  });

  factory ConCallHistoryModel.fromJson(Map<String, dynamic> json) {
    return ConCallHistoryModel(
      id: json['id'] ?? 0,
      uniqueIdTransporter: json['unique_id_transporter']?.toString() ?? '',
      uniqueIdDriver: json['unique_id_driver']?.toString() ?? '',
      userIdTransporter: json['user_id_transporter'] ?? 0,
      userIdDriver: json['user_id_driver'] ?? 0,
      assignedTo: json['assigned_to'] ?? 0,
      jobId: json['job_id']?.toString() ?? '',
      callStatus: json['call_status']?.toString(),
      callFeedback: json['call_feedback']?.toString(),
      callRemarks: json['call_remarks']?.toString(),
      callRecording: json['call_recording']?.toString(),
      callDuration: json['call_duration']?.toString(),
      activeTime: json['active_time']?.toString(),
      matchStatus: json['match_status']?.toString() ?? 'pending',
      driverName: json['driver_name']?.toString() ?? '',
      transporterName: json['transporter_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      callType: json['call_type']?.toString(),
      driverMobile: json['driver_mobile']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unique_id_transporter': uniqueIdTransporter,
      'unique_id_driver': uniqueIdDriver,
      'user_id_transporter': userIdTransporter,
      'user_id_driver': userIdDriver,
      'assigned_to': assignedTo,
      'job_id': jobId,
      'call_status': callStatus,
      'call_feedback': callFeedback,
      'call_remarks': callRemarks,
      'call_recording': callRecording,
      'call_duration': callDuration,
      'active_time': activeTime,
      'match_status': matchStatus,
      'driver_name': driverName,
      'transporter_name': transporterName,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'call_type': callType,
      'driver_mobile': driverMobile,
    };
  }
}
