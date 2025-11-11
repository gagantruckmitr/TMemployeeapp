class DriverApplicant {
  final int jobId;
  final String jobTitle;
  final int contractorId;
  final int driverId;
  final String driverTmid;
  final String name;
  final String mobile;
  final String email;
  final String city;
  final String state;
  final String vehicleType;
  final String drivingExperience;
  final String licenseType;
  final String licenseNumber;
  final String preferredLocation;
  final String aadharNumber;
  final String panNumber;
  final String gstNumber;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String appliedAt;
  final int profileCompletion;
  final String? subscriptionAmount;
  final String? subscriptionStartDate;
  final String? subscriptionEndDate;
  final String subscriptionStatus;
  final String? callFeedback;
  final String? matchStatus;
  final String? feedbackNotes;

  DriverApplicant({
    required this.jobId,
    required this.jobTitle,
    required this.contractorId,
    required this.driverId,
    required this.driverTmid,
    required this.name,
    required this.mobile,
    required this.email,
    required this.city,
    required this.state,
    required this.vehicleType,
    required this.drivingExperience,
    required this.licenseType,
    required this.licenseNumber,
    required this.preferredLocation,
    required this.aadharNumber,
    required this.panNumber,
    required this.gstNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.appliedAt,
    this.profileCompletion = 0,
    this.subscriptionAmount,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.subscriptionStatus = 'inactive',
    this.callFeedback,
    this.matchStatus,
    this.feedbackNotes,
  });

  factory DriverApplicant.fromJson(Map<String, dynamic> json) {
    return DriverApplicant(
      jobId: json['jobId'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      contractorId: json['contractorId'] ?? 0,
      driverId: json['driverId'] ?? 0,
      driverTmid: json['driverTmid'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      drivingExperience: json['drivingExperience'] ?? '',
      licenseType: json['licenseType'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      preferredLocation: json['preferredLocation'] ?? '',
      aadharNumber: json['aadharNumber'] ?? '',
      panNumber: json['panNumber'] ?? '',
      gstNumber: json['gstNumber'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      appliedAt: json['appliedAt'] ?? '',
      profileCompletion: json['profileCompletion'] ?? json['profile_completion'] ?? 0,
      subscriptionAmount: json['subscriptionAmount']?.toString(),
      subscriptionStartDate: json['subscriptionStartDate'],
      subscriptionEndDate: json['subscriptionEndDate'],
      subscriptionStatus: json['subscriptionStatus'] ?? 'inactive',
      callFeedback: json['callFeedback'],
      matchStatus: json['matchStatus'],
      feedbackNotes: json['feedbackNotes'],
    );
  }
}
