import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/payment.dart';

class SettlementRepository {
  SettlementRepository(this._client);

  final SupabaseClient _client;

  Future<List<Payment>> fetchPayments(String groupId) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('group_id', groupId)
        .order('paid_at', ascending: false)
        .order('created_at', ascending: false);
    return data.map(Payment.fromJson).toList();
  }

  Future<List<Payment>> fetchPaymentsForGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return const [];
    final data = await _client
        .from('payments')
        .select()
        .inFilter('group_id', groupIds);
    return data.map(Payment.fromJson).toList();
  }

  Future<void> addPayment({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountCents,
    String? note,
  }) async {
    await _client.from('payments').insert({
      'group_id': groupId,
      'from_member_id': fromMemberId,
      'to_member_id': toMemberId,
      'amount_cents': amountCents,
      'note': note?.isEmpty ?? true ? null : note,
      'paid_at': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> deletePayment(String paymentId) async {
    await _client.from('payments').delete().eq('id', paymentId);
  }

  Future<void> confirmPayment(String paymentId) async {
    await _client
        .from('payments')
        .update({'confirmed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', paymentId);
  }

  Future<void> updatePayment({
    required String paymentId,
    required int amountCents,
    String? note,
    required DateTime paidAt,
  }) async {
    await _client
        .from('payments')
        .update({
          'amount_cents': amountCents,
          'note': note?.isEmpty ?? true ? null : note,
          'paid_at': DateFormat('yyyy-MM-dd').format(paidAt),
        })
        .eq('id', paymentId);
  }
}