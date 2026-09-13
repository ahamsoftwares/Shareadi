import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/expense.dart';
import 'split_engine.dart';

class ExpensesRepository {
  ExpensesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Expense>> fetchExpenses(String groupId) async {
    final data = await _client
        .from('expenses')
        .select('*, splits:expense_splits(*)')
        .eq('group_id', groupId)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);
    return data.map(Expense.fromJson).toList();
  }

  Future<List<Expense>> fetchExpensesForGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return const [];
    final data = await _client
        .from('expenses')
        .select('*, splits:expense_splits(*)')
        .inFilter('group_id', groupIds);
    return data.map(Expense.fromJson).toList();
  }

  Future<Expense> createExpense({
    required String groupId,
    required String description,
    required int amountCents,
    required String paidById,
    required DateTime date,
    required List<MemberSplit> splits,
    String icon = 'receipt_long',
  }) async {
    final expense = await _client
        .from('expenses')
        .insert({
          'group_id': groupId,
          'description': description,
          'amount_cents': amountCents,
          'paid_by': paidById,
          'expense_date': DateFormat('yyyy-MM-dd').format(date),
          'created_by': _client.auth.currentUser?.id,
          'icon': icon,
        })
        .select()
        .single();

    await _client.from('expense_splits').insert(
          splits
              .where((split) => split.amountCents > 0)
              .map(
                (split) => {
                  'expense_id': expense['id'],
                  'member_id': split.memberId,
                  'amount_cents': split.amountCents,
                },
              )
              .toList(),
        );

    return Expense.fromJson({
      ...expense,
      'splits': const [],
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  Future<void> updateExpense({
    required String id,
    required String groupId,
    required String description,
    required int amountCents,
    required String paidById,
    required DateTime date,
    required List<MemberSplit> splits,
    String icon = 'receipt_long',
  }) async {
    await _client
        .from('expenses')
        .update({
          'description': description,
          'amount_cents': amountCents,
          'paid_by': paidById,
          'expense_date': DateFormat('yyyy-MM-dd').format(date),
          'icon': icon,
        })
        .eq('id', id);

    await _client.from('expense_splits').delete().eq('expense_id', id);

    await _client.from('expense_splits').insert(
          splits
              .where((split) => split.amountCents > 0)
              .map(
                (split) => {
                  'expense_id': id,
                  'member_id': split.memberId,
                  'amount_cents': split.amountCents,
                },
              )
              .toList(),
        );
  }
}