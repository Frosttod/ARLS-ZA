/// Character creator (design doc §1.2, §1.3, §15.4).
///
/// Four numbers and a name. What makes this screen worth having is the summary
/// at the bottom: it shows the figures the game derived, live, as the player
/// types. That is the first proof to the player that the game is computing a
/// body rather than assigning a class — and §15.4 asks for exactly that.
///
/// The privacy line is not decoration either. Height, weight, age and sex are
/// health-related data, and the promise that they stay on the device has to be
/// made where they are entered (§1.2).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fonts.dart';
import 'units.dart';
import '../l10n/app_localizations.dart';
import 'effects.dart';
import '../sim/body.dart';

/// What the creator produces.
class CharacterDraft {
  const CharacterDraft({
    required this.name,
    required this.spec,
    required this.deathMode,
  });

  final String name;
  final BodySpec spec;
  final DeathMode deathMode;

  BodyProfile get profile => BodyProfile.from(spec);
}

/// The fields, named so a test can address one rather than "the text field".
/// The creator has four, and picking one by type is picking at random.
const Key kCreatorNameFieldKey = Key('creator.name');
const Key kCreatorAgeKey = Key('creator.age');
const Key kCreatorHeightKey = Key('creator.height');
const Key kCreatorWeightKey = Key('creator.weight');
const Key kCreatorRestingHrKey = Key('creator.restingHr');

class CharacterCreatorScreen extends StatefulWidget {
  const CharacterCreatorScreen({required this.onCreate, super.key});

  final void Function(CharacterDraft draft) onCreate;

  @override
  State<CharacterCreatorScreen> createState() => _CharacterCreatorScreenState();
}

class _CharacterCreatorScreenState extends State<CharacterCreatorScreen> {
  final _nameController = TextEditingController();

  Sex _sex = Sex.male;
  int _age = 30;
  int _height = 180;
  double _weight = 80;

  /// §2.4. Off by default: most people do not know theirs, and a guess typed
  /// in is worse than the formula.
  int? _restingHr;

  /// Nothing is preselected: §15.4 asks for a deliberate choice with its own
  /// confirmation, because the decision cannot be undone (§9).
  DeathMode? _deathMode;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  BodySpec get _spec => BodySpec(
    sex: _sex,
    ageYears: _age,
    heightCm: _height,
    weightKg: _weight,
    measuredRestingHr: _restingHr,
  );

  BodyValidation get _specValidation => BodyValidation.ofSpec(_spec);

  BodyValidation get _nameValidation =>
      BodyValidation.ofName(_nameController.text);

  bool get _canSubmit =>
      _specValidation.isValid && _nameValidation.isValid && _deathMode != null;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final profile = BodyProfile.from(_spec);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createCharacter)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(l10n.creatorIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              l10n.dataStaysOnDevice,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              // Named because the creator now has four text fields and a test
              // that says "the text field" would be picking one at random.
              key: kCreatorNameFieldKey,
              controller: _nameController,
              maxLength: BodyLimits.nameMax,
              inputFormatters: [
                // Trimming as the player types would fight the cursor, so the
                // rule is enforced by validation and only obvious junk is kept
                // out of the field itself.
                FilteringTextInputFormatter.deny(RegExp(r'[\n\t]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.fieldName,
                errorText: _firstNameError(l10n),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 8),
            _SexSelector(
              value: _sex,
              onChanged: (value) => setState(() => _sex = value),
            ),

            _NumberField(
              key: kCreatorAgeKey,
              label: l10n.fieldAge,
              value: _age.toDouble(),
              min: BodyLimits.ageMin.toDouble(),
              max: BodyLimits.ageMax.toDouble(),
              suffix: 'lat',
              error: _specValidation.has(BodyValidationIssue.ageOutOfRange)
                  ? l10n.errAgeRange
                  : null,
              onChanged: (value) => setState(() => _age = value.round()),
            ),
            _NumberField(
              key: kCreatorHeightKey,
              label: l10n.fieldHeight,
              value: _height.toDouble(),
              min: BodyLimits.heightMinCm.toDouble(),
              max: BodyLimits.heightMaxCm.toDouble(),
              suffix: 'cm',
              error: _specValidation.has(BodyValidationIssue.heightOutOfRange)
                  ? l10n.errHeightRange
                  : null,
              onChanged: (value) => setState(() => _height = value.round()),
            ),
            _NumberField(
              key: kCreatorWeightKey,
              label: l10n.fieldWeight,
              value: _weight,
              min: BodyLimits.weightMinKg,
              max: BodyLimits.weightMaxKg,
              suffix: 'kg',
              error: _specValidation.has(BodyValidationIssue.weightOutOfRange)
                  ? l10n.errWeightRange
                  : null,
              onChanged: (value) => setState(() => _weight = value),
            ),

            // §2.4: everything the heart rate does is measured from this
            // floor, so somebody who knows theirs should be able to say it.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _restingHr != null,
              title: Text(l10n.fieldRestingHrKnown),
              subtitle: Text(
                l10n.fieldRestingHrHint,
                style: const TextStyle(fontSize: 11),
              ),
              onChanged: (on) => setState(() => _restingHr = on ? 60 : null),
            ),
            if (_restingHr != null)
              _NumberField(
                key: kCreatorRestingHrKey,
                label: l10n.fieldRestingHr,
                value: _restingHr!.toDouble(),
                min: kRestingHrMin.toDouble(),
                max: kRestingHrMax.toDouble(),
                suffix: 'bpm',
                onChanged: (value) =>
                    setState(() => _restingHr = value.round()),
              ),

            if (_specValidation.has(BodyValidationIssue.bmiTooLow) ||
                _specValidation.has(BodyValidationIssue.bmiTooHigh))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.errBmiTooLow,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),

            const SizedBox(height: 28),
            _ComputedSummary(profile: profile, valid: _specValidation.isValid),

            const SizedBox(height: 28),
            Text(l10n.deathModeTitle, style: theme.textTheme.titleMedium),
            Text(
              l10n.deathModeWarning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            _DeathModeCard(
              title: l10n.softcoreTitle,
              body: l10n.softcoreBody,
              selected: _deathMode == DeathMode.softcore,
              onTap: () => setState(() => _deathMode = DeathMode.softcore),
            ),
            _DeathModeCard(
              title: l10n.hardcoreTitle,
              body: l10n.hardcoreBody,
              selected: _deathMode == DeathMode.hardcore,
              onTap: () => setState(() => _deathMode = DeathMode.hardcore),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: Text(l10n.beginSurvival),
            ),
          ],
        ),
      ),
    );
  }

  String? _firstNameError(L10n l10n) {
    if (_nameController.text.isEmpty) return null;
    final issues = _nameValidation.issues;
    if (issues.isEmpty) return null;

    return switch (issues.first) {
      BodyValidationIssue.nameTooShort => l10n.errNameTooShort,
      BodyValidationIssue.nameTooLong => l10n.errNameTooLong,
      BodyValidationIssue.nameHasInvalidCharacters => l10n.errNameInvalid,
      BodyValidationIssue.nameHasEdgeSpaces => l10n.errNameEdgeSpaces,
      BodyValidationIssue.nameHasDoubleSpaces => l10n.errNameDoubleSpaces,
      _ => null,
    };
  }

  void _submit() {
    final mode = _deathMode;
    if (!_canSubmit || mode == null) return;

    widget.onCreate(
      CharacterDraft(
        name: _nameController.text.trim(),
        spec: _spec,
        deathMode: mode,
      ),
    );
  }
}

class _SexSelector extends StatelessWidget {
  const _SexSelector({required this.value, required this.onChanged});

  final Sex value;
  final ValueChanged<Sex> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(l10n.fieldSex, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 16),
          SegmentedButton<Sex>(
            segments: [
              ButtonSegment(value: Sex.male, label: Text(l10n.sexMale)),
              ButtonSegment(value: Sex.female, label: Text(l10n.sexFemale)),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

/// A slider with the number beside it, and the number is editable (§1.2).
///
/// The slider is right for exploring a range and wrong for landing on a value:
/// height runs from 120 to 220 cm across a few hundred pixels, so a centimetre
/// is under a pixel wide and 178 is a matter of luck. Typing it is exact, and
/// the two stay in step — dragging rewrites the field, typing moves the slider.
///
/// Out-of-range typing is left alone while the field has focus. Clamping mid-
/// keystroke turns "1" on the way to "180" into "120" and eats the rest.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
    this.error,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final String? error;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.value),
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // Leaving the field is when a half-typed number becomes a final answer.
      if (!_focus.hasFocus) _controller.text = _format(widget.value);
    });
  }

  @override
  void didUpdateWidget(_NumberField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != old.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  static String _format(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

  void _onTyped(String text) {
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null) return;
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.label, style: theme.textTheme.bodyMedium),
              ),
              SizedBox(
                width: 84,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: kDataFont,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: widget.suffix,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  onChanged: _onTyped,
                ),
              ),
            ],
          ),
          Slider(
            value: widget.value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: (widget.max - widget.min).round(),
            onChanged: (next) {
              _controller.text = _format(next);
              widget.onChanged(next);
            },
          ),
          if (widget.error != null)
            Text(
              widget.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

/// The derived figures, live. §15.4 calls this the first proof that the game
/// is really calculating.
class _ComputedSummary extends StatelessWidget {
  const _ComputedSummary({required this.profile, required this.valid});

  final BodyProfile profile;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Opacity(
      opacity: valid ? 1 : 0.35,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.computedTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _Row(
              label: l10n.bloodVolume,
              value: l10n.unitMl(profile.bloodVolumeMl.round().toString()),
            ),
            _Row(
              label: l10n.dailyRequirement,
              value: effects([
                '${profile.dailyEnergyKcal.round()} kcal',
                '${profile.baseWaterMlPerDay.round()} ml',
              ]),
            ),
            _Row(
              label: l10n.carryComfort,
              value: l10n.unitKg(amount(profile.carryComfortKg)),
            ),
            _Row(
              label: l10n.carryMax,
              value: l10n.unitKg(amount(profile.carryMaxKg)),
            ),
            _Row(
              label: l10n.maxHeartRate,
              value: l10n.unitBpm(profile.maxHeartRate.round().toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: theme.textTheme.bodySmall)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: kDataFont,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeathModeCard extends StatelessWidget {
  const _DeathModeCard({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: selected ? theme.colorScheme.surfaceContainerHighest : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.dividerColor,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: theme.textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 6),
              Text(body, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
