class Expense {
  const Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amountCents,
    required this.paidById,
    required this.expenseDate,
    required this.createdAt,
    this.createdBy,
    this.splits = const [],
    this.icon = 'receipt_long',
  });

  final String id;
  final String groupId;
  final String description;
  final int amountCents;
  final String paidById;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String? createdBy;
  final List<ExpenseSplit> splits;
  final String icon;

  factory Expense.fromJson(Map<String, dynamic> json) {
    final splitsRaw = json['splits'] as List<dynamic>? ?? const [];
    return Expense(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      description: json['description'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
      paidById: json['paid_by'] as String,
      expenseDate:
          DateTime.tryParse(json['expense_date'] as String? ?? '') ??
              DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      createdBy: json['created_by'] as String?,
      icon: json['icon'] as String? ?? 'receipt_long',
      splits: splitsRaw
          .map((split) => ExpenseSplit.fromJson(split as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExpenseSplit {
  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.amountCents,
  });

  final String id;
  final String expenseId;
  final String memberId;
  final int amountCents;

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      memberId: json['member_id'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
    );
  }
}