class TollFreeUser {
  final int id;
  final String uniqueId;
  final String name;
  final String mobile;
  final String? email;
  final String role;
  final String? states;
  final String? profileCompletion;
  final String? profileImage;
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
    this.profileImage,
    required this.hasSubscription,
    this.latestPayment,
    required this.appliedJobs,
    required this.callLogs,
  });

  factory TollFreeUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    final paymentData = user['latest_successful_payment'];
    
    // Handle payment data - it can be null, false, or a Map
    Map<String, dynamic>? payment;
    bool hasSubscription = false;
    
    if (paymentData != null && paymentData is Map<String, dynamic>) {
      payment = paymentData;
      hasSubscription = true;
    }
    
    // Get profile image URL
    String? imageUrl;
    if (user['images'] != null && user['images'].toString().isNotEmpty) {
      imageUrl = 'https://truckmitr.com/public/${user['images']}';
    }
    
    return TollFreeUser(
      id: int.parse(user['id'].toString()),
      uniqueId: user['unique_id'] ?? '',
      name: user['name'] ?? '',
      mobile: user['mobile'] ?? '',
      email: user['email'],
      role: user['role'] ?? 'driver',
      states: user['states'],
      profileCompletion: user['profile_completion'],
      profileImage: imageUrl,
      hasSubscription: hasSubscription,
      latestPayment: payment,
      appliedJobs: List<Map<String, dynamic>>.from(user['applied_jobs'] ?? []),
      callLogs: List<Map<String, dynamic>>.from(user['call_logs'] ?? []),
    );
  }

  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isTransporter => role.toLowerCase() == 'transporter';
}
