class CallAnalytics {
  final int totalCalls;
  final int transporterCalls;
  final int driverCalls;
  final int totalMatches;
  final int selected;
  final int notSelected;
  final int connectedCalls;
  final int callBacks;
  final int callBackLater;
  final int interviewDone;
  final int willConfirmLater;
  final int matchMakingDone;
  final int ringingBusy;
  final int switchedOff;
  final int didntPick;
  final int busyRightNow;
  final int callTomorrow;
  final int callEvening;
  final int callAfter2Days;

  CallAnalytics({
    required this.totalCalls,
    required this.transporterCalls,
    required this.driverCalls,
    required this.totalMatches,
    required this.selected,
    required this.notSelected,
    required this.connectedCalls,
    required this.callBacks,
    required this.callBackLater,
    required this.interviewDone,
    required this.willConfirmLater,
    required this.matchMakingDone,
    required this.ringingBusy,
    required this.switchedOff,
    required this.didntPick,
    required this.busyRightNow,
    required this.callTomorrow,
    required this.callEvening,
    required this.callAfter2Days,
  });

  factory CallAnalytics.fromJson(Map<String, dynamic> json) {
    return CallAnalytics(
      totalCalls: json['totalCalls'] ?? 0,
      transporterCalls: json['transporterCalls'] ?? 0,
      driverCalls: json['driverCalls'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
      selected: json['selected'] ?? 0,
      notSelected: json['notSelected'] ?? 0,
      connectedCalls: json['connectedCalls'] ?? 0,
      callBacks: json['callBacks'] ?? 0,
      callBackLater: json['callBackLater'] ?? 0,
      interviewDone: json['interviewDone'] ?? 0,
      willConfirmLater: json['willConfirmLater'] ?? 0,
      matchMakingDone: json['matchMakingDone'] ?? 0,
      ringingBusy: json['ringingBusy'] ?? 0,
      switchedOff: json['switchedOff'] ?? 0,
      didntPick: json['didntPick'] ?? 0,
      busyRightNow: json['busyRightNow'] ?? 0,
      callTomorrow: json['callTomorrow'] ?? 0,
      callEvening: json['callEvening'] ?? 0,
      callAfter2Days: json['callAfter2Days'] ?? 0,
    );
  }
}

class CallLog {
  final int id;
  final int callerId;
  final String callerName;
  final String uniqueIdTransporter;
  final String uniqueIdDriver;
  final String userType;
  final String userName;
  final String userTmid;
  final String feedback;
  final String matchStatus;
  final String callRecording;
  final String transporterJobRemark;
  final String additionalNotes;
  final String createdAt;
  final String updatedAt;

  CallLog({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.uniqueIdTransporter,
    required this.uniqueIdDriver,
    required this.userType,
    required this.userName,
    required this.userTmid,
    required this.feedback,
    required this.matchStatus,
    required this.callRecording,
    required this.transporterJobRemark,
    required this.additionalNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'] ?? 0,
      callerId: json['callerId'] ?? 0,
      callerName: json['callerName'] ?? '',
      uniqueIdTransporter: json['uniqueIdTransporter'] ?? '',
      uniqueIdDriver: json['uniqueIdDriver'] ?? '',
      userType: json['userType'] ?? '',
      userName: json['userName'] ?? '',
      userTmid: json['userTmid'] ?? '',
      feedback: json['feedback'] ?? '',
      matchStatus: json['matchStatus'] ?? '',
      callRecording: json['callRecording'] ?? '',
      transporterJobRemark: json['transporterJobRemark'] ?? '',
      additionalNotes: json['additionalNotes'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
