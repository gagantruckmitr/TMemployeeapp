class AttendanceDetailModel {
  final String id;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Duration? totalHours;
  final String status;
  final String? notes;

  AttendanceDetailModel({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.totalHours,
    required this.status,
    this.notes,
  });

  factory AttendanceDetailModel.fromJson(Map<String, dynamic> json) {
    return AttendanceDetailModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'] != null 
          ? DateTime.parse(json['checkInTime']) 
          : null,
      checkOutTime: json['checkOutTime'] != null 
          ? DateTime.parse(json['checkOutTime']) 
          : null,
      totalHours: json['totalHours'] != null 
          ? Duration(minutes: json['totalHours']) 
          : null,
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'totalHours': totalHours?.inMinutes,
      'status': status,
      'notes': notes,
    };
  }
}