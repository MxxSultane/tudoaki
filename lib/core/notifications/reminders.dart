import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Reminders {
  Reminders({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<bool>? _initializing;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<bool> initialize() async {
    if (!supported) {
      return false;
    }
    if (_ready) {
      return true;
    }
    final pending = _initializing;
    if (pending != null) return pending;
    final initialization = _initialize();
    _initializing = initialization;
    try {
      return await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<bool> _initialize() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Maputo'));
    _ready =
        await plugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('ic_notification'),
          ),
        ) ==
        true;
    return _ready;
  }

  // Dates without an offset are civil Maputo time. UTC dates already denote
  // an instant and must not have their components reinterpreted as local time.
  tz.TZDateTime _scheduledTime(DateTime date) => date.isUtc
      ? tz.TZDateTime.from(date, tz.local)
      : tz.TZDateTime(
          tz.local,
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second,
          date.millisecond,
          date.microsecond,
        );

  Future<bool> schedule(int id, String title, DateTime date) async {
    if (!await initialize()) {
      return false;
    }
    final time = _scheduledTime(date);
    if (!time.isAfter(tz.TZDateTime.from(_clock(), tz.local))) return false;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.requestNotificationsPermission() != true) {
      return false;
    }
    // The permission dialog can remain open until the due time has passed.
    if (!time.isAfter(tz.TZDateTime.from(_clock(), tz.local))) return false;
    await plugin.zonedSchedule(
      id,
      title,
      'Está na hora da tua acção planeada.',
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks',
          'Tarefas',
          channelDescription: 'Lembretes de tarefas planeadas',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  Future<void> cancel(int id) async {
    if (await initialize()) {
      await plugin.cancel(id);
    }
  }

  Future<void> cancelAll() async {
    if (await initialize()) {
      await plugin.cancelAll();
    }
  }
}
