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
  
  // Personal Details
  final String? fatherName;
  final String? dob;
  final String? sex;
  final String? maritalStatus;
  final String? highestEducation;
  final String? city;
  final String? pincode;
  final String? address;
  
  // Driving Details
  final String? vehicleType;
  final String? drivingExperience;
  final String? typeOfLicense;
  final String? licenseNumber;
  final String? expiryDateOfLicense;
  final String? preferredLocation;
  final String? currentMonthlyIncome;
  final String? expectedMonthlyIncome;
  final String? jobPlacement;
  final String? previousEmployer;
  
  // Documents
  final String? aadharNumber;
  final String? aadharPhoto;
  final String? drivingLicense;

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
    this.fatherName,
    this.dob,
    this.sex,
    this.maritalStatus,
    this.highestEducation,
    this.city,
    this.pincode,
    this.address,
    this.vehicleType,
    this.drivingExperience,
    this.typeOfLicense,
    this.licenseNumber,
    this.expiryDateOfLicense,
    this.preferredLocation,
    this.currentMonthlyIncome,
    this.expectedMonthlyIncome,
    this.jobPlacement,
    this.previousEmployer,
    this.aadharNumber,
    this.aadharPhoto,
    this.drivingLicense,
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
    
    // Get document URLs
    String? aadharPhotoUrl;
    if (user['Aadhar_Photo'] != null && user['Aadhar_Photo'].toString().isNotEmpty) {
      aadharPhotoUrl = 'https://truckmitr.com/public/${user['Aadhar_Photo']}';
    }
    
    String? drivingLicenseUrl;
    if (user['Driving_License'] != null && user['Driving_License'].toString().isNotEmpty) {
      drivingLicenseUrl = 'https://truckmitr.com/public/${user['Driving_License']}';
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
      // Personal Details
      fatherName: user['Father_Name'],
      dob: user['DOB'],
      sex: user['Sex'],
      maritalStatus: user['Marital_Status'],
      highestEducation: user['Highest_Education'],
      city: user['city'],
      pincode: user['pincode'],
      address: user['address'],
      // Driving Details
      vehicleType: user['vehicle_type'],
      drivingExperience: user['Driving_Experience'],
      typeOfLicense: user['Type_of_License'],
      licenseNumber: user['License_Number'],
      expiryDateOfLicense: user['Expiry_date_of_License'],
      preferredLocation: user['Preferred_Location'],
      currentMonthlyIncome: user['Current_Monthly_Income'],
      expectedMonthlyIncome: user['Expected_Monthly_Income'],
      jobPlacement: user['job_placement'],
      previousEmployer: user['previous_employer'],
      // Documents
      aadharNumber: user['Aadhar_Number'],
      aadharPhoto: aadharPhotoUrl,
      drivingLicense: drivingLicenseUrl,
    );
  }

  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isTransporter => role.toLowerCase() == 'transporter';
}