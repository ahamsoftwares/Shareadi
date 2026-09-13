import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/currency.dart';
import '../../core/supabase.dart';
import '../groups/groups_providers.dart';
import '../groups/models/member.dart';
import 'balance_engine.dart';
import 'models/payment.dart';
import 'payment_pdf.dart';
import 'settlement_providers.dart';
import 'statement_dialog.dart';

class SettleUpScreen extends ConsumerWidget {
  const SettleUpScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final balancesAsync = ref.watch(groupNetBalancesProvider(groupId));
    final paymentsAsync = ref.watch(groupPaymentsProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle up'),
        actions: [
          IconButton(
            tooltip: 'Download group statement (PDF)',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => openStatementDialog(context, ref, groupId),
          ),
        ],
      ),
      body: balancesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (balances) {
          final members = membersAsync.value ?? const <Member>[];
          final debts = BalanceEngine.simplify(balances);
          final memberName = {
            for (final member in members) member.id: member.name,
          };
          final currentUser =
              ref.read(supabaseClientProvider).auth.currentUser;
          final userEmail = currentUser?.email?.toLowerCase();
          String? signedInMemberId;
          for (final member in members) {
            final emailMatches = userEmail != null &&
                member.email != null &&
                member.email!.toLowerCase() == userEmail;
            if (member.profileId == currentUser?.id || emailMatches) {
              signedInMemberId = member.id;
              break;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupNetBalancesProvider(groupId));
              await ref.read(groupNetBalancesProvider(groupId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (members.isEmpty)
                  const _EmptySection(message: 'No members in this group yet.')
                else ...[
                  Text(
                    'Balances',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...members.map(
                    (member) => _BalanceRow(
                      name: member.name,
                      netCents: balances[member.id] ?? 0,
                    ),
                  ),
                ],
                if (members.isNotEmpty && debts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Needs to be paid',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...debts.map(
                    (debt) => _DebtRow(
                      debt: debt,
                      memberName: memberName,
                      onSettle: debt.fromMemberId == signedInMemberId
                          ? () => _showSettleSheet(
                              context,
                              ref,
                              groupId: groupId,
                              debt: debt,
                              members: members,
                            )
                          : null,
                      onRemind: debt.toMemberId == signedInMemberId
                          ? () => _remindDebtor(
                              context,
                              ref,
                              groupId: groupId,
                              debt: debt,
                              memberName: memberName,
                            )
                          : null,
                    ),
                  ),
                ],
                if (members.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Payment history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _PaymentHistory(
                    groupId: groupId,
                    paymentsAsync: paymentsAsync,
                    memberName: memberName,
                    currentMemberId: signedInMemberId,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _remindDebtor(
    BuildContext context,
    WidgetRef ref, {
    required String groupId,
    required Debt debt,
    required Map<String, String> memberName,
  }) async {
    final debtorName = memberName[debt.fromMemberId] ?? 'there';
    final groupName = ref.read(groupDetailProvider(groupId)).value?.name;
    final groupLabel = (groupName == null || groupName.isEmpty)
        ? 'our group'
        : '"$groupName"';
    final message = 'Hi $debtorName, you owe me '
        '${formatMoney(debt.amountCents)} in $groupLabel. '
        'Please settle up on Share Adi.';
    try {
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send reminder: $error')),
      );
    }
  }

  void _showSettleSheet(
    BuildContext context,
    WidgetRef ref, {
    required String groupId,
    required Debt debt,
    required List<Member> members,
  }) {
    final memberById = {for (final member in members) member.id: member};
    final from = memberById[debt.fromMemberId]?.name ?? '?';
    final to = memberById[debt.toMemberId]?.name ?? '?';
    final payeeUpiId = memberById[debt.toMemberId]?.upiId;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _RecordPaymentSheet(
          groupId: groupId,
          debt: debt,
          fromName: from,
          toName: to,
          toUpiId: payeeUpiId,
        ),
      ),
    );
  }
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  const _RecordPaymentSheet({
    required this.groupId,
    required this.debt,
    required this.fromName,
    required this.toName,
    required this.toUpiId,
  });

  final String groupId;
  final Debt debt;
  final String fromName;
  final String toName;
  final String? toUpiId;

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  late final TextEditingController _upiController;
  bool _saving = false;

  int get _outstandingCents => widget.debt.amountCents;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _centsToRupees(_outstandingCents),
    );
    _amountController.addListener(() => setState(() {}));
    _upiController = TextEditingController(text: widget.toUpiId ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  String _centsToRupees(int cents) {
    final rupees = cents / 100;
    return rupees == rupees.roundToDouble()
        ? rupees.toStringAsFixed(0)
        : rupees.toStringAsFixed(2);
  }

  Future<void> _save() async {
    final amount = parseAmountToCents(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(settlementRepositoryProvider)
          .addPayment(
            groupId: widget.groupId,
            fromMemberId: widget.debt.fromMemberId,
            toMemberId: widget.debt.toMemberId,
            amountCents: amount,
            note: _noteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(groupNetBalancesProvider(widget.groupId));
      ref.invalidate(groupPaymentsProvider(widget.groupId));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Payment recorded. Waiting for '
            '${widget.toName} to confirm.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not record payment: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _launchGpay() async {
    final amount = parseAmountToCents(_amountController.text);
    final messenger = ScaffoldMessenger.of(context);
    if (amount == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }
    final upi = _upiController.text.trim();
    if (upi.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${widget.toName} has not set a UPI handle yet.'),
        ),
      );
      return;
    }
    try {
      final note = _noteController.text.trim();
      final uri = Uri.parse(
        'upi://pay'
        '?pa=${Uri.encodeQueryComponent(upi)}'
        '&pn=${Uri.encodeQueryComponent(widget.toName)}'
        '&am=${(amount / 100).toStringAsFixed(2)}'
        '&cu=INR'
        '&tn=${Uri.encodeQueryComponent(note)}',
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No UPI app found on this device.')),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open a UPI app: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entered = parseAmountToCents(_amountController.text);
    final remaining = entered == null ? null : _outstandingCents - entered;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.fromName} \u2192 ${widget.toName}',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Outstanding balance: ${formatMoney(_outstandingCents)}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount to pay',
            prefixText: '\u20b9 ',
            border: OutlineInputBorder(),
          ),
        ),
        if (entered != null && entered > 0 && remaining != null && remaining > 0) ...[
          const SizedBox(height: 12),
          Text(
            '${widget.fromName} will still owe ${widget.toName} '
            '${formatMoney(remaining)} after this payment.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'e.g. UPI payment',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _upiController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: '${widget.toName}\u2019s UPI handle',
            hintText: 'Not set yet',
            border: const OutlineInputBorder(),
            suffixIcon: (widget.toUpiId?.isEmpty ?? true)
                ? const Icon(Icons.warning_amber_outlined)
                : const Icon(Icons.check_circle_outline),
          ),
        ),
        if (widget.toUpiId?.isEmpty ?? true) ...[
          const SizedBox(height: 8),
          Text(
            'Ask ${widget.toName} to set their UPI handle in the group. '
            'Record the payment below until then.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: (widget.toUpiId?.isEmpty ?? true) ? null : _launchGpay,
          icon: const Icon(Icons.account_balance_wallet),
          label: const Text('Pay via UPI'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Record payment only'),
        ),
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.name, required this.netCents});

  final String name;
  final int netCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    final String amount;
    if (netCents > 0) {
      color = Colors.green.shade700;
      amount = 'will get ${formatMoney(netCents)} back';
    } else if (netCents < 0) {
      color = Colors.deepOrange.shade700;
      amount = 'owes ${formatMoney(-netCents)}';
    } else {
      color = theme.colorScheme.onSurfaceVariant;
      amount = 'settled';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(amount, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({
    required this.debt,
    required this.memberName,
    this.onSettle,
    this.onRemind,
  });

  final Debt debt;
  final Map<String, String> memberName;
  final VoidCallback? onSettle;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final from = memberName[debt.fromMemberId] ?? '?';
    final to = memberName[debt.toMemberId] ?? '?';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.swap_horiz),
        title: Text('$from \u2192 $to'),
        subtitle: Text(
          'Remaining: ${formatMoney(debt.amountCents)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRemind != null)
              OutlinedButton.icon(
                onPressed: onRemind,
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                ),
                label: const Text('Remind'),
              ),
            if (onSettle != null) ...[
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onSettle,
                child: const Text('Settle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentHistory extends ConsumerStatefulWidget {
  const _PaymentHistory({
    required this.groupId,
    required this.paymentsAsync,
    required this.memberName,
    required this.currentMemberId,
  });

  final String groupId;
  final AsyncValue<List<Payment>> paymentsAsync;
  final Map<String, String> memberName;
  final String? currentMemberId;

  @override
  ConsumerState<_PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends ConsumerState<_PaymentHistory> {
  String? _confirmingId;

  Future<void> _confirm(Payment payment) async {
    setState(() => _confirmingId = payment.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(settlementRepositoryProvider).confirmPayment(payment.id);
      ref.invalidate(groupPaymentsProvider(widget.groupId));
      ref.invalidate(groupNetBalancesProvider(widget.groupId));
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

  Future<void> _openPdf(Payment payment) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await createPaymentPdf(
        payment: payment,
        fromName: widget.memberName[payment.fromMemberId] ?? '?',
        toName: widget.memberName[payment.toMemberId] ?? '?',
      );
      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not open PDF: ${result.message}')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open PDF: $error')),
      );
    }
  }

  bool _isParticipant(Payment payment) {
    return widget.currentMemberId == payment.fromMemberId ||
        widget.currentMemberId == payment.toMemberId;
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
          'Remove the ${formatMoney(payment.amountCents)} payment from '
          '${widget.memberName[payment.fromMemberId] ?? '?'} to '
          '${widget.memberName[payment.toMemberId] ?? '?'}? '
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
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(settlementRepositoryProvider).deletePayment(payment.id);
      ref.invalidate(groupPaymentsProvider(widget.groupId));
      ref.invalidate(groupNetBalancesProvider(widget.groupId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment deleted.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete payment: $error')),
      );
    }
  }

  void _editPayment(Payment payment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _EditPaymentSheet(
          groupId: widget.groupId,
          payment: payment,
          fromName: widget.memberName[payment.fromMemberId] ?? '?',
          toName: widget.memberName[payment.toMemberId] ?? '?',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.paymentsAsync.maybeWhen(
      data: (payments) {
        if (payments.isEmpty) {
          return Text(
            'No payments recorded yet.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final confirmedColor =
            isDark ? Colors.green.shade300 : Colors.green.shade700;
        final pendingColor =
            isDark ? Colors.orange.shade300 : Colors.orange.shade800;
        return Column(
          children: [
            for (final payment in payments)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            payment.isConfirmed
                                ? Icons.check_circle_outline
                                : Icons.pending_outlined,
                            size: 20,
                            color: payment.isConfirmed
                                ? confirmedColor
                                : pendingColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.memberName[payment.fromMemberId] ?? '?'} '
                              '\u2192 '
                              '${widget.memberName[payment.toMemberId] ?? '?'}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            formatMoney(payment.amountCents),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.isConfirmed
                            ? 'Confirmed'
                                  ' \u00b7 ${DateFormat('d MMM').format(payment.paidAt)}'
                            : 'Waiting for '
                                  '${widget.memberName[payment.toMemberId] ?? '?'} '
                                  'to confirm'
                                  ' \u00b7 ${DateFormat('d MMM').format(payment.paidAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: payment.isConfirmed
                              ? confirmedColor
                              : pendingColor,
                        ),
                      ),
                      if (payment.note?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            payment.note!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (!payment.isConfirmed &&
                          widget.currentMemberId == payment.toMemberId)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonal(
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
                                  : const Text('Confirm receipt'),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isParticipant(payment))
                              IconButton(
                                tooltip: 'Edit payment',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _editPayment(payment),
                              ),
                            if (_isParticipant(payment))
                              IconButton(
                                tooltip: 'Delete payment',
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deletePayment(payment),
                              ),
                            IconButton(
                              tooltip: 'Open payment receipt',
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 20,
                              ),
                              onPressed: () => _openPdf(payment),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      orElse: () => Text(
        'Loading history…',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _EditPaymentSheet extends ConsumerStatefulWidget {
  const _EditPaymentSheet({
    required this.groupId,
    required this.payment,
    required this.fromName,
    required this.toName,
  });

  final String groupId;
  final Payment payment;
  final String fromName;
  final String toName;

  @override
  ConsumerState<_EditPaymentSheet> createState() => _EditPaymentSheetState();
}

class _EditPaymentSheetState extends ConsumerState<_EditPaymentSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rupees = widget.payment.amountCents / 100;
    _amountController = TextEditingController(
      text: rupees == rupees.roundToDouble()
          ? rupees.toStringAsFixed(0)
          : rupees.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.payment.note ?? '');
    _date = widget.payment.paidAt;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = parseAmountToCents(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(settlementRepositoryProvider).updatePayment(
            paymentId: widget.payment.id,
            amountCents: amount,
            note: _noteController.text.trim(),
            paidAt: _date,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(groupPaymentsProvider(widget.groupId));
      ref.invalidate(groupNetBalancesProvider(widget.groupId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment updated.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not update payment: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.fromName} \u2192 ${widget.toName}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Edit payment',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\u20b9 ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(),
            ),
            child: Text(DateFormat('d MMM yyyy').format(_date)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
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
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.check, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
