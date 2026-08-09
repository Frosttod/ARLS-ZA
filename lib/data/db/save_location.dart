/// Resolves the on-device save directory.
///
/// The only Flutter-dependent piece of the persistence layer, kept apart so
/// `database.dart` stays loadable from an isolate and from `dart test`.
library;

import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// The app's private documents directory. Excluded from Android auto-backup
/// and device transfer by the manifest, because the save holds the shelter
/// location and the body parameters (§1.2, §8.2, §11.1.3).
Future<SavePaths> resolveSavePaths() async {
  final dir = await getApplicationDocumentsDirectory();
  final paths = SavePaths(dir);
  await paths.ensureExists();
  return paths;
}
