class JobBrief {
  final int? id;
  final String uniqueId;
  final String jobId;
  final int? callerId;
  final String? callerName;
  final String? jobTitle;
  final String? companyName;
  final String? jobCity;
  final String? name;
  final String? jobLocation;
  final String? route;
  final String? vehicleType;
  final String? licenseType;
  final String? experience;
  final double? salaryFixed;
  final double? salaryVariable;
  final String esiPf;
  final double? foodAllowance;
  final double? tripIncentive;
  final String rehneKiSuvidha;
  final String? mileage;
  final String fastTagRoadKharcha;
  final String? callStatusFeedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JobBrief({
    this.id,
    required this.uniqueId,
    required this.jobId,
    this.callerId,
    this.callerName,
    this.jobTitle,
    this.companyName,
    this.jobCity,
    this.name,
    this.jobLocation,
    this.route,
    this.vehicleType,
    this.licenseType,
    this.experience,
    this.salaryFixed,
    this.salaryVariable,
    this.esiPf = 'No',
    this.foodAllowance,
    this.tripIncentive,
    this.rehneKiSuvidha = 'No',
    this.mileage,
    this.fastTagRoadKharcha = 'Company',
    this.callStatusFeedback,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'uniqueId': uniqueId,
      'jobId': jobId,
      if (callerId != null) 'callerId': callerId,
      if (name != null) 'name': name,
      if (jobLocation != null) 'jobLocation': jobLocation,
      if (route != null) 'route': route,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (licenseType != null) 'licenseType': licenseType,
      if (experience != null) 'experience': experience,
      if (salaryFixed != null) 'salaryFixed': salaryFixed,
      if (salaryVariable != null) 'salaryVariable': salaryVariable,
      'esiPf': esiPf,
      if (foodAllowance != null) 'foodAllowance': foodAllowance,
      if (tripIncentive != null) 'tripIncentive': tripIncentive,
      'rehneKiSuvidha': rehneKiSuvidha,
      if (mileage != null) 'mileage': mileage,
      'fastTagRoadKharcha': fastTagRoadKharcha,
      if (callStatusFeedback != null) 'callStatusFeedback': callStatusFeedback,
    };
  }

  factory JobBrief.fromJson(Map<String, dynamic> json) {
    return JobBrief(
      id: json['id'],
      uniqueId: json['uniqueId'] ?? '',
      jobId: json['jobId'] ?? '',
      callerId: json['callerId'],
      callerName: json['callerName'],
      jobTitle: json['jobTitle'],
      companyName: json['companyName'],
      jobCity: json['jobCity'],
      name: json['name'],
      jobLocation: json['jobLocation'],
      route: json['route'],
      vehicleType: json['vehicleType'],
      licenseType: json['licenseType'],
      experience: json['experience'],
      salaryFixed: json['salaryFixed'] != null ? double.tryParse(json['salaryFixed'].toString()) : null,
      salaryVariable: json['salaryVariable'] != null ? double.tryParse(json['salaryVariable'].toString()) : null,
      esiPf: json['esiPf'] ?? 'No',
      foodAllowance: json['foodAllowance'] != null ? double.tryParse(json['foodAllowance'].toString()) : null,
      tripIncentive: json['tripIncentive'] != null ? double.tryParse(json['tripIncentive'].toString()) : null,
      rehneKiSuvidha: json['rehneKiSuvidha'] ?? 'No',
      mileage: json['mileage'],
      fastTagRoadKharcha: json['fastTagRoadKharcha'] ?? 'Company',
      callStatusFeedback: json['callStatusFeedback'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
