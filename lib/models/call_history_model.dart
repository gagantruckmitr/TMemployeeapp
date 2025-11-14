class CallHistoryLog {
  final int id;
  final int callerId;
  final String callerName;
  final String uniqueIdTransporter;
  final String uniqueIdDriver;
  final String driverName;
  final String transporterName;
  final String feedback;
  final String matchStatus;
  final String remark;
  final String jobId;
  final String callRecording;
  final DateTime createdAt;
  final DateTime updatedAt;

  CallHistoryLog({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.uniqueIdTransporter,
    required this.uniqueIdDriver,
    required this.driverName,
    required this.transporterName,
    required this.feedback,
    required this.matchStatus,
    required this.remark,
    required this.jobId,
    required this.callRecording,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CallHistoryLog.fromJson(Map<String, dynamic> json) {
    return CallHistoryLog(
      id: json['id'] ?? 0,
      callerId: json['callerId'] ?? 0,
      callerName: json['callerName'] ?? '',
      uniqueIdTransporter: json['uniqueIdTransporter'] ?? '',
      uniqueIdDriver: json['uniqueIdDriver'] ?? '',
      driverName: json['driverName'] ?? '',
      transporterName: json['transporterName'] ?? '',
      feedback: json['feedback'] ?? '',
      matchStatus: json['matchStatus'] ?? '',
      remark: json['remark'] ?? '',
      jobId: json['jobId'] ?? '',
      callRecording: json['callRecording'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get contactName => driverName.isNotEmpty ? driverName : transporterName;
  String get contactId => uniqueIdDriver.isNotEmpty ? uniqueIdDriver : uniqueIdTransporter;
  String get contactType => uniqueIdDriver.isNotEmpty ? 'Driver' : 'Transporter';
}
