import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../proactive/proactive_state.dart';
import '../common/app_sheet.dart';
import '../common/list_page_row.dart';
import '../shell/page_frame.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';
import 'action_log_page.dart' show formatLogTime;
import 'loop_test_page.dart' show loopClock;

/// 璁剧疆 鈫?鎵嬫満鎿嶆帶 鈫?涓诲姩鎼瘽: the proactive kernel's own page.
///
/// Everything it shows comes from `dsh/proactive` `status` and `receipts`; nothing is computed
/// here. Two things it deliberately says out loud, because both are true on a locked-down phone:
/// when the system forbids background wakeups (`wakeMode == OPPORTUNISTIC`), and when the kernel is
/// holding back because DSH is using the phone.
class ProactivePage extends StatefulWidget {
  const ProactivePage({super.key, this.channel});

  final ProactiveChannel? channel;

  /// Random gap ladder, in minutes; the kernel clamps anything outside its own range.
  static const minIntervalSteps = [15, 30, 45, 60];
  static const maxIntervalSteps = [60, 120, 180, 240];

  /// Quiet-hours presets; the first entry turns them off.
  static const quietPresets = [
    (0, 0),
    (23 * 60, 8 * 60),
    (22 * 60, 8 * 60),
    (12 * 60, 14 * 60),
  ];

  static const dailyMaxSteps = [0, 2, 4, 6, 10];

  @override
  State<ProactivePage> createState() => _ProactivePageState();
}

class _ProactivePageState extends State<ProactivePage> {
  late final ProactiveChannel _channel = widget.channel ?? ProactiveChannel();
  ProactiveStatus? _status;
  List<ProactiveReceipt> _receipts = const [];
  ProactiveAgentSessions _sessions = const ProactiveAgentSessions();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => unawaited(_refresh()));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final status = await _channel.status();
    final receipts = await _channel.receipts(limit: 50);
    final sessions = await _channel.agentSessions();
    if (!mounted) return;
    setState(() {
      _status = status;
      _receipts = receipts;
      _sessions = sessions;
    });
  }

  /// Picks the session proactive turns go to. Only live sessions are offered; the plugin refuses a
  /// missing, archived or busy one itself, so this page never has to guess.
  Future<void> _pickSession() async {
    final sessions = await _channel.agentSessions();
    if (!mounted) return;
    setState(() => _sessions = sessions);
    if (!sessions.ready) return;
    final picked = await showAppSheet<String>(
      context,
      heightFactor: 0.6,
      builder: (sheet) => _SessionList(sessions: sessions),
    );
    if (picked == null) return;
    // An empty id means "no target", which the plugin stores as null.
    await _channel.setAgentSession(picked.isEmpty ? null : picked);
    await _refresh();
  }

  Future<void> _save(ProactiveConfig next) async {
    await _channel.setConfig(next);
    await _refresh();
  }

  Future<void> _setEnabled(bool on) async {
    final config = _status?.config ?? const ProactiveConfig();
    await _save(config.copyWith(enabled: on));
  }

  Future<void> _cycleMin(ProactiveConfig config) async {
    const steps = ProactivePage.minIntervalSteps;
    final i = steps.indexOf(config.minIntervalMs ~/ 60000);
    final next = steps[(i + 1) % steps.length];
    // Keep the window valid: min may never exceed max.
    final max = config.maxIntervalMs < next * 60000 ? next * 60000 : config.maxIntervalMs;
    await _save(config.copyWith(minIntervalMs: next * 60000, maxIntervalMs: max));
  }

  Future<void> _cycleMax(ProactiveConfig config) async {
    const steps = ProactivePage.maxIntervalSteps;
    final i = steps.indexOf(config.maxIntervalMs ~/ 60000);
    final next = steps[(i + 1) % steps.length];
    final min = config.minIntervalMs > next * 60000 ? next * 60000 : config.minIntervalMs;
    await _save(config.copyWith(maxIntervalMs: next * 60000, minIntervalMs: min));
  }

  Future<void> _cycleQuiet(ProactiveConfig config) async {
    const presets = ProactivePage.quietPresets;
    var i = presets.indexWhere((p) => p.$1 == config.quietStartMinute && p.$2 == config.quietEndMinute);
    if (i < 0) i = -1;
    final next = presets[(i + 1) % presets.length];
    await _save(config.copyWith(quietStartMinute: next.$1, quietEndMinute: next.$2));
  }

  Future<void> _cycleDaily(ProactiveConfig config) async {
    const steps = ProactivePage.dailyMaxSteps;
    final i = steps.indexOf(config.dailyMax);
    await _save(config.copyWith(dailyMax: steps[(i + 1) % steps.length]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = DshColors.of(context);
    final status = _status;
    final config = status?.config ?? const ProactiveConfig();
    return AppPage.list(
      title: l10n.proactiveTitle,
      subtitle: Text(l10n.proactiveSubtitle),
      actions: [
        GlassIconButton(icon: AppIcons.refresh, tooltip: l10n.loopRefresh, onPressed: () => unawaited(_refresh())),
      ],
      children: [
        ListPageCard(
          children: [
            MergeSemantics(
              child: ListPageRow(
                icon: AppIcons.notificationsOff,
                title: l10n.proactiveEnabled,
                subtitle: l10n.proactiveEnabledHint,
                subtitleMaxLines: 3,
                onTap: status == null ? null : () => unawaited(_setEnabled(!config.enabled)),
                trailing: Switch(
                  value: config.enabled,
                  onChanged: status == null ? null : (v) => unawaited(_setEnabled(v)),
                ),
              ),
            ),
            ListPageRow(
              icon: AppIcons.commandTimeout,
              title: l10n.proactiveGap,
              subtitle: l10n.proactiveGapHint,
              value: l10n.proactiveGapValue(config.minIntervalMs ~/ 60000, config.maxIntervalMs ~/ 60000),
              onTap: status == null ? null : () => unawaited(_cycleMin(config)),
            ),
            ListPageRow(
              icon: AppIcons.commandTimeout,
              title: l10n.proactiveGapMax,
              subtitle: l10n.proactiveGapMaxHint,
              value: l10n.proactiveMinutes(config.maxIntervalMs ~/ 60000),
              onTap: status == null ? null : () => unawaited(_cycleMax(config)),
            ),
            ListPageRow(
              icon: AppIcons.notificationsOff,
              title: l10n.proactiveQuiet,
              subtitle: l10n.proactiveQuietHint,
              value: config.quietSet
                  ? l10n.proactiveQuietValue(loopClock(config.quietStartMinute), loopClock(config.quietEndMinute))
                  : l10n.loopQuietHoursOff,
              onTap: status == null ? null : () => unawaited(_cycleQuiet(config)),
            ),
            ListPageRow(
              icon: AppIcons.today,
              title: l10n.proactiveDaily,
              subtitle: l10n.proactiveDailyHint,
              value: config.dailyMax <= 0 ? l10n.loopDailyCapOff : l10n.proactiveDailyValue(config.dailyMax),
              onTap: status == null ? null : () => unawaited(_cycleDaily(config)),
            ),
            ListPageRow(
              icon: AppIcons.chat,
              title: l10n.proactiveSession,
              subtitle: sessionsSubtitle(l10n, _sessions),
              subtitleMaxLines: 2,
              value: _sessions.sessionId == null && _sessions.ready ? l10n.proactiveSessionNone : null,
              onTap: () => unawaited(_pickSession()),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListPageCard(
          title: l10n.proactiveState,
          children: [
            ListPageRow(
              icon: status?.holdReason == null ? AppIcons.allowed : AppIcons.stopped,
              iconColor: status?.holdReason == null ? colors.success : colors.warning,
              title: status?.holdReason == null ? l10n.proactiveGateFree : l10n.proactiveGateHold(proactiveHoldLabel(l10n, status!.holdReason!)),
              titleMaxLines: 3,
              subtitle: status?.activeStage == null ? null : l10n.proactiveActiveStage(status!.activeStage!),
              subtitleMaxLines: 2,
            ),
            // The honest warning: on a phone that forbids background wakeups there is no alarm at
            // all, and a message only happens while DSH is open or the screen changes.
            if (status != null && status.wakeRestricted)
              ListPageRow(
                icon: AppIcons.warning,
                iconColor: colors.warning,
                title: l10n.proactiveWakeRestricted,
                titleMaxLines: 4,
              ),
            if (status != null && status.wakeMode != 'OPPORTUNISTIC')
              ListPageRow(
                icon: AppIcons.alarmClock,
                title: l10n.proactiveWakeMode(status.wakeMode),
                subtitle: status.alarmError,
                subtitleMaxLines: 2,
              ),
            ListPageRow(
              icon: status?.transport ?? false ? AppIcons.allowed : AppIcons.error,
              iconColor: status?.transport ?? false ? colors.success : colors.warning,
              title: status?.transport ?? false ? l10n.proactiveTransportReady : l10n.proactiveTransportMissing,
              titleMaxLines: 2,
              subtitle: l10n.proactiveQueued(status?.queued ?? 0),
            ),
            if (status?.storageError != null)
              ListPageRow(
                icon: AppIcons.error,
                iconColor: colors.danger,
                title: l10n.loopStorageError(status!.storageError!),
                titleMaxLines: 3,
              ),
            if (status?.recoveryIssue != null)
              ListPageRow(
                icon: AppIcons.warning,
                iconColor: colors.warning,
                title: l10n.proactiveRecoveryIssue(status!.recoveryIssue!),
                titleMaxLines: 3,
              ),
          ],
        ),
        const SizedBox(height: 24),
        ListPageCard(
          title: l10n.proactiveReceipts,
          children: [
            if (_receipts.isEmpty)
              ListPageRow(icon: AppIcons.history, iconColor: colors.textTertiary, title: l10n.proactiveReceiptsEmpty)
            else
              for (final r in _receipts) _ReceiptRow(r),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Why the kernel is holding back, in the person's words.
String proactiveHoldLabel(L10n l10n, String reason) => switch (reason) {
  'dsh_task' || 'dsh' => l10n.proactiveHoldDshTask,
  'dsh_prompt' => l10n.proactiveHoldDshPrompt,
  'locked' => l10n.proactiveHoldLocked,
  'screen_off' => l10n.proactiveHoldScreenOff,
  'protected' => l10n.proactiveHoldProtected,
  'a11y' => l10n.proactiveHoldA11y,
  _ => reason,
};

/// The session row's second line: the target, or why there is none.
String sessionsSubtitle(L10n l10n, ProactiveAgentSessions s) {
  if (!s.ready) return l10n.proactiveSessionUnavailable(s.error ?? '');
  if (s.sessionId != null) return l10n.proactiveSessionChosen(s.sessionId!);
  return l10n.proactiveSessionHint;
}

/// The live sessions, plus an explicit "no target" row.
class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});

  final ProactiveAgentSessions sessions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(l10n.proactivePickSession, style: theme.textTheme.titleMedium),
        ),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(AppIcons.blocked),
                title: Text(l10n.proactiveSessionNone),
                subtitle: Text(l10n.proactiveSessionNoneHint),
                trailing: sessions.sessionId == null ? const Icon(AppIcons.selected) : null,
                onTap: () => Navigator.pop(context, ''),
              ),
              for (final a in sessions.agents)
                ListTile(
                  leading: Icon(a.idle ? AppIcons.chat : AppIcons.queued),
                  title: Text(a.id),
                  subtitle: Text(a.idle ? l10n.proactiveSessionIdle : l10n.proactiveSessionRunning),
                  trailing: a.id == sessions.sessionId ? const Icon(AppIcons.selected) : null,
                  // A running agent is still selectable: the plugin answers 409 while it is busy
                  // and the page then shows that honestly, rather than hiding the row.
                  onTap: () => Navigator.pop(context, a.id),
                ),
              if (sessions.agents.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(l10n.proactiveSessionEmpty, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The outcome of one receipt, in the person's words.
String proactiveOutcomeLabel(L10n l10n, String? outcome) => switch (outcome) {
  'RESPONDED' => l10n.proactiveOutcomeResponded,
  'DISMISSED' => l10n.proactiveOutcomeDismissed,
  'IGNORED_SEEN' => l10n.proactiveOutcomeIgnoredSeen,
  'UNCONFIRMED' => l10n.proactiveOutcomeUnconfirmed,
  'NOT_DELIVERED' => l10n.proactiveOutcomeNotDelivered,
  null => l10n.proactiveOutcomeOpen,
  _ => outcome,
};

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.receipt);

  final ProactiveReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = DshColors.of(context);
    final (icon, color) = switch (receipt.outcome) {
      'RESPONDED' => (AppIcons.allowed, colors.success),
      'DISMISSED' || 'IGNORED_SEEN' => (AppIcons.stopped, colors.warning),
      'NOT_DELIVERED' => (AppIcons.error, colors.danger),
      'UNCONFIRMED' => (AppIcons.pending, colors.textTertiary),
      _ => (AppIcons.pending, colors.textTertiary),
    };
    // The six moments the kernel keeps apart, so "it was sent" and "they saw it" never blur.
    final marks = <String>[
      if (receipt.acceptedAt != null) l10n.proactiveMarkAccepted,
      if (receipt.generatedAt != null) l10n.proactiveMarkGenerated,
      if (receipt.deliveredAt != null) l10n.proactiveMarkDelivered,
      if (receipt.shownAt != null) l10n.proactiveMarkShown,
      if (receipt.respondedAt != null) l10n.proactiveMarkResponded,
    ];
    final surface = switch (receipt.surface) {
      'notification' => l10n.loopSurfaceNotification,
      _ => null,
    };
    final detail = [?surface, if (marks.isNotEmpty) marks.join(' 鈫?'), ?receipt.reason].join(' 路 ');
    return ListPageRow(
      icon: icon,
      iconColor: color,
      title: proactiveOutcomeLabel(l10n, receipt.outcome),
      subtitle: detail.isEmpty ? null : detail,
      subtitleMaxLines: 3,
      meta: formatLogTime(receipt.closedAt ?? receipt.deliveredAt ?? receipt.createdAt),
    );
  }
}

