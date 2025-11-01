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
  agreeForSubscriptionToday('Agree for Subscription (Today)'),
  agreeForSubscriptionTomorrow('Agree for Subscription (Tomorrow)'),
  alreadySubscribed('Already Subscribed'),
  appIssue('App Issue'),
  doesntUnderstandApp('Doesn\'t Understand App'),
  languageBarrier('Language Barrier'),
  needJobUrgently('Need Job Urgently'),
  needLoad('Need Load'),
  noMoney('No Money'),
  notATruckDriver('Not a Truck Driver'),
  needsHelpInProfile('Needs Help in Profile'),
  notInterested('Not Interested'),
  others('Others'),
  willSubscribeLater('Will Subscribe Later (Not sure when)'),
  willSubscribeWhenNeedJob('Will Subscribe when I need Job'),
  wantsDemoVideo('Wants Demo Video'),
  wantsToThink('Wants to Think');

  const ConnectedFeedback(this.displayName);
  final String displayName;
}

enum CallBackReason {
  ringingCallBusy('Ringing / Call Busy'),
  switchedOffNotReachable('Switched Off / Not Reachable / Disconnected'),
  didntPick('Didn\'t Pick');

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

enum SubscriptionStatus {
  active,
  inactive,
  pending,
  expired,
}

enum PaymentStatus {
  success,
  pending,
  failed,
  none,
}

class PaymentInfo {
  final String? subscriptionType;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final String? amount;
  final DateTime? expiryDate;

  PaymentInfo({
    this.subscriptionType,
    required this.paymentStatus,
    this.paymentDate,
    this.amount,
    this.expiryDate,
  });

  factory PaymentInfo.none() {
    return PaymentInfo(
      subscriptionType: null,
      paymentStatus: PaymentStatus.none,
      paymentDate: null,
      amount: null,
      expiryDate: null,
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
    );
  }
}

class CallFeedback {
  final CallStatus status;
  final ConnectedFeedback? connectedFeedback;
  final CallBackReason? callBackReason;
  final CallBackTime? callBackTime;
  final String? remarks;
  final dynamic recordingFile; // File object for recording upload

  CallFeedback({
    required this.status,
    this.connectedFeedback,
    this.callBackReason,
    this.callBackTime,
    this.remarks,
    this.recordingFile,
  });
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
  interested,
  connectedCalls,
  callBacks,
  callBackLater,
  pendingCalls,
  callHistory,
  profile,
}

// No dummy data - using real database data only