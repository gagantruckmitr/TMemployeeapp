import '../core/config/api_config.dart';

enum CallStatus {
  connected,
  callBack,
  callBackLater,
  notReachable,
  notInterested,
  invalid,
  pending,
}

enum ConnectedFeedback {
  agreeForSubscription('Agree for Subscription'),
  agreeForSubscriptionToday('Agree for Subscription (Today)'),
  agreeForSubscriptionTomorrow('Agree for Subscription (Tomorrow)'),
  alreadySubscribed('Already Subscribed'),
  appIssue('App Issue'),
  doesntUnderstandApp('Doesn\'t Understand App'),
  driverCabBus('Driver - Cab | Bus'),
  internetIssueLowSpeed('Internet Issue - Low Speed'),
  languageBarrier('Language Barrier'),
  misbehave('Misbehave'),
  needLoad('Need Load'),
  needsHelpInProfile('Needs Help in Profile'),
  needJobUrgently('Needs Job Urgently'),
  neitherTransporterNorDriver('Neither Transporter nor Driver'),
  noMoney('No Money'),
  notInterested('Not Interested'),
  readyForInterview('Ready for Interview'),
  transporterButRegisteredAsDriver('Transporter but Registered as Driver'),
  wantsDemoVideo('Wants Demo Video'),
  wantsToThink('Wants to Think Before Subscribing'),
  willSubscribeLater('Will Subscribe Later (No specific time)'),
  willSubscribeWhenNeedJob('Will Subscribe When Job Needed'),
  wrongNumber('Wrong Number'),
  thirdPersonReceivedAskedToCallLater(
    'Third Person Received – Asked to Call Later',
  ),
  others('Others');

  const ConnectedFeedback(this.displayName);
  final String displayName;
}

// Transporter-specific feedback options for Welcome Call
enum TransporterConnectedFeedback {
  agreeForSubscription('Agree for Subscription'),
  agreeForSubscriptionToday('Agree for Subscription (Today)'),
  agreeForSubscriptionTomorrow('Agree for Subscription (Tomorrow)'),
  alreadySubscribed('Already Subscribed'),
  appIssue('App Issue'),
  doesntUnderstandApp('Doesn\'t Understand App'),
  driverCabBus('Driver - Cab | Bus'),
  driverButRegisteredAsTransporter('Driver but Registered as Transporter'),
  internetIssueLowSpeed('Internet Issue - Low Speed'),
  languageBarrier('Language Barrier'),
  misbehave('Misbehave'),
  needLoad('Need Load'),
  needsDriverUrgently('Needs Driver Urgently'),
  needsHelpInProfile('Needs Help in Profile'),
  neitherTransporterNorDriver('Neither Transporter nor Driver'),
  notInterested('Not Interested'),
  wantsDemoVideo('Wants Demo Video'),
  wantsToThink('Wants to Think Before Subscribing'),
  willSubscribeLater('Will Subscribe Later (No specific time)'),
  willSubscribeWhenDriversNeeded('Will Subscribe When Drivers Needed'),
  wrongNumber('Wrong Number'),
  thirdPersonReceivedAskedToCallLater(
    'Third Person Received – Asked to Call Later',
  ),
  others('Others');

  const TransporterConnectedFeedback(this.displayName);
  final String displayName;
}

enum CallBackReason {
  ringingNoAnswer('Ringing – No Answer'),
  switchedOff('Switched Off'),
  notReachable('Not Reachable'),
  callDisconnected('Call Disconnected'),
  numberBusy('Number Busy');

  const CallBackReason(this.displayName);
  final String displayName;
}

enum CallBackTime {
  busyRightNow('Busy Right Now'),
  callTomorrowMorning('Call Tomorrow Morning'),
  callInEvening('Call in Evening'),
  callAfter2Days('Call After 2 Days');

  const CallBackTime(this.displayName);
  final String displayName;
}

enum SubscriptionStatus { active, inactive, pending, expired }

enum PaymentStatus { success, pending, failed, none }

class PaymentInfo {
  final String? subscriptionType;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final String? amount;
  final DateTime? expiryDate;
  final DateTime? updatedAt; // Subscription updated_at from payments array
  final DateTime? startAt;
  final DateTime? endAt;
  final String? paymentId;
  final DateTime?
  subscriptionCreatedAt; // The created_at timestamp of the subscription

  PaymentInfo({
    this.subscriptionType,
    required this.paymentStatus,
    this.paymentDate,
    this.amount,
    this.expiryDate,
    this.updatedAt,
    this.startAt,
    this.endAt,
    this.paymentId,
    this.subscriptionCreatedAt,
  });

  factory PaymentInfo.none() {
    return PaymentInfo(
      subscriptionType: null,
      paymentStatus: PaymentStatus.none,
      paymentDate: null,
      amount: null,
      expiryDate: null,
      updatedAt: null,
      startAt: null,
      endAt: null,
      paymentId: null,
      subscriptionCreatedAt: null,
    );
  }

  /// Helper to parse Unix timestamp (seconds since epoch) to DateTime
  static DateTime? _parseUnixTimestamp(dynamic value) {
    if (value == null) return null;
    final timestamp = int.tryParse(value.toString());
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    return null;
  }

  /// Helper to parse date string to DateTime (handles both ISO and space-separated formats)
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final dateStr = value.toString();
    // Try parsing as ISO date first
    DateTime? result = DateTime.tryParse(dateStr);
    if (result != null) return result;

    // Try parsing space-separated format like "2025-10-07 04:27:49"
    // DateTime.tryParse already handles this format, but let's be explicit
    try {
      // Replace space with 'T' to make it ISO compliant
      result = DateTime.tryParse(dateStr.replaceFirst(' ', 'T'));
      if (result != null) return result;
    } catch (_) {}

    return null;
  }

  /// Factory to create PaymentInfo from payments array (first/latest payment)
  factory PaymentInfo.fromPaymentsJson(List<dynamic> payments) {
    if (payments.isEmpty) {
      return PaymentInfo.none();
    }

    // Try to find a payment with payment_status = "captured" first (for root payments array)
    Map<String, dynamic>? capturedPayment;
    for (final p in payments) {
      final payment = p as Map<String, dynamic>;
      if (payment['payment_status']?.toString().toLowerCase() == 'captured') {
        capturedPayment = payment;
        break;
      }
    }

    // If no captured payment found, use the first payment (for full_details.payments which doesn't have payment_status)
    capturedPayment ??= payments[0] as Map<String, dynamic>;

    // Parse start_at and end_at - could be Unix timestamps OR date strings
    DateTime? startAt = _parseUnixTimestamp(capturedPayment['start_at']);
    DateTime? endAt = _parseUnixTimestamp(capturedPayment['end_at']);

    // If not Unix timestamps, try parsing as date strings (for full_details.payments format)
    startAt ??= _parseDate(capturedPayment['start_at']);
    endAt ??= _parseDate(capturedPayment['end_at']);

    // Parse created_at and updated_at as date strings
    final createdAt = _parseDate(capturedPayment['created_at']);
    final updatedAt = _parseDate(capturedPayment['updated_at']);

    return PaymentInfo(
      subscriptionType: 'Premium',
      paymentStatus: PaymentStatus.success,
      paymentDate: startAt,
      amount: capturedPayment['amount']?.toString(),
      expiryDate: endAt,
      updatedAt: updatedAt,
      startAt: startAt,
      endAt: endAt,
      paymentId: capturedPayment['payment_id']?.toString(),
      subscriptionCreatedAt: createdAt,
    );
  }
}

class ProfileCompletion {
  final int percentage;
  final Map<String, bool> documentStatus;
  final Map<String, String?> documentValues;

  ProfileCompletion({
    required this.percentage,
    required this.documentStatus,
    this.documentValues = const {},
  });

  factory ProfileCompletion.fromPercentageString(String percentageStr) {
    final percentage = int.tryParse(percentageStr.replaceAll('%', '')) ?? 0;
    return ProfileCompletion(
      percentage: percentage,
      documentStatus: {},
      documentValues: {},
    );
  }
}

class AppliedJob {
  final String jobId;
  final String jobCode;
  final String jobTitle;
  final String? location;
  final String? salary;
  final String? companyName;
  final DateTime? appliedDate;

  AppliedJob({
    required this.jobId,
    required this.jobCode,
    required this.jobTitle,
    this.location,
    this.salary,
    this.companyName,
    this.appliedDate,
  });

  factory AppliedJob.fromJson(Map<String, dynamic> json) {
    // Check if job_details is nested (from backlog API)
    final jobDetails = json['job_details'] as Map<String, dynamic>?;

    // Get values from job_details if available, otherwise from root
    final String jobId =
        jobDetails?['job_id']?.toString() ?? json['job_id']?.toString() ?? '';
    final String jobCode =
        jobDetails?['job_id']?.toString() ?? json['job_code']?.toString() ?? '';
    final String jobTitle =
        jobDetails?['job_title']?.toString() ??
        json['job_title']?.toString() ??
        '';
    final String? location =
        jobDetails?['job_location']?.toString() ??
        jobDetails?['location']?.toString() ??
        json['location']?.toString();
    final String? salary =
        jobDetails?['Salary_Range']?.toString() ??
        jobDetails?['salary']?.toString() ??
        json['salary']?.toString();
    final String? companyName =
        json['company_name']?.toString() ?? json['transport_name']?.toString();

    // Parse applied date from created_at or applied_date
    DateTime? appliedDate;
    if (json['created_at'] != null) {
      appliedDate = DateTime.tryParse(json['created_at'].toString());
    } else if (json['applied_date'] != null) {
      appliedDate = DateTime.tryParse(json['applied_date'].toString());
    }

    return AppliedJob(
      jobId: jobId,
      jobCode: jobCode,
      jobTitle: jobTitle,
      location: location,
      salary: salary,
      companyName: companyName,
      appliedDate: appliedDate,
    );
  }
}

class CallHistoryEntry {
  final String id;
  final String callerId;
  final String? telecallerName;
  final String callStatus;
  final String? feedback;
  final String? remarks;
  final int? callDuration;
  final String? recordingUrl;
  final DateTime? callTime;
  final String callType; // 'welcome_call' or 'match_making'
  final String? matchStatus; // For match-making calls
  final String? jobId; // For match-making calls
  final String? otherPartyName; // Driver/Transporter name in match-making
  final String? otherPartyTmid; // Driver/Transporter TMID in match-making

  CallHistoryEntry({
    required this.id,
    required this.callerId,
    this.telecallerName,
    required this.callStatus,
    this.feedback,
    this.remarks,
    this.callDuration,
    this.recordingUrl,
    this.callTime,
    this.callType = 'welcome_call',
    this.matchStatus,
    this.jobId,
    this.otherPartyName,
    this.otherPartyTmid,
  });

  // Mapping of known telecaller IDs to names
  // TODO: This should be fetched from API or database
  static const Map<int, String> _telecallerNames = {
    1: 'Admin',
    2: 'Telecaller 2',
    3: 'Lalit Lamba',
    4: 'Anil Kumar',
    5: 'Shiv Kumar',
    6: 'Vikas Singh',
    7: 'Rohit Sharma',
    8: 'Telecaller 8',
    9: 'Telecaller 9',
    10: 'Telecaller 10',
    11: 'Telecaller 11',
    12: 'Telecaller 12',
    13: 'Telecaller 13',
    14: 'Telecaller 14',
    15: 'Telecaller 15',
    16: 'Telecaller 16',
    17: 'Telecaller 17',
    18: 'Telecaller 18',
    19: 'Telecaller 19',
    20: 'Telecaller 20',
  };

  static String? _getTelecallerName(dynamic assignedTo) {
    if (assignedTo == null) return null;
    final id = int.tryParse(assignedTo.toString());
    if (id != null && _telecallerNames.containsKey(id)) {
      return _telecallerNames[id];
    }
    // Return "Telecaller #ID" if ID is valid but name unknown
    return id != null ? 'Telecaller #$id' : null;
  }

  factory CallHistoryEntry.fromJson(Map<String, dynamic> json) {
    // Debug: Print call_log structure to understand API response
    print('📞 CallHistoryEntry.fromJson - Keys: ${json.keys.toList()}');
    print('📞 CallHistoryEntry.fromJson - Data: $json');

    // Get telecaller name - try multiple fields
    String? telecallerName = json['telecaller_name']?.toString();

    // Try assigned_admin_name field (from telehead API call_logs)
    if (telecallerName == null || telecallerName.isEmpty) {
      telecallerName = json['assigned_admin_name']?.toString();
    }

    // Try caller_name field
    if (telecallerName == null || telecallerName.isEmpty) {
      telecallerName = json['caller_name']?.toString();
    }

    // Try admin_name field
    if (telecallerName == null || telecallerName.isEmpty) {
      telecallerName = json['admin_name']?.toString();
    }

    // Try assigned_name field
    if (telecallerName == null || telecallerName.isEmpty) {
      telecallerName = json['assigned_name']?.toString();
    }

    // Try nested admin.name object
    if (telecallerName == null || telecallerName.isEmpty) {
      if (json['admin'] is Map) {
        telecallerName = json['admin']['name']?.toString();
      }
    }

    // Try nested caller.name object
    if (telecallerName == null || telecallerName.isEmpty) {
      if (json['caller'] is Map) {
        telecallerName = json['caller']['name']?.toString();
      }
    }

    // Try nested assigned.name object
    if (telecallerName == null || telecallerName.isEmpty) {
      if (json['assigned'] is Map) {
        telecallerName = json['assigned']['name']?.toString();
      }
    }

    // Try assigned_to mapping
    if (telecallerName == null || telecallerName.isEmpty) {
      telecallerName = _getTelecallerName(json['assigned_to']);
    }

    // Try caller_id mapping
    if (telecallerName == null || telecallerName.isEmpty) {
      telecallerName = _getTelecallerName(json['caller_id']);
    }

    print(
      '📞 CallHistoryEntry.fromJson - Final telecallerName: $telecallerName',
    );

    // Get feedback - try multiple field names
    String? feedback = json['feedback']?.toString();
    if (feedback == null || feedback.isEmpty) {
      feedback = json['call_feedback']?.toString();
    }

    // Get remarks - try multiple field names
    String? remarks = json['remarks']?.toString();
    if (remarks == null || remarks.isEmpty) {
      remarks = json['call_remarks']?.toString();
    }

    // Get recording URL - try multiple field names
    String? recordingUrl = json['recording_url']?.toString();
    if (recordingUrl == null || recordingUrl.isEmpty) {
      recordingUrl = json['manual_call_recording_url']?.toString();
    }
    if (recordingUrl == null || recordingUrl.isEmpty) {
      recordingUrl = json['call_recording']?.toString();
    }

    // Get call time - try multiple field names
    DateTime? callTime;
    if (json['call_time'] != null) {
      callTime = DateTime.tryParse(json['call_time'].toString());
    } else if (json['created_at'] != null) {
      callTime = DateTime.tryParse(json['created_at'].toString());
    }

    // Determine call type from source or process field
    String callType = json['call_type']?.toString() ?? 'welcome_call';
    if (json['source'] == 'call_logs_match_making') {
      callType = 'match_making';
    } else if (json['process']?.toString().contains('Onboarding') == true) {
      callType = 'welcome_call';
    }

    return CallHistoryEntry(
      id: json['id']?.toString() ?? '',
      callerId:
          json['caller_id']?.toString() ??
          json['assigned_to']?.toString() ??
          '',
      telecallerName: telecallerName,
      callStatus: json['call_status']?.toString() ?? 'pending',
      feedback: feedback,
      remarks: remarks,
      callDuration: json['call_duration'] != null
          ? int.tryParse(json['call_duration'].toString())
          : null,
      recordingUrl: recordingUrl,
      callTime: callTime,
      callType: callType,
      matchStatus: json['match_status']?.toString(),
      jobId: json['job_id']?.toString(),
      otherPartyName:
          json['other_party_name']?.toString() ??
          json['driver_name']?.toString(),
      otherPartyTmid:
          json['other_party_tmid']?.toString() ??
          json['unique_id_driver']?.toString(),
    );
  }
}

class TrainingInfo {
  final bool isCompleted;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final int rating;
  final double rankingPercentage;
  final String tier;

  TrainingInfo({
    required this.isCompleted,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.rating,
    required this.rankingPercentage,
    required this.tier,
  });

  factory TrainingInfo.fromJson(Map<String, dynamic> json) {
    return TrainingInfo(
      isCompleted:
          json['is_completed'] == true ||
          json['is_completed'] == 1 ||
          json['is_completed'].toString().toLowerCase() == 'true',
      totalQuestions:
          int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      correctAnswers:
          int.tryParse(json['correct_answers']?.toString() ?? '0') ?? 0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
      rating: int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      rankingPercentage:
          double.tryParse(json['ranking_percentage']?.toString() ?? '0') ?? 0.0,
      tier: json['tier']?.toString() ?? 'N/A',
    );
  }
}

class DriverContact {
  final String id;
  final String tmid;
  final String name;
  final String company;
  final String phoneNumber;
  final String state;
  final SubscriptionStatus subscriptionStatus;
  final CallStatus status;
  final String? lastFeedback;
  final DateTime? lastCallTime;
  final String? remarks;
  final PaymentInfo? paymentInfo;
  final DateTime? registrationDate;
  final ProfileCompletion? profileCompletion;
  final String? profilePicture;
  final String? licenseType;
  final List<AppliedJob>? appliedJobs;
  final String? assignedTelecaller;
  final String? role;
  final List<CallHistoryEntry>? callHistory;
  final TrainingInfo? trainingInfo;
  final List<PostedJob>? postedJobs;
  final List<MatchMakingEntry>? matchMakingHistory;
  final String? fleetSize;

  DriverContact({
    required this.id,
    required this.tmid,
    required this.name,
    required this.company,
    required this.phoneNumber,
    required this.state,
    required this.subscriptionStatus,
    required this.status,
    this.lastFeedback,
    this.lastCallTime,
    this.remarks,
    this.paymentInfo,
    this.registrationDate,
    this.profileCompletion,
    this.profilePicture,
    this.licenseType,
    this.appliedJobs,
    this.assignedTelecaller,
    this.role,
    this.callHistory,
    this.trainingInfo,
    this.postedJobs,
    this.matchMakingHistory,
    this.fleetSize,
  });

  DriverContact copyWith({
    String? id,
    String? tmid,
    String? name,
    String? company,
    String? phoneNumber,
    String? state,
    SubscriptionStatus? subscriptionStatus,
    CallStatus? status,
    String? lastFeedback,
    DateTime? lastCallTime,
    String? remarks,
    PaymentInfo? paymentInfo,
    DateTime? registrationDate,
    ProfileCompletion? profileCompletion,
    String? profilePicture,
    String? licenseType,
    List<AppliedJob>? appliedJobs,
    String? assignedTelecaller,
    String? role,
    List<CallHistoryEntry>? callHistory,
    TrainingInfo? trainingInfo,
    List<PostedJob>? postedJobs,
    List<MatchMakingEntry>? matchMakingHistory,
    String? fleetSize,
  }) {
    return DriverContact(
      id: id ?? this.id,
      tmid: tmid ?? this.tmid,
      name: name ?? this.name,
      company: company ?? this.company,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      state: state ?? this.state,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      status: status ?? this.status,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      lastCallTime: lastCallTime ?? this.lastCallTime,
      remarks: remarks ?? this.remarks,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      registrationDate: registrationDate ?? this.registrationDate,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      profilePicture: profilePicture ?? this.profilePicture,
      licenseType: licenseType ?? this.licenseType,
      appliedJobs: appliedJobs ?? this.appliedJobs,
      assignedTelecaller: assignedTelecaller ?? this.assignedTelecaller,
      role: role ?? this.role,
      callHistory: callHistory ?? this.callHistory,
      trainingInfo: trainingInfo ?? this.trainingInfo,
      postedJobs: postedJobs ?? this.postedJobs,
      matchMakingHistory: matchMakingHistory ?? this.matchMakingHistory,
      fleetSize: fleetSize ?? this.fleetSize,
    );
  }

  /// Build full profile image URL from relative path
  static String? _buildProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // Build full URL with base path
    final baseUrl = ApiConfig.publicUrl;
    return '$baseUrl/$imagePath';
  }

  // Factory method to create DriverContact from backlog API JSON (telehead API)
  factory DriverContact.fromBacklogJson(Map<String, dynamic> json) {
    // Get full_details for nested data
    final fullDetails = json['full_details'] as Map<String, dynamic>?;

    // Parse profile completion - check multiple possible field names
    ProfileCompletion? profileCompletion;
    int completionPercentage = 0;

    // First check full_details.profile_completion (most accurate from Laravel API)
    if (fullDetails != null && fullDetails['profile_completion'] != null) {
      final fullDetailsCompletion = fullDetails['profile_completion'];
      completionPercentage = fullDetailsCompletion is int
          ? fullDetailsCompletion
          : int.tryParse(fullDetailsCompletion.toString()) ?? 0;
    }
    // Then try root level fields
    else if (json['profileCompletion'] != null) {
      completionPercentage =
          int.tryParse(json['profileCompletion'].toString()) ?? 0;
    } else if (json['profile_completion'] != null) {
      completionPercentage =
          int.tryParse(json['profile_completion'].toString()) ?? 0;
    } else if (json['driver_completion'] != null) {
      completionPercentage =
          int.tryParse(json['driver_completion'].toString()) ?? 0;
    } else if (json['driverCompletion'] != null) {
      completionPercentage =
          int.tryParse(json['driverCompletion'].toString()) ?? 0;
    }

    // Always create ProfileCompletion so avatar shows percentage badge
    profileCompletion = ProfileCompletion(
      percentage: completionPercentage,
      documentStatus: {},
      documentValues: {},
    );

    // Parse payment info (subscription) from payments array
    // Check full_details.payments first, then root level payments
    PaymentInfo? paymentInfo;
    List<dynamic>? paymentsArray;
    if (fullDetails != null &&
        fullDetails['payments'] is List &&
        (fullDetails['payments'] as List).isNotEmpty) {
      paymentsArray = fullDetails['payments'] as List;
    } else if (json['payments'] is List &&
        (json['payments'] as List).isNotEmpty) {
      paymentsArray = json['payments'] as List;
    }

    if (paymentsArray != null && paymentsArray.isNotEmpty) {
      paymentInfo = PaymentInfo.fromPaymentsJson(paymentsArray);
    } else if (json['sub_id'] != null &&
        json['sub_id'].toString().isNotEmpty &&
        json['sub_id'] != 'null') {
      paymentInfo = PaymentInfo(
        subscriptionType: 'Premium',
        paymentStatus: PaymentStatus.success,
        paymentDate: null,
        amount: null,
        expiryDate: null,
      );
    }

    // Parse registration date
    DateTime? registrationDate;
    if (json['Created_at'] != null) {
      registrationDate = DateTime.tryParse(json['Created_at'].toString());
    }

    // Parse call history - check full_details.call_logs first, then root level
    List<CallHistoryEntry>? callHistory;
    List<dynamic>? callLogsArray;
    if (fullDetails != null && fullDetails['call_logs'] is List) {
      callLogsArray = fullDetails['call_logs'] as List;
    } else if (json['call_history'] is List) {
      callLogsArray = json['call_history'] as List;
    } else if (json['call_logs'] is List) {
      callLogsArray = json['call_logs'] as List;
    }

    if (callLogsArray != null && callLogsArray.isNotEmpty) {
      callHistory = callLogsArray
          .map((e) => CallHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse applied jobs (for drivers) - check both camelCase and snake_case
    List<AppliedJob>? appliedJobs;
    List<dynamic>? appliedJobsArray;
    if (json['appliedJobs'] is List) {
      appliedJobsArray = json['appliedJobs'] as List;
    } else if (json['applied_jobs'] is List) {
      appliedJobsArray = json['applied_jobs'] as List;
    } else if (fullDetails != null && fullDetails['appliedJobs'] is List) {
      appliedJobsArray = fullDetails['appliedJobs'] as List;
    } else if (fullDetails != null && fullDetails['applied_jobs'] is List) {
      appliedJobsArray = fullDetails['applied_jobs'] as List;
    }

    if (appliedJobsArray != null && appliedJobsArray.isNotEmpty) {
      appliedJobs = appliedJobsArray
          .map((e) => AppliedJob.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse posted jobs (for transporters) - check both camelCase and snake_case
    List<PostedJob>? postedJobs;
    List<dynamic>? postedJobsArray;
    if (json['postedJobs'] is List) {
      postedJobsArray = json['postedJobs'] as List;
    } else if (json['posted_jobs'] is List) {
      postedJobsArray = json['posted_jobs'] as List;
    } else if (fullDetails != null && fullDetails['postedJobs'] is List) {
      postedJobsArray = fullDetails['postedJobs'] as List;
    } else if (fullDetails != null && fullDetails['posted_jobs'] is List) {
      postedJobsArray = fullDetails['posted_jobs'] as List;
    }

    if (postedJobsArray != null && postedJobsArray.isNotEmpty) {
      postedJobs = postedJobsArray
          .map((e) => PostedJob.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse match making history (for transporters)
    List<MatchMakingEntry>? matchMakingHistory;
    List<dynamic>? matchMakingArray;
    if (json['match_making_history'] is List) {
      matchMakingArray = json['match_making_history'] as List;
    } else if (fullDetails != null &&
        fullDetails['match_making_history'] is List) {
      matchMakingArray = fullDetails['match_making_history'] as List;
    }

    if (matchMakingArray != null && matchMakingArray.isNotEmpty) {
      matchMakingHistory = matchMakingArray
          .map((e) => MatchMakingEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse training info (for drivers) - check full_details first
    TrainingInfo? trainingInfo;
    Map<String, dynamic>? trainingInfoMap;
    if (fullDetails != null && fullDetails['training_info'] is Map) {
      trainingInfoMap = fullDetails['training_info'] as Map<String, dynamic>;
    } else if (json['training_info'] is Map) {
      trainingInfoMap = json['training_info'] as Map<String, dynamic>;
    }

    if (trainingInfoMap != null) {
      trainingInfo = TrainingInfo.fromJson(trainingInfoMap);
    }

    return DriverContact(
      id: json['id']?.toString() ?? '',
      tmid: json['unique_id']?.toString() ?? '',
      name: json['name_eng']?.toString() ?? json['name']?.toString() ?? '',
      company:
          json['Transport_Name']?.toString() ??
          json['name_eng']?.toString() ??
          '',
      phoneNumber: json['mobile']?.toString() ?? '',
      state: json['states']?.toString() ?? '',
      subscriptionStatus: paymentInfo != null
          ? SubscriptionStatus.active
          : SubscriptionStatus.inactive,
      status: CallStatus.callBackLater,
      lastFeedback: json['last_feedback']?.toString(),
      lastCallTime: json['last_call_time'] != null
          ? DateTime.tryParse(json['last_call_time'].toString())
          : null,
      remarks: json['remarks']?.toString(),
      paymentInfo: paymentInfo,
      registrationDate: registrationDate,
      profileCompletion: profileCompletion,
      profilePicture: _buildProfileImageUrl(
        json['images']?.toString() ?? json['avatar']?.toString(),
      ),
      licenseType: json['Type_of_License']?.toString(),
      appliedJobs: appliedJobs ?? [],
      assignedTelecaller: json['admins']?.toString(),
      role: json['role']?.toString(),
      callHistory: callHistory ?? [],
      trainingInfo: trainingInfo,
      postedJobs: postedJobs ?? [],
      matchMakingHistory: matchMakingHistory ?? [],
      fleetSize: json['Fleet_Size']?.toString(),
    );
  }

  // Callback history and count properties
  List<dynamic>? get callbackHistory => null;
  int? get callbackRequestsCount => null;
}

class PostedJob {
  final String id;
  final String jobCode;
  final String jobTitle;
  final String location;
  final String salary;
  final DateTime? postedDate;
  final String status;
  final int applicantCount;

  PostedJob({
    required this.id,
    required this.jobCode,
    required this.jobTitle,
    required this.location,
    required this.salary,
    this.postedDate,
    required this.status,
    required this.applicantCount,
  });

  factory PostedJob.fromJson(Map<String, dynamic> json) {
    // Handle both snake_case and other field name variations
    String jobCode = json['job_code']?.toString() ?? '';
    if (jobCode.isEmpty) {
      jobCode = json['job_id']?.toString() ?? '';
    }

    String location = json['location']?.toString() ?? '';
    if (location.isEmpty) {
      location = json['job_location']?.toString() ?? '';
    }

    String salary = json['salary']?.toString() ?? '';
    if (salary.isEmpty) {
      salary = json['Salary_Range']?.toString() ?? '';
    }

    DateTime? postedDate;
    if (json['posted_date'] != null) {
      postedDate = DateTime.tryParse(json['posted_date'].toString());
    } else if (json['Created_at'] != null) {
      postedDate = DateTime.tryParse(json['Created_at'].toString());
    }

    int applicantCount =
        int.tryParse(json['applicant_count']?.toString() ?? '0') ?? 0;
    // If no applicant count, fallback to number_of_drivers_required
    if (applicantCount == 0) {
      applicantCount =
          int.tryParse(json['number_of_drivers_required']?.toString() ?? '0') ??
          0;
    }

    return PostedJob(
      id: json['id']?.toString() ?? '',
      jobCode: jobCode,
      jobTitle: json['job_title']?.toString() ?? '',
      location: location,
      salary: salary,
      postedDate: postedDate,
      status: json['status']?.toString() ?? '0',
      applicantCount: applicantCount,
    );
  }
}

class MatchMakingEntry {
  final String id;
  final DateTime? matchDate;
  final String driverName;
  final String driverTmid;
  final String jobId;
  final String matchStatus;
  final String feedback;

  MatchMakingEntry({
    required this.id,
    this.matchDate,
    required this.driverName,
    required this.driverTmid,
    required this.jobId,
    required this.matchStatus,
    required this.feedback,
  });

  factory MatchMakingEntry.fromJson(Map<String, dynamic> json) {
    return MatchMakingEntry(
      id: json['id']?.toString() ?? '',
      matchDate: json['match_date'] != null
          ? DateTime.tryParse(json['match_date'].toString())
          : null,
      driverName: json['driver_name']?.toString() ?? '',
      driverTmid: json['driver_tmid']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      matchStatus: json['match_status']?.toString() ?? '',
      feedback: json['feedback']?.toString() ?? '',
    );
  }
}

class CallFeedback {
  final CallStatus status;
  final ConnectedFeedback? connectedFeedback;
  final TransporterConnectedFeedback? transporterConnectedFeedback;
  final CallBackReason? callBackReason;
  final CallBackTime? callBackTime;
  final String? remarks;
  final dynamic recordingFile; // File object for recording upload
  final bool? closeJob; // Whether to close the job after feedback

  CallFeedback({
    required this.status,
    this.connectedFeedback,
    this.transporterConnectedFeedback,
    this.callBackReason,
    this.callBackTime,
    this.remarks,
    this.recordingFile,
    this.closeJob,
  });
}

// Transporter Contact Model (similar to DriverContact)
class TransporterContact {
  final String id;
  final String tmid;
  final String name;
  final String company;
  final String phoneNumber;
  final String state;
  final SubscriptionStatus subscriptionStatus;
  final CallStatus status;
  final String? lastFeedback;
  final DateTime? lastCallTime;
  final String? remarks;
  final PaymentInfo? paymentInfo;
  final DateTime? registrationDate;
  final ProfileCompletion? profileCompletion;
  final String? profilePicture;

  TransporterContact({
    required this.id,
    required this.tmid,
    required this.name,
    required this.company,
    required this.phoneNumber,
    required this.state,
    required this.subscriptionStatus,
    required this.status,
    this.lastFeedback,
    this.lastCallTime,
    this.remarks,
    this.paymentInfo,
    this.registrationDate,
    this.profileCompletion,
    this.profilePicture,
  });

  TransporterContact copyWith({
    String? id,
    String? tmid,
    String? name,
    String? company,
    String? phoneNumber,
    String? state,
    SubscriptionStatus? subscriptionStatus,
    CallStatus? status,
    String? lastFeedback,
    DateTime? lastCallTime,
    String? remarks,
    PaymentInfo? paymentInfo,
    DateTime? registrationDate,
    ProfileCompletion? profileCompletion,
    String? profilePicture,
  }) {
    return TransporterContact(
      id: id ?? this.id,
      tmid: tmid ?? this.tmid,
      name: name ?? this.name,
      company: company ?? this.company,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      state: state ?? this.state,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      status: status ?? this.status,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      lastCallTime: lastCallTime ?? this.lastCallTime,
      remarks: remarks ?? this.remarks,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      registrationDate: registrationDate ?? this.registrationDate,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}

// Contact categorization helper
class ContactCategorizer {
  static NavigationSection getCategoryForContact(DriverContact contact) {
    switch (contact.status) {
      case CallStatus.pending:
        return NavigationSection.home;
      case CallStatus.connected:
        if (isInterestedFeedback(contact.lastFeedback)) {
          return NavigationSection.interested;
        }
        return NavigationSection.connectedCalls;
      case CallStatus.callBack:
        return NavigationSection.callBacks;
      case CallStatus.callBackLater:
        return NavigationSection.callBackLater;
      case CallStatus.notReachable:
      case CallStatus.notInterested:
      case CallStatus.invalid:
        return NavigationSection.home; // These go back to home for retry
    }
  }

  static bool isInterestedFeedback(String? feedback) {
    if (feedback == null) return false;
    return feedback.contains('Agree') ||
        feedback.contains('Demo') ||
        feedback.contains('Subscribe');
  }
}

enum NavigationSection {
  home,
  interested, // Now "Driver Bucket"
  connectedCalls, // Removed from menu
  callBacks, // Removed from menu
  callBackLater, // Removed from menu
  pendingCalls,
  callHistory, // Removed from menu
  profile,
  // New sections for Apple-style menu
  welcomeCall,
  tollFree,
  jobMatching,
  callbackRequest,
  socialMediaLeads,
  settings,
}

// No dummy data - using real database data only
