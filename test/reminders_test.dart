import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/notifications/reminders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  late Reminders reminders;
  late DateTime now;
  late Future<Object?> Function(MethodCall) respond;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    now = DateTime.utc(2090, 1, 1, 6);
    reminders = Reminders(clock: () => now);
    calls.clear();
    respond = (_) async => true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return respond(call);
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });
  List<MethodCall> method(String name) =>
      calls.where((c) => c.method == name).toList();
  Map<dynamic, dynamic> scheduled() =>
      method('zonedSchedule').single.arguments as Map;

  test('civil Maputo date preserves time and uses an inexact alarm', () async {
    expect(
      await reminders.schedule(4, 'Consulta', DateTime(2090, 1, 1, 9, 15, 37)),
      isTrue,
    );
    expect(scheduled()['timeZoneName'], 'Africa/Maputo');
    expect(scheduled()['scheduledDateTime'], '2090-01-01T09:15:37');
    expect(
      (scheduled()['platformSpecifics'] as Map)['scheduleMode'],
      'inexactAllowWhileIdle',
    );
    expect(scheduled()['id'], 4);
    expect(scheduled()['title'], 'Consulta');
  });
  test('UTC and offset ISO inputs preserve their instant in Maputo', () async {
    await reminders.schedule(1, 'UTC', DateTime.utc(2090, 1, 1, 9, 15));
    expect(scheduled()['scheduledDateTime'], '2090-01-01T11:15:00');
    calls.clear();
    await reminders.schedule(
      2,
      'Offset',
      DateTime.parse('2090-01-01T09:15:00+02:00'),
    );
    expect(scheduled()['scheduledDateTime'], '2090-01-01T09:15:00');
  });
  test('past dates never request permission or schedule an alarm', () async {
    expect(
      await reminders.schedule(1, 'Passada', DateTime(2090, 1, 1, 7)),
      isFalse,
    );
    expect(method('requestNotificationsPermission'), isEmpty);
    expect(method('zonedSchedule'), isEmpty);
  });
  test('permission refused leaves no alarm and can be retried', () async {
    respond = (call) async => call.method != 'requestNotificationsPermission';
    expect(
      await reminders.schedule(1, 'Consulta', DateTime(2090, 1, 1, 9)),
      isFalse,
    );
    expect(method('zonedSchedule'), isEmpty);
    respond = (_) async => true;
    expect(
      await reminders.schedule(1, 'Consulta', DateTime(2090, 1, 1, 9)),
      isTrue,
    );
    expect(method('initialize'), hasLength(1));
  });
  test('due time can pass while the permission dialog is open', () async {
    respond = (call) async {
      if (call.method == 'requestNotificationsPermission') {
        now = DateTime.utc(2090, 1, 1, 8);
      }
      return true;
    };
    expect(
      await reminders.schedule(1, 'Passou', DateTime(2090, 1, 1, 9)),
      isFalse,
    );
    expect(method('zonedSchedule'), isEmpty);
  });
  test(
    'failed initialization is retryable and concurrent calls share it',
    () async {
      respond = (_) async => false;
      expect(await reminders.initialize(), isFalse);
      final ready = Completer<Object?>();
      respond = (_) => ready.future;
      final first = reminders.initialize();
      final second = reminders.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(method('initialize'), hasLength(2));
      ready.complete(true);
      expect(await Future.wait([first, second]), [true, true]);
      expect(await reminders.initialize(), isTrue);
      expect(method('initialize'), hasLength(2));
    },
  );
  test(
    'native failures propagate and cancellation never asks permission',
    () async {
      respond = (call) async {
        if (call.method == 'zonedSchedule') {
          throw PlatformException(code: 'alarm_error');
        }
        return true;
      };
      await expectLater(
        reminders.schedule(7, 'Consulta', DateTime(2090, 1, 1, 9)),
        throwsA(isA<PlatformException>()),
      );
      calls.clear();
      await reminders.cancel(7);
      await reminders.cancelAll();
      expect(calls.map((c) => c.method), ['cancel', 'cancelAll']);
      expect(method('cancel').single.arguments, containsPair('id', 7));
    },
  );
  test('unsupported platforms perform no native calls', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      await reminders.schedule(1, 'Consulta', DateTime(2090, 1, 1, 9)),
      isFalse,
    );
    await reminders.cancel(1);
    await reminders.cancelAll();
    expect(calls, isEmpty);
  });
}
