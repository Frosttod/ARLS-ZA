/// What the model's own enums are called, in the player's language.
///
/// ⚠️ Here rather than on the screen that happens to draw them first. A skill
/// is named in the profile and in the journal, and two screens each holding
/// their own switch is two screens that drift apart — which is how the shelter
/// modules ended up with three different names for the workshop.
library;

import '../l10n/app_localizations.dart';
import '../skills/skill.dart';

String skillName(L10n l10n, Skill skill) => switch (skill) {
  Skill.scouting => l10n.profileSkillScouting,
  Skill.weapons => l10n.profileSkillWeapons,
  Skill.medicine => l10n.profileSkillMedicine,
  Skill.engineering => l10n.profileSkillEngineering,
};
