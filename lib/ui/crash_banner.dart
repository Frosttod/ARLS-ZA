/// The red strip that says something broke, and hands over the evidence.
///
/// ⚠️ **A tester on a pavement cannot read a console.** The crash log goes to
/// a file as well, but a file needs a cable and a computer and a walk home. A
/// strip with a copy button turns "nie da się jeść, crash" into a stack trace
/// pasted from the phone before the walk is over.
///
/// Deliberately over the whole app rather than on one screen: a crash that
/// happens on the map should not need the player to find their way back to a
/// menu before they can report it — and half the time the screen they were on
/// is the thing that broke.
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
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<CrashReport>>(
        valueListenable: CrashLog.reports,
        builder: (context, reports, _) => Stack(
          children: [
            child,
            // Nothing at all when nothing has gone wrong. The strip costs one
            // rebuild per crash and none the rest of the time.
            if (reports.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Material(
                    color: Colors.transparent,
                    child: _Strip(reports: reports),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _Strip extends StatelessWidget {
  const _Strip({required this.reports});

  final List<CrashReport> reports;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final last = reports.last;

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
                  reports.length == 1
                      ? l10n.crashOne
                      : l10n.crashMany(reports.length),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // The first line of the exception, which is usually the whole
                // answer. The rest is behind the copy button.
                Text(
                  last.error.split('\n').first,
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

  Future<void> _copy(BuildContext context, List<CrashReport> reports) async {
    final l10n = L10n.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    // ⚠️ The file, not just this session — a crash on the way out of the app
    // is written down and then the process ends, and the run after it is the
    // one where somebody presses copy.
    final onDisk = await CrashLog.readAll();
    final text =
        onDisk ?? [for (final report in reports) report.text].join('\n\n');

    await Clipboard.setData(ClipboardData(text: text));

    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.crashCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
