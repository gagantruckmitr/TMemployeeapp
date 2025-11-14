class SocialMediaLead {
  final int id;
  final int assignedId;
  final String name;
  final String mobile;
  final String source;
  final String? remarks;
  final DateTime chatDateTime;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  SocialMediaLead({
    required this.id,
    required this.assignedId,
    required this.name,
    required this.mobile,
    required this.source,
    this.remarks,
    required this.chatDateTime,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocialMediaLead.fromJson(Map<String, dynamic> json) {
    return SocialMediaLead(
      id: int.parse(json['id'].toString()),
      assignedId: int.parse(json['assigned_id'].toString()),
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      source: json['source'] ?? '',
      remarks: json['remarks'],
      chatDateTime: DateTime.parse(json['chat_date_time']),
      role: json['role'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assigned_id': assignedId,
      'name': name,
      'mobile': mobile,
      'source': source,
      'remarks': remarks,
      'chat_date_time': chatDateTime.toIso8601String(),
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isTransporter => role.toLowerCase() == 'transporter';
}
