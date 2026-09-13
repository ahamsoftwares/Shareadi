import 'package:flutter_test/flutter_test.dart';
import 'package:share_adi/features/expenses/models/expense.dart';
import 'package:share_adi/features/settlement/balance_engine.dart';
import 'package:share_adi/features/settlement/models/payment.dart';

Expense expense({
  required String id,
  required String paidBy,
  required List<(String, int)> splits,
  int amountCents = 0,
}) {
  final total = amountCents == 0
      ? splits.fold(0, (sum, split) => sum + split.$2)
      : amountCents;
  return Expense(
    id: id,
    groupId: 'g',
    description: 'x',
    amountCents: total,
    paidById: paidBy,
    expenseDate: DateTime(2026, 9, 8),
    createdAt: DateTime(2026, 9, 8),
    splits: [
      for (final (memberId, cents) in splits)
        ExpenseSplit(
          id: 's_$memberId',
          expenseId: id,
          memberId: memberId,
          amountCents: cents,
        ),
    ],
  );
}

void main() {
  const a = 'a';
  const b = 'b';
  const c = 'c';
  const d = 'd';

  group('computeNet', () {
    test('one payer split equally', () {
      final expenses = [
        expense(id: 'e1', paidBy: a, splits: [(a, 100), (b, 100), (c, 100)]),
      ];
      final net = BalanceEngine.computeNet(expenses: expenses);
      expect(net[a], 200);
      expect(net[b], -100);
      expect(net[c], -100);
    });

    test('applies payments on top of expenses', () {
      final expenses = [
        expense(id: 'e1', paidBy: a, splits: [(a, 100), (b, 100)]),
      ];
      final payments = [
        Payment(
          id: 'p1',
          groupId: 'g',
          fromMemberId: b,
          toMemberId: a,
          amountCents: 100,
          paidAt: DateTime(2026, 9, 9),
        ),
      ];
      final net = BalanceEngine.computeNet(
        expenses: expenses,
        payments: payments,
      );
      expect(net[a], 0);
      expect(net[b], 0);
    });
  });

  group('simplify', () {
    test('direct debts survive', () {
      final debts = BalanceEngine.simplify({a: 200, b: -150, c: -50});
      expect(debts.length, 2);
      expect(debts.map((d) => d.fromMemberId), containsAll([b, c]));
      expect(debts.every((d) => d.toMemberId == a), isTrue);
      expect(
        debts.fold<int>(0, (sum, d) => sum + d.amountCents),
        200,
      );
    });

    test('chain collapses to one transaction', () {
      final debts = BalanceEngine.simplify({a: -100, b: 0, c: 100});
      expect(debts.length, 1);
      expect(debts.single.fromMemberId, a);
      expect(debts.single.toMemberId, c);
      expect(debts.single.amountCents, 100);
    });

    test('closed circle resolves to nothing', () {
      final debts = BalanceEngine.simplify({a: 0, b: 0, c: 0});
      expect(debts, isEmpty);
    });

    test('three-way net settles by matching largest debt to largest credit', () {
      final debts = BalanceEngine.simplify({a: 30, b: 60, c: -20, d: -70});
      expect(debts.length, 3);
      expect(
        debts.fold<int>(0, (sum, d) => sum + d.amountCents),
        90,
      );
      expect(
        debts
            .where((d) => d.fromMemberId == c)
            .fold<int>(0, (sum, d) => sum + d.amountCents),
        20,
      );
      expect(
        debts
            .where((debt) => debt.fromMemberId == d)
            .fold<int>(0, (sum, debt) => sum + debt.amountCents),
        70,
      );
    });
  });
}