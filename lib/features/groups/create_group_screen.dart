import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/category_icons.dart';
import '../../widgets/icon_picker.dart';
import 'groups_providers.dart';
import 'models/group.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  GroupType _type = GroupType.travel;
  String _icon = 'travel_explore';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final group = await ref.read(groupsRepositoryProvider).createGroup(
            name: _nameController.text.trim(),
            type: _type,
            icon: _icon,
          );
      ref.invalidate(groupsListProvider);
      if (!mounted) return;
      context.pushReplacement('/group/${group.id}');
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not create group: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    hintText: 'e.g. Goa Trip 2026',
                    prefixIcon: Icon(Icons.groups_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a group name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Group type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<GroupType>(
                  segments: GroupType.values
                      .map(
                        (type) => ButtonSegment(
                          value: type,
                          label: Text(type.label),
                          icon: Icon(
                            type == GroupType.travel
                                ? Icons.flight_takeoff
                                : Icons.home_outlined,
                          ),
                        ),
                      )
                      .toList(),
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() => _type = selection.first);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Travel is for trips that end. House is for ongoing '
                  'monthly splitting with people you live with.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  'Group icon',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                IconPicker(
                  options: groupIcons,
                  selectedKey: _icon,
                  onChanged: (key) => setState(() => _icon = key),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}