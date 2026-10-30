// Dart side of the `dsh/loop` method channel (android/.../loop/LoopPlugin.kt):
// 设置 → 手机操控 → 触发测试, the first closed loop.

import 'package:flutter/services.dart';

class LoopConfig {
  const LoopConfig({this.enabled = false, this.targetPackage, this.cooldownMs = 60000, this.timeoutMs = 60000});

  final bool enabled;
  final String? targetPackage;
  final int cooldownMs;
  final int timeoutMs;

  static LoopConfig fromWire(Object? raw) {
    final m = raw is Map ? raw : const {};
    return LoopConfig(
      enabled: m['enabled'] == true,
      targetPackage: m['targetPackage'] is String ? m['targetPackage'] as String : null,
      cooldownMs: m['cooldownMs'] is num ? (m['cooldownMs'] as num).toInt() : 60000,
      timeoutMs: m['timeoutMs'] is num ? (m['timeoutMs'] as num).toInt() : 60000,
    );
  }
}

class LoopStatus {
  const LoopStatus({
    this.config = const LoopConfig(),
    this.a11yEnabled = false,
    this.a11yConnected = false,
    this.eventsSeen = 0,
    this.readings = 0,
    this.lastForeground,
    this.storageError,
    this.insideTarget = false,
  });

  final LoopConfig config;
  final bool a11yEnabled;
  final bool a11yConnected;
  final int eventsSeen;
  final int readings;
  final String? lastForeground;
  final String? storageError;
  final bool insideTarget;

  static LoopStatus fromWire(Object? raw) {
    final m = raw is Map ? raw : const {};
    int n(Object? v) => v is num ? v.toInt() : 0;
    String? s(Object? v) => v is String ? v : null;
    return LoopStatus(
      config: LoopConfig.fromWire(m['config']),
      a11yEnabled: m['a11yEnabled'] == true,
      a11yConnected: m['a11yConnected'] == true,
      eventsSeen: n(m['eventsSeen']),
      readings: n(m['readings']),
      lastForeground: s(m['lastForeground']),
      storageError: s(m['storageError']),
      insideTarget: m['insideTarget'] == true,
    );
  }
}

/// One receipt: the shared event record (eventId, source, timestamp, state, result, error).
class LoopEvent {
  const LoopEvent({
    required this.eventId,
    required this.source,
    required this.timestamp,
    required this.state,
    this.result,
    this.error,
    this.reason,
    this.packageName,
    this.updatedAt,
  });

  final String eventId;
  final String source;
  final DateTime timestamp;

  /// CONFIRMED / TRIGGERED / SHOWN / CLOSED.
  final String state;

  /// RETURNED / BACK / DISMISSED / TIMEOUT / ABANDONED / UNAVAILABLE / SUPPRESSED / ERROR; null while open.
  final String? result;
  final String? error;
  final String? reason;
  final String? packageName;
  final DateTime? updatedAt;

  static LoopEvent? fromWire(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['eventId'];
    final ts = raw['timestamp'];
    if (id is! String || ts is! num) return null;
    String? s(Object? v) => v is String ? v : null;
    final up = raw['updatedAt'];
    return LoopEvent(
      eventId: id,
      source: s(raw['source']) ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts.toInt()),
      state: s(raw['state']) ?? '',
      result: s(raw['result']),
      error: s(raw['error']),
      reason: s(raw['reason']),
      packageName: s(raw['packageName']),
      updatedAt: up is num ? DateTime.fromMillisecondsSinceEpoch(up.toInt()) : null,
    );
  }
}

class LoopApp {
  const LoopApp(this.package, this.label);

  final String package;
  final String label;
}

class LoopChannel {
  LoopChannel({MethodChannel? methods}) : _methods = methods ?? const MethodChannel('dsh/loop');

  final MethodChannel _methods;

  /// Null when the native side is missing or failed.
  Future<LoopStatus?> status() async {
    try {
      return LoopStatus.fromWire(await _methods.invokeMethod<Object?>('status'));
    } on Exception {
      return null;
    }
  }

  /// Only the given fields change. [clearTarget] sets the test app to none.
  Future<LoopConfig?> setConfig({bool? enabled, String? targetPackage, bool clearTarget = false, int? cooldownMs}) async {
    try {
      final raw = await _methods.invokeMethod<Object?>('setConfig', {
        'enabled': ?enabled,
        if (targetPackage != null || clearTarget) 'targetPackage': targetPackage,
        'cooldownMs': ?cooldownMs,
      });
      return LoopConfig.fromWire(raw);
    } on Exception {
      return null;
    }
  }

  Future<List<LoopEvent>> events({int limit = 50}) async {
    try {
      final raw = await _methods.invokeMethod<List<Object?>>('events', {'limit': limit});
      return [for (final e in raw ?? const []) ?LoopEvent.fromWire(e)];
    } on Exception {
      return const [];
    }
  }

  Future<bool> clearEvents() async {
    try {
      return await _methods.invokeMethod<bool>('clearEvents') ?? false;
    } on Exception {
      return false;
    }
  }

  Future<List<LoopApp>> apps() async {
    try {
      final raw = await _methods.invokeMethod<List<Object?>>('apps');
      return [
        for (final a in raw ?? const [])
          if (a is Map && a['package'] is String) LoopApp(a['package'] as String, (a['label'] as String?) ?? a['package'] as String),
      ];
    } on Exception {
      return const [];
    }
  }
}
