class DriverApplicant {
  final int jobId;
  final String jobIdString; // Full job ID like "TMJB00250"
  final String jobTitle;
  final int contractorId;
  final String transporterTmid;
  final String transporterName;
  final int driverId;
  final String driverTmid;
  final String name;
  final String mobile;
  final String email;
  final String city;
  final String state;
  final String? gender;
  final String? profileImage;
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
  final String? callStatus;
  final String? callFeedback;
  final String? callRemarks;
  final String? matchStatus;
  final String? matchMakerName;
  final String? feedbackNotes;
  final String? otherAppliedJobs;
  final int totalJobsApplied;

  DriverApplicant({
    required this.jobId,
    this.jobIdString = '',
    required this.jobTitle,
    required this.contractorId,
    this.transporterTmid = '',
    this.transporterName = '',
    required this.driverId,
    required this.driverTmid,
    required this.name,
    required this.mobile,
    required this.email,
    required this.city,
    required this.state,
    this.gender,
    this.profileImage,
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
    this.callStatus,
    this.callFeedback,
    this.callRemarks,
    this.matchStatus,
    this.matchMakerName,
    this.feedbackNotes,
    this.otherAppliedJobs,
    this.totalJobsApplied = 0,
  });

  factory DriverApplicant.fromJson(Map<String, dynamic> json) {
    return DriverApplicant(
      jobId: json['jobId'] ?? 0,
      jobIdString: json['jobIdString'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      contractorId: json['contractorId'] ?? 0,
      transporterTmid: json['transporterTmid'] ?? '',
      transporterName: json['transporterName'] ?? '',
      driverId: json['driverId'] ?? 0,
      driverTmid: json['driverTmid'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      gender: json['gender'],
      profileImage: json['profileImage'] ?? json['images'],
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
      profileCompletion: int.tryParse((json['profileCompletion'] ?? json['profile_completion'] ?? 0).toString()) ?? 0,
      subscriptionAmount: json['subscriptionAmount']?.toString(),
      subscriptionStartDate: json['subscriptionStartDate'],
      subscriptionEndDate: json['subscriptionEndDate'],
      subscriptionStatus: json['subscriptionStatus'] ?? 'inactive',
      callStatus: json['callStatus'] ?? json['call_status'],
      callFeedback: json['callFeedback'] ?? json['call_feedback'],
      callRemarks: json['callRemarks'] ?? json['call_remarks'],
      matchStatus: json['matchStatus'],
      matchMakerName: json['matchMakerName'],
      feedbackNotes: json['feedbackNotes'],
      otherAppliedJobs: json['otherAppliedJobs'],
      totalJobsApplied: int.tryParse((json['totalJobsApplied'] ?? json['total_jobs_applied'] ?? 0).toString()) ?? 0,
    );
  }
}
