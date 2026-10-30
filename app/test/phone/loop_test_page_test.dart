// 触发测试 page (lib/ui/phone/loop_test_page.dart) over a fake `dsh/loop` channel,
// plus the wire parsing in lib/loop/loop_channel.dart.

import 'package:dsh_app/loop/loop_channel.dart';
import 'package:dsh_app/ui/phone/loop_test_page.dart';
import 'package:dsh_app/ui/phone/phone_control_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

class FakeLoopNative {
  Map<String, Object?> config = {'enabled': false, 'targetPackage': null, 'cooldownMs': 60000, 'timeoutMs': 60000};
  List<Map<String, Object?>> events = [];
  final calls = <MethodCall>[];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dsh/loop'),
      (call) async {
        calls.add(call);
        switch (call.method) {
          case 'status':
            return {
              'config': config,
              'a11yEnabled': true,
              'a11yConnected': true,
              'eventsSeen': 12,
              'readings': 3,
              'lastForeground': 'com.example.test',
              'storageError': null,
              'insideTarget': false,
            };
          case 'setConfig':
            final args = (call.arguments as Map).cast<String, Object?>();
            config = {...config, ...args};
            return config;
          case 'events':
            return events;
          case 'clearEvents':
            events = [];
            return true;
          case 'apps':
            return [
              {'package': 'com.example.test', 'label': '测试应用'},
              {'package': 'com.example.other', 'label': '别的应用'},
            ];
        }
        return null;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dsh/loop'),
        null,
      ),
    );
  }

  List<Object?> argsOf(String method) => [for (final c in calls) if (c.method == method) c.arguments];
}

Map<String, Object?> receipt(String id, String? result, {String state = 'CLOSED', String? reason}) => {
  'eventId': id,
  'source': 'A11Y_WINDOW',
  'timestamp': DateTime(2026, 10, 30, 9, 15).millisecondsSinceEpoch,
  'state': state,
  'result': result,
  'error': null,
  'reason': reason,
  'packageName': 'com.example.test',
  'visitId': 'v-$id',
  'surface': 'activity',
  'updatedAt': DateTime(2026, 10, 30, 9, 16).millisecondsSinceEpoch,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('wire', () {
    test('a receipt carries the shared event fields', () {
      final e = LoopEvent.fromWire(receipt('a', 'RETURNED'))!;
      expect(e.eventId, 'a');
      expect(e.source, 'A11Y_WINDOW');
      expect(e.state, 'CLOSED');
      expect(e.result, 'RETURNED');
      expect(e.timestamp, DateTime(2026, 10, 30, 9, 15));
      expect(LoopEvent.fromWire({'eventId': 'x'}), isNull);
      expect(LoopEvent.fromWire('nope'), isNull);
    });

    test('status survives missing and odd fields', () {
      final s = LoopStatus.fromWire({'config': {'enabled': true, 'cooldownMs': 10000.0}, 'eventsSeen': 'x'});
      expect(s.config.enabled, isTrue);
      expect(s.config.cooldownMs, 10000);
      expect(s.config.targetPackage, isNull);
      expect(s.eventsSeen, 0);
      expect(LoopStatus.fromWire(null).a11yConnected, isFalse);
    });
  });

  group('page', () {
    testWidgets('shows status and receipts, newest first', (tester) async {
      final native = FakeLoopNative()
        ..events = [receipt('b', null, state: 'SHOWN'), receipt('a', 'SUPPRESSED', reason: 'cooldown')]
        ..install();
      await pumpPhone(tester, const LoopTestPage());
      expect(find.text('无障碍服务已连接'), findsOneWidget);
      expect(find.text('进行中'), findsOneWidget);
      expect(find.text('未触发'), findsOneWidget);
      expect(find.textContaining('cooldown'), findsOneWidget);
      expect(native.argsOf('events').single, {'limit': 100});
    });

    testWidgets('switch, app picker and cooldown write config', (tester) async {
      final native = FakeLoopNative()..install();
      await pumpPhone(tester, const LoopTestPage());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(native.argsOf('setConfig').last, {'enabled': true});

      await tester.tap(find.text('测试 APP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('测试应用'));
      await tester.pumpAndSettle();
      expect(native.argsOf('setConfig').last, {'targetPackage': 'com.example.test'});
      expect(find.textContaining('com.example.test'), findsWidgets);

      await tester.tap(find.text('冷却时间'));
      await tester.pumpAndSettle();
      expect(native.argsOf('setConfig').last, {'cooldownMs': 300000});
      expect(find.text('300 秒'), findsOneWidget);
    });

    testWidgets('clearing receipts empties the list', (tester) async {
      final native = FakeLoopNative()
        ..events = [receipt('a', 'RETURNED')]
        ..install();
      await pumpPhone(tester, const LoopTestPage());
      expect(find.text('点了返回'), findsOneWidget);
      await tester.tap(find.text('清空回执'));
      await tester.pumpAndSettle();
      expect(native.argsOf('clearEvents'), hasLength(1));
      expect(find.text('还没有回执'), findsOneWidget);
    });

    testWidgets('phone control links to it', (tester) async {
      FakeLoopNative().install();
      await pumpPhone(tester, const PhoneControlScreen());
      await tester.scrollUntilVisible(find.text('触发测试'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('触发测试'));
      await tester.pumpAndSettle();
      expect(find.byType(LoopTestPage), findsOneWidget);
    });
  });
}
