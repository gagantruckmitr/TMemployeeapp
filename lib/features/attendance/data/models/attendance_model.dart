class AttendanceModel {
  final String id;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final String? location;
  final String? remark;

  AttendanceModel({
    required this.id,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.location,
    this.remark,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      checkInTime: DateTime.parse(json['checkin_time']),
      checkOutTime: json['checkout_time'] != null 
          ? DateTime.parse(json['checkout_time']) 
          : null,
      status: json['status'] ?? 'present',
      location: json['location'],
      remark: json['remark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkin_time': checkInTime.toIso8601String(),
      'checkout_time': checkOutTime?.toIso8601String(),
      'status': status,
      'location': location,
      'remark': remark,
    };
  }

  // Helper getters for formatted display
  String get checkInTimeFormatted {
    final hour = checkInTime.hour > 12
        ? checkInTime.hour - 12
        : (checkInTime.hour == 0 ? 12 : checkInTime.hour);
    final period = checkInTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')} $period';
  }

  String get checkOutTimeFormatted {
    if (checkOutTime == null) return '--:--';
    final hour = checkOutTime!.hour > 12
        ? checkOutTime!.hour - 12
        : (checkOutTime!.hour == 0 ? 12 : checkOutTime!.hour);
    final period = checkOutTime!.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')} $period';
  }

  String get dateFormatted {
    return '${checkInTime.day.toString().padLeft(2, '0')}/${checkInTime.month.toString().padLeft(2, '0')}/${checkInTime.year}';
  }

  Duration? get workingHours {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  String get workingHoursFormatted {
    final duration = workingHours;
    if (duration == null) return '--:--';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}