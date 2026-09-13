import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase.dart';
import '../expenses/expenses_providers.dart';
import 'balance_engine.dart';
import 'models/payment.dart';
import 'settlement_repository.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>(
  (ref) => SettlementRepository(ref.watch(supabaseClientProvider)),
);

final groupPaymentsProvider = FutureProvider.family<List<Payment>, String>(
  (ref, groupId) =>
      ref.watch(settlementRepositoryProvider).fetchPayments(groupId),
);

final groupNetBalancesProvider =
    FutureProvider.family<Map<String, int>, String>((ref, groupId) async {
  final expenses = await ref.watch(groupExpensesProvider(groupId).future);
  final payments = await ref.watch(groupPaymentsProvider(groupId).future);
  final confirmedPayments =
      payments.where((payment) => payment.isConfirmed).toList();
  return BalanceEngine.computeNet(
    expenses: expenses,
    payments: confirmedPayments,
  );
});