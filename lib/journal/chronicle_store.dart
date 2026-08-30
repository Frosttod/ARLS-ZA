/// Czytanie skończonych pass (§13.1, §11.1).
///
/// Osobny plik, bo `chronicleFor` zwraca wiersz drifta, a ekran ma dostać
/// [PastRun] — jedno miejsce, w którym wiersz zamienia się w rzecz, o której
/// da się myśleć bez bazy pod ręką.
library;

import '../data/db/database.dart';
import '../sim/body.dart';
import 'chronicle.dart';

class ChronicleStore {
  const ChronicleStore(this.db);

  final SaveDatabase db;

  /// Passy tego profilu, **najświeższa pierwsza**.
  ///
  /// ⚠️ Kolejność jest tutaj, nie w zapytaniu: wiersze wchodzą w kolejności
  /// wstawiania i tak też wychodzą, a ekran, na którym ostatnia śmierć jest na
  /// samym dole, każe przewijać przez cudze porażki do własnej.
  Future<List<PastRun>> load(int profileId) async {
    final rows = await db.chronicleFor(profileId);

    return [
      for (final row in rows)
        PastRun(
          days: row.survivalDays,
          startedAt: row.startedAt.toUtc(),
          endedAt: row.endedAt.toUtc(),
          cause: row.cause,
          hardcore: row.deathMode == DeathMode.hardcore.wire,
        ),
    ]..sort((a, b) => b.endedAt.compareTo(a.endedAt));
  }
}
