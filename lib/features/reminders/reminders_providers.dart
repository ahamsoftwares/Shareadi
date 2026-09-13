import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../expenses/expenses_providers.dart';
import '../groups/groups_providers.dart';
import '../settlement/balance_engine.dart';
import '../settlement/settlement_providers.dart';
import 'notification_service.dart';

final reminderServiceProvider = Provider<ReminderNotificationService>(
  (ref) => ReminderNotificationService(),
);

/// Number of the signed-in user's groups that still have outstanding
/// balances (i.e. someone owes someone after confirmed payments).
final unsettledGroupCountProvider = FutureProvider<int>((ref) async {
  final groups = await ref.watch(groupsListProvider.future);
  if (groups.isEmpty) return 0;

  final groupIds = groups.map((group) => group.id).toList();
  final expenses = await ref
      .watch(expensesRepositoryProvider)
      .fetchExpensesForGroups(groupIds);
  final payments = await ref
      .watch(settlementRepositoryProvider)
      .fetchPaymentsForGroups(groupIds);

  var unsettled = 0;
  for (final group in groups) {
    final groupExpenses =
        expenses.where((expense) => expense.groupId == group.id).toList();
    final groupPayments = payments
        .where((payment) => payment.groupId == group.id && payment.isConfirmed)
        .toList();
    final net = BalanceEngine.computeNet(
      expenses: groupExpenses,
      payments: groupPayments,
    );
    if (net.values.any((value) => value != 0)) {
      unsettled++;
    }
  }
  return unsettled;
});