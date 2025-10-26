// Database Models for TruckMitr App

class Admin {
  final int id;
  final String role;
  final String name;
  final String mobile;
  final String email;
  final DateTime? emailVerifiedAt;
  final String password;
  final String rememberToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  Admin({
    required this.id,
    required this.role,
    required this.name,
    required this.mobile,
    required this.email,
    this.emailVerifiedAt,
    required this.password,
    required this.rememberToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as int,
      role: json['role'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.parse(json['email_verified_at']) 
          : null,
      password: json['password'] as String,
      rememberToken: json['remember_token'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'mobile': mobile,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'password': password,
      'remember_token': rememberToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class User {
  final int id;
  final String? uniqueId;
  final String? subId;
  final String role; // 'driver' or 'transporter'
  final String name;
  final String? nameEng;
  final String? mobile;
  final String? otp;
  final String? email;
  final DateTime? emailVerifiedAt;
  final String? password;
  final String? city;
  final String? states;
  final String? pincode;
  final String? address;
  final String? images;
  final String? provider;
  final String? providerId;
  final String? avatar;
  
  // Driver specific fields
  final String? fatherName;
  final String? dob;
  final String? vehicleType;
  final String? sex;
  final String? maritalStatus;
  final String? highestEducation;
  final String? drivingExperience;
  final String? typeOfLicense;
  final String? licenseNumber;
  final String? expiryDateOfLicense;
  final String? preferredLocation;
  final String? currentMonthlyIncome;
  final String? expectedMonthlyIncome;
  final String? aadharNumber;
  final String? jobPlacement;
  final String? previousEmployer;
  final String? aadharPhoto;
  final String? drivingLicense;
  
  // Transporter specific fields
  final String? transportName;
  final String? yearOfEstablishment;
  final String? registeredId;
  final String? panNumber;
  final String? gstNumber;
  final String? fleetSize;
  final String? operationalSegment;
  final String? averageKm;
  final String? referralCode;
  final String? panImage;
  final String? gstCertificate;
  
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    this.uniqueId,
    this.subId,
    required this.role,
    required this.name,
    this.nameEng,
    this.mobile,
    this.otp,
    this.email,
    this.emailVerifiedAt,
    this.password,
    this.city,
    this.states,
    this.pincode,
    this.address,
    this.images,
    this.provider,
    this.providerId,
    this.avatar,
    this.fatherName,
    this.dob,
    this.vehicleType,
    this.sex,
    this.maritalStatus,
    this.highestEducation,
    this.drivingExperience,
    this.typeOfLicense,
    this.licenseNumber,
    this.expiryDateOfLicense,
    this.preferredLocation,
    this.currentMonthlyIncome,
    this.expectedMonthlyIncome,
    this.aadharNumber,
    this.jobPlacement,
    this.previousEmployer,
    this.aadharPhoto,
    this.drivingLicense,
    this.transportName,
    this.yearOfEstablishment,
    this.registeredId,
    this.panNumber,
    this.gstNumber,
    this.fleetSize,
    this.operationalSegment,
    this.averageKm,
    this.referralCode,
    this.panImage,
    this.gstCertificate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      uniqueId: json['unique_id'] as String?,
      subId: json['sub_id'] as String?,
      role: json['role'] as String,
      name: json['name'] as String,
      nameEng: json['name_eng'] as String?,
      mobile: json['mobile'] as String?,
      otp: json['otp'] as String?,
      email: json['email'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.parse(json['email_verified_at']) 
          : null,
      password: json['password'] as String?,
      city: json['city'] as String?,
      states: json['states'] as String?,
      pincode: json['pincode'] as String?,
      address: json['address'] as String?,
      images: json['images'] as String?,
      provider: json['provider'] as String?,
      providerId: json['provider_id'] as String?,
      avatar: json['avatar'] as String?,
      fatherName: json['Father_Name'] as String?,
      dob: json['DOB'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      sex: json['Sex'] as String?,
      maritalStatus: json['Marital_Status'] as String?,
      highestEducation: json['Highest_Education'] as String?,
      drivingExperience: json['Driving_Experience'] as String?,
      typeOfLicense: json['Type_of_License'] as String?,
      licenseNumber: json['License_Number'] as String?,
      expiryDateOfLicense: json['Expiry_date_of_License'] as String?,
      preferredLocation: json['Preferred_Location'] as String?,
      currentMonthlyIncome: json['Current_Monthly_Income'] as String?,
      expectedMonthlyIncome: json['Expected_Monthly_Income'] as String?,
      aadharNumber: json['Aadhar_Number'] as String?,
      jobPlacement: json['job_placement'] as String?,
      previousEmployer: json['previous_employer'] as String?,
      aadharPhoto: json['Aadhar_Photo'] as String?,
      drivingLicense: json['Driving_License'] as String?,
      transportName: json['Transport_Name'] as String?,
      yearOfEstablishment: json['Year_of_Establishment'] as String?,
      registeredId: json['Registered_ID'] as String?,
      panNumber: json['PAN_Number'] as String?,
      gstNumber: json['GST_Number'] as String?,
      fleetSize: json['Fleet_Size'] as String?,
      operationalSegment: json['Operational_Segment'] as String?,
      averageKm: json['Average_KM'] as String?,
      referralCode: json['Referral_Code'] as String?,
      panImage: json['PAN_Image'] as String?,
      gstCertificate: json['GST_Certificate'] as String?,
      status: json['status'] as String? ?? '0',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'sub_id': subId,
      'role': role,
      'name': name,
      'name_eng': nameEng,
      'mobile': mobile,
      'otp': otp,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'password': password,
      'city': city,
      'states': states,
      'pincode': pincode,
      'address': address,
      'images': images,
      'provider': provider,
      'provider_id': providerId,
      'avatar': avatar,
      'Father_Name': fatherName,
      'DOB': dob,
      'vehicle_type': vehicleType,
      'Sex': sex,
      'Marital_Status': maritalStatus,
      'Highest_Education': highestEducation,
      'Driving_Experience': drivingExperience,
      'Type_of_License': typeOfLicense,
      'License_Number': licenseNumber,
      'Expiry_date_of_License': expiryDateOfLicense,
      'Preferred_Location': preferredLocation,
      'Current_Monthly_Income': currentMonthlyIncome,
      'Expected_Monthly_Income': expectedMonthlyIncome,
      'Aadhar_Number': aadharNumber,
      'job_placement': jobPlacement,
      'previous_employer': previousEmployer,
      'Aadhar_Photo': aadharPhoto,
      'Driving_License': drivingLicense,
      'Transport_Name': transportName,
      'Year_of_Establishment': yearOfEstablishment,
      'Registered_ID': registeredId,
      'PAN_Number': panNumber,
      'GST_Number': gstNumber,
      'Fleet_Size': fleetSize,
      'Operational_Segment': operationalSegment,
      'Average_KM': averageKm,
      'Referral_Code': referralCode,
      'PAN_Image': panImage,
      'GST_Certificate': gstCertificate,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

enum CallbackStatus {
  pending('Pending'),
  contacted('Contacted'),
  resolved('Resolved'),
  ringingCallBusy('Ringing / Call Busy'),
  disconnected('Disconnected'),
  callback('Callback'),
  switchedOff('Swtiched Off / Out of Service or Network'),
  interested('Interested'),
  notInterested('Not Interested'),
  futureProspects('Future Prospects');

  const CallbackStatus(this.value);
  final String value;

  static CallbackStatus fromString(String value) {
    return CallbackStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CallbackStatus.pending,
    );
  }
}

enum AppType {
  driver('driver'),
  transporter('transporter');

  const AppType(this.value);
  final String value;

  static AppType fromString(String value) {
    return AppType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AppType.driver,
    );
  }
}

class CallbackRequest {
  final int id;
  final String? uniqueId;
  final int? assignedTo;
  final String userName;
  final String mobileNumber;
  final DateTime requestDateTime;
  final String contactReason;
  final AppType appType;
  final CallbackStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CallbackRequest({
    required this.id,
    this.uniqueId,
    this.assignedTo,
    required this.userName,
    required this.mobileNumber,
    required this.requestDateTime,
    required this.contactReason,
    required this.appType,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CallbackRequest.fromJson(Map<String, dynamic> json) {
    return CallbackRequest(
      id: json['id'] as int,
      uniqueId: json['unique_id'] as String?,
      assignedTo: json['assigned_to'] as int?,
      userName: json['user_name'] as String,
      mobileNumber: json['mobile_number'] as String,
      requestDateTime: DateTime.parse(json['request_date_time']),
      contactReason: json['contact_reason'] as String,
      appType: AppType.fromString(json['app_type'] as String),
      status: CallbackStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'assigned_to': assignedTo,
      'user_name': userName,
      'mobile_number': mobileNumber,
      'request_date_time': requestDateTime.toIso8601String(),
      'contact_reason': contactReason,
      'app_type': appType.value,
      'status': status.value,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class CallLog {
  final int id;
  final int? callerId;
  final int? userId;
  final String? callerNumber;
  final String? userNumber;
  final DateTime callTime;
  final String? referenceId;
  final String? apiResponse;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CallLog({
    required this.id,
    this.callerId,
    this.userId,
    this.callerNumber,
    this.userNumber,
    required this.callTime,
    this.referenceId,
    this.apiResponse,
    this.createdAt,
    this.updatedAt,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'] as int,
      callerId: json['caller_id'] as int?,
      userId: json['user_id'] as int?,
      callerNumber: json['caller_number'] as String?,
      userNumber: json['user_number'] as String?,
      callTime: DateTime.parse(json['call_time']),
      referenceId: json['reference_id'] as String?,
      apiResponse: json['api_response'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller_id': callerId,
      'user_id': userId,
      'caller_number': callerNumber,
      'user_number': userNumber,
      'call_time': callTime.toIso8601String(),
      'reference_id': referenceId,
      'api_response': apiResponse,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}