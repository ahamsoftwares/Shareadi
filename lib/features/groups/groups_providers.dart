import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase.dart';
import 'groups_repository.dart';
import 'models/group.dart';
import 'models/member.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => GroupsRepository(ref.watch(supabaseClientProvider)),
);

final groupsListProvider = FutureProvider<List<Group>>(
  (ref) => ref.watch(groupsRepositoryProvider).fetchGroups(),
);

final groupDetailProvider = FutureProvider.family<Group, String>(
  (ref, groupId) => ref.watch(groupsRepositoryProvider).fetchGroup(groupId),
);

final groupMembersProvider = FutureProvider.family<List<Member>, String>(
  (ref, groupId) => ref.watch(groupsRepositoryProvider).fetchMembers(groupId),
);