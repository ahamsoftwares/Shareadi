import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/group.dart';
import 'models/member.dart';

class GroupNotFoundException implements Exception {
  const GroupNotFoundException();

  @override
  String toString() => 'That join code is not valid.';
}

class GroupsRepository {
  GroupsRepository(this._client);

  final SupabaseClient _client;

  String generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<List<Group>> fetchGroups() async {
    final data = await _client
        .from('groups')
        .select('*, members(count)')
        .order('created_at', ascending: false);
    return data.map(Group.fromJson).toList();
  }

  Future<Group> fetchGroup(String groupId) async {
    final data = await _client
        .from('groups')
        .select('*, members(count)')
        .eq('id', groupId)
        .single();
    return Group.fromJson(data);
  }

  Future<Group> createGroup({
    required String name,
    required GroupType type,
    String icon = 'groups',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Not signed in');
    }
    final data = await _client
        .from('groups')
        .insert({
          'name': name,
          'type': type.storageValue,
          'join_code': generateJoinCode(),
          'created_by': user.id,
          'icon': icon,
        })
        .select()
        .single();

    await _client.from('members').insert({
      'group_id': data['id'],
      'name': user.userMetadata?['full_name'] ?? user.email,
      'email': user.email,
      'profile_id': user.id,
    });

    return Group.fromJson(data);
  }

  Future<List<Member>> fetchMembers(String groupId) async {
    final data = await _client
        .from('members')
        .select()
        .eq('group_id', groupId)
        .order('joined_at');
    return data.map(Member.fromJson).toList();
  }

  Future<void> addMember({
    required String groupId,
    required String name,
    String? email,
  }) async {
    await _client.from('members').insert({
      'group_id': groupId,
      'name': name,
      'email': email?.isEmpty ?? true ? null : email,
    });
  }

  Future<void> setMemberUpi({
    required String memberId,
    required String? upiId,
  }) async {
    await _client
        .from('members')
        .update({'upi_id': upiId})
        .eq('id', memberId);
  }

  Future<void> renameMember({
    required String memberId,
    required String name,
  }) async {
    await _client.rpc('rename_member', params: {
      'mid': memberId,
      'new_name': name.trim(),
    });
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    required String icon,
  }) async {
    await _client.rpc('update_group', params: {
      'gid': groupId,
      'new_name': name.trim(),
      'new_icon': icon,
    });
  }

  Future<Map<String, dynamic>?> inviteByEmail({
    required String groupId,
    required String email,
  }) async {
    return _client.from('invites').insert({
      'group_id': groupId,
      'email': email,
      'created_by': _client.auth.currentUser?.id,
    }).maybeSingle();
  }

  Future<Group> joinWithCode(String code) async {
    final data = await _client.rpc(
      'join_group_by_code',
      params: {'p_code': code.trim()},
    );
    final row = data is List<dynamic>
        ? (data.isEmpty ? throw const GroupNotFoundException() : data.first)
        : data;
    return Group.fromJson(row as Map<String, dynamic>);
  }

  Future<void> leaveGroup(String groupId) async {
    await _client.rpc('leave_group', params: {'p_gid': groupId});
  }
}