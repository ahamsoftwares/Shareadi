class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hymwdxwrzxhlkdxyehlo.supabase.co',
  );
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_QWcsJojtFcxxZvp5NxQarQ_1DCAzRys',
  );

  /// HTTPS landing page that WhatsApp can link to (it only linkifies
  /// http(s) URLs) and that hands the browser off to the shareadi://join
  /// deep link. Hosted as `index.html` on GitHub Pages
  /// (git@github.com:USERNAME/shareadi), because Supabase Storage and
  /// Edge Functions refuse to serve interactive HTML.
  static const String joinLandingUrl = String.fromEnvironment(
    'JOIN_LANDING_URL',
    defaultValue: 'https://ahamsoftwares.github.io/Shareadi/join.html',
  );

  static const String deepLinkRedirect = 'shareadi://login/';

  static bool get isConfigured =>
      !supabaseUrl.startsWith('https://your-project') &&
      !supabaseKey.startsWith('your-publishable-key');
}