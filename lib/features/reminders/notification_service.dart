import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderNotificationService {
  ReminderNotificationService._();

  factory ReminderNotificationService() => _instance;

  static final ReminderNotificationService _instance =
      ReminderNotificationService._();

  static const int _monthEndNotificationId = 5011;
  static const int _reminderDayOfMonth = 1;
  static const int _reminderHour = 18;
  static const int _reminderMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (kIsWeb) return false;
    if (_initialized) return true;
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Fall back to the default (UTC) location if the device timezone
      // cannot be resolved.
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    _initialized = await _plugin.initialize(settings: settings) ?? false;
    return _initialized;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a recurring notification on the [1st] of every month.
  ///
  /// The notification is re-scheduled (with fresh text) every time the app
  /// is opened and there are unsettled groups, so the copy stays current.
  Future<void> scheduleMonthlyReminder({
    required int unsettledGroupCount,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      _reminderDayOfMonth,
      _reminderHour,
      _reminderMinute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year + (now.month == 12 ? 1 : 0),
        now.month == 12 ? 1 : now.month + 1,
        _reminderDayOfMonth,
        _reminderHour,
        _reminderMinute,
      );
    }

    final title = unsettledGroupCount == 1
        ? '1 group is not settled up'
        : '$unsettledGroupCount groups are not settled up';
    const body = 'A new month starts today. Open Share Adi and settle last '
        "month's balances.";

    await _plugin.zonedSchedule(
      id: _monthEndNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'month_end_reminders',
          'Month-end reminders',
          channelDescription:
              'Reminders to settle up groups that still have outstanding '
              'balances',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> cancelScheduledReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(id: _monthEndNotificationId);
  }
}