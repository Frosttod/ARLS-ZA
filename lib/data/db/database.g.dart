// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MetaEntriesTable extends MetaEntries
    with TableInfo<$MetaEntriesTable, MetaEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetaEntriesTable createAlias(String alias) {
    return $MetaEntriesTable(attachedDatabase, alias);
  }
}

class MetaEntry extends DataClass implements Insertable<MetaEntry> {
  final String key;
  final String value;
  const MetaEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaEntriesCompanion toCompanion(bool nullToAbsent) {
    return MetaEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory MetaEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaEntry copyWith({String? key, String? value}) =>
      MetaEntry(key: key ?? this.key, value: value ?? this.value);
  MetaEntry copyWithCompanion(MetaEntriesCompanion data) {
    return MetaEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class MetaEntriesCompanion extends UpdateCompanion<MetaEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 4,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageYearsMeta = const VerificationMeta(
    'ageYears',
  );
  @override
  late final GeneratedColumn<int> ageYears = GeneratedColumn<int>(
    'age_years',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<int> heightCm = GeneratedColumn<int>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredRestingHrMeta = const VerificationMeta(
    'measuredRestingHr',
  );
  @override
  late final GeneratedColumn<int> measuredRestingHr = GeneratedColumn<int>(
    'measured_resting_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deathModeMeta = const VerificationMeta(
    'deathMode',
  );
  @override
  late final GeneratedColumn<String> deathMode = GeneratedColumn<String>(
    'death_mode',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rngSeedMeta = const VerificationMeta(
    'rngSeed',
  );
  @override
  late final GeneratedColumn<int> rngSeed = GeneratedColumn<int>(
    'rng_seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diedAtMeta = const VerificationMeta('diedAt');
  @override
  late final GeneratedColumn<DateTime> diedAt = GeneratedColumn<DateTime>(
    'died_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deathCauseMeta = const VerificationMeta(
    'deathCause',
  );
  @override
  late final GeneratedColumn<String> deathCause = GeneratedColumn<String>(
    'death_cause',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sex,
    ageYears,
    heightCm,
    weightKg,
    measuredRestingHr,
    deathMode,
    rngSeed,
    createdAt,
    diedAt,
    deathCause,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('age_years')) {
      context.handle(
        _ageYearsMeta,
        ageYears.isAcceptableOrUnknown(data['age_years']!, _ageYearsMeta),
      );
    } else if (isInserting) {
      context.missing(_ageYearsMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('measured_resting_hr')) {
      context.handle(
        _measuredRestingHrMeta,
        measuredRestingHr.isAcceptableOrUnknown(
          data['measured_resting_hr']!,
          _measuredRestingHrMeta,
        ),
      );
    }
    if (data.containsKey('death_mode')) {
      context.handle(
        _deathModeMeta,
        deathMode.isAcceptableOrUnknown(data['death_mode']!, _deathModeMeta),
      );
    } else if (isInserting) {
      context.missing(_deathModeMeta);
    }
    if (data.containsKey('rng_seed')) {
      context.handle(
        _rngSeedMeta,
        rngSeed.isAcceptableOrUnknown(data['rng_seed']!, _rngSeedMeta),
      );
    } else if (isInserting) {
      context.missing(_rngSeedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('died_at')) {
      context.handle(
        _diedAtMeta,
        diedAt.isAcceptableOrUnknown(data['died_at']!, _diedAtMeta),
      );
    }
    if (data.containsKey('death_cause')) {
      context.handle(
        _deathCauseMeta,
        deathCause.isAcceptableOrUnknown(data['death_cause']!, _deathCauseMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      ageYears: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age_years'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height_cm'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      measuredRestingHr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}measured_resting_hr'],
      ),
      deathMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}death_mode'],
      )!,
      rngSeed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rng_seed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      diedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}died_at'],
      ),
      deathCause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}death_cause'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;

  /// 'M' or 'F'. Needed by the Nadler and Mifflin–St Jeor formulas (§1.3),
  /// nothing else.
  final String sex;
  final int ageYears;
  final int heightCm;
  final double weightKg;

  /// The player's own resting heart rate, or null to use §1.3's estimate.
  ///
  /// Self-reported, like height and weight, and it never leaves the device
  /// (§1.3). Nullable because most people do not know theirs, and a guessed
  /// number would be worse than the formula.
  final int? measuredRestingHr;

  /// 'hardcore' | 'softcore'. Chosen once, never changed (§9).
  final String deathMode;

  /// Root seed for the deterministic RNG (§11).
  final int rngSeed;
  final DateTime createdAt;

  /// Set when a hardcore character dies; the row is kept for the Chronicle.
  final DateTime? diedAt;
  final String? deathCause;

  /// Whether this is the character the game resumes into.
  final bool isActive;
  const Profile({
    required this.id,
    required this.name,
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    this.measuredRestingHr,
    required this.deathMode,
    required this.rngSeed,
    required this.createdAt,
    this.diedAt,
    this.deathCause,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sex'] = Variable<String>(sex);
    map['age_years'] = Variable<int>(ageYears);
    map['height_cm'] = Variable<int>(heightCm);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || measuredRestingHr != null) {
      map['measured_resting_hr'] = Variable<int>(measuredRestingHr);
    }
    map['death_mode'] = Variable<String>(deathMode);
    map['rng_seed'] = Variable<int>(rngSeed);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || diedAt != null) {
      map['died_at'] = Variable<DateTime>(diedAt);
    }
    if (!nullToAbsent || deathCause != null) {
      map['death_cause'] = Variable<String>(deathCause);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      sex: Value(sex),
      ageYears: Value(ageYears),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      measuredRestingHr: measuredRestingHr == null && nullToAbsent
          ? const Value.absent()
          : Value(measuredRestingHr),
      deathMode: Value(deathMode),
      rngSeed: Value(rngSeed),
      createdAt: Value(createdAt),
      diedAt: diedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(diedAt),
      deathCause: deathCause == null && nullToAbsent
          ? const Value.absent()
          : Value(deathCause),
      isActive: Value(isActive),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sex: serializer.fromJson<String>(json['sex']),
      ageYears: serializer.fromJson<int>(json['ageYears']),
      heightCm: serializer.fromJson<int>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      measuredRestingHr: serializer.fromJson<int?>(json['measuredRestingHr']),
      deathMode: serializer.fromJson<String>(json['deathMode']),
      rngSeed: serializer.fromJson<int>(json['rngSeed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      diedAt: serializer.fromJson<DateTime?>(json['diedAt']),
      deathCause: serializer.fromJson<String?>(json['deathCause']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sex': serializer.toJson<String>(sex),
      'ageYears': serializer.toJson<int>(ageYears),
      'heightCm': serializer.toJson<int>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'measuredRestingHr': serializer.toJson<int?>(measuredRestingHr),
      'deathMode': serializer.toJson<String>(deathMode),
      'rngSeed': serializer.toJson<int>(rngSeed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'diedAt': serializer.toJson<DateTime?>(diedAt),
      'deathCause': serializer.toJson<String?>(deathCause),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Profile copyWith({
    int? id,
    String? name,
    String? sex,
    int? ageYears,
    int? heightCm,
    double? weightKg,
    Value<int?> measuredRestingHr = const Value.absent(),
    String? deathMode,
    int? rngSeed,
    DateTime? createdAt,
    Value<DateTime?> diedAt = const Value.absent(),
    Value<String?> deathCause = const Value.absent(),
    bool? isActive,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    sex: sex ?? this.sex,
    ageYears: ageYears ?? this.ageYears,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    measuredRestingHr: measuredRestingHr.present
        ? measuredRestingHr.value
        : this.measuredRestingHr,
    deathMode: deathMode ?? this.deathMode,
    rngSeed: rngSeed ?? this.rngSeed,
    createdAt: createdAt ?? this.createdAt,
    diedAt: diedAt.present ? diedAt.value : this.diedAt,
    deathCause: deathCause.present ? deathCause.value : this.deathCause,
    isActive: isActive ?? this.isActive,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sex: data.sex.present ? data.sex.value : this.sex,
      ageYears: data.ageYears.present ? data.ageYears.value : this.ageYears,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      measuredRestingHr: data.measuredRestingHr.present
          ? data.measuredRestingHr.value
          : this.measuredRestingHr,
      deathMode: data.deathMode.present ? data.deathMode.value : this.deathMode,
      rngSeed: data.rngSeed.present ? data.rngSeed.value : this.rngSeed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      diedAt: data.diedAt.present ? data.diedAt.value : this.diedAt,
      deathCause: data.deathCause.present
          ? data.deathCause.value
          : this.deathCause,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('ageYears: $ageYears, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('measuredRestingHr: $measuredRestingHr, ')
          ..write('deathMode: $deathMode, ')
          ..write('rngSeed: $rngSeed, ')
          ..write('createdAt: $createdAt, ')
          ..write('diedAt: $diedAt, ')
          ..write('deathCause: $deathCause, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sex,
    ageYears,
    heightCm,
    weightKg,
    measuredRestingHr,
    deathMode,
    rngSeed,
    createdAt,
    diedAt,
    deathCause,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.sex == this.sex &&
          other.ageYears == this.ageYears &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.measuredRestingHr == this.measuredRestingHr &&
          other.deathMode == this.deathMode &&
          other.rngSeed == this.rngSeed &&
          other.createdAt == this.createdAt &&
          other.diedAt == this.diedAt &&
          other.deathCause == this.deathCause &&
          other.isActive == this.isActive);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> sex;
  final Value<int> ageYears;
  final Value<int> heightCm;
  final Value<double> weightKg;
  final Value<int?> measuredRestingHr;
  final Value<String> deathMode;
  final Value<int> rngSeed;
  final Value<DateTime> createdAt;
  final Value<DateTime?> diedAt;
  final Value<String?> deathCause;
  final Value<bool> isActive;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sex = const Value.absent(),
    this.ageYears = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.measuredRestingHr = const Value.absent(),
    this.deathMode = const Value.absent(),
    this.rngSeed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.diedAt = const Value.absent(),
    this.deathCause = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String sex,
    required int ageYears,
    required int heightCm,
    required double weightKg,
    this.measuredRestingHr = const Value.absent(),
    required String deathMode,
    required int rngSeed,
    required DateTime createdAt,
    this.diedAt = const Value.absent(),
    this.deathCause = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : name = Value(name),
       sex = Value(sex),
       ageYears = Value(ageYears),
       heightCm = Value(heightCm),
       weightKg = Value(weightKg),
       deathMode = Value(deathMode),
       rngSeed = Value(rngSeed),
       createdAt = Value(createdAt);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? sex,
    Expression<int>? ageYears,
    Expression<int>? heightCm,
    Expression<double>? weightKg,
    Expression<int>? measuredRestingHr,
    Expression<String>? deathMode,
    Expression<int>? rngSeed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? diedAt,
    Expression<String>? deathCause,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sex != null) 'sex': sex,
      if (ageYears != null) 'age_years': ageYears,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (measuredRestingHr != null) 'measured_resting_hr': measuredRestingHr,
      if (deathMode != null) 'death_mode': deathMode,
      if (rngSeed != null) 'rng_seed': rngSeed,
      if (createdAt != null) 'created_at': createdAt,
      if (diedAt != null) 'died_at': diedAt,
      if (deathCause != null) 'death_cause': deathCause,
      if (isActive != null) 'is_active': isActive,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? sex,
    Value<int>? ageYears,
    Value<int>? heightCm,
    Value<double>? weightKg,
    Value<int?>? measuredRestingHr,
    Value<String>? deathMode,
    Value<int>? rngSeed,
    Value<DateTime>? createdAt,
    Value<DateTime?>? diedAt,
    Value<String?>? deathCause,
    Value<bool>? isActive,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      ageYears: ageYears ?? this.ageYears,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      measuredRestingHr: measuredRestingHr ?? this.measuredRestingHr,
      deathMode: deathMode ?? this.deathMode,
      rngSeed: rngSeed ?? this.rngSeed,
      createdAt: createdAt ?? this.createdAt,
      diedAt: diedAt ?? this.diedAt,
      deathCause: deathCause ?? this.deathCause,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (ageYears.present) {
      map['age_years'] = Variable<int>(ageYears.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<int>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (measuredRestingHr.present) {
      map['measured_resting_hr'] = Variable<int>(measuredRestingHr.value);
    }
    if (deathMode.present) {
      map['death_mode'] = Variable<String>(deathMode.value);
    }
    if (rngSeed.present) {
      map['rng_seed'] = Variable<int>(rngSeed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (diedAt.present) {
      map['died_at'] = Variable<DateTime>(diedAt.value);
    }
    if (deathCause.present) {
      map['death_cause'] = Variable<String>(deathCause.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('ageYears: $ageYears, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('measuredRestingHr: $measuredRestingHr, ')
          ..write('deathMode: $deathMode, ')
          ..write('rngSeed: $rngSeed, ')
          ..write('createdAt: $createdAt, ')
          ..write('diedAt: $diedAt, ')
          ..write('deathCause: $deathCause, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $VitalsTable extends Vitals with TableInfo<$VitalsTable, Vital> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VitalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdateMeta = const VerificationMeta(
    'lastUpdate',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdate = GeneratedColumn<DateTime>(
    'last_update',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bloodMlMeta = const VerificationMeta(
    'bloodMl',
  );
  @override
  late final GeneratedColumn<double> bloodMl = GeneratedColumn<double>(
    'blood_ml',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waterMlMeta = const VerificationMeta(
    'waterMl',
  );
  @override
  late final GeneratedColumn<double> waterMl = GeneratedColumn<double>(
    'water_ml',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesKcalMeta = const VerificationMeta(
    'caloriesKcal',
  );
  @override
  late final GeneratedColumn<double> caloriesKcal = GeneratedColumn<double>(
    'calories_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heartRateBpmMeta = const VerificationMeta(
    'heartRateBpm',
  );
  @override
  late final GeneratedColumn<double> heartRateBpm = GeneratedColumn<double>(
    'heart_rate_bpm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sleepDebtSecondsMeta = const VerificationMeta(
    'sleepDebtSeconds',
  );
  @override
  late final GeneratedColumn<int> sleepDebtSeconds = GeneratedColumn<int>(
    'sleep_debt_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _zoneMeta = const VerificationMeta('zone');
  @override
  late final GeneratedColumn<String> zone = GeneratedColumn<String>(
    'zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rngCursorsMeta = const VerificationMeta(
    'rngCursors',
  );
  @override
  late final GeneratedColumn<String> rngCursors = GeneratedColumn<String>(
    'rng_cursors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _bleedTierMeta = const VerificationMeta(
    'bleedTier',
  );
  @override
  late final GeneratedColumn<String> bleedTier = GeneratedColumn<String>(
    'bleed_tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _downUntilMeta = const VerificationMeta(
    'downUntil',
  );
  @override
  late final GeneratedColumn<DateTime> downUntil = GeneratedColumn<DateTime>(
    'down_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _huntUntilMeta = const VerificationMeta(
    'huntUntil',
  );
  @override
  late final GeneratedColumn<DateTime> huntUntil = GeneratedColumn<DateTime>(
    'hunt_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _huntLatitudeMeta = const VerificationMeta(
    'huntLatitude',
  );
  @override
  late final GeneratedColumn<double> huntLatitude = GeneratedColumn<double>(
    'hunt_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _huntLongitudeMeta = const VerificationMeta(
    'huntLongitude',
  );
  @override
  late final GeneratedColumn<double> huntLongitude = GeneratedColumn<double>(
    'hunt_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _huntCountMeta = const VerificationMeta(
    'huntCount',
  );
  @override
  late final GeneratedColumn<int> huntCount = GeneratedColumn<int>(
    'hunt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _occupationJsonMeta = const VerificationMeta(
    'occupationJson',
  );
  @override
  late final GeneratedColumn<String> occupationJson = GeneratedColumn<String>(
    'occupation_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedKmhMeta = const VerificationMeta(
    'speedKmh',
  );
  @override
  late final GeneratedColumn<double> speedKmh = GeneratedColumn<double>(
    'speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carriedKgMeta = const VerificationMeta(
    'carriedKg',
  );
  @override
  late final GeneratedColumn<double> carriedKg = GeneratedColumn<double>(
    'carried_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pendingKcalMeta = const VerificationMeta(
    'pendingKcal',
  );
  @override
  late final GeneratedColumn<double> pendingKcal = GeneratedColumn<double>(
    'pending_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pendingWaterMlMeta = const VerificationMeta(
    'pendingWaterMl',
  );
  @override
  late final GeneratedColumn<double> pendingWaterMl = GeneratedColumn<double>(
    'pending_water_ml',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    lastUpdate,
    bloodMl,
    waterMl,
    caloriesKcal,
    heartRateBpm,
    sleepDebtSeconds,
    zone,
    latitude,
    longitude,
    accuracyM,
    rngCursors,
    bleedTier,
    downUntil,
    huntUntil,
    huntLatitude,
    huntLongitude,
    huntCount,
    occupationJson,
    speedKmh,
    carriedKg,
    pendingKcal,
    pendingWaterMl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vitals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vital> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('last_update')) {
      context.handle(
        _lastUpdateMeta,
        lastUpdate.isAcceptableOrUnknown(data['last_update']!, _lastUpdateMeta),
      );
    } else if (isInserting) {
      context.missing(_lastUpdateMeta);
    }
    if (data.containsKey('blood_ml')) {
      context.handle(
        _bloodMlMeta,
        bloodMl.isAcceptableOrUnknown(data['blood_ml']!, _bloodMlMeta),
      );
    } else if (isInserting) {
      context.missing(_bloodMlMeta);
    }
    if (data.containsKey('water_ml')) {
      context.handle(
        _waterMlMeta,
        waterMl.isAcceptableOrUnknown(data['water_ml']!, _waterMlMeta),
      );
    } else if (isInserting) {
      context.missing(_waterMlMeta);
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
        _caloriesKcalMeta,
        caloriesKcal.isAcceptableOrUnknown(
          data['calories_kcal']!,
          _caloriesKcalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesKcalMeta);
    }
    if (data.containsKey('heart_rate_bpm')) {
      context.handle(
        _heartRateBpmMeta,
        heartRateBpm.isAcceptableOrUnknown(
          data['heart_rate_bpm']!,
          _heartRateBpmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_heartRateBpmMeta);
    }
    if (data.containsKey('sleep_debt_seconds')) {
      context.handle(
        _sleepDebtSecondsMeta,
        sleepDebtSeconds.isAcceptableOrUnknown(
          data['sleep_debt_seconds']!,
          _sleepDebtSecondsMeta,
        ),
      );
    }
    if (data.containsKey('zone')) {
      context.handle(
        _zoneMeta,
        zone.isAcceptableOrUnknown(data['zone']!, _zoneMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('rng_cursors')) {
      context.handle(
        _rngCursorsMeta,
        rngCursors.isAcceptableOrUnknown(data['rng_cursors']!, _rngCursorsMeta),
      );
    }
    if (data.containsKey('bleed_tier')) {
      context.handle(
        _bleedTierMeta,
        bleedTier.isAcceptableOrUnknown(data['bleed_tier']!, _bleedTierMeta),
      );
    }
    if (data.containsKey('down_until')) {
      context.handle(
        _downUntilMeta,
        downUntil.isAcceptableOrUnknown(data['down_until']!, _downUntilMeta),
      );
    }
    if (data.containsKey('hunt_until')) {
      context.handle(
        _huntUntilMeta,
        huntUntil.isAcceptableOrUnknown(data['hunt_until']!, _huntUntilMeta),
      );
    }
    if (data.containsKey('hunt_latitude')) {
      context.handle(
        _huntLatitudeMeta,
        huntLatitude.isAcceptableOrUnknown(
          data['hunt_latitude']!,
          _huntLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('hunt_longitude')) {
      context.handle(
        _huntLongitudeMeta,
        huntLongitude.isAcceptableOrUnknown(
          data['hunt_longitude']!,
          _huntLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('hunt_count')) {
      context.handle(
        _huntCountMeta,
        huntCount.isAcceptableOrUnknown(data['hunt_count']!, _huntCountMeta),
      );
    }
    if (data.containsKey('occupation_json')) {
      context.handle(
        _occupationJsonMeta,
        occupationJson.isAcceptableOrUnknown(
          data['occupation_json']!,
          _occupationJsonMeta,
        ),
      );
    }
    if (data.containsKey('speed_kmh')) {
      context.handle(
        _speedKmhMeta,
        speedKmh.isAcceptableOrUnknown(data['speed_kmh']!, _speedKmhMeta),
      );
    }
    if (data.containsKey('carried_kg')) {
      context.handle(
        _carriedKgMeta,
        carriedKg.isAcceptableOrUnknown(data['carried_kg']!, _carriedKgMeta),
      );
    }
    if (data.containsKey('pending_kcal')) {
      context.handle(
        _pendingKcalMeta,
        pendingKcal.isAcceptableOrUnknown(
          data['pending_kcal']!,
          _pendingKcalMeta,
        ),
      );
    }
    if (data.containsKey('pending_water_ml')) {
      context.handle(
        _pendingWaterMlMeta,
        pendingWaterMl.isAcceptableOrUnknown(
          data['pending_water_ml']!,
          _pendingWaterMlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  Vital map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vital(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      lastUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_update'],
      )!,
      bloodMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}blood_ml'],
      )!,
      waterMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_ml'],
      )!,
      caloriesKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories_kcal'],
      )!,
      heartRateBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heart_rate_bpm'],
      )!,
      sleepDebtSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_debt_seconds'],
      )!,
      zone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      rngCursors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rng_cursors'],
      )!,
      bleedTier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bleed_tier'],
      )!,
      downUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}down_until'],
      ),
      huntUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hunt_until'],
      ),
      huntLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hunt_latitude'],
      ),
      huntLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hunt_longitude'],
      ),
      huntCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hunt_count'],
      )!,
      occupationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occupation_json'],
      ),
      speedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_kmh'],
      )!,
      carriedKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carried_kg'],
      )!,
      pendingKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pending_kcal'],
      )!,
      pendingWaterMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pending_water_ml'],
      )!,
    );
  }

  @override
  $VitalsTable createAlias(String alias) {
    return $VitalsTable(attachedDatabase, alias);
  }
}

class Vital extends DataClass implements Insertable<Vital> {
  final int profileId;

  /// Monotonic timestamp the simulation has been advanced to. Every tick is
  /// derived from this rather than from an incrementing counter, which is what
  /// makes replaying a tick idempotent (§11.1.2).
  final DateTime lastUpdate;
  final double bloodMl;
  final double waterMl;
  final double caloriesKcal;
  final double heartRateBpm;

  /// Accumulated sleep debt in seconds (§2.5.4).
  final int sleepDebtSeconds;

  /// Last known metabolic zone: 'open' | 'camp' | 'shelter' | 'sleep' (§2.1).
  /// With GPS off the game assumes the character stayed in this zone.
  final String zone;
  final double? latitude;
  final double? longitude;
  final double? accuracyM;

  /// Draw position of each RNG stream, so a resumed session continues the
  /// sequence instead of restarting it.
  final String rngCursors;

  /// Current bleeding tier (§2.6): none | superficial | moderate | severe |
  /// arterial. A wound has to survive the app being killed — otherwise closing
  /// the app would be first aid.
  final String bleedTier;

  /// §9.2: when a softcore character comes round, or null while they are on
  /// their feet. Wall-clock, and the one state in the game that runs with the
  /// app closed on purpose — being unconscious cannot require watching a
  /// screen.
  final DateTime? downUntil;

  /// §5.6.2, §6.1a: a fight the player walked out of, and where.
  ///
  /// ⚠️ The enemies themselves are not written down — §6.4 remakes them every
  /// run — so without this, closing the app is a perfect escape from anything.
  /// Four numbers is all it takes to make it not one: when the street was last
  /// stirred up, where, and by how many.
  final DateTime? huntUntil;
  final double? huntLatitude;
  final double? huntLongitude;
  final int huntCount;

  /// Occupation in progress, as JSON (§2.1a). Null when the character is idle.
  ///
  /// Stored opaquely rather than as columns: occupations gain fields as the
  /// shelter systems of §8 and §18 arrive, and each of those would otherwise
  /// be a schema migration.
  final String? occupationJson;

  /// Ground speed from the last accepted fix, in km/h. Persisted so a catch-up
  /// after a crash does not restart the character from a standstill.
  final double speedKmh;

  /// What the character is carrying, in kilograms. Feeds the load surcharge of
  /// §2.2 until the real inventory arrives in stage 4.
  final double carriedKg;

  /// Eaten and drunk, not yet absorbed (§2.2, §2.3).
  ///
  /// Persisted because it is real: a player who eats and closes the app has
  /// food in them, and losing it on a restart would teach them to stand and
  /// watch the bar instead.
  final double pendingKcal;
  final double pendingWaterMl;
  const Vital({
    required this.profileId,
    required this.lastUpdate,
    required this.bloodMl,
    required this.waterMl,
    required this.caloriesKcal,
    required this.heartRateBpm,
    required this.sleepDebtSeconds,
    required this.zone,
    this.latitude,
    this.longitude,
    this.accuracyM,
    required this.rngCursors,
    required this.bleedTier,
    this.downUntil,
    this.huntUntil,
    this.huntLatitude,
    this.huntLongitude,
    required this.huntCount,
    this.occupationJson,
    required this.speedKmh,
    required this.carriedKg,
    required this.pendingKcal,
    required this.pendingWaterMl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['last_update'] = Variable<DateTime>(lastUpdate);
    map['blood_ml'] = Variable<double>(bloodMl);
    map['water_ml'] = Variable<double>(waterMl);
    map['calories_kcal'] = Variable<double>(caloriesKcal);
    map['heart_rate_bpm'] = Variable<double>(heartRateBpm);
    map['sleep_debt_seconds'] = Variable<int>(sleepDebtSeconds);
    map['zone'] = Variable<String>(zone);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    map['rng_cursors'] = Variable<String>(rngCursors);
    map['bleed_tier'] = Variable<String>(bleedTier);
    if (!nullToAbsent || downUntil != null) {
      map['down_until'] = Variable<DateTime>(downUntil);
    }
    if (!nullToAbsent || huntUntil != null) {
      map['hunt_until'] = Variable<DateTime>(huntUntil);
    }
    if (!nullToAbsent || huntLatitude != null) {
      map['hunt_latitude'] = Variable<double>(huntLatitude);
    }
    if (!nullToAbsent || huntLongitude != null) {
      map['hunt_longitude'] = Variable<double>(huntLongitude);
    }
    map['hunt_count'] = Variable<int>(huntCount);
    if (!nullToAbsent || occupationJson != null) {
      map['occupation_json'] = Variable<String>(occupationJson);
    }
    map['speed_kmh'] = Variable<double>(speedKmh);
    map['carried_kg'] = Variable<double>(carriedKg);
    map['pending_kcal'] = Variable<double>(pendingKcal);
    map['pending_water_ml'] = Variable<double>(pendingWaterMl);
    return map;
  }

  VitalsCompanion toCompanion(bool nullToAbsent) {
    return VitalsCompanion(
      profileId: Value(profileId),
      lastUpdate: Value(lastUpdate),
      bloodMl: Value(bloodMl),
      waterMl: Value(waterMl),
      caloriesKcal: Value(caloriesKcal),
      heartRateBpm: Value(heartRateBpm),
      sleepDebtSeconds: Value(sleepDebtSeconds),
      zone: Value(zone),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      rngCursors: Value(rngCursors),
      bleedTier: Value(bleedTier),
      downUntil: downUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(downUntil),
      huntUntil: huntUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(huntUntil),
      huntLatitude: huntLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(huntLatitude),
      huntLongitude: huntLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(huntLongitude),
      huntCount: Value(huntCount),
      occupationJson: occupationJson == null && nullToAbsent
          ? const Value.absent()
          : Value(occupationJson),
      speedKmh: Value(speedKmh),
      carriedKg: Value(carriedKg),
      pendingKcal: Value(pendingKcal),
      pendingWaterMl: Value(pendingWaterMl),
    );
  }

  factory Vital.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vital(
      profileId: serializer.fromJson<int>(json['profileId']),
      lastUpdate: serializer.fromJson<DateTime>(json['lastUpdate']),
      bloodMl: serializer.fromJson<double>(json['bloodMl']),
      waterMl: serializer.fromJson<double>(json['waterMl']),
      caloriesKcal: serializer.fromJson<double>(json['caloriesKcal']),
      heartRateBpm: serializer.fromJson<double>(json['heartRateBpm']),
      sleepDebtSeconds: serializer.fromJson<int>(json['sleepDebtSeconds']),
      zone: serializer.fromJson<String>(json['zone']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      rngCursors: serializer.fromJson<String>(json['rngCursors']),
      bleedTier: serializer.fromJson<String>(json['bleedTier']),
      downUntil: serializer.fromJson<DateTime?>(json['downUntil']),
      huntUntil: serializer.fromJson<DateTime?>(json['huntUntil']),
      huntLatitude: serializer.fromJson<double?>(json['huntLatitude']),
      huntLongitude: serializer.fromJson<double?>(json['huntLongitude']),
      huntCount: serializer.fromJson<int>(json['huntCount']),
      occupationJson: serializer.fromJson<String?>(json['occupationJson']),
      speedKmh: serializer.fromJson<double>(json['speedKmh']),
      carriedKg: serializer.fromJson<double>(json['carriedKg']),
      pendingKcal: serializer.fromJson<double>(json['pendingKcal']),
      pendingWaterMl: serializer.fromJson<double>(json['pendingWaterMl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'lastUpdate': serializer.toJson<DateTime>(lastUpdate),
      'bloodMl': serializer.toJson<double>(bloodMl),
      'waterMl': serializer.toJson<double>(waterMl),
      'caloriesKcal': serializer.toJson<double>(caloriesKcal),
      'heartRateBpm': serializer.toJson<double>(heartRateBpm),
      'sleepDebtSeconds': serializer.toJson<int>(sleepDebtSeconds),
      'zone': serializer.toJson<String>(zone),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'rngCursors': serializer.toJson<String>(rngCursors),
      'bleedTier': serializer.toJson<String>(bleedTier),
      'downUntil': serializer.toJson<DateTime?>(downUntil),
      'huntUntil': serializer.toJson<DateTime?>(huntUntil),
      'huntLatitude': serializer.toJson<double?>(huntLatitude),
      'huntLongitude': serializer.toJson<double?>(huntLongitude),
      'huntCount': serializer.toJson<int>(huntCount),
      'occupationJson': serializer.toJson<String?>(occupationJson),
      'speedKmh': serializer.toJson<double>(speedKmh),
      'carriedKg': serializer.toJson<double>(carriedKg),
      'pendingKcal': serializer.toJson<double>(pendingKcal),
      'pendingWaterMl': serializer.toJson<double>(pendingWaterMl),
    };
  }

  Vital copyWith({
    int? profileId,
    DateTime? lastUpdate,
    double? bloodMl,
    double? waterMl,
    double? caloriesKcal,
    double? heartRateBpm,
    int? sleepDebtSeconds,
    String? zone,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<double?> accuracyM = const Value.absent(),
    String? rngCursors,
    String? bleedTier,
    Value<DateTime?> downUntil = const Value.absent(),
    Value<DateTime?> huntUntil = const Value.absent(),
    Value<double?> huntLatitude = const Value.absent(),
    Value<double?> huntLongitude = const Value.absent(),
    int? huntCount,
    Value<String?> occupationJson = const Value.absent(),
    double? speedKmh,
    double? carriedKg,
    double? pendingKcal,
    double? pendingWaterMl,
  }) => Vital(
    profileId: profileId ?? this.profileId,
    lastUpdate: lastUpdate ?? this.lastUpdate,
    bloodMl: bloodMl ?? this.bloodMl,
    waterMl: waterMl ?? this.waterMl,
    caloriesKcal: caloriesKcal ?? this.caloriesKcal,
    heartRateBpm: heartRateBpm ?? this.heartRateBpm,
    sleepDebtSeconds: sleepDebtSeconds ?? this.sleepDebtSeconds,
    zone: zone ?? this.zone,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    rngCursors: rngCursors ?? this.rngCursors,
    bleedTier: bleedTier ?? this.bleedTier,
    downUntil: downUntil.present ? downUntil.value : this.downUntil,
    huntUntil: huntUntil.present ? huntUntil.value : this.huntUntil,
    huntLatitude: huntLatitude.present ? huntLatitude.value : this.huntLatitude,
    huntLongitude: huntLongitude.present
        ? huntLongitude.value
        : this.huntLongitude,
    huntCount: huntCount ?? this.huntCount,
    occupationJson: occupationJson.present
        ? occupationJson.value
        : this.occupationJson,
    speedKmh: speedKmh ?? this.speedKmh,
    carriedKg: carriedKg ?? this.carriedKg,
    pendingKcal: pendingKcal ?? this.pendingKcal,
    pendingWaterMl: pendingWaterMl ?? this.pendingWaterMl,
  );
  Vital copyWithCompanion(VitalsCompanion data) {
    return Vital(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      lastUpdate: data.lastUpdate.present
          ? data.lastUpdate.value
          : this.lastUpdate,
      bloodMl: data.bloodMl.present ? data.bloodMl.value : this.bloodMl,
      waterMl: data.waterMl.present ? data.waterMl.value : this.waterMl,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      heartRateBpm: data.heartRateBpm.present
          ? data.heartRateBpm.value
          : this.heartRateBpm,
      sleepDebtSeconds: data.sleepDebtSeconds.present
          ? data.sleepDebtSeconds.value
          : this.sleepDebtSeconds,
      zone: data.zone.present ? data.zone.value : this.zone,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      rngCursors: data.rngCursors.present
          ? data.rngCursors.value
          : this.rngCursors,
      bleedTier: data.bleedTier.present ? data.bleedTier.value : this.bleedTier,
      downUntil: data.downUntil.present ? data.downUntil.value : this.downUntil,
      huntUntil: data.huntUntil.present ? data.huntUntil.value : this.huntUntil,
      huntLatitude: data.huntLatitude.present
          ? data.huntLatitude.value
          : this.huntLatitude,
      huntLongitude: data.huntLongitude.present
          ? data.huntLongitude.value
          : this.huntLongitude,
      huntCount: data.huntCount.present ? data.huntCount.value : this.huntCount,
      occupationJson: data.occupationJson.present
          ? data.occupationJson.value
          : this.occupationJson,
      speedKmh: data.speedKmh.present ? data.speedKmh.value : this.speedKmh,
      carriedKg: data.carriedKg.present ? data.carriedKg.value : this.carriedKg,
      pendingKcal: data.pendingKcal.present
          ? data.pendingKcal.value
          : this.pendingKcal,
      pendingWaterMl: data.pendingWaterMl.present
          ? data.pendingWaterMl.value
          : this.pendingWaterMl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vital(')
          ..write('profileId: $profileId, ')
          ..write('lastUpdate: $lastUpdate, ')
          ..write('bloodMl: $bloodMl, ')
          ..write('waterMl: $waterMl, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('sleepDebtSeconds: $sleepDebtSeconds, ')
          ..write('zone: $zone, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('rngCursors: $rngCursors, ')
          ..write('bleedTier: $bleedTier, ')
          ..write('downUntil: $downUntil, ')
          ..write('huntUntil: $huntUntil, ')
          ..write('huntLatitude: $huntLatitude, ')
          ..write('huntLongitude: $huntLongitude, ')
          ..write('huntCount: $huntCount, ')
          ..write('occupationJson: $occupationJson, ')
          ..write('speedKmh: $speedKmh, ')
          ..write('carriedKg: $carriedKg, ')
          ..write('pendingKcal: $pendingKcal, ')
          ..write('pendingWaterMl: $pendingWaterMl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    profileId,
    lastUpdate,
    bloodMl,
    waterMl,
    caloriesKcal,
    heartRateBpm,
    sleepDebtSeconds,
    zone,
    latitude,
    longitude,
    accuracyM,
    rngCursors,
    bleedTier,
    downUntil,
    huntUntil,
    huntLatitude,
    huntLongitude,
    huntCount,
    occupationJson,
    speedKmh,
    carriedKg,
    pendingKcal,
    pendingWaterMl,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vital &&
          other.profileId == this.profileId &&
          other.lastUpdate == this.lastUpdate &&
          other.bloodMl == this.bloodMl &&
          other.waterMl == this.waterMl &&
          other.caloriesKcal == this.caloriesKcal &&
          other.heartRateBpm == this.heartRateBpm &&
          other.sleepDebtSeconds == this.sleepDebtSeconds &&
          other.zone == this.zone &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracyM == this.accuracyM &&
          other.rngCursors == this.rngCursors &&
          other.bleedTier == this.bleedTier &&
          other.downUntil == this.downUntil &&
          other.huntUntil == this.huntUntil &&
          other.huntLatitude == this.huntLatitude &&
          other.huntLongitude == this.huntLongitude &&
          other.huntCount == this.huntCount &&
          other.occupationJson == this.occupationJson &&
          other.speedKmh == this.speedKmh &&
          other.carriedKg == this.carriedKg &&
          other.pendingKcal == this.pendingKcal &&
          other.pendingWaterMl == this.pendingWaterMl);
}

class VitalsCompanion extends UpdateCompanion<Vital> {
  final Value<int> profileId;
  final Value<DateTime> lastUpdate;
  final Value<double> bloodMl;
  final Value<double> waterMl;
  final Value<double> caloriesKcal;
  final Value<double> heartRateBpm;
  final Value<int> sleepDebtSeconds;
  final Value<String> zone;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> accuracyM;
  final Value<String> rngCursors;
  final Value<String> bleedTier;
  final Value<DateTime?> downUntil;
  final Value<DateTime?> huntUntil;
  final Value<double?> huntLatitude;
  final Value<double?> huntLongitude;
  final Value<int> huntCount;
  final Value<String?> occupationJson;
  final Value<double> speedKmh;
  final Value<double> carriedKg;
  final Value<double> pendingKcal;
  final Value<double> pendingWaterMl;
  const VitalsCompanion({
    this.profileId = const Value.absent(),
    this.lastUpdate = const Value.absent(),
    this.bloodMl = const Value.absent(),
    this.waterMl = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.sleepDebtSeconds = const Value.absent(),
    this.zone = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.rngCursors = const Value.absent(),
    this.bleedTier = const Value.absent(),
    this.downUntil = const Value.absent(),
    this.huntUntil = const Value.absent(),
    this.huntLatitude = const Value.absent(),
    this.huntLongitude = const Value.absent(),
    this.huntCount = const Value.absent(),
    this.occupationJson = const Value.absent(),
    this.speedKmh = const Value.absent(),
    this.carriedKg = const Value.absent(),
    this.pendingKcal = const Value.absent(),
    this.pendingWaterMl = const Value.absent(),
  });
  VitalsCompanion.insert({
    this.profileId = const Value.absent(),
    required DateTime lastUpdate,
    required double bloodMl,
    required double waterMl,
    required double caloriesKcal,
    required double heartRateBpm,
    this.sleepDebtSeconds = const Value.absent(),
    this.zone = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.rngCursors = const Value.absent(),
    this.bleedTier = const Value.absent(),
    this.downUntil = const Value.absent(),
    this.huntUntil = const Value.absent(),
    this.huntLatitude = const Value.absent(),
    this.huntLongitude = const Value.absent(),
    this.huntCount = const Value.absent(),
    this.occupationJson = const Value.absent(),
    this.speedKmh = const Value.absent(),
    this.carriedKg = const Value.absent(),
    this.pendingKcal = const Value.absent(),
    this.pendingWaterMl = const Value.absent(),
  }) : lastUpdate = Value(lastUpdate),
       bloodMl = Value(bloodMl),
       waterMl = Value(waterMl),
       caloriesKcal = Value(caloriesKcal),
       heartRateBpm = Value(heartRateBpm);
  static Insertable<Vital> custom({
    Expression<int>? profileId,
    Expression<DateTime>? lastUpdate,
    Expression<double>? bloodMl,
    Expression<double>? waterMl,
    Expression<double>? caloriesKcal,
    Expression<double>? heartRateBpm,
    Expression<int>? sleepDebtSeconds,
    Expression<String>? zone,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracyM,
    Expression<String>? rngCursors,
    Expression<String>? bleedTier,
    Expression<DateTime>? downUntil,
    Expression<DateTime>? huntUntil,
    Expression<double>? huntLatitude,
    Expression<double>? huntLongitude,
    Expression<int>? huntCount,
    Expression<String>? occupationJson,
    Expression<double>? speedKmh,
    Expression<double>? carriedKg,
    Expression<double>? pendingKcal,
    Expression<double>? pendingWaterMl,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (lastUpdate != null) 'last_update': lastUpdate,
      if (bloodMl != null) 'blood_ml': bloodMl,
      if (waterMl != null) 'water_ml': waterMl,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (heartRateBpm != null) 'heart_rate_bpm': heartRateBpm,
      if (sleepDebtSeconds != null) 'sleep_debt_seconds': sleepDebtSeconds,
      if (zone != null) 'zone': zone,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (rngCursors != null) 'rng_cursors': rngCursors,
      if (bleedTier != null) 'bleed_tier': bleedTier,
      if (downUntil != null) 'down_until': downUntil,
      if (huntUntil != null) 'hunt_until': huntUntil,
      if (huntLatitude != null) 'hunt_latitude': huntLatitude,
      if (huntLongitude != null) 'hunt_longitude': huntLongitude,
      if (huntCount != null) 'hunt_count': huntCount,
      if (occupationJson != null) 'occupation_json': occupationJson,
      if (speedKmh != null) 'speed_kmh': speedKmh,
      if (carriedKg != null) 'carried_kg': carriedKg,
      if (pendingKcal != null) 'pending_kcal': pendingKcal,
      if (pendingWaterMl != null) 'pending_water_ml': pendingWaterMl,
    });
  }

  VitalsCompanion copyWith({
    Value<int>? profileId,
    Value<DateTime>? lastUpdate,
    Value<double>? bloodMl,
    Value<double>? waterMl,
    Value<double>? caloriesKcal,
    Value<double>? heartRateBpm,
    Value<int>? sleepDebtSeconds,
    Value<String>? zone,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<double?>? accuracyM,
    Value<String>? rngCursors,
    Value<String>? bleedTier,
    Value<DateTime?>? downUntil,
    Value<DateTime?>? huntUntil,
    Value<double?>? huntLatitude,
    Value<double?>? huntLongitude,
    Value<int>? huntCount,
    Value<String?>? occupationJson,
    Value<double>? speedKmh,
    Value<double>? carriedKg,
    Value<double>? pendingKcal,
    Value<double>? pendingWaterMl,
  }) {
    return VitalsCompanion(
      profileId: profileId ?? this.profileId,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      bloodMl: bloodMl ?? this.bloodMl,
      waterMl: waterMl ?? this.waterMl,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      sleepDebtSeconds: sleepDebtSeconds ?? this.sleepDebtSeconds,
      zone: zone ?? this.zone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyM: accuracyM ?? this.accuracyM,
      rngCursors: rngCursors ?? this.rngCursors,
      bleedTier: bleedTier ?? this.bleedTier,
      downUntil: downUntil ?? this.downUntil,
      huntUntil: huntUntil ?? this.huntUntil,
      huntLatitude: huntLatitude ?? this.huntLatitude,
      huntLongitude: huntLongitude ?? this.huntLongitude,
      huntCount: huntCount ?? this.huntCount,
      occupationJson: occupationJson ?? this.occupationJson,
      speedKmh: speedKmh ?? this.speedKmh,
      carriedKg: carriedKg ?? this.carriedKg,
      pendingKcal: pendingKcal ?? this.pendingKcal,
      pendingWaterMl: pendingWaterMl ?? this.pendingWaterMl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (lastUpdate.present) {
      map['last_update'] = Variable<DateTime>(lastUpdate.value);
    }
    if (bloodMl.present) {
      map['blood_ml'] = Variable<double>(bloodMl.value);
    }
    if (waterMl.present) {
      map['water_ml'] = Variable<double>(waterMl.value);
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<double>(caloriesKcal.value);
    }
    if (heartRateBpm.present) {
      map['heart_rate_bpm'] = Variable<double>(heartRateBpm.value);
    }
    if (sleepDebtSeconds.present) {
      map['sleep_debt_seconds'] = Variable<int>(sleepDebtSeconds.value);
    }
    if (zone.present) {
      map['zone'] = Variable<String>(zone.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (rngCursors.present) {
      map['rng_cursors'] = Variable<String>(rngCursors.value);
    }
    if (bleedTier.present) {
      map['bleed_tier'] = Variable<String>(bleedTier.value);
    }
    if (downUntil.present) {
      map['down_until'] = Variable<DateTime>(downUntil.value);
    }
    if (huntUntil.present) {
      map['hunt_until'] = Variable<DateTime>(huntUntil.value);
    }
    if (huntLatitude.present) {
      map['hunt_latitude'] = Variable<double>(huntLatitude.value);
    }
    if (huntLongitude.present) {
      map['hunt_longitude'] = Variable<double>(huntLongitude.value);
    }
    if (huntCount.present) {
      map['hunt_count'] = Variable<int>(huntCount.value);
    }
    if (occupationJson.present) {
      map['occupation_json'] = Variable<String>(occupationJson.value);
    }
    if (speedKmh.present) {
      map['speed_kmh'] = Variable<double>(speedKmh.value);
    }
    if (carriedKg.present) {
      map['carried_kg'] = Variable<double>(carriedKg.value);
    }
    if (pendingKcal.present) {
      map['pending_kcal'] = Variable<double>(pendingKcal.value);
    }
    if (pendingWaterMl.present) {
      map['pending_water_ml'] = Variable<double>(pendingWaterMl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VitalsCompanion(')
          ..write('profileId: $profileId, ')
          ..write('lastUpdate: $lastUpdate, ')
          ..write('bloodMl: $bloodMl, ')
          ..write('waterMl: $waterMl, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('sleepDebtSeconds: $sleepDebtSeconds, ')
          ..write('zone: $zone, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('rngCursors: $rngCursors, ')
          ..write('bleedTier: $bleedTier, ')
          ..write('downUntil: $downUntil, ')
          ..write('huntUntil: $huntUntil, ')
          ..write('huntLatitude: $huntLatitude, ')
          ..write('huntLongitude: $huntLongitude, ')
          ..write('huntCount: $huntCount, ')
          ..write('occupationJson: $occupationJson, ')
          ..write('speedKmh: $speedKmh, ')
          ..write('carriedKg: $carriedKg, ')
          ..write('pendingKcal: $pendingKcal, ')
          ..write('pendingWaterMl: $pendingWaterMl')
          ..write(')'))
        .toString();
  }
}

class $ChronicleEntriesTable extends ChronicleEntries
    with TableInfo<$ChronicleEntriesTable, ChronicleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChronicleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _survivalDaysMeta = const VerificationMeta(
    'survivalDays',
  );
  @override
  late final GeneratedColumn<int> survivalDays = GeneratedColumn<int>(
    'survival_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _causeMeta = const VerificationMeta('cause');
  @override
  late final GeneratedColumn<String> cause = GeneratedColumn<String>(
    'cause',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deathModeMeta = const VerificationMeta(
    'deathMode',
  );
  @override
  late final GeneratedColumn<String> deathMode = GeneratedColumn<String>(
    'death_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta(
    'snapshotJson',
  );
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    survivalDays,
    startedAt,
    endedAt,
    cause,
    deathMode,
    snapshotJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chronicle_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChronicleEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('survival_days')) {
      context.handle(
        _survivalDaysMeta,
        survivalDays.isAcceptableOrUnknown(
          data['survival_days']!,
          _survivalDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_survivalDaysMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('cause')) {
      context.handle(
        _causeMeta,
        cause.isAcceptableOrUnknown(data['cause']!, _causeMeta),
      );
    } else if (isInserting) {
      context.missing(_causeMeta);
    }
    if (data.containsKey('death_mode')) {
      context.handle(
        _deathModeMeta,
        deathMode.isAcceptableOrUnknown(data['death_mode']!, _deathModeMeta),
      );
    } else if (isInserting) {
      context.missing(_deathModeMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChronicleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChronicleEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      survivalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}survival_days'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      cause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cause'],
      )!,
      deathMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}death_mode'],
      )!,
      snapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
    );
  }

  @override
  $ChronicleEntriesTable createAlias(String alias) {
    return $ChronicleEntriesTable(attachedDatabase, alias);
  }
}

class ChronicleEntry extends DataClass implements Insertable<ChronicleEntry> {
  final int id;
  final int profileId;
  final int survivalDays;
  final DateTime startedAt;
  final DateTime endedAt;
  final String cause;
  final String deathMode;

  /// Full state dump at the moment the streak ended, as JSON: hotspot levels,
  /// skills, location. Kept opaque so adding fields never needs a migration.
  final String snapshotJson;
  const ChronicleEntry({
    required this.id,
    required this.profileId,
    required this.survivalDays,
    required this.startedAt,
    required this.endedAt,
    required this.cause,
    required this.deathMode,
    required this.snapshotJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['survival_days'] = Variable<int>(survivalDays);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['cause'] = Variable<String>(cause);
    map['death_mode'] = Variable<String>(deathMode);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    return map;
  }

  ChronicleEntriesCompanion toCompanion(bool nullToAbsent) {
    return ChronicleEntriesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      survivalDays: Value(survivalDays),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      cause: Value(cause),
      deathMode: Value(deathMode),
      snapshotJson: Value(snapshotJson),
    );
  }

  factory ChronicleEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChronicleEntry(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      survivalDays: serializer.fromJson<int>(json['survivalDays']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      cause: serializer.fromJson<String>(json['cause']),
      deathMode: serializer.fromJson<String>(json['deathMode']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'survivalDays': serializer.toJson<int>(survivalDays),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'cause': serializer.toJson<String>(cause),
      'deathMode': serializer.toJson<String>(deathMode),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
    };
  }

  ChronicleEntry copyWith({
    int? id,
    int? profileId,
    int? survivalDays,
    DateTime? startedAt,
    DateTime? endedAt,
    String? cause,
    String? deathMode,
    String? snapshotJson,
  }) => ChronicleEntry(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    survivalDays: survivalDays ?? this.survivalDays,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    cause: cause ?? this.cause,
    deathMode: deathMode ?? this.deathMode,
    snapshotJson: snapshotJson ?? this.snapshotJson,
  );
  ChronicleEntry copyWithCompanion(ChronicleEntriesCompanion data) {
    return ChronicleEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      survivalDays: data.survivalDays.present
          ? data.survivalDays.value
          : this.survivalDays,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      cause: data.cause.present ? data.cause.value : this.cause,
      deathMode: data.deathMode.present ? data.deathMode.value : this.deathMode,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChronicleEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('survivalDays: $survivalDays, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('cause: $cause, ')
          ..write('deathMode: $deathMode, ')
          ..write('snapshotJson: $snapshotJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    survivalDays,
    startedAt,
    endedAt,
    cause,
    deathMode,
    snapshotJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChronicleEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.survivalDays == this.survivalDays &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.cause == this.cause &&
          other.deathMode == this.deathMode &&
          other.snapshotJson == this.snapshotJson);
}

class ChronicleEntriesCompanion extends UpdateCompanion<ChronicleEntry> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<int> survivalDays;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<String> cause;
  final Value<String> deathMode;
  final Value<String> snapshotJson;
  const ChronicleEntriesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.survivalDays = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.cause = const Value.absent(),
    this.deathMode = const Value.absent(),
    this.snapshotJson = const Value.absent(),
  });
  ChronicleEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required int survivalDays,
    required DateTime startedAt,
    required DateTime endedAt,
    required String cause,
    required String deathMode,
    this.snapshotJson = const Value.absent(),
  }) : profileId = Value(profileId),
       survivalDays = Value(survivalDays),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       cause = Value(cause),
       deathMode = Value(deathMode);
  static Insertable<ChronicleEntry> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<int>? survivalDays,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? cause,
    Expression<String>? deathMode,
    Expression<String>? snapshotJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (survivalDays != null) 'survival_days': survivalDays,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (cause != null) 'cause': cause,
      if (deathMode != null) 'death_mode': deathMode,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
    });
  }

  ChronicleEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<int>? survivalDays,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<String>? cause,
    Value<String>? deathMode,
    Value<String>? snapshotJson,
  }) {
    return ChronicleEntriesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      survivalDays: survivalDays ?? this.survivalDays,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      cause: cause ?? this.cause,
      deathMode: deathMode ?? this.deathMode,
      snapshotJson: snapshotJson ?? this.snapshotJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (survivalDays.present) {
      map['survival_days'] = Variable<int>(survivalDays.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (cause.present) {
      map['cause'] = Variable<String>(cause.value);
    }
    if (deathMode.present) {
      map['death_mode'] = Variable<String>(deathMode.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChronicleEntriesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('survivalDays: $survivalDays, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('cause: $cause, ')
          ..write('deathMode: $deathMode, ')
          ..write('snapshotJson: $snapshotJson')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotRecordsTable extends SnapshotRecords
    with TableInfo<$SnapshotRecordsTable, SnapshotRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('periodic'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileName,
    takenAt,
    sizeBytes,
    checksum,
    schemaVersion,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshot_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SnapshotRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $SnapshotRecordsTable createAlias(String alias) {
    return $SnapshotRecordsTable(attachedDatabase, alias);
  }
}

class SnapshotRecord extends DataClass implements Insertable<SnapshotRecord> {
  final int id;
  final String fileName;
  final DateTime takenAt;
  final int sizeBytes;

  /// SHA-256 of the snapshot file, checked before any restore.
  final String checksum;

  /// Schema version the snapshot was taken at, so a snapshot from an older
  /// build is migrated rather than loaded blind.
  final int schemaVersion;

  /// 'periodic' | 'pre_migration' — a pre-migration snapshot is never rotated
  /// out until the migration it guards has been proven good.
  final String reason;
  const SnapshotRecord({
    required this.id,
    required this.fileName,
    required this.takenAt,
    required this.sizeBytes,
    required this.checksum,
    required this.schemaVersion,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_name'] = Variable<String>(fileName);
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['checksum'] = Variable<String>(checksum);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  SnapshotRecordsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotRecordsCompanion(
      id: Value(id),
      fileName: Value(fileName),
      takenAt: Value(takenAt),
      sizeBytes: Value(sizeBytes),
      checksum: Value(checksum),
      schemaVersion: Value(schemaVersion),
      reason: Value(reason),
    );
  }

  factory SnapshotRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotRecord(
      id: serializer.fromJson<int>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      checksum: serializer.fromJson<String>(json['checksum']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileName': serializer.toJson<String>(fileName),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'checksum': serializer.toJson<String>(checksum),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'reason': serializer.toJson<String>(reason),
    };
  }

  SnapshotRecord copyWith({
    int? id,
    String? fileName,
    DateTime? takenAt,
    int? sizeBytes,
    String? checksum,
    int? schemaVersion,
    String? reason,
  }) => SnapshotRecord(
    id: id ?? this.id,
    fileName: fileName ?? this.fileName,
    takenAt: takenAt ?? this.takenAt,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    checksum: checksum ?? this.checksum,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    reason: reason ?? this.reason,
  );
  SnapshotRecord copyWithCompanion(SnapshotRecordsCompanion data) {
    return SnapshotRecord(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotRecord(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('takenAt: $takenAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('checksum: $checksum, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileName,
    takenAt,
    sizeBytes,
    checksum,
    schemaVersion,
    reason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotRecord &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.takenAt == this.takenAt &&
          other.sizeBytes == this.sizeBytes &&
          other.checksum == this.checksum &&
          other.schemaVersion == this.schemaVersion &&
          other.reason == this.reason);
}

class SnapshotRecordsCompanion extends UpdateCompanion<SnapshotRecord> {
  final Value<int> id;
  final Value<String> fileName;
  final Value<DateTime> takenAt;
  final Value<int> sizeBytes;
  final Value<String> checksum;
  final Value<int> schemaVersion;
  final Value<String> reason;
  const SnapshotRecordsCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.checksum = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.reason = const Value.absent(),
  });
  SnapshotRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String fileName,
    required DateTime takenAt,
    required int sizeBytes,
    required String checksum,
    required int schemaVersion,
    this.reason = const Value.absent(),
  }) : fileName = Value(fileName),
       takenAt = Value(takenAt),
       sizeBytes = Value(sizeBytes),
       checksum = Value(checksum),
       schemaVersion = Value(schemaVersion);
  static Insertable<SnapshotRecord> custom({
    Expression<int>? id,
    Expression<String>? fileName,
    Expression<DateTime>? takenAt,
    Expression<int>? sizeBytes,
    Expression<String>? checksum,
    Expression<int>? schemaVersion,
    Expression<String>? reason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (takenAt != null) 'taken_at': takenAt,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (checksum != null) 'checksum': checksum,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (reason != null) 'reason': reason,
    });
  }

  SnapshotRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? fileName,
    Value<DateTime>? takenAt,
    Value<int>? sizeBytes,
    Value<String>? checksum,
    Value<int>? schemaVersion,
    Value<String>? reason,
  }) {
    return SnapshotRecordsCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      takenAt: takenAt ?? this.takenAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksum: checksum ?? this.checksum,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotRecordsCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('takenAt: $takenAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('checksum: $checksum, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }
}

class $InventoryLinesTable extends InventoryLines
    with TableInfo<$InventoryLinesTable, InventoryLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pack'),
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<double> condition = GeneratedColumn<double>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pagesTotalMeta = const VerificationMeta(
    'pagesTotal',
  );
  @override
  late final GeneratedColumn<int> pagesTotal = GeneratedColumn<int>(
    'pages_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pagesReadMeta = const VerificationMeta(
    'pagesRead',
  );
  @override
  late final GeneratedColumn<int> pagesRead = GeneratedColumn<int>(
    'pages_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionMeta = const VerificationMeta(
    'portion',
  );
  @override
  late final GeneratedColumn<double> portion = GeneratedColumn<double>(
    'portion',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _attachmentsMeta = const VerificationMeta(
    'attachments',
  );
  @override
  late final GeneratedColumn<String> attachments = GeneratedColumn<String>(
    'attachments',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    itemId,
    count,
    slot,
    condition,
    pagesTotal,
    pagesRead,
    noteId,
    portion,
    attachments,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('pages_total')) {
      context.handle(
        _pagesTotalMeta,
        pagesTotal.isAcceptableOrUnknown(data['pages_total']!, _pagesTotalMeta),
      );
    }
    if (data.containsKey('pages_read')) {
      context.handle(
        _pagesReadMeta,
        pagesRead.isAcceptableOrUnknown(data['pages_read']!, _pagesReadMeta),
      );
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    }
    if (data.containsKey('portion')) {
      context.handle(
        _portionMeta,
        portion.isAcceptableOrUnknown(data['portion']!, _portionMeta),
      );
    }
    if (data.containsKey('attachments')) {
      context.handle(
        _attachmentsMeta,
        attachments.isAcceptableOrUnknown(
          data['attachments']!,
          _attachmentsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}condition'],
      ),
      pagesTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages_total'],
      ),
      pagesRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages_read'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      ),
      portion: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}portion'],
      )!,
      attachments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments'],
      )!,
    );
  }

  @override
  $InventoryLinesTable createAlias(String alias) {
    return $InventoryLinesTable(attachedDatabase, alias);
  }
}

class InventoryLine extends DataClass implements Insertable<InventoryLine> {
  final int id;
  final int profileId;

  /// Catalogue id (§4.1). Not a foreign key: the catalogue is data files, not
  /// tables, and an item that a removed content pack defined must not take the
  /// save down with it — it is dropped on read and reported.
  final String itemId;
  final int count;

  /// 'pack' | 'worn'. Worn kit costs mass but not volume (§18.1a), so where a
  /// thing is decides which limit it counts against.
  final String slot;

  /// 0–100 for anything that wears out, null for anything that does not.
  final double? condition;

  /// Rolled per copy at generation (§4.6.4). Null for anything but literature.
  final int? pagesTotal;
  final int pagesRead;

  /// Which note this is, for a picked-up `lit_note` (§19.1). Null for anything
  /// else. The text is not stored: it lives in `notes.json` and is resolved
  /// again on reading, so a corrected translation reaches notes already in a
  /// player's pack.
  final String? noteId;

  /// How much of the piece is left, 0–1 (§4.7). One for everything whole, and
  /// for every line written before a half-drunk bottle was a thing the game
  /// could hold.
  final double portion;

  /// §5.6.3: what is bolted to this piece, as item ids separated by commas.
  ///
  /// A list in a column, which is a compromise: a table of its own would be
  /// correct and would also mean a join for something that is never queried on
  /// its own. Empty for everything that is not a weapon with something on it.
  final String attachments;
  const InventoryLine({
    required this.id,
    required this.profileId,
    required this.itemId,
    required this.count,
    required this.slot,
    this.condition,
    this.pagesTotal,
    required this.pagesRead,
    this.noteId,
    required this.portion,
    required this.attachments,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['item_id'] = Variable<String>(itemId);
    map['count'] = Variable<int>(count);
    map['slot'] = Variable<String>(slot);
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<double>(condition);
    }
    if (!nullToAbsent || pagesTotal != null) {
      map['pages_total'] = Variable<int>(pagesTotal);
    }
    map['pages_read'] = Variable<int>(pagesRead);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    map['portion'] = Variable<double>(portion);
    map['attachments'] = Variable<String>(attachments);
    return map;
  }

  InventoryLinesCompanion toCompanion(bool nullToAbsent) {
    return InventoryLinesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      itemId: Value(itemId),
      count: Value(count),
      slot: Value(slot),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      pagesTotal: pagesTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(pagesTotal),
      pagesRead: Value(pagesRead),
      noteId: noteId == null && nullToAbsent
          ? const Value.absent()
          : Value(noteId),
      portion: Value(portion),
      attachments: Value(attachments),
    );
  }

  factory InventoryLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryLine(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      count: serializer.fromJson<int>(json['count']),
      slot: serializer.fromJson<String>(json['slot']),
      condition: serializer.fromJson<double?>(json['condition']),
      pagesTotal: serializer.fromJson<int?>(json['pagesTotal']),
      pagesRead: serializer.fromJson<int>(json['pagesRead']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      portion: serializer.fromJson<double>(json['portion']),
      attachments: serializer.fromJson<String>(json['attachments']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'itemId': serializer.toJson<String>(itemId),
      'count': serializer.toJson<int>(count),
      'slot': serializer.toJson<String>(slot),
      'condition': serializer.toJson<double?>(condition),
      'pagesTotal': serializer.toJson<int?>(pagesTotal),
      'pagesRead': serializer.toJson<int>(pagesRead),
      'noteId': serializer.toJson<String?>(noteId),
      'portion': serializer.toJson<double>(portion),
      'attachments': serializer.toJson<String>(attachments),
    };
  }

  InventoryLine copyWith({
    int? id,
    int? profileId,
    String? itemId,
    int? count,
    String? slot,
    Value<double?> condition = const Value.absent(),
    Value<int?> pagesTotal = const Value.absent(),
    int? pagesRead,
    Value<String?> noteId = const Value.absent(),
    double? portion,
    String? attachments,
  }) => InventoryLine(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    itemId: itemId ?? this.itemId,
    count: count ?? this.count,
    slot: slot ?? this.slot,
    condition: condition.present ? condition.value : this.condition,
    pagesTotal: pagesTotal.present ? pagesTotal.value : this.pagesTotal,
    pagesRead: pagesRead ?? this.pagesRead,
    noteId: noteId.present ? noteId.value : this.noteId,
    portion: portion ?? this.portion,
    attachments: attachments ?? this.attachments,
  );
  InventoryLine copyWithCompanion(InventoryLinesCompanion data) {
    return InventoryLine(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      count: data.count.present ? data.count.value : this.count,
      slot: data.slot.present ? data.slot.value : this.slot,
      condition: data.condition.present ? data.condition.value : this.condition,
      pagesTotal: data.pagesTotal.present
          ? data.pagesTotal.value
          : this.pagesTotal,
      pagesRead: data.pagesRead.present ? data.pagesRead.value : this.pagesRead,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      portion: data.portion.present ? data.portion.value : this.portion,
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryLine(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('itemId: $itemId, ')
          ..write('count: $count, ')
          ..write('slot: $slot, ')
          ..write('condition: $condition, ')
          ..write('pagesTotal: $pagesTotal, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('noteId: $noteId, ')
          ..write('portion: $portion, ')
          ..write('attachments: $attachments')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    itemId,
    count,
    slot,
    condition,
    pagesTotal,
    pagesRead,
    noteId,
    portion,
    attachments,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryLine &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.itemId == this.itemId &&
          other.count == this.count &&
          other.slot == this.slot &&
          other.condition == this.condition &&
          other.pagesTotal == this.pagesTotal &&
          other.pagesRead == this.pagesRead &&
          other.noteId == this.noteId &&
          other.portion == this.portion &&
          other.attachments == this.attachments);
}

class InventoryLinesCompanion extends UpdateCompanion<InventoryLine> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> itemId;
  final Value<int> count;
  final Value<String> slot;
  final Value<double?> condition;
  final Value<int?> pagesTotal;
  final Value<int> pagesRead;
  final Value<String?> noteId;
  final Value<double> portion;
  final Value<String> attachments;
  const InventoryLinesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.count = const Value.absent(),
    this.slot = const Value.absent(),
    this.condition = const Value.absent(),
    this.pagesTotal = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.noteId = const Value.absent(),
    this.portion = const Value.absent(),
    this.attachments = const Value.absent(),
  });
  InventoryLinesCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String itemId,
    this.count = const Value.absent(),
    this.slot = const Value.absent(),
    this.condition = const Value.absent(),
    this.pagesTotal = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.noteId = const Value.absent(),
    this.portion = const Value.absent(),
    this.attachments = const Value.absent(),
  }) : profileId = Value(profileId),
       itemId = Value(itemId);
  static Insertable<InventoryLine> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? itemId,
    Expression<int>? count,
    Expression<String>? slot,
    Expression<double>? condition,
    Expression<int>? pagesTotal,
    Expression<int>? pagesRead,
    Expression<String>? noteId,
    Expression<double>? portion,
    Expression<String>? attachments,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (itemId != null) 'item_id': itemId,
      if (count != null) 'count': count,
      if (slot != null) 'slot': slot,
      if (condition != null) 'condition': condition,
      if (pagesTotal != null) 'pages_total': pagesTotal,
      if (pagesRead != null) 'pages_read': pagesRead,
      if (noteId != null) 'note_id': noteId,
      if (portion != null) 'portion': portion,
      if (attachments != null) 'attachments': attachments,
    });
  }

  InventoryLinesCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? itemId,
    Value<int>? count,
    Value<String>? slot,
    Value<double?>? condition,
    Value<int?>? pagesTotal,
    Value<int>? pagesRead,
    Value<String?>? noteId,
    Value<double>? portion,
    Value<String>? attachments,
  }) {
    return InventoryLinesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      itemId: itemId ?? this.itemId,
      count: count ?? this.count,
      slot: slot ?? this.slot,
      condition: condition ?? this.condition,
      pagesTotal: pagesTotal ?? this.pagesTotal,
      pagesRead: pagesRead ?? this.pagesRead,
      noteId: noteId ?? this.noteId,
      portion: portion ?? this.portion,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (condition.present) {
      map['condition'] = Variable<double>(condition.value);
    }
    if (pagesTotal.present) {
      map['pages_total'] = Variable<int>(pagesTotal.value);
    }
    if (pagesRead.present) {
      map['pages_read'] = Variable<int>(pagesRead.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (portion.present) {
      map['portion'] = Variable<double>(portion.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(attachments.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryLinesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('itemId: $itemId, ')
          ..write('count: $count, ')
          ..write('slot: $slot, ')
          ..write('condition: $condition, ')
          ..write('pagesTotal: $pagesTotal, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('noteId: $noteId, ')
          ..write('portion: $portion, ')
          ..write('attachments: $attachments')
          ..write(')'))
        .toString();
  }
}

class $LootBoxesTable extends LootBoxes
    with TableInfo<$LootBoxesTable, LootBoxe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LootBoxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _poiIdMeta = const VerificationMeta('poiId');
  @override
  late final GeneratedColumn<String> poiId = GeneratedColumn<String>(
    'poi_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<String> tableId = GeneratedColumn<String>(
    'table_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spawnedAtMeta = const VerificationMeta(
    'spawnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> spawnedAt = GeneratedColumn<DateTime>(
    'spawned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lootedAtMeta = const VerificationMeta(
    'lootedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lootedAt = GeneratedColumn<DateTime>(
    'looted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _respawnAtMeta = const VerificationMeta(
    'respawnAt',
  );
  @override
  late final GeneratedColumn<DateTime> respawnAt = GeneratedColumn<DateTime>(
    'respawn_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchUnitsMeta = const VerificationMeta(
    'searchUnits',
  );
  @override
  late final GeneratedColumn<int> searchUnits = GeneratedColumn<int>(
    'search_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    poiId,
    latitude,
    longitude,
    tableId,
    name,
    spawnedAt,
    lootedAt,
    respawnAt,
    openedAt,
    searchUnits,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loot_boxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LootBoxe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('poi_id')) {
      context.handle(
        _poiIdMeta,
        poiId.isAcceptableOrUnknown(data['poi_id']!, _poiIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poiIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tableIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('spawned_at')) {
      context.handle(
        _spawnedAtMeta,
        spawnedAt.isAcceptableOrUnknown(data['spawned_at']!, _spawnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_spawnedAtMeta);
    }
    if (data.containsKey('looted_at')) {
      context.handle(
        _lootedAtMeta,
        lootedAt.isAcceptableOrUnknown(data['looted_at']!, _lootedAtMeta),
      );
    }
    if (data.containsKey('respawn_at')) {
      context.handle(
        _respawnAtMeta,
        respawnAt.isAcceptableOrUnknown(data['respawn_at']!, _respawnAtMeta),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('search_units')) {
      context.handle(
        _searchUnitsMeta,
        searchUnits.isAcceptableOrUnknown(
          data['search_units']!,
          _searchUnitsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LootBoxe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LootBoxe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      poiId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poi_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      spawnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}spawned_at'],
      )!,
      lootedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}looted_at'],
      ),
      respawnAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}respawn_at'],
      ),
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      searchUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}search_units'],
      )!,
    );
  }

  @override
  $LootBoxesTable createAlias(String alias) {
    return $LootBoxesTable(attachedDatabase, alias);
  }
}

class LootBoxe extends DataClass implements Insertable<LootBoxe> {
  final int id;
  final int profileId;

  /// From `Poi.id`: position to six decimals plus what the place is.
  final String poiId;
  final double latitude;
  final double longitude;

  /// Which table of §10.3 this place draws from.
  final String tableId;

  /// The name off the tile, where the map had one. Shown on the marker.
  final String? name;
  final DateTime spawnedAt;

  /// Null while it still has something in it.
  final DateTime? lootedAt;

  /// Rolled when it is emptied, never on a schedule — a fixed interval would
  /// let a player time a whole city off one box (§10).
  final DateTime? respawnAt;

  /// When the barrier of §19.3 was got through, or null while it still shuts.
  ///
  /// Persisted because a forced door stays forced. Making the player break in
  /// again after a restart would turn one decision into a chore.
  final DateTime? openedAt;

  /// How much of §10.3.5's budget has been spent searching this place.
  ///
  /// Persisted for the same reason the barrier is: a shelf somebody already
  /// turned over is still turned over after a restart. Zero on every save
  /// written before this existed, which reads as untouched — right for a box
  /// that had only ever been searched once and emptied by it.
  final int searchUnits;
  const LootBoxe({
    required this.id,
    required this.profileId,
    required this.poiId,
    required this.latitude,
    required this.longitude,
    required this.tableId,
    this.name,
    required this.spawnedAt,
    this.lootedAt,
    this.respawnAt,
    this.openedAt,
    required this.searchUnits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['poi_id'] = Variable<String>(poiId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['table_id'] = Variable<String>(tableId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['spawned_at'] = Variable<DateTime>(spawnedAt);
    if (!nullToAbsent || lootedAt != null) {
      map['looted_at'] = Variable<DateTime>(lootedAt);
    }
    if (!nullToAbsent || respawnAt != null) {
      map['respawn_at'] = Variable<DateTime>(respawnAt);
    }
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    map['search_units'] = Variable<int>(searchUnits);
    return map;
  }

  LootBoxesCompanion toCompanion(bool nullToAbsent) {
    return LootBoxesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      poiId: Value(poiId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      tableId: Value(tableId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      spawnedAt: Value(spawnedAt),
      lootedAt: lootedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lootedAt),
      respawnAt: respawnAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respawnAt),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      searchUnits: Value(searchUnits),
    );
  }

  factory LootBoxe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LootBoxe(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      poiId: serializer.fromJson<String>(json['poiId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      tableId: serializer.fromJson<String>(json['tableId']),
      name: serializer.fromJson<String?>(json['name']),
      spawnedAt: serializer.fromJson<DateTime>(json['spawnedAt']),
      lootedAt: serializer.fromJson<DateTime?>(json['lootedAt']),
      respawnAt: serializer.fromJson<DateTime?>(json['respawnAt']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      searchUnits: serializer.fromJson<int>(json['searchUnits']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'poiId': serializer.toJson<String>(poiId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'tableId': serializer.toJson<String>(tableId),
      'name': serializer.toJson<String?>(name),
      'spawnedAt': serializer.toJson<DateTime>(spawnedAt),
      'lootedAt': serializer.toJson<DateTime?>(lootedAt),
      'respawnAt': serializer.toJson<DateTime?>(respawnAt),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'searchUnits': serializer.toJson<int>(searchUnits),
    };
  }

  LootBoxe copyWith({
    int? id,
    int? profileId,
    String? poiId,
    double? latitude,
    double? longitude,
    String? tableId,
    Value<String?> name = const Value.absent(),
    DateTime? spawnedAt,
    Value<DateTime?> lootedAt = const Value.absent(),
    Value<DateTime?> respawnAt = const Value.absent(),
    Value<DateTime?> openedAt = const Value.absent(),
    int? searchUnits,
  }) => LootBoxe(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    poiId: poiId ?? this.poiId,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    tableId: tableId ?? this.tableId,
    name: name.present ? name.value : this.name,
    spawnedAt: spawnedAt ?? this.spawnedAt,
    lootedAt: lootedAt.present ? lootedAt.value : this.lootedAt,
    respawnAt: respawnAt.present ? respawnAt.value : this.respawnAt,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    searchUnits: searchUnits ?? this.searchUnits,
  );
  LootBoxe copyWithCompanion(LootBoxesCompanion data) {
    return LootBoxe(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      poiId: data.poiId.present ? data.poiId.value : this.poiId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      name: data.name.present ? data.name.value : this.name,
      spawnedAt: data.spawnedAt.present ? data.spawnedAt.value : this.spawnedAt,
      lootedAt: data.lootedAt.present ? data.lootedAt.value : this.lootedAt,
      respawnAt: data.respawnAt.present ? data.respawnAt.value : this.respawnAt,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      searchUnits: data.searchUnits.present
          ? data.searchUnits.value
          : this.searchUnits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LootBoxe(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('poiId: $poiId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('tableId: $tableId, ')
          ..write('name: $name, ')
          ..write('spawnedAt: $spawnedAt, ')
          ..write('lootedAt: $lootedAt, ')
          ..write('respawnAt: $respawnAt, ')
          ..write('openedAt: $openedAt, ')
          ..write('searchUnits: $searchUnits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    poiId,
    latitude,
    longitude,
    tableId,
    name,
    spawnedAt,
    lootedAt,
    respawnAt,
    openedAt,
    searchUnits,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LootBoxe &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.poiId == this.poiId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.tableId == this.tableId &&
          other.name == this.name &&
          other.spawnedAt == this.spawnedAt &&
          other.lootedAt == this.lootedAt &&
          other.respawnAt == this.respawnAt &&
          other.openedAt == this.openedAt &&
          other.searchUnits == this.searchUnits);
}

class LootBoxesCompanion extends UpdateCompanion<LootBoxe> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> poiId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> tableId;
  final Value<String?> name;
  final Value<DateTime> spawnedAt;
  final Value<DateTime?> lootedAt;
  final Value<DateTime?> respawnAt;
  final Value<DateTime?> openedAt;
  final Value<int> searchUnits;
  const LootBoxesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.poiId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.tableId = const Value.absent(),
    this.name = const Value.absent(),
    this.spawnedAt = const Value.absent(),
    this.lootedAt = const Value.absent(),
    this.respawnAt = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.searchUnits = const Value.absent(),
  });
  LootBoxesCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String poiId,
    required double latitude,
    required double longitude,
    required String tableId,
    this.name = const Value.absent(),
    required DateTime spawnedAt,
    this.lootedAt = const Value.absent(),
    this.respawnAt = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.searchUnits = const Value.absent(),
  }) : profileId = Value(profileId),
       poiId = Value(poiId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       tableId = Value(tableId),
       spawnedAt = Value(spawnedAt);
  static Insertable<LootBoxe> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? poiId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? tableId,
    Expression<String>? name,
    Expression<DateTime>? spawnedAt,
    Expression<DateTime>? lootedAt,
    Expression<DateTime>? respawnAt,
    Expression<DateTime>? openedAt,
    Expression<int>? searchUnits,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (poiId != null) 'poi_id': poiId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (tableId != null) 'table_id': tableId,
      if (name != null) 'name': name,
      if (spawnedAt != null) 'spawned_at': spawnedAt,
      if (lootedAt != null) 'looted_at': lootedAt,
      if (respawnAt != null) 'respawn_at': respawnAt,
      if (openedAt != null) 'opened_at': openedAt,
      if (searchUnits != null) 'search_units': searchUnits,
    });
  }

  LootBoxesCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? poiId,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String>? tableId,
    Value<String?>? name,
    Value<DateTime>? spawnedAt,
    Value<DateTime?>? lootedAt,
    Value<DateTime?>? respawnAt,
    Value<DateTime?>? openedAt,
    Value<int>? searchUnits,
  }) {
    return LootBoxesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      poiId: poiId ?? this.poiId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tableId: tableId ?? this.tableId,
      name: name ?? this.name,
      spawnedAt: spawnedAt ?? this.spawnedAt,
      lootedAt: lootedAt ?? this.lootedAt,
      respawnAt: respawnAt ?? this.respawnAt,
      openedAt: openedAt ?? this.openedAt,
      searchUnits: searchUnits ?? this.searchUnits,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (poiId.present) {
      map['poi_id'] = Variable<String>(poiId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (spawnedAt.present) {
      map['spawned_at'] = Variable<DateTime>(spawnedAt.value);
    }
    if (lootedAt.present) {
      map['looted_at'] = Variable<DateTime>(lootedAt.value);
    }
    if (respawnAt.present) {
      map['respawn_at'] = Variable<DateTime>(respawnAt.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (searchUnits.present) {
      map['search_units'] = Variable<int>(searchUnits.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LootBoxesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('poiId: $poiId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('tableId: $tableId, ')
          ..write('name: $name, ')
          ..write('spawnedAt: $spawnedAt, ')
          ..write('lootedAt: $lootedAt, ')
          ..write('respawnAt: $respawnAt, ')
          ..write('openedAt: $openedAt, ')
          ..write('searchUnits: $searchUnits')
          ..write(')'))
        .toString();
  }
}

class $GroundItemsTable extends GroundItems
    with TableInfo<$GroundItemsTable, GroundItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroundItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<double> condition = GeneratedColumn<double>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pagesTotalMeta = const VerificationMeta(
    'pagesTotal',
  );
  @override
  late final GeneratedColumn<int> pagesTotal = GeneratedColumn<int>(
    'pages_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pagesReadMeta = const VerificationMeta(
    'pagesRead',
  );
  @override
  late final GeneratedColumn<int> pagesRead = GeneratedColumn<int>(
    'pages_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _droppedAtMeta = const VerificationMeta(
    'droppedAt',
  );
  @override
  late final GeneratedColumn<DateTime> droppedAt = GeneratedColumn<DateTime>(
    'dropped_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    itemId,
    count,
    condition,
    pagesTotal,
    pagesRead,
    latitude,
    longitude,
    droppedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ground_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroundItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('pages_total')) {
      context.handle(
        _pagesTotalMeta,
        pagesTotal.isAcceptableOrUnknown(data['pages_total']!, _pagesTotalMeta),
      );
    }
    if (data.containsKey('pages_read')) {
      context.handle(
        _pagesReadMeta,
        pagesRead.isAcceptableOrUnknown(data['pages_read']!, _pagesReadMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('dropped_at')) {
      context.handle(
        _droppedAtMeta,
        droppedAt.isAcceptableOrUnknown(data['dropped_at']!, _droppedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_droppedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroundItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroundItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}condition'],
      ),
      pagesTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages_total'],
      ),
      pagesRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages_read'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      droppedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dropped_at'],
      )!,
    );
  }

  @override
  $GroundItemsTable createAlias(String alias) {
    return $GroundItemsTable(attachedDatabase, alias);
  }
}

class GroundItem extends DataClass implements Insertable<GroundItem> {
  final int id;
  final int profileId;
  final String itemId;
  final int count;

  /// Per-piece state, exactly as the inventory keeps it: a dropped rifle is
  /// still as worn as it was, and a part-read book keeps its place (§4.6.3).
  final double? condition;
  final int? pagesTotal;
  final int pagesRead;
  final double latitude;
  final double longitude;
  final DateTime droppedAt;
  const GroundItem({
    required this.id,
    required this.profileId,
    required this.itemId,
    required this.count,
    this.condition,
    this.pagesTotal,
    required this.pagesRead,
    required this.latitude,
    required this.longitude,
    required this.droppedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['item_id'] = Variable<String>(itemId);
    map['count'] = Variable<int>(count);
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<double>(condition);
    }
    if (!nullToAbsent || pagesTotal != null) {
      map['pages_total'] = Variable<int>(pagesTotal);
    }
    map['pages_read'] = Variable<int>(pagesRead);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['dropped_at'] = Variable<DateTime>(droppedAt);
    return map;
  }

  GroundItemsCompanion toCompanion(bool nullToAbsent) {
    return GroundItemsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      itemId: Value(itemId),
      count: Value(count),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      pagesTotal: pagesTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(pagesTotal),
      pagesRead: Value(pagesRead),
      latitude: Value(latitude),
      longitude: Value(longitude),
      droppedAt: Value(droppedAt),
    );
  }

  factory GroundItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroundItem(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      count: serializer.fromJson<int>(json['count']),
      condition: serializer.fromJson<double?>(json['condition']),
      pagesTotal: serializer.fromJson<int?>(json['pagesTotal']),
      pagesRead: serializer.fromJson<int>(json['pagesRead']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      droppedAt: serializer.fromJson<DateTime>(json['droppedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'itemId': serializer.toJson<String>(itemId),
      'count': serializer.toJson<int>(count),
      'condition': serializer.toJson<double?>(condition),
      'pagesTotal': serializer.toJson<int?>(pagesTotal),
      'pagesRead': serializer.toJson<int>(pagesRead),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'droppedAt': serializer.toJson<DateTime>(droppedAt),
    };
  }

  GroundItem copyWith({
    int? id,
    int? profileId,
    String? itemId,
    int? count,
    Value<double?> condition = const Value.absent(),
    Value<int?> pagesTotal = const Value.absent(),
    int? pagesRead,
    double? latitude,
    double? longitude,
    DateTime? droppedAt,
  }) => GroundItem(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    itemId: itemId ?? this.itemId,
    count: count ?? this.count,
    condition: condition.present ? condition.value : this.condition,
    pagesTotal: pagesTotal.present ? pagesTotal.value : this.pagesTotal,
    pagesRead: pagesRead ?? this.pagesRead,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    droppedAt: droppedAt ?? this.droppedAt,
  );
  GroundItem copyWithCompanion(GroundItemsCompanion data) {
    return GroundItem(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      count: data.count.present ? data.count.value : this.count,
      condition: data.condition.present ? data.condition.value : this.condition,
      pagesTotal: data.pagesTotal.present
          ? data.pagesTotal.value
          : this.pagesTotal,
      pagesRead: data.pagesRead.present ? data.pagesRead.value : this.pagesRead,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      droppedAt: data.droppedAt.present ? data.droppedAt.value : this.droppedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroundItem(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('itemId: $itemId, ')
          ..write('count: $count, ')
          ..write('condition: $condition, ')
          ..write('pagesTotal: $pagesTotal, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('droppedAt: $droppedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    itemId,
    count,
    condition,
    pagesTotal,
    pagesRead,
    latitude,
    longitude,
    droppedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroundItem &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.itemId == this.itemId &&
          other.count == this.count &&
          other.condition == this.condition &&
          other.pagesTotal == this.pagesTotal &&
          other.pagesRead == this.pagesRead &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.droppedAt == this.droppedAt);
}

class GroundItemsCompanion extends UpdateCompanion<GroundItem> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> itemId;
  final Value<int> count;
  final Value<double?> condition;
  final Value<int?> pagesTotal;
  final Value<int> pagesRead;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> droppedAt;
  const GroundItemsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.count = const Value.absent(),
    this.condition = const Value.absent(),
    this.pagesTotal = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.droppedAt = const Value.absent(),
  });
  GroundItemsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String itemId,
    this.count = const Value.absent(),
    this.condition = const Value.absent(),
    this.pagesTotal = const Value.absent(),
    this.pagesRead = const Value.absent(),
    required double latitude,
    required double longitude,
    required DateTime droppedAt,
  }) : profileId = Value(profileId),
       itemId = Value(itemId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       droppedAt = Value(droppedAt);
  static Insertable<GroundItem> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? itemId,
    Expression<int>? count,
    Expression<double>? condition,
    Expression<int>? pagesTotal,
    Expression<int>? pagesRead,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? droppedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (itemId != null) 'item_id': itemId,
      if (count != null) 'count': count,
      if (condition != null) 'condition': condition,
      if (pagesTotal != null) 'pages_total': pagesTotal,
      if (pagesRead != null) 'pages_read': pagesRead,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (droppedAt != null) 'dropped_at': droppedAt,
    });
  }

  GroundItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? itemId,
    Value<int>? count,
    Value<double?>? condition,
    Value<int?>? pagesTotal,
    Value<int>? pagesRead,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<DateTime>? droppedAt,
  }) {
    return GroundItemsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      itemId: itemId ?? this.itemId,
      count: count ?? this.count,
      condition: condition ?? this.condition,
      pagesTotal: pagesTotal ?? this.pagesTotal,
      pagesRead: pagesRead ?? this.pagesRead,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      droppedAt: droppedAt ?? this.droppedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (condition.present) {
      map['condition'] = Variable<double>(condition.value);
    }
    if (pagesTotal.present) {
      map['pages_total'] = Variable<int>(pagesTotal.value);
    }
    if (pagesRead.present) {
      map['pages_read'] = Variable<int>(pagesRead.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (droppedAt.present) {
      map['dropped_at'] = Variable<DateTime>(droppedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroundItemsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('itemId: $itemId, ')
          ..write('count: $count, ')
          ..write('condition: $condition, ')
          ..write('pagesTotal: $pagesTotal, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('droppedAt: $droppedAt')
          ..write(')'))
        .toString();
  }
}

class $SheltersTable extends Shelters
    with TableInfo<$SheltersTable, ShelterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SheltersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buildSecondsMeta = const VerificationMeta(
    'buildSeconds',
  );
  @override
  late final GeneratedColumn<int> buildSeconds = GeneratedColumn<int>(
    'build_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buildLeftSecondsMeta = const VerificationMeta(
    'buildLeftSeconds',
  );
  @override
  late final GeneratedColumn<int> buildLeftSeconds = GeneratedColumn<int>(
    'build_left_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workedAtMeta = const VerificationMeta(
    'workedAt',
  );
  @override
  late final GeneratedColumn<DateTime> workedAt = GeneratedColumn<DateTime>(
    'worked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modulesMeta = const VerificationMeta(
    'modules',
  );
  @override
  late final GeneratedColumn<String> modules = GeneratedColumn<String>(
    'modules',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _visitedAtMeta = const VerificationMeta(
    'visitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
    'visited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buildingMeta = const VerificationMeta(
    'building',
  );
  @override
  late final GeneratedColumn<String> building = GeneratedColumn<String>(
    'building',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buildingReadyAtMeta = const VerificationMeta(
    'buildingReadyAt',
  );
  @override
  late final GeneratedColumn<DateTime> buildingReadyAt =
      GeneratedColumn<DateTime>(
        'building_ready_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _buildingLeftSecondsMeta =
      const VerificationMeta('buildingLeftSeconds');
  @override
  late final GeneratedColumn<int> buildingLeftSeconds = GeneratedColumn<int>(
    'building_left_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    kind,
    latitude,
    longitude,
    startedAt,
    buildSeconds,
    buildLeftSeconds,
    workedAt,
    modules,
    visitedAt,
    building,
    buildingReadyAt,
    buildingLeftSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShelterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('build_seconds')) {
      context.handle(
        _buildSecondsMeta,
        buildSeconds.isAcceptableOrUnknown(
          data['build_seconds']!,
          _buildSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_buildSecondsMeta);
    }
    if (data.containsKey('build_left_seconds')) {
      context.handle(
        _buildLeftSecondsMeta,
        buildLeftSeconds.isAcceptableOrUnknown(
          data['build_left_seconds']!,
          _buildLeftSecondsMeta,
        ),
      );
    }
    if (data.containsKey('worked_at')) {
      context.handle(
        _workedAtMeta,
        workedAt.isAcceptableOrUnknown(data['worked_at']!, _workedAtMeta),
      );
    }
    if (data.containsKey('modules')) {
      context.handle(
        _modulesMeta,
        modules.isAcceptableOrUnknown(data['modules']!, _modulesMeta),
      );
    }
    if (data.containsKey('visited_at')) {
      context.handle(
        _visitedAtMeta,
        visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta),
      );
    }
    if (data.containsKey('building')) {
      context.handle(
        _buildingMeta,
        building.isAcceptableOrUnknown(data['building']!, _buildingMeta),
      );
    }
    if (data.containsKey('building_ready_at')) {
      context.handle(
        _buildingReadyAtMeta,
        buildingReadyAt.isAcceptableOrUnknown(
          data['building_ready_at']!,
          _buildingReadyAtMeta,
        ),
      );
    }
    if (data.containsKey('building_left_seconds')) {
      context.handle(
        _buildingLeftSecondsMeta,
        buildingLeftSeconds.isAcceptableOrUnknown(
          data['building_left_seconds']!,
          _buildingLeftSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShelterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShelterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      buildSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}build_seconds'],
      )!,
      buildLeftSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}build_left_seconds'],
      ),
      workedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}worked_at'],
      ),
      modules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modules'],
      )!,
      visitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_at'],
      ),
      building: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}building'],
      ),
      buildingReadyAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}building_ready_at'],
      ),
      buildingLeftSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}building_left_seconds'],
      ),
    );
  }

  @override
  $SheltersTable createAlias(String alias) {
    return $SheltersTable(attachedDatabase, alias);
  }
}

class ShelterRow extends DataClass implements Insertable<ShelterRow> {
  final int id;
  final int profileId;

  /// `main` or `camp` (§8.5.1). Text rather than an index so a save is
  /// readable, as everywhere else in this schema.
  final String kind;
  final double latitude;
  final double longitude;

  /// §2.1a.3: building runs against the clock, so the record keeps when it
  /// began and what it was going to take. Recomputing the second from the
  /// first would let a hammer lost halfway through lengthen a finished job.
  final DateTime startedAt;
  final int buildSeconds;

  /// §2.1a.3: how much of that work is left, and it only comes down while the
  /// player is standing on the site. Null on a row written before the rule
  /// existed, which then falls back to the plain deadline.
  final int? buildLeftSeconds;

  /// §8.3: when work was last credited against this place.
  ///
  /// ⚠️ On the row rather than in memory. Held in memory it started again at
  /// nothing every time the process did — so a shelter left to build overnight,
  /// with the app closed as §8.3 intends, was in exactly the same state in the
  /// morning as it had been at bedtime.
  final DateTime? workedAt;

  /// §8.4: `storage:2,lounge:1`. Absent means nought, which is what every
  /// shelter starts as.
  final String modules;

  /// §8.5.2: when the player was last inside. A camp nobody comes back to
  /// falls down; the shelter never does.
  final DateTime? visitedAt;

  /// §8.4, §18.2: the module currently going up, as `lounge:2`, and when it
  /// will be finished. Both null when nothing is being built.
  ///
  /// On the row rather than in an occupation because it has to finish while
  /// the app is dead — §8.3 says as much about the shelter itself, and a
  /// nine-hour workshop is even less of a thing to sit and watch.
  final String? building;
  final DateTime? buildingReadyAt;

  /// §2.1a.3 again, for the module: work left, spent only on site.
  final int? buildingLeftSeconds;
  const ShelterRow({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.startedAt,
    required this.buildSeconds,
    this.buildLeftSeconds,
    this.workedAt,
    required this.modules,
    this.visitedAt,
    this.building,
    this.buildingReadyAt,
    this.buildingLeftSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['kind'] = Variable<String>(kind);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['build_seconds'] = Variable<int>(buildSeconds);
    if (!nullToAbsent || buildLeftSeconds != null) {
      map['build_left_seconds'] = Variable<int>(buildLeftSeconds);
    }
    if (!nullToAbsent || workedAt != null) {
      map['worked_at'] = Variable<DateTime>(workedAt);
    }
    map['modules'] = Variable<String>(modules);
    if (!nullToAbsent || visitedAt != null) {
      map['visited_at'] = Variable<DateTime>(visitedAt);
    }
    if (!nullToAbsent || building != null) {
      map['building'] = Variable<String>(building);
    }
    if (!nullToAbsent || buildingReadyAt != null) {
      map['building_ready_at'] = Variable<DateTime>(buildingReadyAt);
    }
    if (!nullToAbsent || buildingLeftSeconds != null) {
      map['building_left_seconds'] = Variable<int>(buildingLeftSeconds);
    }
    return map;
  }

  SheltersCompanion toCompanion(bool nullToAbsent) {
    return SheltersCompanion(
      id: Value(id),
      profileId: Value(profileId),
      kind: Value(kind),
      latitude: Value(latitude),
      longitude: Value(longitude),
      startedAt: Value(startedAt),
      buildSeconds: Value(buildSeconds),
      buildLeftSeconds: buildLeftSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(buildLeftSeconds),
      workedAt: workedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(workedAt),
      modules: Value(modules),
      visitedAt: visitedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(visitedAt),
      building: building == null && nullToAbsent
          ? const Value.absent()
          : Value(building),
      buildingReadyAt: buildingReadyAt == null && nullToAbsent
          ? const Value.absent()
          : Value(buildingReadyAt),
      buildingLeftSeconds: buildingLeftSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(buildingLeftSeconds),
    );
  }

  factory ShelterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShelterRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      kind: serializer.fromJson<String>(json['kind']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      buildSeconds: serializer.fromJson<int>(json['buildSeconds']),
      buildLeftSeconds: serializer.fromJson<int?>(json['buildLeftSeconds']),
      workedAt: serializer.fromJson<DateTime?>(json['workedAt']),
      modules: serializer.fromJson<String>(json['modules']),
      visitedAt: serializer.fromJson<DateTime?>(json['visitedAt']),
      building: serializer.fromJson<String?>(json['building']),
      buildingReadyAt: serializer.fromJson<DateTime?>(json['buildingReadyAt']),
      buildingLeftSeconds: serializer.fromJson<int?>(
        json['buildingLeftSeconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'kind': serializer.toJson<String>(kind),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'buildSeconds': serializer.toJson<int>(buildSeconds),
      'buildLeftSeconds': serializer.toJson<int?>(buildLeftSeconds),
      'workedAt': serializer.toJson<DateTime?>(workedAt),
      'modules': serializer.toJson<String>(modules),
      'visitedAt': serializer.toJson<DateTime?>(visitedAt),
      'building': serializer.toJson<String?>(building),
      'buildingReadyAt': serializer.toJson<DateTime?>(buildingReadyAt),
      'buildingLeftSeconds': serializer.toJson<int?>(buildingLeftSeconds),
    };
  }

  ShelterRow copyWith({
    int? id,
    int? profileId,
    String? kind,
    double? latitude,
    double? longitude,
    DateTime? startedAt,
    int? buildSeconds,
    Value<int?> buildLeftSeconds = const Value.absent(),
    Value<DateTime?> workedAt = const Value.absent(),
    String? modules,
    Value<DateTime?> visitedAt = const Value.absent(),
    Value<String?> building = const Value.absent(),
    Value<DateTime?> buildingReadyAt = const Value.absent(),
    Value<int?> buildingLeftSeconds = const Value.absent(),
  }) => ShelterRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    kind: kind ?? this.kind,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    startedAt: startedAt ?? this.startedAt,
    buildSeconds: buildSeconds ?? this.buildSeconds,
    buildLeftSeconds: buildLeftSeconds.present
        ? buildLeftSeconds.value
        : this.buildLeftSeconds,
    workedAt: workedAt.present ? workedAt.value : this.workedAt,
    modules: modules ?? this.modules,
    visitedAt: visitedAt.present ? visitedAt.value : this.visitedAt,
    building: building.present ? building.value : this.building,
    buildingReadyAt: buildingReadyAt.present
        ? buildingReadyAt.value
        : this.buildingReadyAt,
    buildingLeftSeconds: buildingLeftSeconds.present
        ? buildingLeftSeconds.value
        : this.buildingLeftSeconds,
  );
  ShelterRow copyWithCompanion(SheltersCompanion data) {
    return ShelterRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      kind: data.kind.present ? data.kind.value : this.kind,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      buildSeconds: data.buildSeconds.present
          ? data.buildSeconds.value
          : this.buildSeconds,
      buildLeftSeconds: data.buildLeftSeconds.present
          ? data.buildLeftSeconds.value
          : this.buildLeftSeconds,
      workedAt: data.workedAt.present ? data.workedAt.value : this.workedAt,
      modules: data.modules.present ? data.modules.value : this.modules,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
      building: data.building.present ? data.building.value : this.building,
      buildingReadyAt: data.buildingReadyAt.present
          ? data.buildingReadyAt.value
          : this.buildingReadyAt,
      buildingLeftSeconds: data.buildingLeftSeconds.present
          ? data.buildingLeftSeconds.value
          : this.buildingLeftSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShelterRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('startedAt: $startedAt, ')
          ..write('buildSeconds: $buildSeconds, ')
          ..write('buildLeftSeconds: $buildLeftSeconds, ')
          ..write('workedAt: $workedAt, ')
          ..write('modules: $modules, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('building: $building, ')
          ..write('buildingReadyAt: $buildingReadyAt, ')
          ..write('buildingLeftSeconds: $buildingLeftSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    kind,
    latitude,
    longitude,
    startedAt,
    buildSeconds,
    buildLeftSeconds,
    workedAt,
    modules,
    visitedAt,
    building,
    buildingReadyAt,
    buildingLeftSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShelterRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.kind == this.kind &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.startedAt == this.startedAt &&
          other.buildSeconds == this.buildSeconds &&
          other.buildLeftSeconds == this.buildLeftSeconds &&
          other.workedAt == this.workedAt &&
          other.modules == this.modules &&
          other.visitedAt == this.visitedAt &&
          other.building == this.building &&
          other.buildingReadyAt == this.buildingReadyAt &&
          other.buildingLeftSeconds == this.buildingLeftSeconds);
}

class SheltersCompanion extends UpdateCompanion<ShelterRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> kind;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> startedAt;
  final Value<int> buildSeconds;
  final Value<int?> buildLeftSeconds;
  final Value<DateTime?> workedAt;
  final Value<String> modules;
  final Value<DateTime?> visitedAt;
  final Value<String?> building;
  final Value<DateTime?> buildingReadyAt;
  final Value<int?> buildingLeftSeconds;
  const SheltersCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.kind = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.buildSeconds = const Value.absent(),
    this.buildLeftSeconds = const Value.absent(),
    this.workedAt = const Value.absent(),
    this.modules = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.building = const Value.absent(),
    this.buildingReadyAt = const Value.absent(),
    this.buildingLeftSeconds = const Value.absent(),
  });
  SheltersCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String kind,
    required double latitude,
    required double longitude,
    required DateTime startedAt,
    required int buildSeconds,
    this.buildLeftSeconds = const Value.absent(),
    this.workedAt = const Value.absent(),
    this.modules = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.building = const Value.absent(),
    this.buildingReadyAt = const Value.absent(),
    this.buildingLeftSeconds = const Value.absent(),
  }) : profileId = Value(profileId),
       kind = Value(kind),
       latitude = Value(latitude),
       longitude = Value(longitude),
       startedAt = Value(startedAt),
       buildSeconds = Value(buildSeconds);
  static Insertable<ShelterRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? kind,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? startedAt,
    Expression<int>? buildSeconds,
    Expression<int>? buildLeftSeconds,
    Expression<DateTime>? workedAt,
    Expression<String>? modules,
    Expression<DateTime>? visitedAt,
    Expression<String>? building,
    Expression<DateTime>? buildingReadyAt,
    Expression<int>? buildingLeftSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (kind != null) 'kind': kind,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (startedAt != null) 'started_at': startedAt,
      if (buildSeconds != null) 'build_seconds': buildSeconds,
      if (buildLeftSeconds != null) 'build_left_seconds': buildLeftSeconds,
      if (workedAt != null) 'worked_at': workedAt,
      if (modules != null) 'modules': modules,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (building != null) 'building': building,
      if (buildingReadyAt != null) 'building_ready_at': buildingReadyAt,
      if (buildingLeftSeconds != null)
        'building_left_seconds': buildingLeftSeconds,
    });
  }

  SheltersCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? kind,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<DateTime>? startedAt,
    Value<int>? buildSeconds,
    Value<int?>? buildLeftSeconds,
    Value<DateTime?>? workedAt,
    Value<String>? modules,
    Value<DateTime?>? visitedAt,
    Value<String?>? building,
    Value<DateTime?>? buildingReadyAt,
    Value<int?>? buildingLeftSeconds,
  }) {
    return SheltersCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      kind: kind ?? this.kind,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startedAt: startedAt ?? this.startedAt,
      buildSeconds: buildSeconds ?? this.buildSeconds,
      buildLeftSeconds: buildLeftSeconds ?? this.buildLeftSeconds,
      workedAt: workedAt ?? this.workedAt,
      modules: modules ?? this.modules,
      visitedAt: visitedAt ?? this.visitedAt,
      building: building ?? this.building,
      buildingReadyAt: buildingReadyAt ?? this.buildingReadyAt,
      buildingLeftSeconds: buildingLeftSeconds ?? this.buildingLeftSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (buildSeconds.present) {
      map['build_seconds'] = Variable<int>(buildSeconds.value);
    }
    if (buildLeftSeconds.present) {
      map['build_left_seconds'] = Variable<int>(buildLeftSeconds.value);
    }
    if (workedAt.present) {
      map['worked_at'] = Variable<DateTime>(workedAt.value);
    }
    if (modules.present) {
      map['modules'] = Variable<String>(modules.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (building.present) {
      map['building'] = Variable<String>(building.value);
    }
    if (buildingReadyAt.present) {
      map['building_ready_at'] = Variable<DateTime>(buildingReadyAt.value);
    }
    if (buildingLeftSeconds.present) {
      map['building_left_seconds'] = Variable<int>(buildingLeftSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SheltersCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('startedAt: $startedAt, ')
          ..write('buildSeconds: $buildSeconds, ')
          ..write('buildLeftSeconds: $buildLeftSeconds, ')
          ..write('workedAt: $workedAt, ')
          ..write('modules: $modules, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('building: $building, ')
          ..write('buildingReadyAt: $buildingReadyAt, ')
          ..write('buildingLeftSeconds: $buildingLeftSeconds')
          ..write(')'))
        .toString();
  }
}

class $RemainsEntriesTable extends RemainsEntries
    with TableInfo<$RemainsEntriesTable, RemainsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemainsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enemyIdMeta = const VerificationMeta(
    'enemyId',
  );
  @override
  late final GeneratedColumn<String> enemyId = GeneratedColumn<String>(
    'enemy_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diedAtMeta = const VerificationMeta('diedAt');
  @override
  late final GeneratedColumn<DateTime> diedAt = GeneratedColumn<DateTime>(
    'died_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchedMeta = const VerificationMeta(
    'searched',
  );
  @override
  late final GeneratedColumn<bool> searched = GeneratedColumn<bool>(
    'searched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("searched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    enemyId,
    kind,
    latitude,
    longitude,
    diedAt,
    searched,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remains_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemainsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('enemy_id')) {
      context.handle(
        _enemyIdMeta,
        enemyId.isAcceptableOrUnknown(data['enemy_id']!, _enemyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_enemyIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('died_at')) {
      context.handle(
        _diedAtMeta,
        diedAt.isAcceptableOrUnknown(data['died_at']!, _diedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_diedAtMeta);
    }
    if (data.containsKey('searched')) {
      context.handle(
        _searchedMeta,
        searched.isAcceptableOrUnknown(data['searched']!, _searchedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemainsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemainsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      enemyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enemy_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      diedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}died_at'],
      )!,
      searched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}searched'],
      )!,
    );
  }

  @override
  $RemainsEntriesTable createAlias(String alias) {
    return $RemainsEntriesTable(attachedDatabase, alias);
  }
}

class RemainsRow extends DataClass implements Insertable<RemainsRow> {
  final int id;
  final int profileId;

  /// The enemy's own id, so the same body cannot be written twice.
  final String enemyId;

  /// §6.2's kind, by name — what it was decides what is in its pockets.
  final String kind;
  final double latitude;
  final double longitude;
  final DateTime diedAt;

  /// Pockets already turned out. The mark stays on the map rather than the row
  /// being deleted: a player who searched it should be able to see that they
  /// did, or they walk back to it a second time.
  final bool searched;
  const RemainsRow({
    required this.id,
    required this.profileId,
    required this.enemyId,
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.diedAt,
    required this.searched,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['enemy_id'] = Variable<String>(enemyId);
    map['kind'] = Variable<String>(kind);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['died_at'] = Variable<DateTime>(diedAt);
    map['searched'] = Variable<bool>(searched);
    return map;
  }

  RemainsEntriesCompanion toCompanion(bool nullToAbsent) {
    return RemainsEntriesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      enemyId: Value(enemyId),
      kind: Value(kind),
      latitude: Value(latitude),
      longitude: Value(longitude),
      diedAt: Value(diedAt),
      searched: Value(searched),
    );
  }

  factory RemainsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemainsRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      enemyId: serializer.fromJson<String>(json['enemyId']),
      kind: serializer.fromJson<String>(json['kind']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      diedAt: serializer.fromJson<DateTime>(json['diedAt']),
      searched: serializer.fromJson<bool>(json['searched']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'enemyId': serializer.toJson<String>(enemyId),
      'kind': serializer.toJson<String>(kind),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'diedAt': serializer.toJson<DateTime>(diedAt),
      'searched': serializer.toJson<bool>(searched),
    };
  }

  RemainsRow copyWith({
    int? id,
    int? profileId,
    String? enemyId,
    String? kind,
    double? latitude,
    double? longitude,
    DateTime? diedAt,
    bool? searched,
  }) => RemainsRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    enemyId: enemyId ?? this.enemyId,
    kind: kind ?? this.kind,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    diedAt: diedAt ?? this.diedAt,
    searched: searched ?? this.searched,
  );
  RemainsRow copyWithCompanion(RemainsEntriesCompanion data) {
    return RemainsRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      enemyId: data.enemyId.present ? data.enemyId.value : this.enemyId,
      kind: data.kind.present ? data.kind.value : this.kind,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      diedAt: data.diedAt.present ? data.diedAt.value : this.diedAt,
      searched: data.searched.present ? data.searched.value : this.searched,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemainsRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('enemyId: $enemyId, ')
          ..write('kind: $kind, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('diedAt: $diedAt, ')
          ..write('searched: $searched')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    enemyId,
    kind,
    latitude,
    longitude,
    diedAt,
    searched,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemainsRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.enemyId == this.enemyId &&
          other.kind == this.kind &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.diedAt == this.diedAt &&
          other.searched == this.searched);
}

class RemainsEntriesCompanion extends UpdateCompanion<RemainsRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> enemyId;
  final Value<String> kind;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> diedAt;
  final Value<bool> searched;
  const RemainsEntriesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.enemyId = const Value.absent(),
    this.kind = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.diedAt = const Value.absent(),
    this.searched = const Value.absent(),
  });
  RemainsEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String enemyId,
    required String kind,
    required double latitude,
    required double longitude,
    required DateTime diedAt,
    this.searched = const Value.absent(),
  }) : profileId = Value(profileId),
       enemyId = Value(enemyId),
       kind = Value(kind),
       latitude = Value(latitude),
       longitude = Value(longitude),
       diedAt = Value(diedAt);
  static Insertable<RemainsRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? enemyId,
    Expression<String>? kind,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? diedAt,
    Expression<bool>? searched,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (enemyId != null) 'enemy_id': enemyId,
      if (kind != null) 'kind': kind,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (diedAt != null) 'died_at': diedAt,
      if (searched != null) 'searched': searched,
    });
  }

  RemainsEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? enemyId,
    Value<String>? kind,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<DateTime>? diedAt,
    Value<bool>? searched,
  }) {
    return RemainsEntriesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      enemyId: enemyId ?? this.enemyId,
      kind: kind ?? this.kind,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      diedAt: diedAt ?? this.diedAt,
      searched: searched ?? this.searched,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (enemyId.present) {
      map['enemy_id'] = Variable<String>(enemyId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (diedAt.present) {
      map['died_at'] = Variable<DateTime>(diedAt.value);
    }
    if (searched.present) {
      map['searched'] = Variable<bool>(searched.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemainsEntriesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('enemyId: $enemyId, ')
          ..write('kind: $kind, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('diedAt: $diedAt, ')
          ..write('searched: $searched')
          ..write(')'))
        .toString();
  }
}

abstract class _$SaveDatabase extends GeneratedDatabase {
  _$SaveDatabase(QueryExecutor e) : super(e);
  $SaveDatabaseManager get managers => $SaveDatabaseManager(this);
  late final $MetaEntriesTable metaEntries = $MetaEntriesTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $VitalsTable vitals = $VitalsTable(this);
  late final $ChronicleEntriesTable chronicleEntries = $ChronicleEntriesTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final $SnapshotRecordsTable snapshotRecords = $SnapshotRecordsTable(
    this,
  );
  late final $InventoryLinesTable inventoryLines = $InventoryLinesTable(this);
  late final $LootBoxesTable lootBoxes = $LootBoxesTable(this);
  late final $GroundItemsTable groundItems = $GroundItemsTable(this);
  late final $SheltersTable shelters = $SheltersTable(this);
  late final $RemainsEntriesTable remainsEntries = $RemainsEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    metaEntries,
    profiles,
    vitals,
    chronicleEntries,
    settings,
    snapshotRecords,
    inventoryLines,
    lootBoxes,
    groundItems,
    shelters,
    remainsEntries,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$MetaEntriesTableCreateCompanionBuilder =
    MetaEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetaEntriesTableUpdateCompanionBuilder =
    MetaEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetaEntriesTableFilterComposer
    extends Composer<_$SaveDatabase, $MetaEntriesTable> {
  $$MetaEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaEntriesTableOrderingComposer
    extends Composer<_$SaveDatabase, $MetaEntriesTable> {
  $$MetaEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaEntriesTableAnnotationComposer
    extends Composer<_$SaveDatabase, $MetaEntriesTable> {
  $$MetaEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaEntriesTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $MetaEntriesTable,
          MetaEntry,
          $$MetaEntriesTableFilterComposer,
          $$MetaEntriesTableOrderingComposer,
          $$MetaEntriesTableAnnotationComposer,
          $$MetaEntriesTableCreateCompanionBuilder,
          $$MetaEntriesTableUpdateCompanionBuilder,
          (
            MetaEntry,
            BaseReferences<_$SaveDatabase, $MetaEntriesTable, MetaEntry>,
          ),
          MetaEntry,
          PrefetchHooks Function()
        > {
  $$MetaEntriesTableTableManager(_$SaveDatabase db, $MetaEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetaEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $MetaEntriesTable,
      MetaEntry,
      $$MetaEntriesTableFilterComposer,
      $$MetaEntriesTableOrderingComposer,
      $$MetaEntriesTableAnnotationComposer,
      $$MetaEntriesTableCreateCompanionBuilder,
      $$MetaEntriesTableUpdateCompanionBuilder,
      (MetaEntry, BaseReferences<_$SaveDatabase, $MetaEntriesTable, MetaEntry>),
      MetaEntry,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      required String name,
      required String sex,
      required int ageYears,
      required int heightCm,
      required double weightKg,
      Value<int?> measuredRestingHr,
      required String deathMode,
      required int rngSeed,
      required DateTime createdAt,
      Value<DateTime?> diedAt,
      Value<String?> deathCause,
      Value<bool> isActive,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> sex,
      Value<int> ageYears,
      Value<int> heightCm,
      Value<double> weightKg,
      Value<int?> measuredRestingHr,
      Value<String> deathMode,
      Value<int> rngSeed,
      Value<DateTime> createdAt,
      Value<DateTime?> diedAt,
      Value<String?> deathCause,
      Value<bool> isActive,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$SaveDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ageYears => $composableBuilder(
    column: $table.ageYears,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get measuredRestingHr => $composableBuilder(
    column: $table.measuredRestingHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deathMode => $composableBuilder(
    column: $table.deathMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rngSeed => $composableBuilder(
    column: $table.rngSeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get diedAt => $composableBuilder(
    column: $table.diedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deathCause => $composableBuilder(
    column: $table.deathCause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$SaveDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ageYears => $composableBuilder(
    column: $table.ageYears,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get measuredRestingHr => $composableBuilder(
    column: $table.measuredRestingHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deathMode => $composableBuilder(
    column: $table.deathMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rngSeed => $composableBuilder(
    column: $table.rngSeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get diedAt => $composableBuilder(
    column: $table.diedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deathCause => $composableBuilder(
    column: $table.deathCause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$SaveDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get ageYears =>
      $composableBuilder(column: $table.ageYears, builder: (column) => column);

  GeneratedColumn<int> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get measuredRestingHr => $composableBuilder(
    column: $table.measuredRestingHr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deathMode =>
      $composableBuilder(column: $table.deathMode, builder: (column) => column);

  GeneratedColumn<int> get rngSeed =>
      $composableBuilder(column: $table.rngSeed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get diedAt =>
      $composableBuilder(column: $table.diedAt, builder: (column) => column);

  GeneratedColumn<String> get deathCause => $composableBuilder(
    column: $table.deathCause,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$SaveDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$SaveDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<int> ageYears = const Value.absent(),
                Value<int> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<int?> measuredRestingHr = const Value.absent(),
                Value<String> deathMode = const Value.absent(),
                Value<int> rngSeed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> diedAt = const Value.absent(),
                Value<String?> deathCause = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                sex: sex,
                ageYears: ageYears,
                heightCm: heightCm,
                weightKg: weightKg,
                measuredRestingHr: measuredRestingHr,
                deathMode: deathMode,
                rngSeed: rngSeed,
                createdAt: createdAt,
                diedAt: diedAt,
                deathCause: deathCause,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String sex,
                required int ageYears,
                required int heightCm,
                required double weightKg,
                Value<int?> measuredRestingHr = const Value.absent(),
                required String deathMode,
                required int rngSeed,
                required DateTime createdAt,
                Value<DateTime?> diedAt = const Value.absent(),
                Value<String?> deathCause = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                sex: sex,
                ageYears: ageYears,
                heightCm: heightCm,
                weightKg: weightKg,
                measuredRestingHr: measuredRestingHr,
                deathMode: deathMode,
                rngSeed: rngSeed,
                createdAt: createdAt,
                diedAt: diedAt,
                deathCause: deathCause,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$SaveDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$VitalsTableCreateCompanionBuilder =
    VitalsCompanion Function({
      Value<int> profileId,
      required DateTime lastUpdate,
      required double bloodMl,
      required double waterMl,
      required double caloriesKcal,
      required double heartRateBpm,
      Value<int> sleepDebtSeconds,
      Value<String> zone,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<double?> accuracyM,
      Value<String> rngCursors,
      Value<String> bleedTier,
      Value<DateTime?> downUntil,
      Value<DateTime?> huntUntil,
      Value<double?> huntLatitude,
      Value<double?> huntLongitude,
      Value<int> huntCount,
      Value<String?> occupationJson,
      Value<double> speedKmh,
      Value<double> carriedKg,
      Value<double> pendingKcal,
      Value<double> pendingWaterMl,
    });
typedef $$VitalsTableUpdateCompanionBuilder =
    VitalsCompanion Function({
      Value<int> profileId,
      Value<DateTime> lastUpdate,
      Value<double> bloodMl,
      Value<double> waterMl,
      Value<double> caloriesKcal,
      Value<double> heartRateBpm,
      Value<int> sleepDebtSeconds,
      Value<String> zone,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<double?> accuracyM,
      Value<String> rngCursors,
      Value<String> bleedTier,
      Value<DateTime?> downUntil,
      Value<DateTime?> huntUntil,
      Value<double?> huntLatitude,
      Value<double?> huntLongitude,
      Value<int> huntCount,
      Value<String?> occupationJson,
      Value<double> speedKmh,
      Value<double> carriedKg,
      Value<double> pendingKcal,
      Value<double> pendingWaterMl,
    });

class $$VitalsTableFilterComposer
    extends Composer<_$SaveDatabase, $VitalsTable> {
  $$VitalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdate => $composableBuilder(
    column: $table.lastUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bloodMl => $composableBuilder(
    column: $table.bloodMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterMl => $composableBuilder(
    column: $table.waterMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepDebtSeconds => $composableBuilder(
    column: $table.sleepDebtSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rngCursors => $composableBuilder(
    column: $table.rngCursors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bleedTier => $composableBuilder(
    column: $table.bleedTier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downUntil => $composableBuilder(
    column: $table.downUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get huntUntil => $composableBuilder(
    column: $table.huntUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get huntLatitude => $composableBuilder(
    column: $table.huntLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get huntLongitude => $composableBuilder(
    column: $table.huntLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get huntCount => $composableBuilder(
    column: $table.huntCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occupationJson => $composableBuilder(
    column: $table.occupationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedKmh => $composableBuilder(
    column: $table.speedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carriedKg => $composableBuilder(
    column: $table.carriedKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pendingKcal => $composableBuilder(
    column: $table.pendingKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pendingWaterMl => $composableBuilder(
    column: $table.pendingWaterMl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VitalsTableOrderingComposer
    extends Composer<_$SaveDatabase, $VitalsTable> {
  $$VitalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdate => $composableBuilder(
    column: $table.lastUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bloodMl => $composableBuilder(
    column: $table.bloodMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterMl => $composableBuilder(
    column: $table.waterMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepDebtSeconds => $composableBuilder(
    column: $table.sleepDebtSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rngCursors => $composableBuilder(
    column: $table.rngCursors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bleedTier => $composableBuilder(
    column: $table.bleedTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downUntil => $composableBuilder(
    column: $table.downUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get huntUntil => $composableBuilder(
    column: $table.huntUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get huntLatitude => $composableBuilder(
    column: $table.huntLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get huntLongitude => $composableBuilder(
    column: $table.huntLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get huntCount => $composableBuilder(
    column: $table.huntCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occupationJson => $composableBuilder(
    column: $table.occupationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedKmh => $composableBuilder(
    column: $table.speedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carriedKg => $composableBuilder(
    column: $table.carriedKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pendingKcal => $composableBuilder(
    column: $table.pendingKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pendingWaterMl => $composableBuilder(
    column: $table.pendingWaterMl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VitalsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $VitalsTable> {
  $$VitalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdate => $composableBuilder(
    column: $table.lastUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bloodMl =>
      $composableBuilder(column: $table.bloodMl, builder: (column) => column);

  GeneratedColumn<double> get waterMl =>
      $composableBuilder(column: $table.waterMl, builder: (column) => column);

  GeneratedColumn<double> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepDebtSeconds => $composableBuilder(
    column: $table.sleepDebtSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zone =>
      $composableBuilder(column: $table.zone, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<String> get rngCursors => $composableBuilder(
    column: $table.rngCursors,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bleedTier =>
      $composableBuilder(column: $table.bleedTier, builder: (column) => column);

  GeneratedColumn<DateTime> get downUntil =>
      $composableBuilder(column: $table.downUntil, builder: (column) => column);

  GeneratedColumn<DateTime> get huntUntil =>
      $composableBuilder(column: $table.huntUntil, builder: (column) => column);

  GeneratedColumn<double> get huntLatitude => $composableBuilder(
    column: $table.huntLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get huntLongitude => $composableBuilder(
    column: $table.huntLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<int> get huntCount =>
      $composableBuilder(column: $table.huntCount, builder: (column) => column);

  GeneratedColumn<String> get occupationJson => $composableBuilder(
    column: $table.occupationJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speedKmh =>
      $composableBuilder(column: $table.speedKmh, builder: (column) => column);

  GeneratedColumn<double> get carriedKg =>
      $composableBuilder(column: $table.carriedKg, builder: (column) => column);

  GeneratedColumn<double> get pendingKcal => $composableBuilder(
    column: $table.pendingKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pendingWaterMl => $composableBuilder(
    column: $table.pendingWaterMl,
    builder: (column) => column,
  );
}

class $$VitalsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $VitalsTable,
          Vital,
          $$VitalsTableFilterComposer,
          $$VitalsTableOrderingComposer,
          $$VitalsTableAnnotationComposer,
          $$VitalsTableCreateCompanionBuilder,
          $$VitalsTableUpdateCompanionBuilder,
          (Vital, BaseReferences<_$SaveDatabase, $VitalsTable, Vital>),
          Vital,
          PrefetchHooks Function()
        > {
  $$VitalsTableTableManager(_$SaveDatabase db, $VitalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VitalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VitalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VitalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<DateTime> lastUpdate = const Value.absent(),
                Value<double> bloodMl = const Value.absent(),
                Value<double> waterMl = const Value.absent(),
                Value<double> caloriesKcal = const Value.absent(),
                Value<double> heartRateBpm = const Value.absent(),
                Value<int> sleepDebtSeconds = const Value.absent(),
                Value<String> zone = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<String> rngCursors = const Value.absent(),
                Value<String> bleedTier = const Value.absent(),
                Value<DateTime?> downUntil = const Value.absent(),
                Value<DateTime?> huntUntil = const Value.absent(),
                Value<double?> huntLatitude = const Value.absent(),
                Value<double?> huntLongitude = const Value.absent(),
                Value<int> huntCount = const Value.absent(),
                Value<String?> occupationJson = const Value.absent(),
                Value<double> speedKmh = const Value.absent(),
                Value<double> carriedKg = const Value.absent(),
                Value<double> pendingKcal = const Value.absent(),
                Value<double> pendingWaterMl = const Value.absent(),
              }) => VitalsCompanion(
                profileId: profileId,
                lastUpdate: lastUpdate,
                bloodMl: bloodMl,
                waterMl: waterMl,
                caloriesKcal: caloriesKcal,
                heartRateBpm: heartRateBpm,
                sleepDebtSeconds: sleepDebtSeconds,
                zone: zone,
                latitude: latitude,
                longitude: longitude,
                accuracyM: accuracyM,
                rngCursors: rngCursors,
                bleedTier: bleedTier,
                downUntil: downUntil,
                huntUntil: huntUntil,
                huntLatitude: huntLatitude,
                huntLongitude: huntLongitude,
                huntCount: huntCount,
                occupationJson: occupationJson,
                speedKmh: speedKmh,
                carriedKg: carriedKg,
                pendingKcal: pendingKcal,
                pendingWaterMl: pendingWaterMl,
              ),
          createCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                required DateTime lastUpdate,
                required double bloodMl,
                required double waterMl,
                required double caloriesKcal,
                required double heartRateBpm,
                Value<int> sleepDebtSeconds = const Value.absent(),
                Value<String> zone = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<String> rngCursors = const Value.absent(),
                Value<String> bleedTier = const Value.absent(),
                Value<DateTime?> downUntil = const Value.absent(),
                Value<DateTime?> huntUntil = const Value.absent(),
                Value<double?> huntLatitude = const Value.absent(),
                Value<double?> huntLongitude = const Value.absent(),
                Value<int> huntCount = const Value.absent(),
                Value<String?> occupationJson = const Value.absent(),
                Value<double> speedKmh = const Value.absent(),
                Value<double> carriedKg = const Value.absent(),
                Value<double> pendingKcal = const Value.absent(),
                Value<double> pendingWaterMl = const Value.absent(),
              }) => VitalsCompanion.insert(
                profileId: profileId,
                lastUpdate: lastUpdate,
                bloodMl: bloodMl,
                waterMl: waterMl,
                caloriesKcal: caloriesKcal,
                heartRateBpm: heartRateBpm,
                sleepDebtSeconds: sleepDebtSeconds,
                zone: zone,
                latitude: latitude,
                longitude: longitude,
                accuracyM: accuracyM,
                rngCursors: rngCursors,
                bleedTier: bleedTier,
                downUntil: downUntil,
                huntUntil: huntUntil,
                huntLatitude: huntLatitude,
                huntLongitude: huntLongitude,
                huntCount: huntCount,
                occupationJson: occupationJson,
                speedKmh: speedKmh,
                carriedKg: carriedKg,
                pendingKcal: pendingKcal,
                pendingWaterMl: pendingWaterMl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VitalsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $VitalsTable,
      Vital,
      $$VitalsTableFilterComposer,
      $$VitalsTableOrderingComposer,
      $$VitalsTableAnnotationComposer,
      $$VitalsTableCreateCompanionBuilder,
      $$VitalsTableUpdateCompanionBuilder,
      (Vital, BaseReferences<_$SaveDatabase, $VitalsTable, Vital>),
      Vital,
      PrefetchHooks Function()
    >;
typedef $$ChronicleEntriesTableCreateCompanionBuilder =
    ChronicleEntriesCompanion Function({
      Value<int> id,
      required int profileId,
      required int survivalDays,
      required DateTime startedAt,
      required DateTime endedAt,
      required String cause,
      required String deathMode,
      Value<String> snapshotJson,
    });
typedef $$ChronicleEntriesTableUpdateCompanionBuilder =
    ChronicleEntriesCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<int> survivalDays,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<String> cause,
      Value<String> deathMode,
      Value<String> snapshotJson,
    });

class $$ChronicleEntriesTableFilterComposer
    extends Composer<_$SaveDatabase, $ChronicleEntriesTable> {
  $$ChronicleEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get survivalDays => $composableBuilder(
    column: $table.survivalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cause => $composableBuilder(
    column: $table.cause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deathMode => $composableBuilder(
    column: $table.deathMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChronicleEntriesTableOrderingComposer
    extends Composer<_$SaveDatabase, $ChronicleEntriesTable> {
  $$ChronicleEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get survivalDays => $composableBuilder(
    column: $table.survivalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cause => $composableBuilder(
    column: $table.cause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deathMode => $composableBuilder(
    column: $table.deathMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChronicleEntriesTableAnnotationComposer
    extends Composer<_$SaveDatabase, $ChronicleEntriesTable> {
  $$ChronicleEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get survivalDays => $composableBuilder(
    column: $table.survivalDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get cause =>
      $composableBuilder(column: $table.cause, builder: (column) => column);

  GeneratedColumn<String> get deathMode =>
      $composableBuilder(column: $table.deathMode, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => column,
  );
}

class $$ChronicleEntriesTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $ChronicleEntriesTable,
          ChronicleEntry,
          $$ChronicleEntriesTableFilterComposer,
          $$ChronicleEntriesTableOrderingComposer,
          $$ChronicleEntriesTableAnnotationComposer,
          $$ChronicleEntriesTableCreateCompanionBuilder,
          $$ChronicleEntriesTableUpdateCompanionBuilder,
          (
            ChronicleEntry,
            BaseReferences<
              _$SaveDatabase,
              $ChronicleEntriesTable,
              ChronicleEntry
            >,
          ),
          ChronicleEntry,
          PrefetchHooks Function()
        > {
  $$ChronicleEntriesTableTableManager(
    _$SaveDatabase db,
    $ChronicleEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChronicleEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChronicleEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChronicleEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> survivalDays = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<String> cause = const Value.absent(),
                Value<String> deathMode = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
              }) => ChronicleEntriesCompanion(
                id: id,
                profileId: profileId,
                survivalDays: survivalDays,
                startedAt: startedAt,
                endedAt: endedAt,
                cause: cause,
                deathMode: deathMode,
                snapshotJson: snapshotJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required int survivalDays,
                required DateTime startedAt,
                required DateTime endedAt,
                required String cause,
                required String deathMode,
                Value<String> snapshotJson = const Value.absent(),
              }) => ChronicleEntriesCompanion.insert(
                id: id,
                profileId: profileId,
                survivalDays: survivalDays,
                startedAt: startedAt,
                endedAt: endedAt,
                cause: cause,
                deathMode: deathMode,
                snapshotJson: snapshotJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChronicleEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $ChronicleEntriesTable,
      ChronicleEntry,
      $$ChronicleEntriesTableFilterComposer,
      $$ChronicleEntriesTableOrderingComposer,
      $$ChronicleEntriesTableAnnotationComposer,
      $$ChronicleEntriesTableCreateCompanionBuilder,
      $$ChronicleEntriesTableUpdateCompanionBuilder,
      (
        ChronicleEntry,
        BaseReferences<_$SaveDatabase, $ChronicleEntriesTable, ChronicleEntry>,
      ),
      ChronicleEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$SaveDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$SaveDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$SaveDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$SaveDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$SaveDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$SnapshotRecordsTableCreateCompanionBuilder =
    SnapshotRecordsCompanion Function({
      Value<int> id,
      required String fileName,
      required DateTime takenAt,
      required int sizeBytes,
      required String checksum,
      required int schemaVersion,
      Value<String> reason,
    });
typedef $$SnapshotRecordsTableUpdateCompanionBuilder =
    SnapshotRecordsCompanion Function({
      Value<int> id,
      Value<String> fileName,
      Value<DateTime> takenAt,
      Value<int> sizeBytes,
      Value<String> checksum,
      Value<int> schemaVersion,
      Value<String> reason,
    });

class $$SnapshotRecordsTableFilterComposer
    extends Composer<_$SaveDatabase, $SnapshotRecordsTable> {
  $$SnapshotRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SnapshotRecordsTableOrderingComposer
    extends Composer<_$SaveDatabase, $SnapshotRecordsTable> {
  $$SnapshotRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnapshotRecordsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $SnapshotRecordsTable> {
  $$SnapshotRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$SnapshotRecordsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $SnapshotRecordsTable,
          SnapshotRecord,
          $$SnapshotRecordsTableFilterComposer,
          $$SnapshotRecordsTableOrderingComposer,
          $$SnapshotRecordsTableAnnotationComposer,
          $$SnapshotRecordsTableCreateCompanionBuilder,
          $$SnapshotRecordsTableUpdateCompanionBuilder,
          (
            SnapshotRecord,
            BaseReferences<
              _$SaveDatabase,
              $SnapshotRecordsTable,
              SnapshotRecord
            >,
          ),
          SnapshotRecord,
          PrefetchHooks Function()
        > {
  $$SnapshotRecordsTableTableManager(
    _$SaveDatabase db,
    $SnapshotRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> reason = const Value.absent(),
              }) => SnapshotRecordsCompanion(
                id: id,
                fileName: fileName,
                takenAt: takenAt,
                sizeBytes: sizeBytes,
                checksum: checksum,
                schemaVersion: schemaVersion,
                reason: reason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileName,
                required DateTime takenAt,
                required int sizeBytes,
                required String checksum,
                required int schemaVersion,
                Value<String> reason = const Value.absent(),
              }) => SnapshotRecordsCompanion.insert(
                id: id,
                fileName: fileName,
                takenAt: takenAt,
                sizeBytes: sizeBytes,
                checksum: checksum,
                schemaVersion: schemaVersion,
                reason: reason,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SnapshotRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $SnapshotRecordsTable,
      SnapshotRecord,
      $$SnapshotRecordsTableFilterComposer,
      $$SnapshotRecordsTableOrderingComposer,
      $$SnapshotRecordsTableAnnotationComposer,
      $$SnapshotRecordsTableCreateCompanionBuilder,
      $$SnapshotRecordsTableUpdateCompanionBuilder,
      (
        SnapshotRecord,
        BaseReferences<_$SaveDatabase, $SnapshotRecordsTable, SnapshotRecord>,
      ),
      SnapshotRecord,
      PrefetchHooks Function()
    >;
typedef $$InventoryLinesTableCreateCompanionBuilder =
    InventoryLinesCompanion Function({
      Value<int> id,
      required int profileId,
      required String itemId,
      Value<int> count,
      Value<String> slot,
      Value<double?> condition,
      Value<int?> pagesTotal,
      Value<int> pagesRead,
      Value<String?> noteId,
      Value<double> portion,
      Value<String> attachments,
    });
typedef $$InventoryLinesTableUpdateCompanionBuilder =
    InventoryLinesCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> itemId,
      Value<int> count,
      Value<String> slot,
      Value<double?> condition,
      Value<int?> pagesTotal,
      Value<int> pagesRead,
      Value<String?> noteId,
      Value<double> portion,
      Value<String> attachments,
    });

class $$InventoryLinesTableFilterComposer
    extends Composer<_$SaveDatabase, $InventoryLinesTable> {
  $$InventoryLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pagesTotal => $composableBuilder(
    column: $table.pagesTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pagesRead => $composableBuilder(
    column: $table.pagesRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get portion => $composableBuilder(
    column: $table.portion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryLinesTableOrderingComposer
    extends Composer<_$SaveDatabase, $InventoryLinesTable> {
  $$InventoryLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pagesTotal => $composableBuilder(
    column: $table.pagesTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pagesRead => $composableBuilder(
    column: $table.pagesRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get portion => $composableBuilder(
    column: $table.portion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryLinesTableAnnotationComposer
    extends Composer<_$SaveDatabase, $InventoryLinesTable> {
  $$InventoryLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<double> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<int> get pagesTotal => $composableBuilder(
    column: $table.pagesTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pagesRead =>
      $composableBuilder(column: $table.pagesRead, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<double> get portion =>
      $composableBuilder(column: $table.portion, builder: (column) => column);

  GeneratedColumn<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => column,
  );
}

class $$InventoryLinesTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $InventoryLinesTable,
          InventoryLine,
          $$InventoryLinesTableFilterComposer,
          $$InventoryLinesTableOrderingComposer,
          $$InventoryLinesTableAnnotationComposer,
          $$InventoryLinesTableCreateCompanionBuilder,
          $$InventoryLinesTableUpdateCompanionBuilder,
          (
            InventoryLine,
            BaseReferences<_$SaveDatabase, $InventoryLinesTable, InventoryLine>,
          ),
          InventoryLine,
          PrefetchHooks Function()
        > {
  $$InventoryLinesTableTableManager(
    _$SaveDatabase db,
    $InventoryLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<double?> condition = const Value.absent(),
                Value<int?> pagesTotal = const Value.absent(),
                Value<int> pagesRead = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<double> portion = const Value.absent(),
                Value<String> attachments = const Value.absent(),
              }) => InventoryLinesCompanion(
                id: id,
                profileId: profileId,
                itemId: itemId,
                count: count,
                slot: slot,
                condition: condition,
                pagesTotal: pagesTotal,
                pagesRead: pagesRead,
                noteId: noteId,
                portion: portion,
                attachments: attachments,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String itemId,
                Value<int> count = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<double?> condition = const Value.absent(),
                Value<int?> pagesTotal = const Value.absent(),
                Value<int> pagesRead = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<double> portion = const Value.absent(),
                Value<String> attachments = const Value.absent(),
              }) => InventoryLinesCompanion.insert(
                id: id,
                profileId: profileId,
                itemId: itemId,
                count: count,
                slot: slot,
                condition: condition,
                pagesTotal: pagesTotal,
                pagesRead: pagesRead,
                noteId: noteId,
                portion: portion,
                attachments: attachments,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $InventoryLinesTable,
      InventoryLine,
      $$InventoryLinesTableFilterComposer,
      $$InventoryLinesTableOrderingComposer,
      $$InventoryLinesTableAnnotationComposer,
      $$InventoryLinesTableCreateCompanionBuilder,
      $$InventoryLinesTableUpdateCompanionBuilder,
      (
        InventoryLine,
        BaseReferences<_$SaveDatabase, $InventoryLinesTable, InventoryLine>,
      ),
      InventoryLine,
      PrefetchHooks Function()
    >;
typedef $$LootBoxesTableCreateCompanionBuilder =
    LootBoxesCompanion Function({
      Value<int> id,
      required int profileId,
      required String poiId,
      required double latitude,
      required double longitude,
      required String tableId,
      Value<String?> name,
      required DateTime spawnedAt,
      Value<DateTime?> lootedAt,
      Value<DateTime?> respawnAt,
      Value<DateTime?> openedAt,
      Value<int> searchUnits,
    });
typedef $$LootBoxesTableUpdateCompanionBuilder =
    LootBoxesCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> poiId,
      Value<double> latitude,
      Value<double> longitude,
      Value<String> tableId,
      Value<String?> name,
      Value<DateTime> spawnedAt,
      Value<DateTime?> lootedAt,
      Value<DateTime?> respawnAt,
      Value<DateTime?> openedAt,
      Value<int> searchUnits,
    });

class $$LootBoxesTableFilterComposer
    extends Composer<_$SaveDatabase, $LootBoxesTable> {
  $$LootBoxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poiId => $composableBuilder(
    column: $table.poiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get spawnedAt => $composableBuilder(
    column: $table.spawnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lootedAt => $composableBuilder(
    column: $table.lootedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get respawnAt => $composableBuilder(
    column: $table.respawnAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get searchUnits => $composableBuilder(
    column: $table.searchUnits,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LootBoxesTableOrderingComposer
    extends Composer<_$SaveDatabase, $LootBoxesTable> {
  $$LootBoxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poiId => $composableBuilder(
    column: $table.poiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get spawnedAt => $composableBuilder(
    column: $table.spawnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lootedAt => $composableBuilder(
    column: $table.lootedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get respawnAt => $composableBuilder(
    column: $table.respawnAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get searchUnits => $composableBuilder(
    column: $table.searchUnits,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LootBoxesTableAnnotationComposer
    extends Composer<_$SaveDatabase, $LootBoxesTable> {
  $$LootBoxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get poiId =>
      $composableBuilder(column: $table.poiId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get spawnedAt =>
      $composableBuilder(column: $table.spawnedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lootedAt =>
      $composableBuilder(column: $table.lootedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get respawnAt =>
      $composableBuilder(column: $table.respawnAt, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<int> get searchUnits => $composableBuilder(
    column: $table.searchUnits,
    builder: (column) => column,
  );
}

class $$LootBoxesTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $LootBoxesTable,
          LootBoxe,
          $$LootBoxesTableFilterComposer,
          $$LootBoxesTableOrderingComposer,
          $$LootBoxesTableAnnotationComposer,
          $$LootBoxesTableCreateCompanionBuilder,
          $$LootBoxesTableUpdateCompanionBuilder,
          (LootBoxe, BaseReferences<_$SaveDatabase, $LootBoxesTable, LootBoxe>),
          LootBoxe,
          PrefetchHooks Function()
        > {
  $$LootBoxesTableTableManager(_$SaveDatabase db, $LootBoxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LootBoxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LootBoxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LootBoxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> poiId = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String> tableId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<DateTime> spawnedAt = const Value.absent(),
                Value<DateTime?> lootedAt = const Value.absent(),
                Value<DateTime?> respawnAt = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<int> searchUnits = const Value.absent(),
              }) => LootBoxesCompanion(
                id: id,
                profileId: profileId,
                poiId: poiId,
                latitude: latitude,
                longitude: longitude,
                tableId: tableId,
                name: name,
                spawnedAt: spawnedAt,
                lootedAt: lootedAt,
                respawnAt: respawnAt,
                openedAt: openedAt,
                searchUnits: searchUnits,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String poiId,
                required double latitude,
                required double longitude,
                required String tableId,
                Value<String?> name = const Value.absent(),
                required DateTime spawnedAt,
                Value<DateTime?> lootedAt = const Value.absent(),
                Value<DateTime?> respawnAt = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<int> searchUnits = const Value.absent(),
              }) => LootBoxesCompanion.insert(
                id: id,
                profileId: profileId,
                poiId: poiId,
                latitude: latitude,
                longitude: longitude,
                tableId: tableId,
                name: name,
                spawnedAt: spawnedAt,
                lootedAt: lootedAt,
                respawnAt: respawnAt,
                openedAt: openedAt,
                searchUnits: searchUnits,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LootBoxesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $LootBoxesTable,
      LootBoxe,
      $$LootBoxesTableFilterComposer,
      $$LootBoxesTableOrderingComposer,
      $$LootBoxesTableAnnotationComposer,
      $$LootBoxesTableCreateCompanionBuilder,
      $$LootBoxesTableUpdateCompanionBuilder,
      (LootBoxe, BaseReferences<_$SaveDatabase, $LootBoxesTable, LootBoxe>),
      LootBoxe,
      PrefetchHooks Function()
    >;
typedef $$GroundItemsTableCreateCompanionBuilder =
    GroundItemsCompanion Function({
      Value<int> id,
      required int profileId,
      required String itemId,
      Value<int> count,
      Value<double?> condition,
      Value<int?> pagesTotal,
      Value<int> pagesRead,
      required double latitude,
      required double longitude,
      required DateTime droppedAt,
    });
typedef $$GroundItemsTableUpdateCompanionBuilder =
    GroundItemsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> itemId,
      Value<int> count,
      Value<double?> condition,
      Value<int?> pagesTotal,
      Value<int> pagesRead,
      Value<double> latitude,
      Value<double> longitude,
      Value<DateTime> droppedAt,
    });

class $$GroundItemsTableFilterComposer
    extends Composer<_$SaveDatabase, $GroundItemsTable> {
  $$GroundItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pagesTotal => $composableBuilder(
    column: $table.pagesTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pagesRead => $composableBuilder(
    column: $table.pagesRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get droppedAt => $composableBuilder(
    column: $table.droppedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroundItemsTableOrderingComposer
    extends Composer<_$SaveDatabase, $GroundItemsTable> {
  $$GroundItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pagesTotal => $composableBuilder(
    column: $table.pagesTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pagesRead => $composableBuilder(
    column: $table.pagesRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get droppedAt => $composableBuilder(
    column: $table.droppedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroundItemsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $GroundItemsTable> {
  $$GroundItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<double> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<int> get pagesTotal => $composableBuilder(
    column: $table.pagesTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pagesRead =>
      $composableBuilder(column: $table.pagesRead, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get droppedAt =>
      $composableBuilder(column: $table.droppedAt, builder: (column) => column);
}

class $$GroundItemsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $GroundItemsTable,
          GroundItem,
          $$GroundItemsTableFilterComposer,
          $$GroundItemsTableOrderingComposer,
          $$GroundItemsTableAnnotationComposer,
          $$GroundItemsTableCreateCompanionBuilder,
          $$GroundItemsTableUpdateCompanionBuilder,
          (
            GroundItem,
            BaseReferences<_$SaveDatabase, $GroundItemsTable, GroundItem>,
          ),
          GroundItem,
          PrefetchHooks Function()
        > {
  $$GroundItemsTableTableManager(_$SaveDatabase db, $GroundItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroundItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroundItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroundItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<double?> condition = const Value.absent(),
                Value<int?> pagesTotal = const Value.absent(),
                Value<int> pagesRead = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<DateTime> droppedAt = const Value.absent(),
              }) => GroundItemsCompanion(
                id: id,
                profileId: profileId,
                itemId: itemId,
                count: count,
                condition: condition,
                pagesTotal: pagesTotal,
                pagesRead: pagesRead,
                latitude: latitude,
                longitude: longitude,
                droppedAt: droppedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String itemId,
                Value<int> count = const Value.absent(),
                Value<double?> condition = const Value.absent(),
                Value<int?> pagesTotal = const Value.absent(),
                Value<int> pagesRead = const Value.absent(),
                required double latitude,
                required double longitude,
                required DateTime droppedAt,
              }) => GroundItemsCompanion.insert(
                id: id,
                profileId: profileId,
                itemId: itemId,
                count: count,
                condition: condition,
                pagesTotal: pagesTotal,
                pagesRead: pagesRead,
                latitude: latitude,
                longitude: longitude,
                droppedAt: droppedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroundItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $GroundItemsTable,
      GroundItem,
      $$GroundItemsTableFilterComposer,
      $$GroundItemsTableOrderingComposer,
      $$GroundItemsTableAnnotationComposer,
      $$GroundItemsTableCreateCompanionBuilder,
      $$GroundItemsTableUpdateCompanionBuilder,
      (
        GroundItem,
        BaseReferences<_$SaveDatabase, $GroundItemsTable, GroundItem>,
      ),
      GroundItem,
      PrefetchHooks Function()
    >;
typedef $$SheltersTableCreateCompanionBuilder =
    SheltersCompanion Function({
      Value<int> id,
      required int profileId,
      required String kind,
      required double latitude,
      required double longitude,
      required DateTime startedAt,
      required int buildSeconds,
      Value<int?> buildLeftSeconds,
      Value<DateTime?> workedAt,
      Value<String> modules,
      Value<DateTime?> visitedAt,
      Value<String?> building,
      Value<DateTime?> buildingReadyAt,
      Value<int?> buildingLeftSeconds,
    });
typedef $$SheltersTableUpdateCompanionBuilder =
    SheltersCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> kind,
      Value<double> latitude,
      Value<double> longitude,
      Value<DateTime> startedAt,
      Value<int> buildSeconds,
      Value<int?> buildLeftSeconds,
      Value<DateTime?> workedAt,
      Value<String> modules,
      Value<DateTime?> visitedAt,
      Value<String?> building,
      Value<DateTime?> buildingReadyAt,
      Value<int?> buildingLeftSeconds,
    });

class $$SheltersTableFilterComposer
    extends Composer<_$SaveDatabase, $SheltersTable> {
  $$SheltersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get buildSeconds => $composableBuilder(
    column: $table.buildSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get buildLeftSeconds => $composableBuilder(
    column: $table.buildLeftSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get workedAt => $composableBuilder(
    column: $table.workedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modules => $composableBuilder(
    column: $table.modules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get building => $composableBuilder(
    column: $table.building,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get buildingReadyAt => $composableBuilder(
    column: $table.buildingReadyAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get buildingLeftSeconds => $composableBuilder(
    column: $table.buildingLeftSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SheltersTableOrderingComposer
    extends Composer<_$SaveDatabase, $SheltersTable> {
  $$SheltersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get buildSeconds => $composableBuilder(
    column: $table.buildSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get buildLeftSeconds => $composableBuilder(
    column: $table.buildLeftSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get workedAt => $composableBuilder(
    column: $table.workedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modules => $composableBuilder(
    column: $table.modules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get building => $composableBuilder(
    column: $table.building,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get buildingReadyAt => $composableBuilder(
    column: $table.buildingReadyAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get buildingLeftSeconds => $composableBuilder(
    column: $table.buildingLeftSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SheltersTableAnnotationComposer
    extends Composer<_$SaveDatabase, $SheltersTable> {
  $$SheltersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get buildSeconds => $composableBuilder(
    column: $table.buildSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get buildLeftSeconds => $composableBuilder(
    column: $table.buildLeftSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get workedAt =>
      $composableBuilder(column: $table.workedAt, builder: (column) => column);

  GeneratedColumn<String> get modules =>
      $composableBuilder(column: $table.modules, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);

  GeneratedColumn<String> get building =>
      $composableBuilder(column: $table.building, builder: (column) => column);

  GeneratedColumn<DateTime> get buildingReadyAt => $composableBuilder(
    column: $table.buildingReadyAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get buildingLeftSeconds => $composableBuilder(
    column: $table.buildingLeftSeconds,
    builder: (column) => column,
  );
}

class $$SheltersTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $SheltersTable,
          ShelterRow,
          $$SheltersTableFilterComposer,
          $$SheltersTableOrderingComposer,
          $$SheltersTableAnnotationComposer,
          $$SheltersTableCreateCompanionBuilder,
          $$SheltersTableUpdateCompanionBuilder,
          (
            ShelterRow,
            BaseReferences<_$SaveDatabase, $SheltersTable, ShelterRow>,
          ),
          ShelterRow,
          PrefetchHooks Function()
        > {
  $$SheltersTableTableManager(_$SaveDatabase db, $SheltersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SheltersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SheltersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SheltersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> buildSeconds = const Value.absent(),
                Value<int?> buildLeftSeconds = const Value.absent(),
                Value<DateTime?> workedAt = const Value.absent(),
                Value<String> modules = const Value.absent(),
                Value<DateTime?> visitedAt = const Value.absent(),
                Value<String?> building = const Value.absent(),
                Value<DateTime?> buildingReadyAt = const Value.absent(),
                Value<int?> buildingLeftSeconds = const Value.absent(),
              }) => SheltersCompanion(
                id: id,
                profileId: profileId,
                kind: kind,
                latitude: latitude,
                longitude: longitude,
                startedAt: startedAt,
                buildSeconds: buildSeconds,
                buildLeftSeconds: buildLeftSeconds,
                workedAt: workedAt,
                modules: modules,
                visitedAt: visitedAt,
                building: building,
                buildingReadyAt: buildingReadyAt,
                buildingLeftSeconds: buildingLeftSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String kind,
                required double latitude,
                required double longitude,
                required DateTime startedAt,
                required int buildSeconds,
                Value<int?> buildLeftSeconds = const Value.absent(),
                Value<DateTime?> workedAt = const Value.absent(),
                Value<String> modules = const Value.absent(),
                Value<DateTime?> visitedAt = const Value.absent(),
                Value<String?> building = const Value.absent(),
                Value<DateTime?> buildingReadyAt = const Value.absent(),
                Value<int?> buildingLeftSeconds = const Value.absent(),
              }) => SheltersCompanion.insert(
                id: id,
                profileId: profileId,
                kind: kind,
                latitude: latitude,
                longitude: longitude,
                startedAt: startedAt,
                buildSeconds: buildSeconds,
                buildLeftSeconds: buildLeftSeconds,
                workedAt: workedAt,
                modules: modules,
                visitedAt: visitedAt,
                building: building,
                buildingReadyAt: buildingReadyAt,
                buildingLeftSeconds: buildingLeftSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SheltersTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $SheltersTable,
      ShelterRow,
      $$SheltersTableFilterComposer,
      $$SheltersTableOrderingComposer,
      $$SheltersTableAnnotationComposer,
      $$SheltersTableCreateCompanionBuilder,
      $$SheltersTableUpdateCompanionBuilder,
      (ShelterRow, BaseReferences<_$SaveDatabase, $SheltersTable, ShelterRow>),
      ShelterRow,
      PrefetchHooks Function()
    >;
typedef $$RemainsEntriesTableCreateCompanionBuilder =
    RemainsEntriesCompanion Function({
      Value<int> id,
      required int profileId,
      required String enemyId,
      required String kind,
      required double latitude,
      required double longitude,
      required DateTime diedAt,
      Value<bool> searched,
    });
typedef $$RemainsEntriesTableUpdateCompanionBuilder =
    RemainsEntriesCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> enemyId,
      Value<String> kind,
      Value<double> latitude,
      Value<double> longitude,
      Value<DateTime> diedAt,
      Value<bool> searched,
    });

class $$RemainsEntriesTableFilterComposer
    extends Composer<_$SaveDatabase, $RemainsEntriesTable> {
  $$RemainsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enemyId => $composableBuilder(
    column: $table.enemyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get diedAt => $composableBuilder(
    column: $table.diedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get searched => $composableBuilder(
    column: $table.searched,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemainsEntriesTableOrderingComposer
    extends Composer<_$SaveDatabase, $RemainsEntriesTable> {
  $$RemainsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enemyId => $composableBuilder(
    column: $table.enemyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get diedAt => $composableBuilder(
    column: $table.diedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get searched => $composableBuilder(
    column: $table.searched,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemainsEntriesTableAnnotationComposer
    extends Composer<_$SaveDatabase, $RemainsEntriesTable> {
  $$RemainsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get enemyId =>
      $composableBuilder(column: $table.enemyId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get diedAt =>
      $composableBuilder(column: $table.diedAt, builder: (column) => column);

  GeneratedColumn<bool> get searched =>
      $composableBuilder(column: $table.searched, builder: (column) => column);
}

class $$RemainsEntriesTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $RemainsEntriesTable,
          RemainsRow,
          $$RemainsEntriesTableFilterComposer,
          $$RemainsEntriesTableOrderingComposer,
          $$RemainsEntriesTableAnnotationComposer,
          $$RemainsEntriesTableCreateCompanionBuilder,
          $$RemainsEntriesTableUpdateCompanionBuilder,
          (
            RemainsRow,
            BaseReferences<_$SaveDatabase, $RemainsEntriesTable, RemainsRow>,
          ),
          RemainsRow,
          PrefetchHooks Function()
        > {
  $$RemainsEntriesTableTableManager(
    _$SaveDatabase db,
    $RemainsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemainsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemainsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemainsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> enemyId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<DateTime> diedAt = const Value.absent(),
                Value<bool> searched = const Value.absent(),
              }) => RemainsEntriesCompanion(
                id: id,
                profileId: profileId,
                enemyId: enemyId,
                kind: kind,
                latitude: latitude,
                longitude: longitude,
                diedAt: diedAt,
                searched: searched,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String enemyId,
                required String kind,
                required double latitude,
                required double longitude,
                required DateTime diedAt,
                Value<bool> searched = const Value.absent(),
              }) => RemainsEntriesCompanion.insert(
                id: id,
                profileId: profileId,
                enemyId: enemyId,
                kind: kind,
                latitude: latitude,
                longitude: longitude,
                diedAt: diedAt,
                searched: searched,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemainsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $RemainsEntriesTable,
      RemainsRow,
      $$RemainsEntriesTableFilterComposer,
      $$RemainsEntriesTableOrderingComposer,
      $$RemainsEntriesTableAnnotationComposer,
      $$RemainsEntriesTableCreateCompanionBuilder,
      $$RemainsEntriesTableUpdateCompanionBuilder,
      (
        RemainsRow,
        BaseReferences<_$SaveDatabase, $RemainsEntriesTable, RemainsRow>,
      ),
      RemainsRow,
      PrefetchHooks Function()
    >;

class $SaveDatabaseManager {
  final _$SaveDatabase _db;
  $SaveDatabaseManager(this._db);
  $$MetaEntriesTableTableManager get metaEntries =>
      $$MetaEntriesTableTableManager(_db, _db.metaEntries);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$VitalsTableTableManager get vitals =>
      $$VitalsTableTableManager(_db, _db.vitals);
  $$ChronicleEntriesTableTableManager get chronicleEntries =>
      $$ChronicleEntriesTableTableManager(_db, _db.chronicleEntries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$SnapshotRecordsTableTableManager get snapshotRecords =>
      $$SnapshotRecordsTableTableManager(_db, _db.snapshotRecords);
  $$InventoryLinesTableTableManager get inventoryLines =>
      $$InventoryLinesTableTableManager(_db, _db.inventoryLines);
  $$LootBoxesTableTableManager get lootBoxes =>
      $$LootBoxesTableTableManager(_db, _db.lootBoxes);
  $$GroundItemsTableTableManager get groundItems =>
      $$GroundItemsTableTableManager(_db, _db.groundItems);
  $$SheltersTableTableManager get shelters =>
      $$SheltersTableTableManager(_db, _db.shelters);
  $$RemainsEntriesTableTableManager get remainsEntries =>
      $$RemainsEntriesTableTableManager(_db, _db.remainsEntries);
}
