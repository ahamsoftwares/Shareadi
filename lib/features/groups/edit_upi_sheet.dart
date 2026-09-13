import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'groups_providers.dart';
import 'models/member.dart';

class EditUpiSheet extends ConsumerStatefulWidget {
  const EditUpiSheet({super.key, required this.groupId, required this.ownMember});

  final String groupId;
  final Member ownMember;

  @override
  ConsumerState<EditUpiSheet> createState() => _EditUpiSheetState();
}

class _EditUpiSheetState extends ConsumerState<EditUpiSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.ownMember.upiId ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final upi = _controller.text.trim();
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (upi != (widget.ownMember.upiId ?? '')) {
        await ref
            .read(groupsRepositoryProvider)
            .setMemberUpi(
              memberId: widget.ownMember.id,
              upiId: upi.isEmpty ? null : upi,
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(groupMembersProvider(widget.groupId));
      messenger.showSnackBar(
        const SnackBar(content: Text('UPI handle saved.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save UPI handle: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your UPI handle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'You will receive settle-up payments at this handle.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'name@upi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}