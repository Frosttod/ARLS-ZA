/// The red strip that says something broke, and hands over the evidence.
///
/// ⚠️ **A tester on a pavement cannot read a console.** The logs go to files as
/// well, but a file needs a cable and a computer and a walk home. A strip with
/// a copy button turns "nie da się jeść, crash" into a trace pasted from the
/// phone before the walk is over.
///
/// ⚠️ **Two different failures, and they look nothing alike.**
///
///   - something was *thrown* — there is an exception and a stack;
///   - something *stopped answering* — SIGQUIT, a tombstone, and no exception
///     at all, because a hang throws nothing. All that is left of one of those
///     is the last step that reached the disk before everything stopped.
///
/// Both end up here, because from the tester's side they are the same event:
/// the game stopped working and somebody needs to be told what it was doing.
///
/// Over the whole app rather than on one screen: half the time the screen the
/// player was on is the thing that broke.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/crash_log.dart';
import '../l10n/app_localizations.dart';

/// Wraps [child] with the strip, when there is anything to say.
class CrashBanner extends StatelessWidget {
  const CrashBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([CrashLog.reports, CrashLog.lastRun]),
    builder: (context, _) {
      final reports = CrashLog.reports.value;
      final hung = CrashLog.lastRun.value;

      return Stack(
        children: [
          child,
          // Nothing at all when nothing has gone wrong. The strip costs one
          // rebuild per failure and none the rest of the time.
          if (reports.isNotEmpty || hung != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.transparent,
                  child: _Strip(reports: reports, hung: hung),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _Strip extends StatelessWidget {
  const _Strip({required this.reports, required this.hung});

  final List<CrashReport> reports;

  /// The trail a session that stopped answering left behind, or null.
  final String? hung;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final last = reports.isEmpty ? null : reports.last;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xCC7F1D1D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  last == null
                      ? l10n.crashHung
                      : reports.length == 1
                      ? l10n.crashOne
                      : l10n.crashMany(reports.length),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // The first line of the exception, which is usually the whole
                // answer — or, for a hang, the last step it reached, which is
                // the same thing said the only way a hang can say it.
                Text(
                  last != null ? last.error.split('\n').first : _lastStep(hung),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: Colors.white,
            tooltip: l10n.crashCopy,
            onPressed: () => _copy(context, reports),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white70,
            tooltip: l10n.crashClear,
            onPressed: () => CrashLog.clear(),
          ),
        ],
      ),
    );
  }

  /// The step it got to. The last line of the trail, because that is the one
  /// that was happening when everything stopped.
  String _lastStep(String? trail) {
    final lines = (trail ?? '')
        .split('\n')
        .where((line) => line.trim().isNotEmpty);
    return lines.isEmpty ? '' : lines.last;
  }

  Future<void> _copy(BuildContext context, List<CrashReport> reports) async {
    final l10n = L10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    // ⚠️ The files, not just this session — whatever went wrong may have
    // ended the process, and the run *after* it is the one where somebody
    // presses copy.
    final onDisk = await CrashLog.readAll();
    final hung = CrashLog.lastRun.value;

    final text = [
      if (hung != null) 'ZAWIESIŁO SIĘ. Ostatnie kroki:\n$hung',
      if (onDisk != null) onDisk else for (final report in reports) report.text,
    ].join('\n\n');

    await Clipboard.setData(ClipboardData(text: text));

    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.crashCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
