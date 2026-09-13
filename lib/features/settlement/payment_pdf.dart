import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/currency.dart';
import '../expenses/models/expense.dart';
import 'balance_engine.dart';
import 'models/payment.dart';

pw.ThemeData? _pdfTheme;

/// Roboto covers the rupee sign, minus sign and en dash used by the
/// statements; the bundled default PDF font does not.
Future<pw.ThemeData> _pdfFonts() async {
  if (_pdfTheme != null) return _pdfTheme!;
  final regular =
      (await rootBundle.load('assets/fonts/roboto-regular.ttf')).buffer;
  final bold =
      (await rootBundle.load('assets/fonts/roboto-bold.ttf')).buffer;
  _pdfTheme = pw.ThemeData.withFont(
    base: pw.Font.ttf(regular.asByteData()),
    bold: pw.Font.ttf(bold.asByteData()),
  );
  return _pdfTheme!;
}

pw.Widget _row(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(child: pw.Text(value)),
      ],
    ),
  );
}

Future<File> createPaymentPdf({
  required Payment payment,
  required String fromName,
  required String toName,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/share_adi_payment_${payment.id}.pdf',
  );

  final theme = await _pdfFonts();

  final document = pw.Document(theme: theme);
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Share Adi',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Payment receipt',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.Divider(height: 32),
          _row('Payment made by', fromName),
          _row('Payment received by', toName),
          _row('Amount', formatMoney(payment.amountCents)),
          _row('Date', DateFormat('d MMM yyyy').format(payment.paidAt)),
          if (payment.note?.isNotEmpty ?? false)
            _row('Note', payment.note!),
          _row(
            'Status',
            payment.isConfirmed
                ? 'Confirmed'
                : 'Pending confirmation',
          ),
        ],
      ),
    ),
  );

  await file.writeAsBytes(await document.save());
  return file;
}

class _TxnRow {
  const _TxnRow({
    required this.date,
    required this.description,
    required this.party,
    required this.amountCents,
    required this.status,
  });

  final DateTime date;
  final String description;
  final String party;
  final int amountCents;
  final String status;
}

pw.Widget _sectionTitle(String title) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 24),
      pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey700,
        ),
      ),
      pw.SizedBox(height: 8),
    ],
  );
}

pw.Widget _transactionsTable(List<_TxnRow> rows) {
  return pw.TableHelper.fromTextArray(
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    headers: ['Date', 'Description', 'Party', 'Amount', 'Status'],
    data: [
      for (final row in rows)
        [
          DateFormat('d MMM yyyy').format(row.date),
          row.description,
          row.party,
          formatMoney(row.amountCents),
          row.status,
        ],
    ],
    headerStyle: const pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    ),
    cellStyle: const pw.TextStyle(fontSize: 9),
    columnWidths: {
      0: const pw.FlexColumnWidth(1.6),
      1: const pw.FlexColumnWidth(2.6),
      2: const pw.FlexColumnWidth(2.2),
      3: const pw.FlexColumnWidth(1.6),
      4: const pw.FlexColumnWidth(1.2),
    },
  );
}

Future<File> createGroupStatementPdf({
  required String groupName,
  required List<Expense> expenses,
  required List<Payment> payments,
  required Map<String, String> memberName,
  String? currentMemberId,
  DateTime? from,
  DateTime? to,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/share_adi_statement_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );

  final periodLabel = (from == null && to == null)
      ? 'All time'
      : '${DateFormat('d MMM yyyy').format(from!)}'
          ' \u2013 ${DateFormat('d MMM yyyy').format(to!)}';

  final theme = await _pdfFonts();

  final expenseRows = [
    for (final expense in expenses)
      _TxnRow(
        date: expense.expenseDate,
        description: expense.description,
        party: '${memberName[expense.paidById] ?? '?'} paid',
        amountCents: expense.amountCents,
        status: 'Expense',
      ),
  ];

  final paymentRows = [
    for (final payment in payments)
      _TxnRow(
        date: payment.paidAt,
        description: (payment.note?.isNotEmpty ?? false)
            ? payment.note!
            : 'Settle-up',
        party: '${memberName[payment.fromMemberId] ?? '?'} -> '
            '${memberName[payment.toMemberId] ?? '?'}',
        amountCents: payment.amountCents,
        status: payment.isConfirmed ? 'Confirmed' : 'Pending',
      ),
  ];

  List<_TxnRow> allRows = [...expenseRows, ...paymentRows];
  allRows.sort((a, b) => a.date.compareTo(b.date));

  List<_TxnRow> yourRows = const [];
  if (currentMemberId != null) {
    yourRows = [
      for (final expense in expenses)
        if (expense.paidById == currentMemberId ||
            expense.splits.any((split) => split.memberId == currentMemberId))
          _TxnRow(
            date: expense.expenseDate,
            description: expense.description,
            party: expense.paidById == currentMemberId
                ? 'You paid'
                : '${memberName[expense.paidById] ?? '?'} paid'
                    ' (your share ${formatMoney(
                      expense.splits
                          .where((s) => s.memberId == currentMemberId)
                          .fold<int>(0, (sum, s) => sum + s.amountCents),
                    )})',
            amountCents: expense.amountCents,
            status: 'Expense',
          ),
      for (final payment in payments)
        if (payment.fromMemberId == currentMemberId ||
            payment.toMemberId == currentMemberId)
          _TxnRow(
            date: payment.paidAt,
            description: (payment.note?.isNotEmpty ?? false)
                ? payment.note!
                : 'Settle-up',
            party:
                '${payment.fromMemberId == currentMemberId ? 'You' : memberName[payment.fromMemberId] ?? '?'} '
                '-> '
                '${payment.toMemberId == currentMemberId ? 'You' : memberName[payment.toMemberId] ?? '?'}',
            amountCents: payment.amountCents,
            status: payment.isConfirmed ? 'Confirmed' : 'Pending',
          ),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  // ---- Calculation details (matches the in-app balance engine) ----
  final paidByMember = <String, int>{};
  final shareByMember = <String, int>{};
  for (final expense in expenses) {
    paidByMember[expense.paidById] =
        (paidByMember[expense.paidById] ?? 0) + expense.amountCents;
    for (final split in expense.splits) {
      shareByMember[split.memberId] =
          (shareByMember[split.memberId] ?? 0) + split.amountCents;
    }
  }
  final paidOutByMember = <String, int>{};
  final receivedByMember = <String, int>{};
  final confirmedPayments = payments.where((payment) => payment.isConfirmed);
  for (final payment in confirmedPayments) {
    paidOutByMember[payment.fromMemberId] =
        (paidOutByMember[payment.fromMemberId] ?? 0) + payment.amountCents;
    receivedByMember[payment.toMemberId] =
        (receivedByMember[payment.toMemberId] ?? 0) + payment.amountCents;
  }
  final net = <String, int>{
    for (final memberId in memberName.keys)
      memberId:
          (paidByMember[memberId] ?? 0) -
              (shareByMember[memberId] ?? 0) +
              (paidOutByMember[memberId] ?? 0) -
              (receivedByMember[memberId] ?? 0),
  };
  final debts = BalanceEngine.simplify(net);

  final memberIds = memberName.keys.toList()
    ..sort((a, b) => (memberName[a] ?? '').compareTo(memberName[b] ?? ''));

  final totalSpentCents = expenses.fold<int>(
    0,
    (sum, expense) => sum + expense.amountCents,
  );
  int? paidCents;
  int? shareCents;
  if (currentMemberId != null) {
    paidCents = expenses
        .where((expense) => expense.paidById == currentMemberId)
        .fold<int>(0, (sum, expense) => sum + expense.amountCents);
    var myShare = 0;
    for (final expense in expenses) {
      final split = expense.splits
          .where((split) => split.memberId == currentMemberId)
          .fold<int>(0, (sum, s) => sum + s.amountCents);
      if (split > 0) {
        myShare += split;
      } else if (expense.splits.isEmpty && memberName.isNotEmpty) {
        myShare += expense.amountCents ~/ memberName.length;
      }
    }
    shareCents = myShare;
  }

  final document = pw.Document(theme: theme);
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Share Adi',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Statement of accounts',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
      build: (context) => [
        pw.SizedBox(height: 16),
          _row('Group', groupName),
          _row('Period', periodLabel),
          pw.SizedBox(height: 8),
          pw.Text(
            '${expenses.length} expenses \u00b7 '
            '${payments.length} payments',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Divider(height: 24),
          if (totalSpentCents > 0) ...[
            pw.SizedBox(height: 8),
            _row('Group total spent', formatMoney(totalSpentCents)),
            if (currentMemberId != null) ...[
              _row('You paid', formatMoney(paidCents!)),
              _row('Your expenditure', formatMoney(shareCents!)),
            ],
          ],
          pw.Divider(height: 24),
          if (allRows.isEmpty)
            pw.Text('No transactions in this period.')
          else ...[
            _sectionTitle('All transactions'),
            _transactionsTable(allRows),
          ],
          if (yourRows.isNotEmpty) ...[
            _sectionTitle('Your transactions'),
            _transactionsTable(yourRows),
          ],
          _sectionTitle('Calculation details'),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: [
              'Member',
              'Paid',
              'Share',
              'Paid out',
              'Received',
              'Net',
            ],
            data: [
              for (final memberId in memberIds)
                [
                  memberName[memberId] ?? '?',
                  formatMoney(paidByMember[memberId] ?? 0),
                  formatMoney(shareByMember[memberId] ?? 0),
                  formatMoney(paidOutByMember[memberId] ?? 0),
                  formatMoney(receivedByMember[memberId] ?? 0),
                  formatMoney(net[memberId] ?? 0),
                ],
            ],
            headerStyle: const pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.2),
            },
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Settle up plan',
            style: const pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (debts.isEmpty)
            pw.Text(
              'All settled up.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            for (final debt in debts)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${memberName[debt.fromMemberId] ?? '?'} pays '
                        '${memberName[debt.toMemberId] ?? '?'}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      formatMoney(debt.amountCents),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Net = Paid \u2212 Share + Paid out \u2212 Received. '
            'Positive means the member gets this back, negative means '
            'they owe it. Balances use the expenses and confirmed '
            'payments in this period.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
      ],
    ),
  );

  await file.writeAsBytes(await document.save());
  return file;
}