import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/category_icons.dart';
import '../../core/currency.dart';
import '../../core/supabase.dart';
import '../../widgets/icon_picker.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';
import '../expenses/expenses_providers.dart';
import '../expenses/models/expense.dart';
import '../settlement/models/payment.dart';
import '../settlement/settlement_providers.dart';
import '../settlement/statement_dialog.dart';
import 'add_member_sheet.dart';
import 'edit_upi_sheet.dart';
import 'groups_providers.dart';
import 'invite_members_sheet.dart';
import 'models/member.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final balancesAsync = ref.watch(groupNetBalancesProvider(groupId));
    final paymentsAsync = ref.watch(groupPaymentsProvider(groupId));
    final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
    final userEmail = currentUser?.email?.toLowerCase();
    String? signedInMemberId;
    Member? ownMember;
    final loadedMembers = membersAsync.value;
    if (loadedMembers != null) {
      for (final member in loadedMembers) {
        final emailMatches = userEmail != null &&
            member.email != null &&
            member.email!.toLowerCase() == userEmail;
        if (member.profileId == currentUser?.id || emailMatches) {
          signedInMemberId = member.id;
          ownMember = member;
          break;
        }
      }
    }

    void openInviteSheet() {
      final group = groupAsync.value;
      if (group == null) return;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => InviteMembersSheet(group: group),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.maybeWhen(
          data: (group) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(groupIconFromKey(group.icon), size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      group.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (ownMember != null)
                if (ownMember.upiId?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 1),
                    child: Text(
                      ownMember.upiId!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        height: 1.2,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) => EditUpiSheet(
                          groupId: groupId,
                          ownMember: ownMember!,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 28, top: 1),
                      child: Text(
                        'Set UPI handle here',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              fontSize: 10,
                              height: 1.2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
            ],
          ),
          orElse: () => const Text('Group'),
        ),
        actions: [
          if (groupAsync.value?.createdBy == currentUser?.id)
            IconButton(
              tooltip: 'Edit group',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editGroup(context, ref, groupId),
            ),
          IconButton(
            tooltip: 'Add member',
            icon: const Icon(Icons.person_add_alt),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => AddMemberSheet(groupId: groupId),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Group options',
            onSelected: (value) {
              if (value == 'leave') _leaveGroup(context, ref, groupId);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'leave',
                child: Text('Leave group'),
              ),
            ],
          ),
        ],
        bottom: null,
      ),
      floatingActionButton: membersAsync.maybeWhen(
        data: (members) => members.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          AddExpenseScreen(groupId: groupId, members: members),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
        orElse: () => null,
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (members) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupMembersProvider(groupId));
            ref.invalidate(groupExpensesProvider(groupId));
            await ref.read(groupExpensesProvider(groupId).future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverToBoxAdapter(
                child: _PendingConfirmationsBar(
                  paymentsAsync: paymentsAsync,
                  memberById: {
                    for (final member in members) member.id: member,
                  },
                  currentMemberId: signedInMemberId,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Members (${members.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            tooltip: 'Download group statement (PDF)',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                openStatementDialog(context, ref, groupId),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ownMember != null)
                            IconButton(
                              tooltip: 'Set your UPI handle',
                              icon: const Icon(Icons.payments_outlined, size: 20),
                              onPressed: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (context) => EditUpiSheet(
                                    groupId: groupId,
                                    ownMember: ownMember!,
                                  ),
                                );
                              },
                            ),
                          TextButton.icon(
                            onPressed: openInviteSheet,
                            icon: const Icon(Icons.send_outlined, size: 18),
                            label: const Text('Invite'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
                child: members.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Text(
                          'No members yet. Invite someone to join.',
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final spentById = <String, int>{};
                          for (final expense
                              in expensesAsync.value ?? const <Expense>[]) {
                            spentById[expense.paidById] =
                                (spentById[expense.paidById] ?? 0) +
                                    expense.amountCents;
                          }
                          return SizedBox(
                            height: 76,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                return _MemberAvatar(
                                  member: member,
                                  spentCents: spentById[member.id] ?? 0,
                                  onTap: () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      showDragHandle: true,
                                      builder: (context) => _RenameMemberSheet(
                                        groupId: groupId,
                                        member: member,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            SliverToBoxAdapter(
                child: _BalancesBar(
                  balancesAsync: balancesAsync,
                  expensesAsync: expensesAsync,
                  members: members,
                  currentMemberId: signedInMemberId,
                  onSettleUp: () => context.push('/group/$groupId/settle'),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Expenses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            expensesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stackTrace) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load expenses: $error'),
                  ),
                ),
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No expenses yet.',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Add expense" to split your first bill.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final memberById = {for (final m in members) m.id: m};
                        final expense = expenses[index];
                        final canEdit =
                            signedInMemberId != null &&
                            (expense.paidById == signedInMemberId ||
                                expense.createdBy == currentUser?.id ||
                                expense.splits.any(
                                  (split) =>
                                      split.memberId == signedInMemberId,
                                ));
                        return _ExpenseCard(
                          expense: expense,
                          memberById: memberById,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => ExpenseDetailScreen(
                                  expense: expense,
                                  memberById: memberById,
                                  canEdit: canEdit,
                                  onEdit: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) =>
                                            AddExpenseScreen(
                                              groupId: groupId,
                                              members: members,
                                              expense: expense,
                                            ),
                                      ),
                                    );
                                  },
                                  onDelete: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    try {
                                      await ref
                                          .read(expensesRepositoryProvider)
                                          .deleteExpense(expense.id);
                                      ref.invalidate(
                                        groupExpensesProvider(groupId),
                                      );
                                      ref.invalidate(
                                        groupNetBalancesProvider(groupId),
                                      );
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Expense deleted.'),
                                        ),
                                      );
                                    } catch (error) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not delete expense: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 88 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ),
        ),
      );
  }

  Future<void> _leaveGroup(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave group'),
        content: const Text(
          'You will lose access to this group. Your past expenses and the '
          'balances of the other members stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(groupsRepositoryProvider).leaveGroup(groupId);
      ref.invalidate(groupsListProvider);
      ref.invalidate(groupDetailProvider(groupId));
      ref.invalidate(groupMembersProvider(groupId));
      ref.invalidate(groupExpensesProvider(groupId));
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('You left the group.')),
      );
      context.go('/');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _editGroup(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) async {
    final group = ref.read(groupDetailProvider(groupId)).value;
    if (group == null) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EditGroupDialog(
        initialName: group.name,
        initialIcon: group.icon,
        onSave: (name, icon) => ref
            .read(groupsRepositoryProvider)
            .updateGroup(groupId: groupId, name: name, icon: icon),
      ),
    );
    if (saved == true && context.mounted) {
      ref.invalidate(groupDetailProvider(groupId));
      ref.invalidate(groupsListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group renamed.')),
      );
    }
  }
}

class _PendingConfirmationsBar extends ConsumerStatefulWidget {
  const _PendingConfirmationsBar({
    required this.paymentsAsync,
    required this.memberById,
    required this.currentMemberId,
  });

  final AsyncValue<List<Payment>> paymentsAsync;
  final Map<String, Member> memberById;
  final String? currentMemberId;

  @override
  ConsumerState<_PendingConfirmationsBar> createState() =>
      _PendingConfirmationsBarState();
}

class _PendingConfirmationsBarState
    extends ConsumerState<_PendingConfirmationsBar> {
  String? _confirmingId;

  Future<void> _confirm(Payment payment) async {
    setState(() => _confirmingId = payment.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(settlementRepositoryProvider).confirmPayment(payment.id);
      ref.invalidate(groupPaymentsProvider(payment.groupId));
      ref.invalidate(groupNetBalancesProvider(payment.groupId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment confirmed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not confirm payment: $error')),
      );
    } finally {
      if (mounted) setState(() => _confirmingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.paymentsAsync.maybeWhen(
      data: (payments) {
        final pending = payments
            .where(
              (payment) =>
                  !payment.isConfirmed &&
                  payment.toMemberId == widget.currentMemberId,
            )
            .toList();
        if (pending.isEmpty) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          color: isDark ? Colors.orange.shade900 : Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 20,
                      color: isDark ? Colors.orange.shade200 : Colors.deepOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment${pending.length > 1 ? 's' : ''} received',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                for (final payment in pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatMoney(payment.amountCents),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'from '
                                '${widget.memberById[payment.fromMemberId]?.name ?? '?'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _confirmingId == payment.id
                              ? null
                              : () => _confirm(payment),
                          child: _confirmingId == payment.id
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Confirm'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _BalancesBar extends StatelessWidget {
  const _BalancesBar({
    required this.balancesAsync,
    required this.expensesAsync,
    required this.members,
    required this.currentMemberId,
    required this.onSettleUp,
  });

  final AsyncValue<Map<String, int>> balancesAsync;
  final AsyncValue<List<Expense>> expensesAsync;
  final List<Member> members;
  final String? currentMemberId;
  final VoidCallback onSettleUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var totalSpentCents = 0;
    var paidCents = 0;
    var shareCents = 0;
    for (final expense in expensesAsync.value ?? const <Expense>[]) {
      totalSpentCents += expense.amountCents;
      if (expense.paidById == currentMemberId) {
        paidCents += expense.amountCents;
      }
      if (currentMemberId != null) {
        final mySplit = expense.splits
            .where((split) => split.memberId == currentMemberId)
            .fold<int>(0, (sum, split) => sum + split.amountCents);
        if (mySplit > 0) {
          shareCents += mySplit;
        } else if (expense.splits.isEmpty && members.isNotEmpty) {
          shareCents += expense.amountCents ~/ members.length;
        }
      }
    }
    return balancesAsync.maybeWhen(
      data: (balances) {
        final String text;
        final Color? color;
        if (members.isEmpty || balances.isEmpty) {
          text = 'No expenses yet.';
          color = theme.colorScheme.onSurfaceVariant;
        } else {
          final myNet = currentMemberId == null
              ? 0
              : (balances[currentMemberId] ?? 0);
          if (myNet > 0) {
            text = 'You will get ${formatMoney(myNet)} back';
            color = Colors.green.shade700;
          } else if (myNet < 0) {
            text = 'You owe ${formatMoney(-myNet)}';
            color = Colors.deepOrange.shade700;
          } else {
            text = 'You are all settled';
            color = theme.colorScheme.onSurfaceVariant;
          }
        }
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ListTile(
            leading: Icon(Icons.account_balance_wallet_outlined, color: color),
            title: Text(text, style: TextStyle(color: color)),
            subtitle: totalSpentCents > 0
                ? currentMemberId != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'You paid ${formatMoney(paidCents)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Your expenditure ${formatMoney(shareCents)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Group total ${formatMoney(totalSpentCents)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      )
                    : Text(
                        'Group total spent ${formatMoney(totalSpentCents)}',
                        style: theme.textTheme.bodySmall,
                      )
                : null,
            trailing: TextButton(
              onPressed: onSettleUp,
              child: const Text('Settle up'),
            ),
          ),
        );
      },
      orElse: () => const Card(
        margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ListTile(
          leading: Icon(Icons.account_balance_wallet_outlined),
          title: Text('Loading balances…'),
          trailing: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.spentCents, this.onTap});

  final Member member;
  final int spentCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 76),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spentCents == 0
                      ? 'No spends'
                      : 'Spent ${formatMoney(spentCents)}',
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenameMemberSheet extends ConsumerStatefulWidget {
  const _RenameMemberSheet({required this.groupId, required this.member});

  final String groupId;
  final Member member;

  @override
  ConsumerState<_RenameMemberSheet> createState() => _RenameMemberSheetState();
}

class _RenameMemberSheetState extends ConsumerState<_RenameMemberSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.member.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(groupsRepositoryProvider).renameMember(
            memberId: widget.member.id,
            name: name,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(groupMembersProvider(widget.groupId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Member renamed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not rename member: $error')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
    final canRename = widget.member.profileId == null ||
        widget.member.profileId == currentUser?.id;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.member.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            canRename ? 'Rename this member' : 'Member',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (canRename) ...[
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Member name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ] else ...[
            const Icon(Icons.info_outline, size: 32, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'You can only rename yourself or members added by name '
              '(who have not joined the app yet).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.memberById,
    required this.onTap,
  });

  final Expense expense;
  final Map<String, Member> memberById;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payerName = memberById[expense.paidById]?.name ?? 'Unknown';
    final splitsText = expense.splits
        .map(
          (split) =>
              '${memberById[split.memberId]?.name ?? '?'} '
              '${formatMoney(split.amountCents)}',
        )
        .join('  \u00b7  ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(
              expenseIconFromKey(expense.icon),
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(expense.description),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$payerName paid ${formatMoney(expense.amountCents)} \u00b7 '
                '${DateFormat('d MMM').format(expense.expenseDate)}',
                style: theme.textTheme.bodySmall,
              ),
              if (splitsText.isNotEmpty)
                Text(
                  splitsText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          trailing: Text(
            formatMoney(expense.amountCents),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditGroupDialog extends StatefulWidget {
  const _EditGroupDialog({
    required this.initialName,
    required this.initialIcon,
    required this.onSave,
  });

  final String initialName;
  final String initialIcon;
  final Future<void> Function(String name, String icon) onSave;

  @override
  State<_EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<_EditGroupDialog> {
  late final TextEditingController _controller;
  late String _icon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _icon = widget.initialIcon;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit group'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Group icon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            IconPicker(
              options: groupIcons,
              selectedKey: _icon,
              onChanged: (key) => setState(() => _icon = key),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final name = _controller.text.trim();
                  if (name.isEmpty) return;
                  setState(() => _saving = true);
                  try {
                    await widget.onSave(name, _icon);
                    if (context.mounted) Navigator.of(context).pop(true);
                  } catch (error) {
                    setState(() => _saving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not edit group: $error'),
                        ),
                      );
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
