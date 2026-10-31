// D3: 设置 → 手机操控 → 主动搭话 over a fake `dsh/proactive` channel.

import 'package:dsh_app/proactive/proactive_state.dart';
import 'package:dsh_app/ui/phone/phone_control_screen.dart';
import 'package:dsh_app/ui/phone/proactive_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

class FakeProactiveNative {
  Map<String, Object?> config = {
    'enabled': false,
    'minIntervalMs': 45 * 60000,
    'maxIntervalMs': 180 * 60000,
    'quietStartMinute': 23 * 60,
    'quietEndMinute': 8 * 60,
    'dailyMax': 6,
    'pauseAfterIgnored': 3,
  };
  String? hold;
  String wakeMode = 'EXACT';
  bool transport = true;
  int queued = 0;
  String? storageError;
  String? recoveryIssue;
  String? activeStage;
  List<Map<String, Object?>> receipts = [];
  final calls = <MethodCall>[];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dsh/proactive'),
      (call) async {
        calls.add(call);
        switch (call.method) {
          case 'status':
            return {
              'config': config,
              'gate': {'hold': hold, 'surface': null},
              'wakeMode': wakeMode,
              'alarmError': null,
              'transport': transport,
              'queued': queued,
              'storageError': storageError,
              'recoveryIssue': recoveryIssue,
              'active': activeStage == null ? null : {'stage': activeStage},
            };
          case 'setConfig':
            config = {...config, ...(call.arguments as Map).cast<String, Object?>()};
            return config;
          case 'receipts':
            return receipts;
        }
        return null;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dsh/proactive'),
        null,
      ),
    );
  }

  List<Object?> argsOf(String method) => [for (final c in calls) if (c.method == method) c.arguments];
}

Map<String, Object?> receipt({
  String id = 'e1',
  String stage = 'CLOSED',
  String? outcome = 'RESPONDED',
  String? surface = 'activity',
  int? deliveredAt,
  int? shownAt,
}) => {
  'request': {
    'eventId': id,
    'source': 'SCHEDULER',
    'kind': 'random_chat',
    'dedupeKey': 'k',
    'createdAt': DateTime(2026, 10, 30, 9).millisecondsSinceEpoch,
  },
  'stage': stage,
  'outcome': outcome,
  'reason': null,
  'content': {'text': 'hi', 'source': 'AGENT'},
  'surface': surface,
  'deliveredAt': deliveredAt,
  'shownAt': shownAt,
  'respondedAt': shownAt,
  'closedAt': DateTime(2026, 10, 30, 9, 5).millisecondsSinceEpoch,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('wire', () {
    test('a receipt keeps the six moments apart', () {
      final r = ProactiveReceipt.fromWire(receipt(deliveredAt: 1000, shownAt: 2000))!;
      expect(r.eventId, 'e1');
      expect(r.kind, 'random_chat');
      expect(r.outcome, 'RESPONDED');
      expect(r.deliveredAt!.millisecondsSinceEpoch, 1000);
      expect(r.shownAt!.millisecondsSinceEpoch, 2000);
      expect(ProactiveReceipt.fromWire({'stage': 'CLOSED'}), isNull);
      expect(ProactiveReceipt.fromWire('nope'), isNull);
    });

    test('status survives missing and odd fields', () {
      final s = ProactiveStatus.fromWire({
        'config': {'enabled': true, 'dailyMax': 3.0},
        'gate': {'hold': 'dsh_task'},
        'wakeMode': 'OPPORTUNISTIC',
      });
      expect(s.config.enabled, isTrue);
      expect(s.config.dailyMax, 3);
      expect(s.holdReason, 'dsh_task');
      expect(s.wakeRestricted, isTrue);
      expect(ProactiveStatus.fromWire(null).transport, isFalse);
    });
  });

  group('page', () {
    testWidgets('shows the state, the honest wake warning and the receipts', (tester) async {
      final native = FakeProactiveNative()
        ..hold = 'dsh_task'
        ..wakeMode = 'OPPORTUNISTIC'
        ..queued = 2
        ..receipts = [receipt()];
      native.install();
      await pumpPhone(tester, const ProactivePage());
      expect(find.text('主动搭话'), findsWidgets);
      // The hold line reads "正在让路：DSH 正在操作手机"; the hint above it says the same words, so
      // match the composed line rather than the fragment.
      expect(find.textContaining('正在让路：DSH 正在操作手机'), findsOneWidget);
      expect(find.textContaining('限制了后台唤醒'), findsOneWidget);
      expect(find.text('你回应了'), findsWidgets);
      expect(find.textContaining('排队中：2 条'), findsOneWidget);
    });

    testWidgets('the switch, gaps, quiet hours and daily limit write config', (tester) async {
      final native = FakeProactiveNative()..install();
      await pumpPhone(tester, const ProactivePage());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(native.argsOf('setConfig').last, containsPair('enabled', true));

      await tester.tap(find.text('最短间隔'));
      await tester.pumpAndSettle();
      // 45 min is on the ladder, so the next tap goes to 60.
      expect(native.argsOf('setConfig').last, containsPair('minIntervalMs', 60 * 60000));

      await tester.tap(find.text('最长间隔'));
      await tester.pumpAndSettle();
      expect(native.argsOf('setConfig').last, containsPair('maxIntervalMs', 240 * 60000));

      await tester.tap(find.text('免打扰时段'));
      await tester.pumpAndSettle();
      // 23:00–08:00 is the first preset, so the next tap is 22:00–08:00.
      expect(native.argsOf('setConfig').last, containsPair('quietStartMinute', 22 * 60));

      await tester.tap(find.text('每天上限'));
      await tester.pumpAndSettle();
      // 6 → 10.
      expect(native.argsOf('setConfig').last, containsPair('dailyMax', 10));
    });

    testWidgets('the gaps can never cross', (tester) async {
      final native = FakeProactiveNative()
        ..config = {
          ...FakeProactiveNative().config,
          'minIntervalMs': 60 * 60000,
          'maxIntervalMs': 60 * 60000,
        }
        ..install();
      await pumpPhone(tester, const ProactivePage());
      // Growing the minimum past the maximum lifts the maximum with it.
      await tester.tap(find.text('最短间隔'));
      await tester.pumpAndSettle();
      final sent = native.argsOf('setConfig').last as Map;
      expect((sent['minIntervalMs'] as int) <= (sent['maxIntervalMs'] as int), isTrue);
    });

    testWidgets('a missing transport is stated instead of pretending', (tester) async {
      FakeProactiveNative()
        ..transport = false
        ..install();
      await pumpPhone(tester, const ProactivePage());
      expect(find.textContaining('还没连上引擎'), findsOneWidget);
    });

    testWidgets('a damaged kernel state is surfaced', (tester) async {
      FakeProactiveNative()
        ..recoveryIssue = 'state_unreadable: JsonParseException'
        ..storageError = 'IOException: disk full'
        ..install();
      await pumpPhone(tester, const ProactivePage());
      expect(find.textContaining('上次的状态读不出来'), findsOneWidget);
      expect(find.textContaining('回执保存失败'), findsOneWidget);
    });

    testWidgets('phone control links to it', (tester) async {
      FakeProactiveNative().install();
      await pumpPhone(tester, const PhoneControlScreen());
      await tester.scrollUntilVisible(find.text('主动搭话'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('主动搭话').first);
      await tester.pumpAndSettle();
      expect(find.byType(ProactivePage), findsOneWidget);
    });
  });
}
