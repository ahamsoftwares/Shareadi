import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Join code that arrived via an invite link (shareadi://join?code=...).
/// Kept while the user is not signed in so the router can resume the join
/// right after login.
class PendingJoinCode extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? code) => state = code;
}

final pendingJoinCodeProvider =
    NotifierProvider<PendingJoinCode, String?>(PendingJoinCode.new);

/// Pulls the join code out of either a raw code or a full invite link.
String extractJoinCode(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';

  Uri? uri;
  try {
    uri = Uri.tryParse(trimmed);
  } catch (_) {}

  final hasCode = uri?.queryParameters['code']?.isNotEmpty ?? false;
  final isHttpsJoin = uri != null &&
      uri.scheme == 'https' &&
      hasCode;
  final isSchemeJoin =
      uri != null &&
      uri.host.toLowerCase() == 'join' &&
      hasCode;
  if (isHttpsJoin || isSchemeJoin) {
    final code = uri.queryParameters['code']?.trim().toUpperCase();
    return code ?? '';
  }
  return trimmed.toUpperCase();
}