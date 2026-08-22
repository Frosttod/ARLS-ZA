import 'package:flutter/foundation.dart';

/// Reprezentuje przypięty cel ("Quest") widoczny na głównym ekranie.
class PinnedGoal {
  const PinnedGoal({required this.title, required this.requirements});

  /// Nazwa celu, np. "Magazyn (poziom 2)"
  final String title;

  /// Mapa wymaganych materiałów, itemId -> ilość
  final Map<String, int> requirements;
}

/// Globalny zarządca przypiętego celu.
class PinnedGoalManager {
  static final ValueNotifier<PinnedGoal?> current = ValueNotifier(null);

  static void pin(String title, Map<String, int> requirements) {
    current.value = PinnedGoal(title: title, requirements: requirements);
  }

  static void clear() {
    current.value = null;
  }
}
