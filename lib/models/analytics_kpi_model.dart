class AnalyticsKPIResponse {
  final String assignedTo;
  final String filter;
  final AnalyticsCalls calls;
  final AnalyticsMatches matches;
  final int totalInterviewDone;

  AnalyticsKPIResponse({
    required this.assignedTo,
    required this.filter,
    required this.calls,
    required this.matches,
    this.totalInterviewDone = 0,
  });

  factory AnalyticsKPIResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticsKPIResponse(
      assignedTo: json['assigned_to']?.toString() ?? '',
      filter: json['filter']?.toString() ?? '',
      calls: AnalyticsCalls.fromJson(json['calls'] ?? {}),
      matches: AnalyticsMatches.fromJson(json['matches'] ?? {}),
      totalInterviewDone: json['total_interview_done'] != null
          ? int.tryParse(json['total_interview_done'].toString()) ?? 0
          : 0,
    );
  }
}

class AnalyticsCalls {
  final int totalCalls;
  final int connectedCalls;
  final int notConnectedCalls;
  final int callbackCalls;

  AnalyticsCalls({
    this.totalCalls = 0,
    this.connectedCalls = 0,
    this.notConnectedCalls = 0,
    this.callbackCalls = 0,
  });

  factory AnalyticsCalls.fromJson(Map<String, dynamic> json) {
    return AnalyticsCalls(
      totalCalls: _parseInt(json['total_calls']),
      connectedCalls: _parseInt(json['connected_calls']),
      notConnectedCalls: _parseInt(json['not_connected_calls']),
      callbackCalls: _parseInt(json['callback_calls']),
    );
  }
}

class AnalyticsMatches {
  final int totalMatchStatus;

  AnalyticsMatches({this.totalMatchStatus = 0});

  factory AnalyticsMatches.fromJson(Map<String, dynamic> json) {
    return AnalyticsMatches(
      totalMatchStatus: _parseInt(json['total_match_status']),
    );
  }
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}
