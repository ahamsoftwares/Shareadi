class Payment {
  const Payment({
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountCents,
    required this.paidAt,
    this.note,
    this.confirmedAt,
  });

  final String id;
  final String groupId;
  final String fromMemberId;
  final String toMemberId;
  final int amountCents;
  final String? note;
  final DateTime paidAt;
  final DateTime? confirmedAt;

  bool get isConfirmed => confirmedAt != null;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      fromMemberId: json['from_member_id'] as String,
      toMemberId: json['to_member_id'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
      note: json['note'] as String?,
      paidAt: DateTime.tryParse(json['paid_at'] as String? ?? '') ??
          DateTime.now(),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.tryParse(json['confirmed_at'] as String),
    );
  }
}