import 'dart:math';

import '../expenses/models/expense.dart';
import 'models/payment.dart';

class Debt {
  const Debt({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountCents,
  });

  final String fromMemberId;
  final String toMemberId;
  final int amountCents;
}

class BalanceEngine {
  const BalanceEngine._();

  /// Positive net: the member is owed money (gets back).
  /// Negative net: the member owes money.
  static Map<String, int> computeNet({
    required List<Expense> expenses,
    List<Payment> payments = const [],
  }) {
    final net = <String, int>{};

    for (final expense in expenses) {
      net[expense.paidById] = (net[expense.paidById] ?? 0) + expense.amountCents;
      for (final split in expense.splits) {
        net[split.memberId] = (net[split.memberId] ?? 0) - split.amountCents;
      }
    }

    for (final payment in payments) {
      net[payment.fromMemberId] =
          (net[payment.fromMemberId] ?? 0) + payment.amountCents;
      net[payment.toMemberId] =
          (net[payment.toMemberId] ?? 0) - payment.amountCents;
    }

    return net;
  }

  /// Produces the fewest practical transactions by settling the largest
  /// debt against the largest credit until nothing remains.
  static List<Debt> simplify(Map<String, int> net) {
    final debtors = net.entries
        .where((entry) => entry.value < 0)
        .map((entry) => MapEntry(entry.key, -entry.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final creditors = net.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final debts = <Debt>[];
    var debtorIndex = 0;
    var creditorIndex = 0;
    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final amount = min(debtor.value, creditor.value);
      debts.add(
        Debt(
          fromMemberId: debtor.key,
          toMemberId: creditor.key,
          amountCents: amount,
        ),
      );
      debtors[debtorIndex] = MapEntry(debtor.key, debtor.value - amount);
      creditors[creditorIndex] =
          MapEntry(creditor.key, creditor.value - amount);
      if (debtors[debtorIndex].value == 0) debtorIndex++;
      if (creditors[creditorIndex].value == 0) creditorIndex++;
    }
    return debts;
  }
}