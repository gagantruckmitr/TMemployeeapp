class Phase2User {
  final int id;
  final String name;
  final String mobile;
  final String email;
  final String role;
  final String tcFor;
  final String createdAt;

  Phase2User({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.role,
    required this.tcFor,
    required this.createdAt,
  });

  factory Phase2User.fromJson(Map<String, dynamic> json) {
    return Phase2User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      tcFor: json['tcFor'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'role': role,
      'tcFor': tcFor,
      'createdAt': createdAt,
    };
  }

  @override
  String toString() {
    return 'Phase2User(id: $id, name: $name, mobile: $mobile, email: $email, role: $role, tcFor: $tcFor)';
  }
}
