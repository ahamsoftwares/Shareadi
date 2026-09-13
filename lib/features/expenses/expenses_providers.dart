import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase.dart';
import 'expenses_repository.dart';
import 'models/expense.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(ref.watch(supabaseClientProvider)),
);

final groupExpensesProvider = FutureProvider.family<List<Expense>, String>(
  (ref, groupId) => ref.watch(expensesRepositoryProvider).fetchExpenses(groupId),
);