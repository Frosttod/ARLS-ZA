/// §4.6.3's memory: which titles this character has already read.
///
/// ⚠️ **The one thing reading needs that a book cannot carry itself.** A copy
/// knows how far through it somebody is; only the character knows that this is
/// the fourth first-aid manual they have found. Without that count a player
/// walks into ten chemists and maxes Medicine having read nothing — the first
/// copy pays in full, the second a quarter, the third and the rest nothing.
///
/// Per title, deliberately, because that is where the exploit is: a second
/// *different* manual is a second book and pays in full.
library;

import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../inventory/inventory.dart';

class ReadingController extends ChangeNotifier {
  ReadingController(this._db);

  final SaveDatabase _db;

  /// How many copies of each title have been read to the last page.
  final ValueNotifier<Map<String, int>> titles = ValueNotifier(const {});

  /// §4.6: the copy being read, page by page. Null when nothing is open.
  ///
  /// ⚠️ Held across the page boundary on purpose. A page is its own action
  /// (§4.6.1), and a screen that cleared this between two of them told the
  /// loop nothing was running — §2.5.1 put the character to sleep in their
  /// chair and the next page woke them, once per page, in the log.
  CarriedItem? open;

  int? _profileId;

  Future<void> load(int profileId) async {
    _profileId = profileId;
    titles.value = await _db.readTitlesFor(profileId);
    notifyListeners();
  }

  /// §4.6.3: how many copies of [itemId] are already behind this character.
  int copiesOf(String itemId) => titles.value[itemId] ?? 0;

  /// §4.6.3: another copy read to the last page.
  ///
  /// ⚠️ Counted on **finishing**, not on starting. A player who reads half of
  /// each of ten copies is paid for half of one and a quarter of another and
  /// nothing for the rest — the same as §4.6.1's rule for one book, which is
  /// the point: there is no completion bonus and no completion penalty.
  Future<void> finished(String itemId) async {
    final next = copiesOf(itemId) + 1;

    titles.value = {...titles.value, itemId: next};
    notifyListeners();

    final profileId = _profileId;
    if (profileId != null) {
      await _db.writeReadTitle(profileId, itemId, next);
    }
  }

  @override
  void dispose() {
    titles.dispose();
    super.dispose();
  }
}
