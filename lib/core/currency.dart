import 'package:intl/intl.dart';

final NumberFormat _rupeeFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20b9',
  decimalDigits: 2,
);

String formatMoney(int amountCents) {
  return _rupeeFormat.format(amountCents / 100);
}

int? parseAmountToCents(String input) {
  final cleaned = input.replaceAll(',', '').replaceAll(' ', '').trim();
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}