import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Reminders {
  final plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<bool> initialize() async {
    if (!supported) {
      return false;
    }
    if (_ready) {
      return true;
    }
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Maputo'));
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    _ready = true;
    return true;
  }

  Future<bool> schedule(int id, String title, DateTime date) async {
    if (!await initialize()) {
      return false;
    }
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.requestNotificationsPermission() != true) {
      return false;
    }
    final time = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    );
    if (!time.isAfter(tz.TZDateTime.now(tz.local))) {
      return false;
    }
    await plugin.zonedSchedule(
      id,
      title,
      'Está na hora da sua acção planeada.',
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
