import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'groups_providers.dart';
import 'models/group.dart';
import 'share_service.dart';

class InviteMembersSheet extends ConsumerStatefulWidget {
  const InviteMembersSheet({super.key, required this.group});

  final Group group;

  @override
  ConsumerState<InviteMembersSheet> createState() => _InviteMembersSheetState();
}

class _InviteMembersSheetState extends ConsumerState<InviteMembersSheet> {
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _copyCode() async {
    final group = widget.group;
    await Clipboard.setData(ClipboardData(text: group.joinCode));
    _showMessage('Join code ${group.joinCode} copied.');
  }

  Future<void> _copyLink() async {
    final group = widget.group;
    await Clipboard.setData(ClipboardData(text: buildInviteLink(group)));
    _showMessage('Invite link copied.');
  }

  Future<void> _sendEmailInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Enter a valid email address.');
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(groupsRepositoryProvider)
          .inviteByEmail(groupId: widget.group.id, email: email);
      if (!mounted) return;
      final opened = await shareViaEmail(context, widget.group, email: email);
      if (!mounted) return;
      _showMessage(
        opened ? 'Invite sent to $email.' : 'Copy the message and send it.',
      );
    } catch (error) {
      _showMessage('Could not send invite: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final launched = await shareViaWhatsApp(context, widget.group);
    if (!launched) {
      _showMessage('WhatsApp is not installed on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invite to "${group.name}"',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              leading: const Icon(Icons.qr_code_2),
              title: Text(
                group.joinCode,
                style: theme.textTheme.titleMedium?.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text('Join code'),
              trailing: TextButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _copyLink,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Copy invite link'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Invite by email',
                hintText: 'friend@example.com',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendEmailInvite(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _sending ? null : _sendEmailInvite,
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send invite'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => shareViaOtherApps(group),
                    icon: const Icon(Icons.share),
                    label: const Text('More'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}