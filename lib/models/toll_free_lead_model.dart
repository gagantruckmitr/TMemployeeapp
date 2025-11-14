class TollFreeUser {
  final int id;
  final String uniqueId;
  final String name;
  final String mobile;
  final String? email;
  final String role;
  final String? states;
  final String? profileCompletion;
  final bool hasSubscription;
  final Map<String, dynamic>? latestPayment;
  final List<Map<String, dynamic>> appliedJobs;
  final List<Map<String, dynamic>> callLogs;

  TollFreeUser({
    required this.id,
    required this.uniqueId,
    required this.name,
    required this.mobile,
    this.email,
    required this.role,
    this.states,
    this.profileCompletion,
    required this.hasSubscription,
    this.latestPayment,
    required this.appliedJobs,
    required this.callLogs,
  });

  factory TollFreeUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    
    return TollFreeUser(
      id: int.parse(user['id'].toString()),
      uniqueId: user['unique_id'] ?? '',
      name: user['name'] ?? '',
      mobile: user['mobile'] ?? '',
      email: user['email'],
      role: user['role'] ?? 'driver',
      states: user['states'],
      profileCompletion: user['profile_completion'],
      hasSubscription: user['latest_successful_payment'] != null,
      latestPayment: user['latest_successful_payment'] as Map<String, dynamic>?,
      appliedJobs: List<Map<String, dynamic>>.from(user['applied_jobs'] ?? []),
      callLogs: List<Map<String, dynamic>>.from(user['call_logs'] ?? []),
    );
  }

  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isTransporter => role.toLowerCase() == 'transporter';
}
