class Member {
  const Member({
    required this.id,
    required this.groupId,
    required this.name,
    required this.joinedAt,
    this.email,
    this.profileId,
    this.upiId,
  });

  final String id;
  final String groupId;
  final String name;
  final String? email;
  final String? profileId;
  final String? upiId;
  final DateTime joinedAt;

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      profileId: json['profile_id'] as String?,
      upiId: json['upi_id'] as String?,
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}