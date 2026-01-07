class JobModel {
  final int id;
  final String jobId;
  final String jobTitle;
  final String transporterId;
  final String transporterName;
  final String transporterTmid;
  final String transporterPhone;
  final String transporterCity;
  final String transporterState;
  final int transporterProfileCompletion;
  final String? transporterProfilePhoto;
  final String? transporterGender;
  final String jobLocation;
  final String jobDescription;
  final String salaryRange;
  final String requiredExperience;
  final String preferredStatus;
  final String typeOfLicense;
  final String vehicleType;
  final String vehicleTypeDetail;
  final String applicationDeadline;
  final String jobManagementDate;
  final String jobManagementId;
  final String jobDescriptionId;
  final int numberOfDriverRequired;
  final int activePosition;
  final String createdVehicleDetail;
  final String createdAt;
  final String updatedAt;
  final int status;
  final int applicantsCount;
  final bool isApproved;
  final bool isActive;
  final bool isExpired;
  final int? assignedTo;
  final String? assignedToName;
  final bool isClosed;

  JobModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.transporterId,
    required this.transporterName,
    required this.transporterTmid,
    required this.transporterPhone,
    required this.transporterCity,
    required this.transporterState,
    required this.transporterProfileCompletion,
    this.transporterProfilePhoto,
    this.transporterGender,
    required this.jobLocation,
    required this.jobDescription,
    required this.salaryRange,
    required this.requiredExperience,
    required this.preferredStatus,
    required this.typeOfLicense,
    required this.vehicleType,
    required this.vehicleTypeDetail,
    required this.applicationDeadline,
    required this.jobManagementDate,
    required this.jobManagementId,
    required this.jobDescriptionId,
    required this.numberOfDriverRequired,
    required this.activePosition,
    required this.createdVehicleDetail,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.applicantsCount,
    required this.isApproved,
    required this.isActive,
    required this.isExpired,
    this.assignedTo,
    this.assignedToName,
    required this.isClosed,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] ?? 0,
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      transporterId: json['transporterId'] ?? '',
      transporterName: json['transporterName'] ?? '',
      transporterTmid: json['transporterTmid'] ?? '',
      transporterPhone: json['transporterPhone'] ?? '',
      transporterCity: json['transporterCity'] ?? '',
      transporterState: json['transporterState'] ?? '',
      transporterProfileCompletion: json['transporterProfileCompletion'] ?? 0,
      transporterProfilePhoto: json['transporterImage'] ?? json['transporterProfilePhoto'],
      transporterGender: json['transporterGender'],
      jobLocation: json['jobLocation'] ?? '',
      jobDescription: json['jobDescription'] ?? '',
      salaryRange: json['salaryRange'] ?? '',
      requiredExperience: json['requiredExperience'] ?? '',
      preferredStatus: json['preferredStatus'] ?? '',
      typeOfLicense: json['typeOfLicense'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleTypeDetail: json['vehicleTypeDetail'] ?? '',
      applicationDeadline: json['applicationDeadline'] ?? '',
      jobManagementDate: json['jobManagementDate'] ?? '',
      jobManagementId: json['jobManagementId'] ?? '',
      jobDescriptionId: json['jobDescriptionId'] ?? '',
      numberOfDriverRequired: json['numberOfDriverRequired'] ?? 0,
      activePosition: json['activePosition'] ?? 0,
      createdVehicleDetail: json['createdVehicleDetail'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      status: json['status'] ?? 0,
      applicantsCount: json['applicantsCount'] ?? 0,
      isApproved: json['isApproved'] ?? false,
      isActive: json['isActive'] ?? false,
      isExpired: json['isExpired'] ?? false,
      assignedTo: json['assignedTo'] != null
          ? int.tryParse(json['assignedTo'].toString())
          : json['assigned_to'] != null
              ? int.tryParse(json['assigned_to'].toString())
              : null,
      assignedToName: json['assignedToName'] ?? json['assigned_to_name'],
      isClosed: json['isClosed'] ?? false,
    );
  }

  // Factory method for Laravel API response format
  factory JobModel.fromLaravelJson(Map<String, dynamic> json) {
    // Parse status: 1 = approved, 0 = not approved
    final int statusValue = int.tryParse(json['status']?.toString() ?? '0') ?? 0;
    final bool isApproved = statusValue == 1;
    
    // Parse active_inactive: 1 = active, 0 = pending/inactive
    final int activeInactiveValue = int.tryParse(json['active_inactive']?.toString() ?? '0') ?? 0;
    final bool isActive = activeInactiveValue == 1;
    
    // Parse closed_job - check closed_job_by_jobs_details field
    // If value is 1, job is closed. If null or other value, job is not closed.
    final bool isClosed = json['closed_job_by_jobs_details'] != null && 
                          json['closed_job_by_jobs_details'].toString() == '1';
    
    // Calculate expiry
    bool isExpired = false;
    try {
      if (json['Application_Deadline'] != null) {
        final deadline = DateTime.parse(json['Application_Deadline']);
        final now = DateTime.now();
        isExpired = now.isAfter(deadline);
      }
    } catch (e) {
      // Ignore parse errors
    }

    // Extract transporter details from new API response format
    final transporterName = json['transporter_name']?.toString() ?? 
                           json['transporterName']?.toString() ?? 
                           'Unknown Transporter';
    
    final transporterTmid = json['transporter_unique_id']?.toString() ?? 
                           json['transporterTmid']?.toString() ?? 
                           json['transporter_tmid']?.toString() ?? 
                           '';
    
    final transporterPhone = json['transporter_mobile']?.toString() ?? 
                            json['transporterPhone']?.toString() ?? 
                            '';
    
    final transporterState = json['state_name']?.toString() ?? 
                            json['transporterState']?.toString() ?? 
                            '';
    
    // Parse profile completion percentage
    final profileCompletion = int.tryParse(json['profile_completion']?.toString() ?? '0') ?? 0;
    
    // Parse applicants count
    final applicantsCount = int.tryParse(json['total_applicants']?.toString() ?? '0') ?? 0;

    return JobModel(
      id: json['id'] ?? 0,
      jobId: json['job_id'] ?? '',
      jobTitle: json['job_title'] ?? '',
      transporterId: json['transporter_id']?.toString() ?? '',
      transporterName: transporterName,
      transporterTmid: transporterTmid,
      transporterPhone: transporterPhone,
      transporterCity: '', // Not provided in new API
      transporterState: transporterState,
      transporterProfileCompletion: profileCompletion,
      transporterProfilePhoto: json['transporter_image'],
      transporterGender: null,
      jobLocation: json['job_location'] ?? '',
      jobDescription: json['Job_Description'] ?? '',
      salaryRange: json['Salary_Range'] ?? '',
      requiredExperience: json['Required_Experience'] ?? '',
      preferredStatus: json['Preferred_Skills'] ?? '',
      typeOfLicense: json['Type_of_License'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      vehicleTypeDetail: json['vehicle_type'] ?? '',
      applicationDeadline: json['Application_Deadline'] ?? '',
      jobManagementDate: json['Job_Management'] ?? '',
      jobManagementId: json['Job_Management'] ?? '',
      jobDescriptionId: json['Job_Description'] ?? '',
      numberOfDriverRequired: int.tryParse(json['number_of_drivers_required']?.toString() ?? '1') ?? 1,
      activePosition: 0,
      createdVehicleDetail: json['vehicle_type'] ?? '',
      createdAt: json['Created_at'] ?? '',
      updatedAt: json['Updated_at'] ?? '',
      status: statusValue,
      applicantsCount: applicantsCount,
      isApproved: isApproved,
      isActive: isActive,
      isExpired: isExpired,
      assignedTo: json['assigned_to'] != null
          ? int.tryParse(json['assigned_to'].toString())
          : null,
      assignedToName: null, // Not provided in Laravel API
      isClosed: isClosed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'transporterId': transporterId,
      'transporterName': transporterName,
      'transporterTmid': transporterTmid,
      'transporterPhone': transporterPhone,
      'transporterCity': transporterCity,
      'transporterState': transporterState,
      'transporterProfileCompletion': transporterProfileCompletion,
      'transporterProfilePhoto': transporterProfilePhoto,
      'transporterGender': transporterGender,
      'jobLocation': jobLocation,
      'jobDescription': jobDescription,
      'salaryRange': salaryRange,
      'requiredExperience': requiredExperience,
      'preferredStatus': preferredStatus,
      'typeOfLicense': typeOfLicense,
      'vehicleType': vehicleType,
      'vehicleTypeDetail': vehicleTypeDetail,
      'applicationDeadline': applicationDeadline,
      'jobManagementDate': jobManagementDate,
      'jobManagementId': jobManagementId,
      'jobDescriptionId': jobDescriptionId,
      'numberOfDriverRequired': numberOfDriverRequired,
      'activePosition': activePosition,
      'createdVehicleDetail': createdVehicleDetail,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'status': status,
      'applicantsCount': applicantsCount,
      'isApproved': isApproved,
      'isActive': isActive,
      'isExpired': isExpired,
      'isClosed': isClosed,
    };
  }

  // Check if job is expired based on application deadline
  bool get isExpiredByDeadline {
    if (applicationDeadline.isEmpty) return false;
    
    try {
      DateTime deadline;
      
      // Clean up the deadline string - fix malformed dates like "2025-11-1500:00:00"
      String cleanDeadline = applicationDeadline.trim();
      
      // Fix missing space between date and time (e.g., "2025-11-1500:00:00" -> "2025-11-15 00:00:00")
      if (cleanDeadline.contains('-') && !cleanDeadline.contains(' ') && !cleanDeadline.contains('T')) {
        // Match pattern: YYYY-MM-DDHH:MM:SS
        final regex = RegExp(r'(\d{4}-\d{2}-\d{2})(\d{2}:\d{2}:\d{2})');
        final match = regex.firstMatch(cleanDeadline);
        if (match != null) {
          cleanDeadline = '${match.group(1)} ${match.group(2)}';
        }
      }
      
      // Try different date formats
      if (cleanDeadline.contains('T')) {
        // ISO format: 2024-01-15T23:59:59
        deadline = DateTime.parse(cleanDeadline);
      } else if (cleanDeadline.contains(' ')) {
        // SQL datetime format: 2024-01-15 23:59:59
        deadline = DateTime.parse(cleanDeadline.replaceFirst(' ', 'T'));
      } else if (cleanDeadline.contains('-')) {
        // Date only format: 2024-01-15
        deadline = DateTime.parse('${cleanDeadline}T23:59:59');
      } else {
        // Other formats, try direct parsing
        deadline = DateTime.parse(cleanDeadline);
      }
      
      final now = DateTime.now();
      final isExpired = now.isAfter(deadline);
      
      return isExpired;
    } catch (e) {
      // Silently fail for invalid dates - don't spam console
      return false;
    }
  }
}

class DashboardStats {
  final int totalJobs;
  final int approvedJobs;
  final int pendingJobs;
  final int inactiveJobs;
  final int expiredJobs;
  final int activeTransporters;
  final int driversApplied;
  final int totalMatches;
  final int totalCalls;

  DashboardStats({
    required this.totalJobs,
    required this.approvedJobs,
    required this.pendingJobs,
    required this.inactiveJobs,
    required this.expiredJobs,
    required this.activeTransporters,
    required this.driversApplied,
    required this.totalMatches,
    required this.totalCalls,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalJobs: json['totalJobs'] ?? 0,
      approvedJobs: json['approvedJobs'] ?? 0,
      pendingJobs: json['pendingJobs'] ?? 0,
      inactiveJobs: json['inactiveJobs'] ?? 0,
      expiredJobs: json['expiredJobs'] ?? 0,
      activeTransporters: json['activeTransporters'] ?? 0,
      driversApplied: json['driversApplied'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
      totalCalls: json['totalCalls'] ?? 0,
    );
  }
}

class RecentActivity {
  final String type;
  final String activityType;
  final String name;
  final String tmid;
  final String activity;
  final String time;
  final int timestamp;
  final String city;
  final String? vehicleType;
  final String? status;

  RecentActivity({
    required this.type,
    required this.activityType,
    required this.name,
    required this.tmid,
    required this.activity,
    required this.time,
    required this.timestamp,
    required this.city,
    this.vehicleType,
    this.status,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      activityType: json['activityType'] ?? '',
      name: json['name'] ?? '',
      tmid: json['tmid'] ?? '',
      activity: json['activity'] ?? '',
      time: json['time'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      city: json['city'] ?? '',
      vehicleType: json['vehicleType'],
      status: json['status'],
    );
  }
}
