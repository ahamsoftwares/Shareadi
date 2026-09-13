enum GroupType {
  travel('travel', 'Travel'),
  house('house', 'House');

  const GroupType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static GroupType fromStorage(String value) {
    return values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => GroupType.travel,
    );
  }
}

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.joinCode,
    required this.createdAt,
    this.createdBy,
    this.memberCount = 0,
    this.icon = 'groups',
  });

  final String id;
  final String name;
  final GroupType type;
  final String currency;
  final String joinCode;
  final DateTime createdAt;
  final String? createdBy;
  final int memberCount;
  final String icon;

  factory Group.fromJson(Map<String, dynamic> json) {
    int count = 0;
    final members = json['members'] as List<dynamic>? ?? const [];
    if (members.isNotEmpty && members.first is Map<String, dynamic>) {
      count = (members.first['count'] as num?)?.toInt() ?? 0;
    }
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      type: GroupType.fromStorage(json['type'] as String? ?? 'travel'),
      currency: json['currency'] as String? ?? 'INR',
      joinCode: json['join_code'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      createdBy: json['created_by'] as String?,
      memberCount: count,
      icon: json['icon'] as String? ?? 'groups',
    );
  }
}