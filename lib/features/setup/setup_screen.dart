import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, this.error});

  final String? error;

  Future<void> _copyCommand(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _runCommand));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Run command copied.')),
    );
  }

  static const _runCommand =
      'flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co '
      '--dart-define=SUPABASE_KEY=your-publishable-key';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = AppConfig.supabaseUrl;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Supabase is not connected',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your Supabase project URL and publishable key when '
                    'running the app so it can reach the backend.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (error == null) Text('Configured URL: $url'),
                  if (error == null) const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _copyCommand(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy run command'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Create a project at supabase.com\n'
                    '2. Run supabase/migrations/0001 and 0002 in SQL Editor\n'
                    '3. Replace the URL and key above with yours',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}