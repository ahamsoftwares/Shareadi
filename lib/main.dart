import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_router.dart';
import 'core/constants.dart';
import 'core/deep_links.dart';
import 'core/supabase.dart';
import 'core/theme_provider.dart';
import 'features/expenses/expenses_providers.dart';
import 'features/groups/groups_providers.dart';
import 'features/setup/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    runApp(
      const ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SetupScreen(),
        ),
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
    );
  } catch (error) {
    runApp(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SetupScreen(error: 'Could not reach Supabase ($error)'),
        ),
      ),
    );
    return;
  }

  final initialThemeMode = await loadThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(initialThemeMode),
        ),
      ],
      child: ShareAdiApp(),
    ),
  );
}

class ShareAdiApp extends ConsumerStatefulWidget {
  const ShareAdiApp({super.key});

  @override
  ConsumerState<ShareAdiApp> createState() => _ShareAdiAppState();
}

class _ShareAdiAppState extends ConsumerState<ShareAdiApp> {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    final links = AppLinks();
    links.getInitialLink().then((uri) {
      if (uri != null) _handleJoinLink(uri);
    });
    _linkSub = links.uriLinkStream.listen(_handleJoinLink);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _handleJoinLink(Uri uri) {
    if (uri.scheme != 'shareadi' || uri.host != 'join') return;
    final code = uri.queryParameters['code'];
    if (code == null || code.trim().isEmpty) return;
    ref.read(pendingJoinCodeProvider.notifier).set(code.trim());
    // Re-run the router redirect so it picks up the pending invite link.
    ref.read(routerProvider).refresh();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateChangesProvider, (previous, next) {
      final prevUserId = previous?.value?.session?.user.id;
      final nextUserId = next.value?.session?.user.id;
      if (prevUserId != nextUserId) {
        ref.invalidate(groupsListProvider);
        ref.invalidate(groupDetailProvider);
        ref.invalidate(groupMembersProvider);
        ref.invalidate(groupExpensesProvider);
      }
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Share Adi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}