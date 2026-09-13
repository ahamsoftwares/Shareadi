import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/supabase.dart';
import '../expenses/expenses_providers.dart';
import '../expenses/models/expense.dart';
import '../groups/groups_providers.dart';
import '../groups/models/member.dart';
import 'models/payment.dart';
import 'payment_pdf.dart';
import 'settlement_providers.dart';

Future<void> openStatementDialog(
  BuildContext context,
  WidgetRef ref,
  String groupId,
) async {
  final messenger = ScaffoldMessenger.of(context);

  List<Payment> allPayments;
  List<Expense> allExpenses;
  try {
    allPayments = await ref.read(groupPaymentsProvider(groupId).future);
    allExpenses = await ref.read(groupExpensesProvider(groupId).future);
  } catch (error) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not load transactions.')),
    );
    return;
  }
  if (allPayments.isEmpty && allExpenses.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No transactions to export yet.')),
    );
    return;
  }
  if (!context.mounted) return;

  DateTime? from;
  DateTime? to;
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Statement period'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop('all'),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history),
            title: Text('All time'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop('range'),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.date_range),
            title: Text('Custom date range…'),
          ),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;

  if (choice == 'range') {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Statement period',
      saveText: 'Export',
    );
    if (picked == null || !context.mounted) return;
    from = picked.start;
    to = picked.end;
  }

  final periodStart = from == null
      ? null
      : DateTime(from.year, from.month, from.day);
  final periodEndExclusive = to == null
      ? null
      : DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
  final payments = allPayments.where((payment) {
    if (periodStart == null || periodEndExclusive == null) return true;
    return !payment.paidAt.isBefore(periodStart) &&
        payment.paidAt.isBefore(periodEndExclusive);
  }).toList();

  final expenses = allExpenses.where((expense) {
    if (periodStart == null || periodEndExclusive == null) return true;
    return !expense.expenseDate.isBefore(periodStart) &&
        expense.expenseDate.isBefore(periodEndExclusive);
  }).toList();

  if (payments.isEmpty && expenses.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No transactions in that period.')),
    );
    return;
  }

  final List<Member> members;
  final String groupName;
  try {
    members = await ref.read(groupMembersProvider(groupId).future);
    groupName = (await ref.read(groupDetailProvider(groupId).future)).name;
  } catch (error) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not load group details.')),
    );
    return;
  }
  if (!context.mounted) return;
  final memberName = {for (final member in members) member.id: member.name};

  final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
  final userEmail = currentUser?.email?.toLowerCase();
  String? currentMemberId;
  for (final member in members) {
    final emailMatches = userEmail != null &&
        member.email != null &&
        member.email!.toLowerCase() == userEmail;
    if (member.profileId == currentUser?.id || emailMatches) {
      currentMemberId = member.id;
      break;
    }
  }

  try {
    final file = await createGroupStatementPdf(
      groupName: groupName,
      expenses: expenses,
      payments: payments,
      memberName: memberName,
      currentMemberId: currentMemberId,
      from: from,
      to: to,
    );
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open statement: ${result.message}')),
      );
    }
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not create statement: $error')),
    );
  }
}
