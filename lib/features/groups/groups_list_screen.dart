import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/category_icons.dart';
import '../../core/supabase.dart';
import '../../core/theme_provider.dart';
import '../auth/auth_repository.dart';
import '../profile/profile_providers.dart';
import '../reminders/reminders_providers.dart';
import 'groups_providers.dart';
import 'models/group.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    _initReminders();
  }

  Future<void> _initReminders() async {
    final service = ref.read(reminderServiceProvider);
    try {
      await service.initialize();
      await service.requestPermissions();
    } catch (_) {
      // Reminder scheduling is best-effort; never block the groups screen.
    }
  }

  Future<void> _updateReminder(
    AsyncValue<int>? previous,
    AsyncValue<int> next,
  ) async {
    final count = next.value;
    if (count == null) return;
    final service = ref.read(reminderServiceProvider);
    try {
      if (count == 0) {
        await service.cancelScheduledReminder();
      } else {
        await service.scheduleMonthlyReminder(unsettledGroupCount: count);
      }
    } catch (_) {
      // Best-effort; ignore scheduling failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsListProvider);
    ref.listen(unsettledGroupCountProvider, _updateReminder);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Adi'),
        actions: [
          _ThemeMenu(),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'signout') {
                await ref
                    .read(reminderServiceProvider)
                    .cancelScheduledReminder();
                await ref.read(supabaseClientProvider).auth.signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-group'),
        icon: const Icon(Icons.add),
        label: const Text('New group'),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(groupsListProvider),
        ),
        data: (groups) => Column(
          children: [
            const _ProfileHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(groupsListProvider);
                  await ref.read(groupsListProvider.future);
                },
                child: groups.isEmpty
                    ? _EmptyView(
                        onJoin: () => context.push('/join'),
                        onCreate: () => context.push('/create-group'),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          88 + MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: groups.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const _JoinGroupTile();
                          }
                          return _GroupCard(group: groups[index - 1]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    final profile = ref.watch(currentProfileProvider).value;

    final name = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : (user?.userMetadata?['full_name'] as String?) ?? '';
    final email = profile?.email ?? user?.email;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final displayName = name.isNotEmpty
        ? name
        : (email == null ? 'Account' : email.split('@').first);

    final initial = displayName.isEmpty ? '?' : displayName[0].toUpperCase();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundImage: avatarUrl == null
              ? null
              : NetworkImage(avatarUrl),
          child: Text(
            initial,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: email == null
            ? null
            : Text(
                email,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Icon(
          Icons.edit_outlined,
          color: theme.colorScheme.outline,
        ),
        onTap: () async {
          final newName = await showDialog<String>(
            context: context,
            builder: (context) => _EditProfileNameDialog(initial: displayName),
          );
          if (newName != null && context.mounted) {
            ref.invalidate(currentProfileProvider);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Name updated to $newName')),
              );
          }
        },
      ),
    );
  }
}

class _EditProfileNameDialog extends ConsumerStatefulWidget {
  const _EditProfileNameDialog({required this.initial});

  final String initial;

  @override
  ConsumerState<_EditProfileNameDialog> createState() =>
      _EditProfileNameDialogState();
}

class _EditProfileNameDialogState
    extends ConsumerState<_EditProfileNameDialog> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfileName(name);
      if (mounted) Navigator.of(context).pop(name);
    } catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Could not save name: $error')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 50,
        decoration: const InputDecoration(
          labelText: 'Your name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _save,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            groupIconFromKey(group.icon),
            color: scheme.onPrimaryContainer,
            size: 22,
          ),
        ),
        title: Text(group.name),
        subtitle: Text(
          '${group.type.label} \u00b7 ${group.memberCount} '
          '${group.memberCount == 1 ? 'member' : 'members'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/group/${group.id}'),
      ),
    );
  }
}

class _ThemeMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      icon: Icon(
        themeMode == ThemeMode.dark
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
      ),
      onSelected: (mode) =>
          ref.read(themeModeProvider.notifier).setMode(mode),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.light,
          child: ListTile(
            leading: const Icon(Icons.light_mode_outlined),
            title: const Text('Light theme'),
            trailing: themeMode == ThemeMode.light
                ? const Icon(Icons.check)
                : null,
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark theme'),
            trailing: themeMode == ThemeMode.dark
                ? const Icon(Icons.check)
                : null,
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: ListTile(
            leading: const Icon(Icons.settings_brightness_outlined),
            title: const Text('System theme'),
            trailing: themeMode == ThemeMode.system
                ? const Icon(Icons.check)
                : null,
          ),
        ),
      ],
    );
  }
}

class _JoinGroupTile extends StatelessWidget {
  const _JoinGroupTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.group_add_outlined),
        title: const Text('Join a group'),
        subtitle: const Text('Enter a join code to get started'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/join'),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onJoin, required this.onCreate});

  final VoidCallback onJoin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group for a trip, a flat, or anything else.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create a group'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onJoin,
              child: const Text('Join with a code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}