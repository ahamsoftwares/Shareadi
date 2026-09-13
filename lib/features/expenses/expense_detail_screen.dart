import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/category_icons.dart';
import '../../core/currency.dart';
import '../groups/models/member.dart';
import 'models/expense.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.memberById,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  final Expense expense;
  final Map<String, Member> memberById;
  final bool canEdit;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payer = memberById[expense.paidById]?.name ?? 'Unknown';
    final payerShare = expense.splits
        .where((split) => split.memberId == expense.paidById)
        .fold<int>(0, (sum, split) => sum + split.amountCents);
    final payerNet = expense.amountCents - payerShare;

    return Scaffold(
      appBar: AppBar(
        title: Text(expense.description),
        actions: [
          if (canEdit && onEdit != null)
            IconButton(
              tooltip: 'Edit expense',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          if (canEdit && onDelete != null)
            IconButton(
              tooltip: 'Delete expense',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Icon(
                          expenseIconFromKey(expense.icon),
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          formatMoney(expense.amountCents),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$payer paid ${formatMoney(expense.amountCents)}'),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy').format(expense.expenseDate),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (payerNet > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$payer gets ${formatMoney(payerNet)} back '
                      'after their own share of ${formatMoney(payerShare)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Split between members', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final split in expense.splits)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (memberById[split.memberId]?.name ?? '?').characters.first
                        .toUpperCase(),
                  ),
                ),
                title: Text(memberById[split.memberId]?.name ?? '?'),
                subtitle: Text(
                  split.memberId == expense.paidById
                      ? 'Paid ${formatMoney(expense.amountCents)} '
                            '\u00b7 share ${formatMoney(split.amountCents)}'
                      : 'Owes ${formatMoney(split.amountCents)}',
                ),
                trailing: Text(formatMoney(split.amountCents)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'This removes the expense and its split. '
          'The group balances will be recalculated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await onDelete?.call();
  }
}
