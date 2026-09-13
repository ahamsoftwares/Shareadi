import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase.dart';

class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
    );
  }
}

final currentProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  ref.watch(authStateChangesProvider);
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  Map<String, dynamic>? row;
  try {
    row = await client
        .from('profiles')
        .select('id, name, email')
        .eq('id', user.id)
        .maybeSingle();
  } catch (_) {
    row = null;
  }

  if (row == null) return null;
  final profile = Profile.fromJson(row);
  if (profile.name.isEmpty) {
    final metadataName = user.userMetadata?['full_name'] as String?;
    return Profile(
      id: profile.id,
      name: metadataName ?? '',
      email: profile.email ?? user.email,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }
  return Profile(
    id: profile.id,
    name: profile.name,
    email: profile.email ?? user.email,
    avatarUrl: user.userMetadata?['avatar_url'] as String?,
  );
});