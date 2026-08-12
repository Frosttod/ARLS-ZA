/// Choosing and downloading a map pack (§16.6).
///
/// This screen holds a player's attention for several minutes over a connection
/// that may not survive them, so it is built around the things that go wrong
/// rather than the path where nothing does:
///
/// * The region under the player's feet is offered first, named as such. A list
///   of sixteen voivodeships with no hint is a quiz.
/// * Every failure says what happened and what to do, and leaves the button
///   there. An interrupted download keeps its bytes, so "try again" means
///   "finish", not "start over".
/// * A region nobody has published is shown greyed with a reason, not hidden.
///   Missing from a list reads as a bug; "not published yet" reads as a fact.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../map/pack_manager.dart';
import '../map/pack_store.dart';
import '../map/region_pack.dart';

class RegionPickerScreen extends StatefulWidget {
  const RegionPickerScreen({
    required this.manager,
    this.nearLatitude,
    this.nearLongitude,
    this.onDone,
    super.key,
  });

  final PackManager manager;

  /// The player's position, when it is known. Used only to put the right region
  /// at the top.
  final double? nearLatitude;
  final double? nearLongitude;

  /// Called once at least one pack is installed.
  final VoidCallback? onDone;

  @override
  State<RegionPickerScreen> createState() => _RegionPickerScreenState();
}

class _RegionPickerScreenState extends State<RegionPickerScreen> {
  List<RegionStatus> _statuses = const [];
  bool _loading = true;

  /// The pack being downloaded, if any. Only one at a time: two 200 MB
  /// downloads over a phone connection finish later than one after the other,
  /// and the progress bar stops meaning anything.
  String? _busyId;
  double _progress = 0;
  bool _cancelRequested = false;

  /// The last failure, so the row can say what happened rather than silently
  /// returning to its resting state.
  ({String id, InstallOutcome outcome})? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final statuses = await widget.manager.statuses();
    if (!mounted) return;
    setState(() {
      _statuses = _ordered(statuses);
      _loading = false;
    });
  }

  /// The region under the player first, then the rest in catalogue order.
  List<RegionStatus> _ordered(List<RegionStatus> statuses) {
    final latitude = widget.nearLatitude;
    final longitude = widget.nearLongitude;
    if (latitude == null || longitude == null) return statuses;

    final near = <RegionStatus>[];
    final rest = <RegionStatus>[];
    for (final status in statuses) {
      (status.pack.bounds.contains(latitude, longitude) ? near : rest).add(
        status,
      );
    }
    return [...near, ...rest];
  }

  bool get _isNear =>
      widget.nearLatitude != null && widget.nearLongitude != null;

  bool _nearest(RegionStatus status) =>
      _isNear &&
      status.pack.bounds.contains(widget.nearLatitude!, widget.nearLongitude!);

  Future<void> _download(RegionPack pack) async {
    setState(() {
      _busyId = pack.id;
      _progress = 0;
      _cancelRequested = false;
      _failure = null;
    });

    final outcome = await widget.manager.install(
      pack,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => _progress = progress.fraction);
      },
      isCancelled: () async => _cancelRequested,
    );

    if (!mounted) return;
    setState(() {
      _busyId = null;
      _failure =
          outcome == InstallOutcome.installed ||
              outcome == InstallOutcome.alreadyPresent ||
              outcome == InstallOutcome.cancelled
          ? null
          : (id: pack.id, outcome: outcome);
    });

    await _refresh();
    if (outcome == InstallOutcome.installed && mounted) {
      widget.onDone?.call();
    }
  }

  Future<void> _delete(RegionPack pack) async {
    await widget.manager.delete(pack);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.regionTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _statuses.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      l10n.regionIntro,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return _RegionRow(
                  status: _statuses[index - 1],
                  nearby: _nearest(_statuses[index - 1]),
                  downloading: _busyId == _statuses[index - 1].pack.id,
                  otherBusy:
                      _busyId != null &&
                      _busyId != _statuses[index - 1].pack.id,
                  progress: _progress,
                  failure: _failure?.id == _statuses[index - 1].pack.id
                      ? _failure!.outcome
                      : null,
                  onDownload: () =>
                      unawaited(_download(_statuses[index - 1].pack)),
                  onCancel: () => setState(() => _cancelRequested = true),
                  onDelete: () => unawaited(_delete(_statuses[index - 1].pack)),
                );
              },
            ),
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({
    required this.status,
    required this.nearby,
    required this.downloading,
    required this.otherBusy,
    required this.progress,
    required this.failure,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  final RegionStatus status;
  final bool nearby;
  final bool downloading;

  /// True while a different pack is downloading. Its button is disabled rather
  /// than hidden, so the list does not reshuffle under a finger.
  final bool otherBusy;

  final double progress;
  final InstallOutcome? failure;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final percent = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.pack.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: nearby ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
              _action(l10n),
            ],
          ),
          if (downloading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Text(
              l10n.regionDownloading(percent),
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (failure != null) ...[
            const SizedBox(height: 6),
            Text(
              _failureText(l10n, failure!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle(L10n l10n) {
    if (!status.downloadable) return l10n.regionUnavailable;
    if (status.installed) return l10n.regionInstalled;
    if (nearby) return '${l10n.regionNearYou} · ${status.pack.megabytes} MB';
    return '${status.pack.megabytes} MB';
  }

  Widget _action(L10n l10n) {
    if (downloading) {
      return TextButton(onPressed: onCancel, child: Text(l10n.regionCancel));
    }
    if (status.installed) {
      return TextButton(onPressed: onDelete, child: Text(l10n.regionDelete));
    }
    if (!status.downloadable) {
      return const SizedBox.shrink();
    }
    return FilledButton(
      onPressed: otherBusy ? null : onDownload,
      child: Text(failure == null ? l10n.regionDownload : l10n.regionRetry),
    );
  }

  static String _failureText(L10n l10n, InstallOutcome outcome) =>
      switch (outcome) {
        InstallOutcome.notEnoughSpace => l10n.regionErrSpace,
        InstallOutcome.networkFailed => l10n.regionErrNetwork,
        InstallOutcome.corrupted => l10n.regionErrCorrupt,
        InstallOutcome.installed ||
        InstallOutcome.alreadyPresent ||
        InstallOutcome.cancelled => '',
      };
}
