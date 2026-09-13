import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/category_icons.dart';
import '../../core/currency.dart';
import '../../widgets/icon_picker.dart';
import '../groups/models/member.dart';
import 'expenses_providers.dart';
import 'models/expense.dart';
import 'split_engine.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.members,
    this.expense,
  });

  final String groupId;
  final List<Member> members;
  final Expense? expense;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final Map<String, TextEditingController> _valueControllers = {};
  late Set<String> _selectedMemberIds;
  late String? _paidById;
  late DateTime _date;
  SplitType _splitType = SplitType.equal;
  String _icon = 'receipt_long';
  bool _saving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _paidById = widget.members.isEmpty ? null : widget.members.first.id;
    _selectedMemberIds = widget.members.map((m) => m.id).toSet();
    for (final member in widget.members) {
      _valueControllers[member.id] = TextEditingController();
    }

    final expense = widget.expense;
    if (expense != null) {
      _descriptionController.text = expense.description;
      _amountController.text = _centsToRupees(expense.amountCents);
      _date = expense.expenseDate;
      _paidById = expense.paidById;
      _icon = expense.icon;
      if (expense.splits.isNotEmpty) {
        _selectedMemberIds = expense.splits.map((s) => s.memberId).toSet();
        _splitType = SplitType.amounts;
        for (final split in expense.splits) {
          _valueControllers[split.memberId]?.text =
              _centsToRupees(split.amountCents);
        }
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Member? get _payer => widget.members
      .where((member) => member.id == _paidById)
      .cast<Member?>()
      .firstOrNull;

  String? _validateSplitInput() {
    final selectedIds = _selectedMemberIds.toList();
    if (selectedIds.isEmpty) return 'Select at least one person';
    switch (_splitType) {
      case SplitType.equal:
        return null;
      case SplitType.amounts:
        final sum = selectedIds.fold<int>(
          0,
          (sum, id) => sum + _amountValue(id),
        );
        final total = parseAmountToCents(_amountController.text);
        if (total != null && sum > total) {
          return 'Amounts add up to more than the expense total.';
        }
        return null;
      case SplitType.percentage:
        double totalPct = 0;
        for (final id in selectedIds) {
          totalPct += _percentValue(id);
        }
        if ((totalPct - 100).abs() > 0.01) {
          return 'Percentages must add up to 100.';
        }
        return null;
      case SplitType.shares:
        var totalShares = 0.0;
        for (final id in selectedIds) {
          totalShares += _shareValue(id);
        }
        if (totalShares <= 0) {
          return 'Enter shares greater than 0.';
        }
        return null;
    }
  }

  int _amountValue(String memberId) {
    final text = _valueControllers[memberId]?.text.trim() ?? '';
    if (text.isEmpty) return 0;
    final cleaned = text.replaceAll(',', '').replaceAll(' ', '');
    final parsed = double.tryParse(cleaned);
    return parsed == null || parsed <= 0 ? 0 : (parsed * 100).round();
  }

  double _percentValue(String memberId) {
    return double.tryParse(_valueControllers[memberId]?.text.trim() ?? '') ??
        0;
  }

  double _shareValue(String memberId) {
    return double.tryParse(_valueControllers[memberId]?.text.trim() ?? '') ??
        0;
  }

  String _centsToRupees(int cents) {
    final value = cents / 100;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  List<MemberSplit> _computeSplits() {
    final total = parseAmountToCents(_amountController.text);
    if (total == null) return const [];
    final selectedIds = _selectedMemberIds.toList();
    return SplitEngine.compute(
      type: _splitType,
      totalCents: total,
      payerId: _paidById ?? '',
      memberIds: selectedIds,
      amountCents: {
        for (final id in selectedIds)
          id: _amountValue(id),
      },
      percentages: {
        for (final id in selectedIds)
          id: _percentValue(id),
      },
      shares: {
        for (final id in selectedIds)
          id: _shareValue(id),
      },
    );
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
    if (!_formKey.currentState!.validate()) return;
    final splitError = _validateSplitInput();
    if (splitError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(splitError)),
      );
      return;
    }
    final total = parseAmountToCents(_amountController.text)!;
    final splits = _computeSplits();

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final expense = widget.expense;
      if (expense == null) {
        await ref.read(expensesRepositoryProvider).createExpense(
              groupId: widget.groupId,
              description: _descriptionController.text.trim(),
              amountCents: total,
              paidById: _paidById!,
              date: _date,
              splits: splits,
              icon: _icon,
            );
      } else {
        await ref.read(expensesRepositoryProvider).updateExpense(
              id: expense.id,
              groupId: widget.groupId,
              description: _descriptionController.text.trim(),
              amountCents: total,
              paidById: _paidById!,
              date: _date,
              splits: splits,
              icon: _icon,
            );
      }
      ref.invalidate(groupExpensesProvider(widget.groupId));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(expense == null ? 'Expense added.' : 'Expense updated.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Could not update expense: $error' : 'Could not add expense: $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = parseAmountToCents(_amountController.text);
    final splitError = _validateSplitInput();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit expense' : 'Add expense')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: const Text('Save'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Dinner at Mariott',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Transaction icon',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              IconPicker(
                options: expenseCategoryIcons,
                selectedKey: _icon,
                onChanged: (key) => setState(() => _icon = key),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total amount',
                        prefixText: '\u20b9 ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (parseAmountToCents(value ?? '') == null) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('d MMM yyyy').format(_date),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paidById,
                decoration: const InputDecoration(
                  labelText: 'Paid by',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: widget.members
                    .map(
                      (member) => DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _paidById = value),
              ),
              const SizedBox(height: 24),
              Text('Split between',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.members.map((member) {
                  final selected = _selectedMemberIds.contains(member.id);
                  return FilterChip(
                    label: Text(member.name),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedMemberIds.add(member.id);
                        } else {
                          _selectedMemberIds.remove(member.id);
                        }
                        if (_paidById == member.id && !value) {
                          _paidById =
                              _selectedMemberIds.isEmpty
                                  ? null
                                  : _selectedMemberIds.first;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Split type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<SplitType>(
                segments: SplitType.values
                    .map(
                      (type) => ButtonSegment(
                        value: type,
                        label: Text(type.label),
                        icon: Icon(_iconFor(type)),
                      ),
                    )
                    .toList(),
                selected: {_splitType},
                onSelectionChanged: (selection) {
                  setState(() => _splitType = selection.first);
                },
              ),
              if (_splitType != SplitType.equal) ...[
                const SizedBox(height: 16),
                ..._selectedMemberIds.map((id) {
                  final member =
                      widget.members.firstWhere((m) => m.id == id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _valueControllers[id],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: member.name,
                        suffixText: _splitType == SplitType.percentage
                            ? '%'
                            : _splitType == SplitType.shares
                            ? 'share'
                            : null,
                        prefixText:
                            _splitType == SplitType.amounts ? '\u20b9 ' : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              if (splitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    splitError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (total != null && splitError == null)
                _SplitPreview(
                  splits: _computeSplits(),
                  totalCents: total,
                  payerName: _payer?.name ?? '—',
                  memberName: (id) =>
                      widget.members.firstWhere((m) => m.id == id).name,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return Icons.call_split;
      case SplitType.amounts:
        return Icons.currency_rupee;
      case SplitType.percentage:
        return Icons.percent;
      case SplitType.shares:
        return Icons.equalizer;
    }
  }
}

class _SplitPreview extends StatelessWidget {
  const _SplitPreview({
    required this.splits,
    required this.totalCents,
    required this.payerName,
    required this.memberName,
  });

  final List<MemberSplit> splits;
  final int totalCents;
  final String payerName;
  final String Function(String memberId) memberName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split preview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...splits.map(
              (split) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(memberName(split.memberId)),
                    ),
                    Text(formatMoney(split.amountCents)),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(child: Text('Total')),
                Text(
                  formatMoney(totalCents),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Paid by $payerName',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}