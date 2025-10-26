// Manager Dashboard Models

class ManagerOverview {
  final int totalTelecallers;
  final int onlineTelecallers;
  final int telecallersOnCall;
  final int totalCallsToday;
  final int connectedCallsToday;
  final int interestedCallsToday;
  final int totalCallDurationToday;
  final int uniqueDriversContactedToday;

  ManagerOverview({
    required this.totalTelecallers,
    required this.onlineTelecallers,
    required this.telecallersOnCall,
    required this.totalCallsToday,
    required this.connectedCallsToday,
    required this.interestedCallsToday,
    required this.totalCallDurationToday,
    required this.uniqueDriversContactedToday,
  });

  factory ManagerOverview.fromJson(Map<String, dynamic> json) {
    return ManagerOverview(
      totalTelecallers: int.tryParse(json['total_telecallers']?.toString() ?? '0') ?? 0,
      onlineTelecallers: int.tryParse(json['online_telecallers']?.toString() ?? '0') ?? 0,
      telecallersOnCall: int.tryParse(json['telecallers_on_call']?.toString() ?? '0') ?? 0,
      totalCallsToday: int.tryParse(json['total_calls_today']?.toString() ?? '0') ?? 0,
      connectedCallsToday: int.tryParse(json['connected_calls_today']?.toString() ?? '0') ?? 0,
      interestedCallsToday: int.tryParse(json['interested_calls_today']?.toString() ?? '0') ?? 0,
      totalCallDurationToday: int.tryParse(json['total_call_duration_today']?.toString() ?? '0') ?? 0,
      uniqueDriversContactedToday: int.tryParse(json['unique_drivers_contacted_today']?.toString() ?? '0') ?? 0,
    );
  }
}

class TodayStats {
  final int totalCalls;
  final int connected;
  final int interested;
  final int notInterested;
  final int callbacks;
  final int totalDuration;

  TodayStats({
    required this.totalCalls,
    required this.connected,
    required this.interested,
    required this.notInterested,
    required this.callbacks,
    required this.totalDuration,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      totalCalls: int.tryParse(json['total_calls']?.toString() ?? '0') ?? 0,
      connected: int.tryParse(json['connected']?.toString() ?? '0') ?? 0,
      interested: int.tryParse(json['interested']?.toString() ?? '0') ?? 0,
      notInterested: int.tryParse(json['not_interested']?.toString() ?? '0') ?? 0,
      callbacks: int.tryParse(json['callbacks']?.toString() ?? '0') ?? 0,
      totalDuration: int.tryParse(json['total_duration']?.toString() ?? '0') ?? 0,
    );
  }

  double get conversionRate => totalCalls > 0 ? (interested / totalCalls) * 100 : 0;
  double get connectionRate => totalCalls > 0 ? (connected / totalCalls) * 100 : 0;
}

class WeekTrend {
  final String date;
  final int calls;
  final int interested;

  WeekTrend({
    required this.date,
    required this.calls,
    required this.interested,
  });

  factory WeekTrend.fromJson(Map<String, dynamic> json) {
    return WeekTrend(
      date: json['date'] ?? '',
      calls: int.tryParse(json['calls']?.toString() ?? '0') ?? 0,
      interested: int.tryParse(json['interested']?.toString() ?? '0') ?? 0,
    );
  }
}

class TopPerformer {
  final int id;
  final String name;
  final String mobile;
  final int callsMade;
  final int conversions;
  final int totalDuration;

  TopPerformer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.callsMade,
    required this.conversions,
    required this.totalDuration,
  });

  factory TopPerformer.fromJson(Map<String, dynamic> json) {
    return TopPerformer(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      callsMade: int.tryParse(json['calls_made']?.toString() ?? '0') ?? 0,
      conversions: int.tryParse(json['conversions']?.toString() ?? '0') ?? 0,
      totalDuration: int.tryParse(json['total_duration']?.toString() ?? '0') ?? 0,
    );
  }

  double get conversionRate => callsMade > 0 ? (conversions / callsMade) * 100 : 0;
}

enum TelecallerStatus {
  online,
  offline,
  onCall,
  break_,
  busy;

  String get displayName {
    switch (this) {
      case TelecallerStatus.online:
        return 'Online';
      case TelecallerStatus.offline:
        return 'Offline';
      case TelecallerStatus.onCall:
        return 'On Call';
      case TelecallerStatus.break_:
        return 'Break';
      case TelecallerStatus.busy:
        return 'Busy';
    }
  }

  static TelecallerStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'online':
        return TelecallerStatus.online;
      case 'on_call':
        return TelecallerStatus.onCall;
      case 'break':
        return TelecallerStatus.break_;
      case 'busy':
        return TelecallerStatus.busy;
      default:
        return TelecallerStatus.offline;
    }
  }
}

class TelecallerInfo {
  final int id;
  final String name;
  final String mobile;
  final String? email;
  final TelecallerStatus currentStatus;
  final DateTime? lastActivity;
  final DateTime? loginTime;
  final int totalCallsToday;
  final int connectedToday;
  final int interestedToday;
  final int callDurationToday;

  TelecallerInfo({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.currentStatus,
    this.lastActivity,
    this.loginTime,
    required this.totalCallsToday,
    required this.connectedToday,
    required this.interestedToday,
    required this.callDurationToday,
  });

  factory TelecallerInfo.fromJson(Map<String, dynamic> json) {
    return TelecallerInfo(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      currentStatus: TelecallerStatus.fromString(json['current_status']),
      lastActivity: json['last_activity'] != null ? DateTime.tryParse(json['last_activity']) : null,
      loginTime: json['login_time'] != null ? DateTime.tryParse(json['login_time']) : null,
      totalCallsToday: int.tryParse(json['total_calls_today']?.toString() ?? '0') ?? 0,
      connectedToday: int.tryParse(json['connected_today']?.toString() ?? '0') ?? 0,
      interestedToday: int.tryParse(json['interested_today']?.toString() ?? '0') ?? 0,
      callDurationToday: int.tryParse(json['call_duration_today']?.toString() ?? '0') ?? 0,
    );
  }

  double get conversionRate => totalCallsToday > 0 ? (interestedToday / totalCallsToday) * 100 : 0;
}

class TelecallerDetails {
  final TelecallerInfo telecaller;
  final TodayStats todayStats;
  final List<CallLogEntry> recentCalls;
  final List<DriverAssignment> assignments;

  TelecallerDetails({
    required this.telecaller,
    required this.todayStats,
    required this.recentCalls,
    required this.assignments,
  });
}

class CallLogEntry {
  final int id;
  final int callerId;
  final int driverId;
  final String? driverName;
  final String? driverMobile;
  final String callStatus;
  final int callDuration;
  final DateTime? callStartTime;
  final DateTime? callEndTime;
  final String? feedback;
  final String? notes;
  final String? callOutcome;

  CallLogEntry({
    required this.id,
    required this.callerId,
    required this.driverId,
    this.driverName,
    this.driverMobile,
    required this.callStatus,
    required this.callDuration,
    this.callStartTime,
    this.callEndTime,
    this.feedback,
    this.notes,
    this.callOutcome,
  });

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    return CallLogEntry(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      callerId: int.tryParse(json['caller_id']?.toString() ?? '0') ?? 0,
      driverId: int.tryParse(json['driver_id']?.toString() ?? '0') ?? 0,
      driverName: json['driver_name'],
      driverMobile: json['driver_mobile'],
      callStatus: json['call_status'] ?? 'pending',
      callDuration: int.tryParse(json['call_duration']?.toString() ?? '0') ?? 0,
      callStartTime: json['call_start_time'] != null ? DateTime.tryParse(json['call_start_time']) : null,
      callEndTime: json['call_end_time'] != null ? DateTime.tryParse(json['call_end_time']) : null,
      feedback: json['feedback'],
      notes: json['notes'],
      callOutcome: json['call_outcome'],
    );
  }
}

class DriverAssignment {
  final int id;
  final int telecallerId;
  final int driverId;
  final String? driverName;
  final String? driverMobile;
  final int? assignedBy;
  final DateTime assignedAt;
  final String status;
  final String priority;
  final String? notes;

  DriverAssignment({
    required this.id,
    required this.telecallerId,
    required this.driverId,
    this.driverName,
    this.driverMobile,
    this.assignedBy,
    required this.assignedAt,
    required this.status,
    required this.priority,
    this.notes,
  });

  factory DriverAssignment.fromJson(Map<String, dynamic> json) {
    return DriverAssignment(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      telecallerId: int.tryParse(json['telecaller_id']?.toString() ?? '0') ?? 0,
      driverId: int.tryParse(json['driver_id']?.toString() ?? '0') ?? 0,
      driverName: json['driver_name'],
      driverMobile: json['driver_mobile'],
      assignedBy: json['assigned_by'] != null ? int.tryParse(json['assigned_by'].toString()) : null,
      assignedAt: DateTime.parse(json['assigned_at']),
      status: json['status'] ?? 'active',
      priority: json['priority'] ?? 'medium',
      notes: json['notes'],
    );
  }
}

class PerformanceData {
  final String date;
  final int totalCalls;
  final int connected;
  final int interested;
  final int notInterested;
  final int callbacks;
  final int totalDuration;
  final double avgDuration;
  final double conversionRate;

  PerformanceData({
    required this.date,
    required this.totalCalls,
    required this.connected,
    required this.interested,
    required this.notInterested,
    required this.callbacks,
    required this.totalDuration,
    required this.avgDuration,
    required this.conversionRate,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      date: json['date'] ?? '',
      totalCalls: int.tryParse(json['total_calls']?.toString() ?? '0') ?? 0,
      connected: int.tryParse(json['connected']?.toString() ?? '0') ?? 0,
      interested: int.tryParse(json['interested']?.toString() ?? '0') ?? 0,
      notInterested: int.tryParse(json['not_interested']?.toString() ?? '0') ?? 0,
      callbacks: int.tryParse(json['callbacks']?.toString() ?? '0') ?? 0,
      totalDuration: int.tryParse(json['total_duration']?.toString() ?? '0') ?? 0,
      avgDuration: double.tryParse(json['avg_duration']?.toString() ?? '0') ?? 0,
      conversionRate: double.tryParse(json['conversion_rate']?.toString() ?? '0') ?? 0,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final int id;
  final String name;
  final String mobile;
  final int totalCalls;
  final int connectedCalls;
  final int conversions;
  final int rejections;
  final int totalDuration;
  final double avgDuration;
  final double conversionRate;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    required this.mobile,
    required this.totalCalls,
    required this.connectedCalls,
    required this.conversions,
    required this.rejections,
    required this.totalDuration,
    required this.avgDuration,
    required this.conversionRate,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      totalCalls: int.tryParse(json['total_calls']?.toString() ?? '0') ?? 0,
      connectedCalls: int.tryParse(json['connected_calls']?.toString() ?? '0') ?? 0,
      conversions: int.tryParse(json['conversions']?.toString() ?? '0') ?? 0,
      rejections: int.tryParse(json['rejections']?.toString() ?? '0') ?? 0,
      totalDuration: int.tryParse(json['total_duration']?.toString() ?? '0') ?? 0,
      avgDuration: double.tryParse(json['avg_duration']?.toString() ?? '0') ?? 0,
      conversionRate: double.tryParse(json['conversion_rate']?.toString() ?? '0') ?? 0,
    );
  }
}

class RealTimeStatus {
  final int id;
  final String name;
  final String mobile;
  final TelecallerStatus currentStatus;
  final DateTime? lastActivity;
  final DateTime? loginTime;
  final int? currentCallId;
  final String? currentCallDriver;
  final String? currentCallMobile;
  final DateTime? currentCallStart;

  RealTimeStatus({
    required this.id,
    required this.name,
    required this.mobile,
    required this.currentStatus,
    this.lastActivity,
    this.loginTime,
    this.currentCallId,
    this.currentCallDriver,
    this.currentCallMobile,
    this.currentCallStart,
  });

  factory RealTimeStatus.fromJson(Map<String, dynamic> json) {
    return RealTimeStatus(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      currentStatus: TelecallerStatus.fromString(json['current_status']),
      lastActivity: json['last_activity'] != null ? DateTime.tryParse(json['last_activity']) : null,
      loginTime: json['login_time'] != null ? DateTime.tryParse(json['login_time']) : null,
      currentCallId: json['current_call_id'] != null ? int.tryParse(json['current_call_id'].toString()) : null,
      currentCallDriver: json['current_call_driver'],
      currentCallMobile: json['current_call_mobile'],
      currentCallStart: json['current_call_start'] != null ? DateTime.tryParse(json['current_call_start']) : null,
    );
  }
}
