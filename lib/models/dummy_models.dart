class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatar,
  });
}

class CallRecord {
  final String id;
  final String contactName;
  final String phoneNumber;
  final DateTime callTime;
  final Duration duration;
  final CallStatus status;
  final String notes;

  CallRecord({
    required this.id,
    required this.contactName,
    required this.phoneNumber,
    required this.callTime,
    required this.duration,
    required this.status,
    required this.notes,
  });
}

enum CallStatus {
  connected,
  missed,
  busy,
  noAnswer,
  followUp,
}

class Lead {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phoneNumber;
  final String email;
  final LeadStatus status;
  final DateTime createdAt;
  final DateTime? followUpDate;
  final String notes;

  Lead({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phoneNumber,
    required this.email,
    required this.status,
    required this.createdAt,
    this.followUpDate,
    required this.notes,
  });
}

enum LeadStatus {
  new_,
  contacted,
  interested,
  quoted,
  converted,
  lost,
}

class PerformanceMetrics {
  final int totalCalls;
  final int connectedCalls;
  final int missedCalls;
  final int followUps;
  final double conversionRate;
  final Duration averageCallDuration;
  final DateTime date;

  PerformanceMetrics({
    required this.totalCalls,
    required this.connectedCalls,
    required this.missedCalls,
    required this.followUps,
    required this.conversionRate,
    required this.averageCallDuration,
    required this.date,
  });
}

// Dummy Data
class DummyData {
  static final User currentUser = User(
    id: '1',
    name: 'Rajesh Kumar',
    email: 'rajesh.kumar@truckmitr.com',
    role: 'Telecaller',
    avatar: 'assets/images/profile_placeholder.png',
  );

  static final List<CallRecord> recentCalls = [
    CallRecord(
      id: '1',
      contactName: 'Amit Transport',
      phoneNumber: '+91 98765 43210',
      callTime: DateTime.now().subtract(const Duration(hours: 1)),
      duration: const Duration(minutes: 5, seconds: 30),
      status: CallStatus.connected,
      notes: 'Interested in Delhi-Mumbai route',
    ),
    CallRecord(
      id: '2',
      contactName: 'Sharma Logistics',
      phoneNumber: '+91 87654 32109',
      callTime: DateTime.now().subtract(const Duration(hours: 2)),
      duration: const Duration(minutes: 3, seconds: 15),
      status: CallStatus.followUp,
      notes: 'Requested quote for bulk shipment',
    ),
    CallRecord(
      id: '3',
      contactName: 'Delhi Freight',
      phoneNumber: '+91 76543 21098',
      callTime: DateTime.now().subtract(const Duration(hours: 3)),
      duration: const Duration(seconds: 45),
      status: CallStatus.noAnswer,
      notes: 'No response, will try again',
    ),
  ];

  static final List<Lead> upcomingFollowUps = [
    Lead(
      id: '1',
      companyName: 'Amit Transport',
      contactPerson: 'Amit Singh',
      phoneNumber: '+91 98765 43210',
      email: 'amit@amittransport.com',
      status: LeadStatus.interested,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      followUpDate: DateTime.now().add(const Duration(hours: 2)),
      notes: 'Call back at 2:00 PM for route discussion',
    ),
    Lead(
      id: '2',
      companyName: 'Sharma Logistics',
      contactPerson: 'Rajesh Sharma',
      phoneNumber: '+91 87654 32109',
      email: 'rajesh@sharmalogistics.com',
      status: LeadStatus.quoted,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      followUpDate: DateTime.now().add(const Duration(hours: 4)),
      notes: 'Quote discussion and negotiation',
    ),
    Lead(
      id: '3',
      companyName: 'Delhi Freight',
      contactPerson: 'Suresh Kumar',
      phoneNumber: '+91 76543 21098',
      email: 'suresh@delhifreight.com',
      status: LeadStatus.contacted,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      followUpDate: DateTime.now().add(const Duration(days: 1)),
      notes: 'Payment follow-up required',
    ),
  ];

  static final List<PerformanceMetrics> weeklyPerformance = [
    PerformanceMetrics(
      totalCalls: 25,
      connectedCalls: 18,
      missedCalls: 7,
      followUps: 5,
      conversionRate: 0.72,
      averageCallDuration: const Duration(minutes: 4, seconds: 30),
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
    PerformanceMetrics(
      totalCalls: 35,
      connectedCalls: 28,
      missedCalls: 7,
      followUps: 8,
      conversionRate: 0.80,
      averageCallDuration: const Duration(minutes: 5, seconds: 15),
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    PerformanceMetrics(
      totalCalls: 42,
      connectedCalls: 35,
      missedCalls: 7,
      followUps: 12,
      conversionRate: 0.83,
      averageCallDuration: const Duration(minutes: 4, seconds: 45),
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    PerformanceMetrics(
      totalCalls: 38,
      connectedCalls: 30,
      missedCalls: 8,
      followUps: 10,
      conversionRate: 0.79,
      averageCallDuration: const Duration(minutes: 5, seconds: 0),
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    PerformanceMetrics(
      totalCalls: 45,
      connectedCalls: 38,
      missedCalls: 7,
      followUps: 15,
      conversionRate: 0.84,
      averageCallDuration: const Duration(minutes: 5, seconds: 30),
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PerformanceMetrics(
      totalCalls: 28,
      connectedCalls: 22,
      missedCalls: 6,
      followUps: 8,
      conversionRate: 0.79,
      averageCallDuration: const Duration(minutes: 4, seconds: 20),
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PerformanceMetrics(
      totalCalls: 32,
      connectedCalls: 26,
      missedCalls: 6,
      followUps: 12,
      conversionRate: 0.81,
      averageCallDuration: const Duration(minutes: 4, seconds: 50),
      date: DateTime.now(),
    ),
  ];
}