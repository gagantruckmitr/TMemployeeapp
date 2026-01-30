/// Margdarshak User Model
/// Represents a field agent user with their profile and territory information
class MargdarshakUser {
  final int id;
  final String employeeId;
  final String name;
  final String? email;
  final String mobile;
  final String role;
  final String states;
  final String status;
  final String? profileImage;
  final DateTime? joinDate;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? upiId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? stateName;

  MargdarshakUser({
    required this.id,
    required this.employeeId,
    required this.name,
    this.email,
    required this.mobile,
    required this.role,
    required this.states,
    required this.status,
    this.profileImage,
    this.joinDate,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.bankName,
    this.upiId,
    this.createdAt,
    this.updatedAt,
    this.stateName,
  });

  factory MargdarshakUser.fromJson(Map<String, dynamic> json) {
    return MargdarshakUser(
      id: json['id'] as int,
      employeeId: json['employee_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      mobile: json['mobile'] as String,
      role: json['role'] as String,
      states: json['states'] as String,
      status: json['status'] as String,
      profileImage: json['profile_image'] as String?,
      joinDate: json['join_date'] != null
          ? DateTime.tryParse(json['join_date'])
          : null,
      accountHolderName: json['account_holder_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      bankName: json['bank_name'] as String?,
      upiId: json['upi_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      stateName: json['state_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role,
      'states': states,
      'status': status,
      'profile_image': profileImage,
      'join_date': joinDate?.toIso8601String(),
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'bank_name': bankName,
      'upi_id': upiId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'state_name': stateName,
    };
  }

  bool get isActive => status == 'active';
  bool get isFieldAgent => role == 'field_agent';
}

/// Login Response Model
class MargdarshakLoginResponse {
  final bool status;
  final String message;
  final String? token;
  final MargdarshakUser? user;

  MargdarshakLoginResponse({
    required this.status,
    required this.message,
    this.token,
    this.user,
  });

  factory MargdarshakLoginResponse.fromJson(Map<String, dynamic> json) {
    return MargdarshakLoginResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      token: json['token'] as String?,
      user: json['data'] != null && json['data']['user'] != null
          ? MargdarshakUser.fromJson(json['data']['user'])
          : null,
    );
  }

  bool get isSuccess => status && user != null;
}
