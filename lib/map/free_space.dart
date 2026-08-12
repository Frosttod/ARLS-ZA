/// How much room is left where the pack will be written (§16.6).
///
/// An interface rather than a plugin call, for the same reason the position and
/// the battery have one: the download logic must be drivable from a test, and
/// "the disk is nearly full" is precisely the case nobody can reproduce on
/// demand.
///
/// The measurement is taken on the directory the file will actually be written
/// to. Internal storage, adopted storage and a removable card do not share a
/// budget, and a game that checks the wrong volume gives an answer that is
/// confidently wrong.
library;

import 'dart:io';

import 'package:flutter/services.dart';

abstract class FreeSpace {
  /// Bytes available at [directory], or null when the platform will not say.
  ///
  /// Null is not zero: refusing a download because a measurement failed would
  /// be worse than attempting one that might not fit.
  Future<int?> bytesAt(Directory directory);
}

/// The real thing, over a method channel to `StatFs`.
class PlatformFreeSpace implements FreeSpace {
  const PlatformFreeSpace();

  static const MethodChannel _channel = MethodChannel(
    'com.raidodevelopment.arlsza/storage',
  );

  @override
  Future<int?> bytesAt(Directory directory) async {
    try {
      return await _channel.invokeMethod<int>('freeBytes', {
        'path': directory.path,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // A desktop developer build. The download screen falls back to trying,
      // which is the right behaviour on a machine with a real disk.
      return null;
    }
  }
}

/// Reports whatever it was told. For tests, and for the platforms that have no
/// answer.
class FixedFreeSpace implements FreeSpace {
  const FixedFreeSpace(this.bytes);

  final int? bytes;

  @override
  Future<int?> bytesAt(Directory directory) async => bytes;
}
