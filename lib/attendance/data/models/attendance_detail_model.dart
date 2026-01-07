class AttendanceDetailModel {
  final int id;
  final String employeeId;
  final String date;
  final String checkinTime;
  final String? checkoutTime;
  final String workHours;
  final int shiftId;
  final String attendanceStatus;
  final bool isManual;
  final String? userRemark;
  final String? selfie;
  final String? checkinAddress;
  final String? checkoutAddress;

  AttendanceDetailModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.checkinTime,
    this.checkoutTime,
    required this.workHours,
    required this.shiftId,
    required this.attendanceStatus,
    required this.isManual,
    this.userRemark,
    this.selfie,
    this.checkinAddress,
    this.checkoutAddress,
  });

  factory AttendanceDetailModel.fromJson(Map<String, dynamic> json) {
    return AttendanceDetailModel(
      id: json['id'] as int? ?? 0,
      employeeId: json['employee_id']?.toString() ?? '',
      date: json['date'] as String? ?? '',
      checkinTime: json['checkin_time'] as String? ?? '',
      checkoutTime: json['checkout_time'] as String?,
      workHours: json['work_hours']?.toString() ?? '0.00',
      shiftId: json['shift_id'] as int? ?? 0,
      attendanceStatus: json['attendance_status'] as String? ?? 'present',
      isManual: json['is_manual'] == true || json['is_manual'] == 1,
      userRemark: json['user_remark'] as String?,
      selfie: json['selfie'] as String?,
      checkinAddress: json['checkin_address'] as String?,
      checkoutAddress: _parseCheckoutAddress(json['checkout_address']),
    );
  }

  static String? _parseCheckoutAddress(dynamic value) {
    if (value == null || value == 0) return null;
    return value.toString();
  }
}
