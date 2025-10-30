class LeaveRequest {
  final String id;
  final String telecallerId;
  final String telecallerName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final String status; // pending, approved, rejected
  final String? managerRemarks;
  final String? managerId;
  final DateTime createdAt;
  final DateTime? approvedAt;

  LeaveRequest({
    required this.id,
    required this.telecallerId,
    required this.telecallerName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.managerRemarks,
    this.managerId,
    required this.createdAt,
    this.approvedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'].toString(),
      telecallerId: json['telecaller_id'].toString(),
      telecallerName: json['telecaller_name'] ?? json['name'] ?? '',
      leaveType: json['leave_type'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalDays: int.tryParse(json['total_days'].toString()) ?? 1,
      reason: json['reason'] ?? '',
      status: json['status'] ?? json['manager_approval_status'] ?? 'pending',
      managerRemarks: json['manager_remarks'],
      managerId: json['manager_id']?.toString() ?? json['approved_by']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? json['applied_at'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['approved_at'] != null && json['approved_at'] != '' 
          ? DateTime.parse(json['approved_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'telecaller_id': telecallerId,
      'telecaller_name': telecallerName,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_days': totalDays,
      'reason': reason,
      'status': status,
      'manager_remarks': managerRemarks,
      'manager_id': managerId,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      default:
        return 'orange';
    }
  }

  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '⏳';
    }
  }
}

enum LeaveType {
  sick('Sick Leave', '🤒'),
  casual('Casual Leave', '🏖️'),
  emergency('Emergency Leave', '🚨'),
  personal('Personal Leave', '👤'),
  other('Other', '📝');

  final String displayName;
  final String emoji;
  const LeaveType(this.displayName, this.emoji);
}
