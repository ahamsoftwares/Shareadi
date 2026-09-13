import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import 'models/group.dart';

/// HTTPS landing page that hands the browser off to the real
/// shareadi://join?code=... deep link. WhatsApp only linkifies http(s)
/// links, so the page URL is what gets shared. The page is a static file
/// (supabase/join.html) hosted on GitHub Pages, because Supabase Storage
/// and Edge Functions force text/plain + a sandbox CSP on HTML.
String buildInviteLink(Group group) =>
    '${AppConfig.joinLandingUrl}?code=${group.joinCode}';

const String kPlayStoreLink =
    'https://play.google.com/store/apps/details?id=com.shareadi.share_adi'
    '&pcampaignid=web_share';

String buildInviteMessage(Group group) {
  return 'Join my group "${group.name}" on Share Adi.\n'
      'Tap this link to open the group: ${buildInviteLink(group)}\n'
      'Do not have the app? Get it here: $kPlayStoreLink\n'
      'Then open Share Adi, tap "Join a group", and enter the code '
      '${group.joinCode}.';
}

Future<bool> shareViaWhatsApp(BuildContext context, Group group) async {
  final message = Uri.encodeComponent(buildInviteMessage(group));
  final isIos = Theme.of(context).platform == TargetPlatform.iOS;
  final uri = isIos
      ? Uri.parse('https://wa.me/?text=$message')
      : Uri.parse('whatsapp://send?text=$message');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> shareViaEmail(
  BuildContext context,
  Group group, {
  String? email,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email ?? '',
    queryParameters: {
      'subject': 'Join my group "${group.name}" on Share Adi',
      'body': buildInviteMessage(group),
    },
  );
  return launchUrl(uri);
}

Future<void> shareViaOtherApps(Group group) async {
  await SharePlus.instance.share(
    ShareParams(text: buildInviteMessage(group)),
  );
}