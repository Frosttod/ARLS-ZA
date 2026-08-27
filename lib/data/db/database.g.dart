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
  static const VerificationMeta _graceUntilMeta = const VerificationMeta(
    'graceUntil',
  );
  @override
  late final GeneratedColumn<DateTime> graceUntil = GeneratedColumn<DateTime>(
    'grace_until',
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
  static const VerificationMeta _dryStreakSecondsMeta = const VerificationMeta(
    'dryStreakSeconds',
  );
  @override
  late final GeneratedColumn<int> dryStreakSeconds = GeneratedColumn<int>(
    'dry_streak_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _starvedStreakSecondsMeta =
      const VerificationMeta('starvedStreakSeconds');
  @override
  late final GeneratedColumn<int> starvedStreakSeconds = GeneratedColumn<int>(
    'starved_streak_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bodyMassKgMeta = const VerificationMeta(
    'bodyMassKg',
  );
  @override
  late final GeneratedColumn<double> bodyMassKg = GeneratedColumn<double>(
    'body_mass_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sleepStrainMeta = const VerificationMeta(
    'sleepStrain',
  );
  @override
  late final GeneratedColumn<double> sleepStrain = GeneratedColumn<double>(
    'sleep_strain',
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
    graceUntil,
    huntUntil,
    huntLatitude,
    huntLongitude,
    huntCount,
    occupationJson,
    speedKmh,
    carriedKg,
    pendingKcal,
    pendingWaterMl,
    dryStreakSeconds,
    starvedStreakSeconds,
    bodyMassKg,
    sleepStrain,
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
    if (data.containsKey('grace_until')) {
      context.handle(
        _graceUntilMeta,
        graceUntil.isAcceptableOrUnknown(data['grace_until']!, _graceUntilMeta),
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
    if (data.containsKey('dry_streak_seconds')) {
      context.handle(
        _dryStreakSecondsMeta,
        dryStreakSeconds.isAcceptableOrUnknown(
          data['dry_streak_seconds']!,
          _dryStreakSecondsMeta,
        ),
      );
    }
    if (data.containsKey('starved_streak_seconds')) {
      context.handle(
        _starvedStreakSecondsMeta,
        starvedStreakSeconds.isAcceptableOrUnknown(
          data['starved_streak_seconds']!,
          _starvedStreakSecondsMeta,
        ),
      );
    }
    if (data.containsKey('body_mass_kg')) {
      context.handle(
        _bodyMassKgMeta,
        bodyMassKg.isAcceptableOrUnknown(
          data['body_mass_kg']!,
          _bodyMassKgMeta,
        ),
      );
    }
    if (data.containsKey('sleep_strain')) {
      context.handle(
        _sleepStrainMeta,
        sleepStrain.isAcceptableOrUnknown(
          data['sleep_strain']!,
          _sleepStrainMeta,
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
      graceUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}grace_until'],
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
      dryStreakSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dry_streak_seconds'],
      )!,
      starvedStreakSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starved_streak_seconds'],
      )!,
      bodyMassKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_mass_kg'],
      )!,
      sleepStrain: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sleep_strain'],
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

  /// §9.2: when they stop being taken for dead, or null once they are on
  /// their feet properly.
  ///
  /// ⚠️ Its own column, and not a flag in memory. Held in memory, "already
  /// woken" was forgotten every time the process died — so reopening the app
  /// ran the waking again, put the character back to a quarter of their blood
  /// and announced the caches a second time. A character cannot wake up twice
  /// from the same blackout.
  final DateTime? graceUntil;

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

  /// §2.3: seconds since any water at all reached the body.
  ///
  /// Feeds "brak wody > 48 h w warunkach wysiłku = śmierć". Reset by a
  /// swallow, not by a full reserve.
  final int dryStreakSeconds;

  /// §2.3: seconds the calorie reserve has been at nought.
  ///
  /// Feeds "0% przez > 24 h → postępująca utrata przytomności". Measured on
  /// the reserve rather than on the last meal, which is what that line says.
  final int starvedStreakSeconds;

  /// §2.3, §1.3: what the character weighs now, in kilograms.
  ///
  /// ⚠️ Defaults to nought, which is not a body — it is the marker for "this
  /// row predates a moving mass". The loader fills it from the profile's
  /// creation weight, because that is the only place that knows it (§11.1.4).
  final double bodyMassKg;

  /// §2.5.5: accumulated sleep shortfall, in whole nights.
  ///
  /// Nought is a rested character, which is the right reading for a row
  /// written before this existed: nobody was ever chronically short of sleep
  /// in a version that could not measure it (§11.1.4).
  final double sleepStrain;
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
    this.graceUntil,
    this.huntUntil,
    this.huntLatitude,
    this.huntLongitude,
    required this.huntCount,
    this.occupationJson,
    required this.speedKmh,
    required this.carriedKg,
    required this.pendingKcal,
    required this.pendingWaterMl,
    required this.dryStreakSeconds,
    required this.starvedStreakSeconds,
    required this.bodyMassKg,
    required this.sleepStrain,
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
    if (!nullToAbsent || graceUntil != null) {
      map['grace_until'] = Variable<DateTime>(graceUntil);
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
    map['dry_streak_seconds'] = Variable<int>(dryStreakSeconds);
    map['starved_streak_seconds'] = Variable<int>(starvedStreakSeconds);
    map['body_mass_kg'] = Variable<double>(bodyMassKg);
    map['sleep_strain'] = Variable<double>(sleepStrain);
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
      graceUntil: graceUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(graceUntil),
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
      dryStreakSeconds: Value(dryStreakSeconds),
      starvedStreakSeconds: Value(starvedStreakSeconds),
      bodyMassKg: Value(bodyMassKg),
      sleepStrain: Value(sleepStrain),
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
      graceUntil: serializer.fromJson<DateTime?>(json['graceUntil']),
      huntUntil: serializer.fromJson<DateTime?>(json['huntUntil']),
      huntLatitude: serializer.fromJson<double?>(json['huntLatitude']),
      huntLongitude: serializer.fromJson<double?>(json['huntLongitude']),
      huntCount: serializer.fromJson<int>(json['huntCount']),
      occupationJson: serializer.fromJson<String?>(json['occupationJson']),
      speedKmh: serializer.fromJson<double>(json['speedKmh']),
      carriedKg: serializer.fromJson<double>(json['carriedKg']),
      pendingKcal: serializer.fromJson<double>(json['pendingKcal']),
      pendingWaterMl: serializer.fromJson<double>(json['pendingWaterMl']),
      dryStreakSeconds: serializer.fromJson<int>(json['dryStreakSeconds']),
      starvedStreakSeconds: serializer.fromJson<int>(
        json['starvedStreakSeconds'],
      ),
      bodyMassKg: serializer.fromJson<double>(json['bodyMassKg']),
      sleepStrain: serializer.fromJson<double>(json['sleepStrain']),
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
      'graceUntil': serializer.toJson<DateTime?>(graceUntil),
      'huntUntil': serializer.toJson<DateTime?>(huntUntil),
      'huntLatitude': serializer.toJson<double?>(huntLatitude),
      'huntLongitude': serializer.toJson<double?>(huntLongitude),
      'huntCount': serializer.toJson<int>(huntCount),
      'occupationJson': serializer.toJson<String?>(occupationJson),
      'speedKmh': serializer.toJson<double>(speedKmh),
      'carriedKg': serializer.toJson<double>(carriedKg),
      'pendingKcal': serializer.toJson<double>(pendingKcal),
      'pendingWaterMl': serializer.toJson<double>(pendingWaterMl),
      'dryStreakSeconds': serializer.toJson<int>(dryStreakSeconds),
      'starvedStreakSeconds': serializer.toJson<int>(starvedStreakSeconds),
      'bodyMassKg': serializer.toJson<double>(bodyMassKg),
      'sleepStrain': serializer.toJson<double>(sleepStrain),
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
    Value<DateTime?> graceUntil = const Value.absent(),
    Value<DateTime?> huntUntil = const Value.absent(),
    Value<double?> huntLatitude = const Value.absent(),
    Value<double?> huntLongitude = const Value.absent(),
    int? huntCount,
    Value<String?> occupationJson = const Value.absent(),
    double? speedKmh,
    double? carriedKg,
    double? pendingKcal,
    double? pendingWaterMl,
    int? dryStreakSeconds,
    int? starvedStreakSeconds,
    double? bodyMassKg,
    double? sleepStrain,
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
    graceUntil: graceUntil.present ? graceUntil.value : this.graceUntil,
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
    dryStreakSeconds: dryStreakSeconds ?? this.dryStreakSeconds,
    starvedStreakSeconds: starvedStreakSeconds ?? this.starvedStreakSeconds,
    bodyMassKg: bodyMassKg ?? this.bodyMassKg,
    sleepStrain: sleepStrain ?? this.sleepStrain,
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
      graceUntil: data.graceUntil.present
          ? data.graceUntil.value
          : this.graceUntil,
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
      dryStreakSeconds: data.dryStreakSeconds.present
          ? data.dryStreakSeconds.value
          : this.dryStreakSeconds,
      starvedStreakSeconds: data.starvedStreakSeconds.present
          ? data.starvedStreakSeconds.value
          : this.starvedStreakSeconds,
      bodyMassKg: data.bodyMassKg.present
          ? data.bodyMassKg.value
          : this.bodyMassKg,
      sleepStrain: data.sleepStrain.present
          ? data.sleepStrain.value
          : this.sleepStrain,
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
          ..write('graceUntil: $graceUntil, ')
          ..write('huntUntil: $huntUntil, ')
          ..write('huntLatitude: $huntLatitude, ')
          ..write('huntLongitude: $huntLongitude, ')
          ..write('huntCount: $huntCount, ')
          ..write('occupationJson: $occupationJson, ')
          ..write('speedKmh: $speedKmh, ')
          ..write('carriedKg: $carriedKg, ')
          ..write('pendingKcal: $pendingKcal, ')
          ..write('pendingWaterMl: $pendingWaterMl, ')
          ..write('dryStreakSeconds: $dryStreakSeconds, ')
          ..write('starvedStreakSeconds: $starvedStreakSeconds, ')
          ..write('bodyMassKg: $bodyMassKg, ')
          ..write('sleepStrain: $sleepStrain')
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
    graceUntil,
    huntUntil,
    huntLatitude,
    huntLongitude,
    huntCount,
    occupationJson,
    speedKmh,
    carriedKg,
    pendingKcal,
    pendingWaterMl,
    dryStreakSeconds,
    starvedStreakSeconds,
    bodyMassKg,
    sleepStrain,
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
          other.graceUntil == this.graceUntil &&
          other.huntUntil == this.huntUntil &&
          other.huntLatitude == this.huntLatitude &&
          other.huntLongitude == this.huntLongitude &&
          other.huntCount == this.huntCount &&
          other.occupationJson == this.occupationJson &&
          other.speedKmh == this.speedKmh &&
          other.carriedKg == this.carriedKg &&
          other.pendingKcal == this.pendingKcal &&
          other.pendingWaterMl == this.pendingWaterMl &&
          other.dryStreakSeconds == this.dryStreakSeconds &&
          other.starvedStreakSeconds == this.starvedStreakSeconds &&
          other.bodyMassKg == this.bodyMassKg &&
          other.sleepStrain == this.sleepStrain);
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
  final Value<DateTime?> graceUntil;
  final Value<DateTime?> huntUntil;
  final Value<double?> huntLatitude;
  final Value<double?> huntLongitude;
  final Value<int> huntCount;
  final Value<String?> occupationJson;
  final Value<double> speedKmh;
  final Value<double> carriedKg;
  final Value<double> pendingKcal;
  final Value<double> pendingWaterMl;
  final Value<int> dryStreakSeconds;
  final Value<int> starvedStreakSeconds;
  final Value<double> bodyMassKg;
  final Value<double> sleepStrain;
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
    this.graceUntil = const Value.absent(),
    this.huntUntil = const Value.absent(),
    this.huntLatitude = const Value.absent(),
    this.huntLongitude = const Value.absent(),
    this.huntCount = const Value.absent(),
    this.occupationJson = const Value.absent(),
    this.speedKmh = const Value.absent(),
    this.carriedKg = const Value.absent(),
    this.pendingKcal = const Value.absent(),
    this.pendingWaterMl = const Value.absent(),
    this.dryStreakSeconds = const Value.absent(),
    this.starvedStreakSeconds = const Value.absent(),
    this.bodyMassKg = const Value.absent(),
    this.sleepStrain = const Value.absent(),
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
    this.graceUntil = const Value.absent(),
    this.huntUntil = const Value.absent(),
    this.huntLatitude = const Value.absent(),
    this.huntLongitude = const Value.absent(),
    this.huntCount = const Value.absent(),
    this.occupationJson = const Value.absent(),
    this.speedKmh = const Value.absent(),
    this.carriedKg = const Value.absent(),
    this.pendingKcal = const Value.absent(),
    this.pendingWaterMl = const Value.absent(),
    this.dryStreakSeconds = const Value.absent(),
    this.starvedStreakSeconds = const Value.absent(),
    this.bodyMassKg = const Value.absent(),
    this.sleepStrain = const Value.absent(),
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
    Expression<DateTime>? graceUntil,
    Expression<DateTime>? huntUntil,
    Expression<double>? huntLatitude,
    Expression<double>? huntLongitude,
    Expression<int>? huntCount,
    Expression<String>? occupationJson,
    Expression<double>? speedKmh,
    Expression<double>? carriedKg,
    Expression<double>? pendingKcal,
    Expression<double>? pendingWaterMl,
    Expression<int>? dryStreakSeconds,
    Expression<int>? starvedStreakSeconds,
    Expression<double>? bodyMassKg,
    Expression<double>? sleepStrain,
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
      if (graceUntil != null) 'grace_until': graceUntil,
      if (huntUntil != null) 'hunt_until': huntUntil,
      if (huntLatitude != null) 'hunt_latitude': huntLatitude,
      if (huntLongitude != null) 'hunt_longitude': huntLongitude,
      if (huntCount != null) 'hunt_count': huntCount,
      if (occupationJson != null) 'occupation_json': occupationJson,
      if (speedKmh != null) 'speed_kmh': speedKmh,
      if (carriedKg != null) 'carried_kg': carriedKg,
      if (pendingKcal != null) 'pending_kcal': pendingKcal,
      if (pendingWaterMl != null) 'pending_water_ml': pendingWaterMl,
      if (dryStreakSeconds != null) 'dry_streak_seconds': dryStreakSeconds,
      if (starvedStreakSeconds != null)
        'starved_streak_seconds': starvedStreakSeconds,
      if (bodyMassKg != null) 'body_mass_kg': bodyMassKg,
      if (sleepStrain != null) 'sleep_strain': sleepStrain,
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
    Value<DateTime?>? graceUntil,
    Value<DateTime?>? huntUntil,
    Value<double?>? huntLatitude,
    Value<double?>? huntLongitude,
    Value<int>? huntCount,
    Value<String?>? occupationJson,
    Value<double>? speedKmh,
    Value<double>? carriedKg,
    Value<double>? pendingKcal,
    Value<double>? pendingWaterMl,
    Value<int>? dryStreakSeconds,
    Value<int>? starvedStreakSeconds,
    Value<double>? bodyMassKg,
    Value<double>? sleepStrain,
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
      graceUntil: graceUntil ?? this.graceUntil,
      huntUntil: huntUntil ?? this.huntUntil,
      huntLatitude: huntLatitude ?? this.huntLatitude,
      huntLongitude: huntLongitude ?? this.huntLongitude,
      huntCount: huntCount ?? this.huntCount,
      occupationJson: occupationJson ?? this.occupationJson,
      speedKmh: speedKmh ?? this.speedKmh,
      carriedKg: carriedKg ?? this.carriedKg,
      pendingKcal: pendingKcal ?? this.pendingKcal,
      pendingWaterMl: pendingWaterMl ?? this.pendingWaterMl,
      dryStreakSeconds: dryStreakSeconds ?? this.dryStreakSeconds,
      starvedStreakSeconds: starvedStreakSeconds ?? this.starvedStreakSeconds,
      bodyMassKg: bodyMassKg ?? this.bodyMassKg,
      sleepStrain: sleepStrain ?? this.sleepStrain,
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
    if (graceUntil.present) {
      map['grace_until'] = Variable<DateTime>(graceUntil.value);
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
    if (dryStreakSeconds.present) {
      map['dry_streak_seconds'] = Variable<int>(dryStreakSeconds.value);
    }
    if (starvedStreakSeconds.present) {
      map['starved_streak_seconds'] = Variable<int>(starvedStreakSeconds.value);
    }
    if (bodyMassKg.present) {
      map['body_mass_kg'] = Variable<double>(bodyMassKg.value);
    }
    if (sleepStrain.present) {
      map['sleep_strain'] = Variable<double>(sleepStrain.value);
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
          ..write('graceUntil: $graceUntil, ')
          ..write('huntUntil: $huntUntil, ')
          ..write('huntLatitude: $huntLatitude, ')
          ..write('huntLongitude: $huntLongitude, ')
          ..write('huntCount: $huntCount, ')
          ..write('occupationJson: $occupationJson, ')
          ..write('speedKmh: $speedKmh, ')
          ..write('carriedKg: $carriedKg, ')
          ..write('pendingKcal: $pendingKcal, ')
          ..write('pendingWaterMl: $pendingWaterMl, ')
          ..write('dryStreakSeconds: $dryStreakSeconds, ')
          ..write('starvedStreakSeconds: $starvedStreakSeconds, ')
          ..write('bodyMassKg: $bodyMassKg, ')
          ..write('sleepStrain: $sleepStrain')
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
  static const VerificationMeta _roundsMeta = const VerificationMeta('rounds');
  @override
  late final GeneratedColumn<int> rounds = GeneratedColumn<int>(
    'rounds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salvageSecondsMeta = const VerificationMeta(
    'salvageSeconds',
  );
  @override
  late final GeneratedColumn<int> salvageSeconds = GeneratedColumn<int>(
    'salvage_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    rounds,
    salvageSeconds,
    uid,
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
    if (data.containsKey('rounds')) {
      context.handle(
        _roundsMeta,
        rounds.isAcceptableOrUnknown(data['rounds']!, _roundsMeta),
      );
    }
    if (data.containsKey('salvage_seconds')) {
      context.handle(
        _salvageSecondsMeta,
        salvageSeconds.isAcceptableOrUnknown(
          data['salvage_seconds']!,
          _salvageSecondsMeta,
        ),
      );
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
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
      rounds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounds'],
      ),
      salvageSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salvage_seconds'],
      ),
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      ),
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

  /// §5.3: how many rounds are in this piece.
  ///
  /// ⚠️ On the item because that is where they are. It was one integer in the
  /// interface — what is in the gun — and nothing wrote it down: reloading
  /// took thirty rounds out of the pack, put them in a field in memory, and
  /// closing the app destroyed them. A player lost a magazine every restart.
  ///
  /// Null for everything that cannot hold rounds, which is nearly everything.
  final int? rounds;

  /// §18.6: seconds of taking-apart already spent on this piece.
  ///
  /// Null for everything nobody has started on, which is nearly everything.
  /// Anything else means it has been opened up and no longer works.
  final int? salvageSeconds;

  /// Which piece this is, across a save (§11.1).
  ///
  /// ⚠️ Object identity does not survive a load, and every edit rebuilds the
  /// line anyway — so without this the only way to ask "is this the same
  /// rifle" was to ask "is this the same object", which is a different
  /// question that happens to agree until an await lands in between.
  ///
  /// Null on a row written before this existed; the loader gives it one.
  final String? uid;
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
    this.rounds,
    this.salvageSeconds,
    this.uid,
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
    if (!nullToAbsent || rounds != null) {
      map['rounds'] = Variable<int>(rounds);
    }
    if (!nullToAbsent || salvageSeconds != null) {
      map['salvage_seconds'] = Variable<int>(salvageSeconds);
    }
    if (!nullToAbsent || uid != null) {
      map['uid'] = Variable<String>(uid);
    }
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
      rounds: rounds == null && nullToAbsent
          ? const Value.absent()
          : Value(rounds),
      salvageSeconds: salvageSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(salvageSeconds),
      uid: uid == null && nullToAbsent ? const Value.absent() : Value(uid),
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
      rounds: serializer.fromJson<int?>(json['rounds']),
      salvageSeconds: serializer.fromJson<int?>(json['salvageSeconds']),
      uid: serializer.fromJson<String?>(json['uid']),
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
      'rounds': serializer.toJson<int?>(rounds),
      'salvageSeconds': serializer.toJson<int?>(salvageSeconds),
      'uid': serializer.toJson<String?>(uid),
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
    Value<int?> rounds = const Value.absent(),
    Value<int?> salvageSeconds = const Value.absent(),
    Value<String?> uid = const Value.absent(),
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
    rounds: rounds.present ? rounds.value : this.rounds,
    salvageSeconds: salvageSeconds.present
        ? salvageSeconds.value
        : this.salvageSeconds,
    uid: uid.present ? uid.value : this.uid,
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
      rounds: data.rounds.present ? data.rounds.value : this.rounds,
      salvageSeconds: data.salvageSeconds.present
          ? data.salvageSeconds.value
          : this.salvageSeconds,
      uid: data.uid.present ? data.uid.value : this.uid,
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
          ..write('attachments: $attachments, ')
          ..write('rounds: $rounds, ')
          ..write('salvageSeconds: $salvageSeconds, ')
          ..write('uid: $uid')
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
    rounds,
    salvageSeconds,
    uid,
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
          other.attachments == this.attachments &&
          other.rounds == this.rounds &&
          other.salvageSeconds == this.salvageSeconds &&
          other.uid == this.uid);
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
  final Value<int?> rounds;
  final Value<int?> salvageSeconds;
  final Value<String?> uid;
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
    this.rounds = const Value.absent(),
    this.salvageSeconds = const Value.absent(),
    this.uid = const Value.absent(),
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
    this.rounds = const Value.absent(),
    this.salvageSeconds = const Value.absent(),
    this.uid = const Value.absent(),
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
    Expression<int>? rounds,
    Expression<int>? salvageSeconds,
    Expression<String>? uid,
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
      if (rounds != null) 'rounds': rounds,
      if (salvageSeconds != null) 'salvage_seconds': salvageSeconds,
      if (uid != null) 'uid': uid,
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
    Value<int?>? rounds,
    Value<int?>? salvageSeconds,
    Value<String?>? uid,
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
      rounds: rounds ?? this.rounds,
      salvageSeconds: salvageSeconds ?? this.salvageSeconds,
      uid: uid ?? this.uid,
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
    if (rounds.present) {
      map['rounds'] = Variable<int>(rounds.value);
    }
    if (salvageSeconds.present) {
      map['salvage_seconds'] = Variable<int>(salvageSeconds.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
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
          ..write('attachments: $attachments, ')
          ..write('rounds: $rounds, ')
          ..write('salvageSeconds: $salvageSeconds, ')
          ..write('uid: $uid')
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
  static const VerificationMeta _roundsMeta = const VerificationMeta('rounds');
  @override
  late final GeneratedColumn<int> rounds = GeneratedColumn<int>(
    'rounds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _salvageSecondsMeta = const VerificationMeta(
    'salvageSeconds',
  );
  @override
  late final GeneratedColumn<int> salvageSeconds = GeneratedColumn<int>(
    'salvage_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    attachments,
    rounds,
    latitude,
    longitude,
    droppedAt,
    salvageSeconds,
    uid,
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
    if (data.containsKey('attachments')) {
      context.handle(
        _attachmentsMeta,
        attachments.isAcceptableOrUnknown(
          data['attachments']!,
          _attachmentsMeta,
        ),
      );
    }
    if (data.containsKey('rounds')) {
      context.handle(
        _roundsMeta,
        rounds.isAcceptableOrUnknown(data['rounds']!, _roundsMeta),
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
    if (data.containsKey('salvage_seconds')) {
      context.handle(
        _salvageSecondsMeta,
        salvageSeconds.isAcceptableOrUnknown(
          data['salvage_seconds']!,
          _salvageSecondsMeta,
        ),
      );
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
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
      attachments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments'],
      )!,
      rounds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounds'],
      ),
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
      salvageSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salvage_seconds'],
      ),
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      ),
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

  /// §5.6.3: and what was bolted to it. Same shape as the inventory's column,
  /// `att_red_dot,tool_suppressor`.
  ///
  /// ⚠️ Putting a rifle down used to strip it. The sights, the suppressor and
  /// the long magazine simply stopped existing — the rarest things in the game
  /// (§5.6.3), evaporating on the pavement because the row they were written
  /// to had nowhere to put them.
  final String attachments;

  /// §5.3: how many rounds are in this piece. A loaded rifle put down on the
  /// pavement is still loaded when it is picked up.
  final int? rounds;
  final double latitude;
  final double longitude;
  final DateTime droppedAt;

  /// §18.6: seconds of taking-apart already spent on this piece.
  ///
  /// Null for everything nobody has started on, which is nearly everything.
  /// Anything else means it has been opened up and no longer works.
  final int? salvageSeconds;

  /// Which piece this is, across a save (§11.1).
  ///
  /// ⚠️ Object identity does not survive a load, and every edit rebuilds the
  /// line anyway — so without this the only way to ask "is this the same
  /// rifle" was to ask "is this the same object", which is a different
  /// question that happens to agree until an await lands in between.
  ///
  /// Null on a row written before this existed; the loader gives it one.
  final String? uid;
  const GroundItem({
    required this.id,
    required this.profileId,
    required this.itemId,
    required this.count,
    this.condition,
    this.pagesTotal,
    required this.pagesRead,
    required this.attachments,
    this.rounds,
    required this.latitude,
    required this.longitude,
    required this.droppedAt,
    this.salvageSeconds,
    this.uid,
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
    map['attachments'] = Variable<String>(attachments);
    if (!nullToAbsent || rounds != null) {
      map['rounds'] = Variable<int>(rounds);
    }
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['dropped_at'] = Variable<DateTime>(droppedAt);
    if (!nullToAbsent || salvageSeconds != null) {
      map['salvage_seconds'] = Variable<int>(salvageSeconds);
    }
    if (!nullToAbsent || uid != null) {
      map['uid'] = Variable<String>(uid);
    }
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
      attachments: Value(attachments),
      rounds: rounds == null && nullToAbsent
          ? const Value.absent()
          : Value(rounds),
      latitude: Value(latitude),
      longitude: Value(longitude),
      droppedAt: Value(droppedAt),
      salvageSeconds: salvageSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(salvageSeconds),
      uid: uid == null && nullToAbsent ? const Value.absent() : Value(uid),
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
      attachments: serializer.fromJson<String>(json['attachments']),
      rounds: serializer.fromJson<int?>(json['rounds']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      droppedAt: serializer.fromJson<DateTime>(json['droppedAt']),
      salvageSeconds: serializer.fromJson<int?>(json['salvageSeconds']),
      uid: serializer.fromJson<String?>(json['uid']),
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
      'attachments': serializer.toJson<String>(attachments),
      'rounds': serializer.toJson<int?>(rounds),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'droppedAt': serializer.toJson<DateTime>(droppedAt),
      'salvageSeconds': serializer.toJson<int?>(salvageSeconds),
      'uid': serializer.toJson<String?>(uid),
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
    String? attachments,
    Value<int?> rounds = const Value.absent(),
    double? latitude,
    double? longitude,
    DateTime? droppedAt,
    Value<int?> salvageSeconds = const Value.absent(),
    Value<String?> uid = const Value.absent(),
  }) => GroundItem(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    itemId: itemId ?? this.itemId,
    count: count ?? this.count,
    condition: condition.present ? condition.value : this.condition,
    pagesTotal: pagesTotal.present ? pagesTotal.value : this.pagesTotal,
    pagesRead: pagesRead ?? this.pagesRead,
    attachments: attachments ?? this.attachments,
    rounds: rounds.present ? rounds.value : this.rounds,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    droppedAt: droppedAt ?? this.droppedAt,
    salvageSeconds: salvageSeconds.present
        ? salvageSeconds.value
        : this.salvageSeconds,
    uid: uid.present ? uid.value : this.uid,
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
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
      rounds: data.rounds.present ? data.rounds.value : this.rounds,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      droppedAt: data.droppedAt.present ? data.droppedAt.value : this.droppedAt,
      salvageSeconds: data.salvageSeconds.present
          ? data.salvageSeconds.value
          : this.salvageSeconds,
      uid: data.uid.present ? data.uid.value : this.uid,
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
          ..write('attachments: $attachments, ')
          ..write('rounds: $rounds, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('droppedAt: $droppedAt, ')
          ..write('salvageSeconds: $salvageSeconds, ')
          ..write('uid: $uid')
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
    attachments,
    rounds,
    latitude,
    longitude,
    droppedAt,
    salvageSeconds,
    uid,
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
          other.attachments == this.attachments &&
          other.rounds == this.rounds &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.droppedAt == this.droppedAt &&
          other.salvageSeconds == this.salvageSeconds &&
          other.uid == this.uid);
}

class GroundItemsCompanion extends UpdateCompanion<GroundItem> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> itemId;
  final Value<int> count;
  final Value<double?> condition;
  final Value<int?> pagesTotal;
  final Value<int> pagesRead;
  final Value<String> attachments;
  final Value<int?> rounds;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> droppedAt;
  final Value<int?> salvageSeconds;
  final Value<String?> uid;
  const GroundItemsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.count = const Value.absent(),
    this.condition = const Value.absent(),
    this.pagesTotal = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.attachments = const Value.absent(),
    this.rounds = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.droppedAt = const Value.absent(),
    this.salvageSeconds = const Value.absent(),
    this.uid = const Value.absent(),
  });
  GroundItemsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String itemId,
    this.count = const Value.absent(),
    this.condition = const Value.absent(),
    this.pagesTotal = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.attachments = const Value.absent(),
    this.rounds = const Value.absent(),
    required double latitude,
    required double longitude,
    required DateTime droppedAt,
    this.salvageSeconds = const Value.absent(),
    this.uid = const Value.absent(),
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
    Expression<String>? attachments,
    Expression<int>? rounds,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? droppedAt,
    Expression<int>? salvageSeconds,
    Expression<String>? uid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (itemId != null) 'item_id': itemId,
      if (count != null) 'count': count,
      if (condition != null) 'condition': condition,
      if (pagesTotal != null) 'pages_total': pagesTotal,
      if (pagesRead != null) 'pages_read': pagesRead,
      if (attachments != null) 'attachments': attachments,
      if (rounds != null) 'rounds': rounds,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (droppedAt != null) 'dropped_at': droppedAt,
      if (salvageSeconds != null) 'salvage_seconds': salvageSeconds,
      if (uid != null) 'uid': uid,
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
    Value<String>? attachments,
    Value<int?>? rounds,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<DateTime>? droppedAt,
    Value<int?>? salvageSeconds,
    Value<String?>? uid,
  }) {
    return GroundItemsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      itemId: itemId ?? this.itemId,
      count: count ?? this.count,
      condition: condition ?? this.condition,
      pagesTotal: pagesTotal ?? this.pagesTotal,
      pagesRead: pagesRead ?? this.pagesRead,
      attachments: attachments ?? this.attachments,
      rounds: rounds ?? this.rounds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      droppedAt: droppedAt ?? this.droppedAt,
      salvageSeconds: salvageSeconds ?? this.salvageSeconds,
      uid: uid ?? this.uid,
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
    if (attachments.present) {
      map['attachments'] = Variable<String>(attachments.value);
    }
    if (rounds.present) {
      map['rounds'] = Variable<int>(rounds.value);
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
    if (salvageSeconds.present) {
      map['salvage_seconds'] = Variable<int>(salvageSeconds.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
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
          ..write('attachments: $attachments, ')
          ..write('rounds: $rounds, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('droppedAt: $droppedAt, ')
          ..write('salvageSeconds: $salvageSeconds, ')
          ..write('uid: $uid')
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
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    paused,
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
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
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
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
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

  /// §2.1a, §8.3: whether the work here has been put down on purpose.
  ///
  /// ⚠️ **Not the same as not being on site.** Walking away already stops the
  /// clock (§2.1a.3) and starts it again on the way back, which is right. This
  /// is the player standing on their own site and saying *not now* — because a
  /// build in progress is an occupation (§2.1a) and blocks every other one, so
  /// without it the only way to search a house while a workshop was half up
  /// was to cancel the workshop.
  ///
  /// Nought is a save from before this existed, which is a save where nothing
  /// was ever put down (§11.1.4).
  final bool paused;
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
    required this.paused,
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
    map['paused'] = Variable<bool>(paused);
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
      paused: Value(paused),
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
      paused: serializer.fromJson<bool>(json['paused']),
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
      'paused': serializer.toJson<bool>(paused),
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
    bool? paused,
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
    paused: paused ?? this.paused,
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
      paused: data.paused.present ? data.paused.value : this.paused,
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
          ..write('buildingLeftSeconds: $buildingLeftSeconds, ')
          ..write('paused: $paused')
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
    paused,
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
          other.buildingLeftSeconds == this.buildingLeftSeconds &&
          other.paused == this.paused);
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
  final Value<bool> paused;
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
    this.paused = const Value.absent(),
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
    this.paused = const Value.absent(),
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
    Expression<bool>? paused,
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
      if (paused != null) 'paused': paused,
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
    Value<bool>? paused,
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
      paused: paused ?? this.paused,
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
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
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
          ..write('buildingLeftSeconds: $buildingLeftSeconds, ')
          ..write('paused: $paused')
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

class $ProfileStatsTable extends ProfileStats
    with TableInfo<$ProfileStatsTable, StatsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileStatsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _shotsFiredMeta = const VerificationMeta(
    'shotsFired',
  );
  @override
  late final GeneratedColumn<int> shotsFired = GeneratedColumn<int>(
    'shots_fired',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _shotsHitMeta = const VerificationMeta(
    'shotsHit',
  );
  @override
  late final GeneratedColumn<int> shotsHit = GeneratedColumn<int>(
    'shots_hit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _swingsMeta = const VerificationMeta('swings');
  @override
  late final GeneratedColumn<int> swings = GeneratedColumn<int>(
    'swings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _swingsHitMeta = const VerificationMeta(
    'swingsHit',
  );
  @override
  late final GeneratedColumn<int> swingsHit = GeneratedColumn<int>(
    'swings_hit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hitsHeadMeta = const VerificationMeta(
    'hitsHead',
  );
  @override
  late final GeneratedColumn<int> hitsHead = GeneratedColumn<int>(
    'hits_head',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hitsTorsoMeta = const VerificationMeta(
    'hitsTorso',
  );
  @override
  late final GeneratedColumn<int> hitsTorso = GeneratedColumn<int>(
    'hits_torso',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hitsArmsMeta = const VerificationMeta(
    'hitsArms',
  );
  @override
  late final GeneratedColumn<int> hitsArms = GeneratedColumn<int>(
    'hits_arms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hitsLegsMeta = const VerificationMeta(
    'hitsLegs',
  );
  @override
  late final GeneratedColumn<int> hitsLegs = GeneratedColumn<int>(
    'hits_legs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _killsMeta = const VerificationMeta('kills');
  @override
  late final GeneratedColumn<int> kills = GeneratedColumn<int>(
    'kills',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bloodDealtMlMeta = const VerificationMeta(
    'bloodDealtMl',
  );
  @override
  late final GeneratedColumn<double> bloodDealtMl = GeneratedColumn<double>(
    'blood_dealt_ml',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bloodLostMlMeta = const VerificationMeta(
    'bloodLostMl',
  );
  @override
  late final GeneratedColumn<double> bloodLostMl = GeneratedColumn<double>(
    'blood_lost_ml',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _searchesMeta = const VerificationMeta(
    'searches',
  );
  @override
  late final GeneratedColumn<int> searches = GeneratedColumn<int>(
    'searches',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _blackoutsMeta = const VerificationMeta(
    'blackouts',
  );
  @override
  late final GeneratedColumn<int> blackouts = GeneratedColumn<int>(
    'blackouts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    shotsFired,
    shotsHit,
    swings,
    swingsHit,
    hitsHead,
    hitsTorso,
    hitsArms,
    hitsLegs,
    kills,
    bloodDealtMl,
    bloodLostMl,
    searches,
    blackouts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<StatsRow> instance, {
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
    if (data.containsKey('shots_fired')) {
      context.handle(
        _shotsFiredMeta,
        shotsFired.isAcceptableOrUnknown(data['shots_fired']!, _shotsFiredMeta),
      );
    }
    if (data.containsKey('shots_hit')) {
      context.handle(
        _shotsHitMeta,
        shotsHit.isAcceptableOrUnknown(data['shots_hit']!, _shotsHitMeta),
      );
    }
    if (data.containsKey('swings')) {
      context.handle(
        _swingsMeta,
        swings.isAcceptableOrUnknown(data['swings']!, _swingsMeta),
      );
    }
    if (data.containsKey('swings_hit')) {
      context.handle(
        _swingsHitMeta,
        swingsHit.isAcceptableOrUnknown(data['swings_hit']!, _swingsHitMeta),
      );
    }
    if (data.containsKey('hits_head')) {
      context.handle(
        _hitsHeadMeta,
        hitsHead.isAcceptableOrUnknown(data['hits_head']!, _hitsHeadMeta),
      );
    }
    if (data.containsKey('hits_torso')) {
      context.handle(
        _hitsTorsoMeta,
        hitsTorso.isAcceptableOrUnknown(data['hits_torso']!, _hitsTorsoMeta),
      );
    }
    if (data.containsKey('hits_arms')) {
      context.handle(
        _hitsArmsMeta,
        hitsArms.isAcceptableOrUnknown(data['hits_arms']!, _hitsArmsMeta),
      );
    }
    if (data.containsKey('hits_legs')) {
      context.handle(
        _hitsLegsMeta,
        hitsLegs.isAcceptableOrUnknown(data['hits_legs']!, _hitsLegsMeta),
      );
    }
    if (data.containsKey('kills')) {
      context.handle(
        _killsMeta,
        kills.isAcceptableOrUnknown(data['kills']!, _killsMeta),
      );
    }
    if (data.containsKey('blood_dealt_ml')) {
      context.handle(
        _bloodDealtMlMeta,
        bloodDealtMl.isAcceptableOrUnknown(
          data['blood_dealt_ml']!,
          _bloodDealtMlMeta,
        ),
      );
    }
    if (data.containsKey('blood_lost_ml')) {
      context.handle(
        _bloodLostMlMeta,
        bloodLostMl.isAcceptableOrUnknown(
          data['blood_lost_ml']!,
          _bloodLostMlMeta,
        ),
      );
    }
    if (data.containsKey('searches')) {
      context.handle(
        _searchesMeta,
        searches.isAcceptableOrUnknown(data['searches']!, _searchesMeta),
      );
    }
    if (data.containsKey('blackouts')) {
      context.handle(
        _blackoutsMeta,
        blackouts.isAcceptableOrUnknown(data['blackouts']!, _blackoutsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  StatsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatsRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      shotsFired: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shots_fired'],
      )!,
      shotsHit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shots_hit'],
      )!,
      swings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}swings'],
      )!,
      swingsHit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}swings_hit'],
      )!,
      hitsHead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits_head'],
      )!,
      hitsTorso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits_torso'],
      )!,
      hitsArms: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits_arms'],
      )!,
      hitsLegs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits_legs'],
      )!,
      kills: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kills'],
      )!,
      bloodDealtMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}blood_dealt_ml'],
      )!,
      bloodLostMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}blood_lost_ml'],
      )!,
      searches: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}searches'],
      )!,
      blackouts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blackouts'],
      )!,
    );
  }

  @override
  $ProfileStatsTable createAlias(String alias) {
    return $ProfileStatsTable(attachedDatabase, alias);
  }
}

class StatsRow extends DataClass implements Insertable<StatsRow> {
  final int profileId;

  /// §5.1: every trigger pull, and how many of them landed.
  final int shotsFired;
  final int shotsHit;

  /// §5.4: the same for anything swung.
  final int swings;
  final int swingsHit;

  /// §2.6: where the ones that landed landed.
  final int hitsHead;
  final int hitsTorso;
  final int hitsArms;
  final int hitsLegs;

  /// §6.2: how many went down, and how much blood it took to do it.
  final int kills;
  final double bloodDealtMl;

  /// §2.6: and how much of the player's own went the other way.
  final double bloodLostMl;

  /// §10.2: places turned over, and §9.2's blackouts.
  final int searches;
  final int blackouts;
  const StatsRow({
    required this.profileId,
    required this.shotsFired,
    required this.shotsHit,
    required this.swings,
    required this.swingsHit,
    required this.hitsHead,
    required this.hitsTorso,
    required this.hitsArms,
    required this.hitsLegs,
    required this.kills,
    required this.bloodDealtMl,
    required this.bloodLostMl,
    required this.searches,
    required this.blackouts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['shots_fired'] = Variable<int>(shotsFired);
    map['shots_hit'] = Variable<int>(shotsHit);
    map['swings'] = Variable<int>(swings);
    map['swings_hit'] = Variable<int>(swingsHit);
    map['hits_head'] = Variable<int>(hitsHead);
    map['hits_torso'] = Variable<int>(hitsTorso);
    map['hits_arms'] = Variable<int>(hitsArms);
    map['hits_legs'] = Variable<int>(hitsLegs);
    map['kills'] = Variable<int>(kills);
    map['blood_dealt_ml'] = Variable<double>(bloodDealtMl);
    map['blood_lost_ml'] = Variable<double>(bloodLostMl);
    map['searches'] = Variable<int>(searches);
    map['blackouts'] = Variable<int>(blackouts);
    return map;
  }

  ProfileStatsCompanion toCompanion(bool nullToAbsent) {
    return ProfileStatsCompanion(
      profileId: Value(profileId),
      shotsFired: Value(shotsFired),
      shotsHit: Value(shotsHit),
      swings: Value(swings),
      swingsHit: Value(swingsHit),
      hitsHead: Value(hitsHead),
      hitsTorso: Value(hitsTorso),
      hitsArms: Value(hitsArms),
      hitsLegs: Value(hitsLegs),
      kills: Value(kills),
      bloodDealtMl: Value(bloodDealtMl),
      bloodLostMl: Value(bloodLostMl),
      searches: Value(searches),
      blackouts: Value(blackouts),
    );
  }

  factory StatsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatsRow(
      profileId: serializer.fromJson<int>(json['profileId']),
      shotsFired: serializer.fromJson<int>(json['shotsFired']),
      shotsHit: serializer.fromJson<int>(json['shotsHit']),
      swings: serializer.fromJson<int>(json['swings']),
      swingsHit: serializer.fromJson<int>(json['swingsHit']),
      hitsHead: serializer.fromJson<int>(json['hitsHead']),
      hitsTorso: serializer.fromJson<int>(json['hitsTorso']),
      hitsArms: serializer.fromJson<int>(json['hitsArms']),
      hitsLegs: serializer.fromJson<int>(json['hitsLegs']),
      kills: serializer.fromJson<int>(json['kills']),
      bloodDealtMl: serializer.fromJson<double>(json['bloodDealtMl']),
      bloodLostMl: serializer.fromJson<double>(json['bloodLostMl']),
      searches: serializer.fromJson<int>(json['searches']),
      blackouts: serializer.fromJson<int>(json['blackouts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'shotsFired': serializer.toJson<int>(shotsFired),
      'shotsHit': serializer.toJson<int>(shotsHit),
      'swings': serializer.toJson<int>(swings),
      'swingsHit': serializer.toJson<int>(swingsHit),
      'hitsHead': serializer.toJson<int>(hitsHead),
      'hitsTorso': serializer.toJson<int>(hitsTorso),
      'hitsArms': serializer.toJson<int>(hitsArms),
      'hitsLegs': serializer.toJson<int>(hitsLegs),
      'kills': serializer.toJson<int>(kills),
      'bloodDealtMl': serializer.toJson<double>(bloodDealtMl),
      'bloodLostMl': serializer.toJson<double>(bloodLostMl),
      'searches': serializer.toJson<int>(searches),
      'blackouts': serializer.toJson<int>(blackouts),
    };
  }

  StatsRow copyWith({
    int? profileId,
    int? shotsFired,
    int? shotsHit,
    int? swings,
    int? swingsHit,
    int? hitsHead,
    int? hitsTorso,
    int? hitsArms,
    int? hitsLegs,
    int? kills,
    double? bloodDealtMl,
    double? bloodLostMl,
    int? searches,
    int? blackouts,
  }) => StatsRow(
    profileId: profileId ?? this.profileId,
    shotsFired: shotsFired ?? this.shotsFired,
    shotsHit: shotsHit ?? this.shotsHit,
    swings: swings ?? this.swings,
    swingsHit: swingsHit ?? this.swingsHit,
    hitsHead: hitsHead ?? this.hitsHead,
    hitsTorso: hitsTorso ?? this.hitsTorso,
    hitsArms: hitsArms ?? this.hitsArms,
    hitsLegs: hitsLegs ?? this.hitsLegs,
    kills: kills ?? this.kills,
    bloodDealtMl: bloodDealtMl ?? this.bloodDealtMl,
    bloodLostMl: bloodLostMl ?? this.bloodLostMl,
    searches: searches ?? this.searches,
    blackouts: blackouts ?? this.blackouts,
  );
  StatsRow copyWithCompanion(ProfileStatsCompanion data) {
    return StatsRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      shotsFired: data.shotsFired.present
          ? data.shotsFired.value
          : this.shotsFired,
      shotsHit: data.shotsHit.present ? data.shotsHit.value : this.shotsHit,
      swings: data.swings.present ? data.swings.value : this.swings,
      swingsHit: data.swingsHit.present ? data.swingsHit.value : this.swingsHit,
      hitsHead: data.hitsHead.present ? data.hitsHead.value : this.hitsHead,
      hitsTorso: data.hitsTorso.present ? data.hitsTorso.value : this.hitsTorso,
      hitsArms: data.hitsArms.present ? data.hitsArms.value : this.hitsArms,
      hitsLegs: data.hitsLegs.present ? data.hitsLegs.value : this.hitsLegs,
      kills: data.kills.present ? data.kills.value : this.kills,
      bloodDealtMl: data.bloodDealtMl.present
          ? data.bloodDealtMl.value
          : this.bloodDealtMl,
      bloodLostMl: data.bloodLostMl.present
          ? data.bloodLostMl.value
          : this.bloodLostMl,
      searches: data.searches.present ? data.searches.value : this.searches,
      blackouts: data.blackouts.present ? data.blackouts.value : this.blackouts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatsRow(')
          ..write('profileId: $profileId, ')
          ..write('shotsFired: $shotsFired, ')
          ..write('shotsHit: $shotsHit, ')
          ..write('swings: $swings, ')
          ..write('swingsHit: $swingsHit, ')
          ..write('hitsHead: $hitsHead, ')
          ..write('hitsTorso: $hitsTorso, ')
          ..write('hitsArms: $hitsArms, ')
          ..write('hitsLegs: $hitsLegs, ')
          ..write('kills: $kills, ')
          ..write('bloodDealtMl: $bloodDealtMl, ')
          ..write('bloodLostMl: $bloodLostMl, ')
          ..write('searches: $searches, ')
          ..write('blackouts: $blackouts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    profileId,
    shotsFired,
    shotsHit,
    swings,
    swingsHit,
    hitsHead,
    hitsTorso,
    hitsArms,
    hitsLegs,
    kills,
    bloodDealtMl,
    bloodLostMl,
    searches,
    blackouts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatsRow &&
          other.profileId == this.profileId &&
          other.shotsFired == this.shotsFired &&
          other.shotsHit == this.shotsHit &&
          other.swings == this.swings &&
          other.swingsHit == this.swingsHit &&
          other.hitsHead == this.hitsHead &&
          other.hitsTorso == this.hitsTorso &&
          other.hitsArms == this.hitsArms &&
          other.hitsLegs == this.hitsLegs &&
          other.kills == this.kills &&
          other.bloodDealtMl == this.bloodDealtMl &&
          other.bloodLostMl == this.bloodLostMl &&
          other.searches == this.searches &&
          other.blackouts == this.blackouts);
}

class ProfileStatsCompanion extends UpdateCompanion<StatsRow> {
  final Value<int> profileId;
  final Value<int> shotsFired;
  final Value<int> shotsHit;
  final Value<int> swings;
  final Value<int> swingsHit;
  final Value<int> hitsHead;
  final Value<int> hitsTorso;
  final Value<int> hitsArms;
  final Value<int> hitsLegs;
  final Value<int> kills;
  final Value<double> bloodDealtMl;
  final Value<double> bloodLostMl;
  final Value<int> searches;
  final Value<int> blackouts;
  const ProfileStatsCompanion({
    this.profileId = const Value.absent(),
    this.shotsFired = const Value.absent(),
    this.shotsHit = const Value.absent(),
    this.swings = const Value.absent(),
    this.swingsHit = const Value.absent(),
    this.hitsHead = const Value.absent(),
    this.hitsTorso = const Value.absent(),
    this.hitsArms = const Value.absent(),
    this.hitsLegs = const Value.absent(),
    this.kills = const Value.absent(),
    this.bloodDealtMl = const Value.absent(),
    this.bloodLostMl = const Value.absent(),
    this.searches = const Value.absent(),
    this.blackouts = const Value.absent(),
  });
  ProfileStatsCompanion.insert({
    this.profileId = const Value.absent(),
    this.shotsFired = const Value.absent(),
    this.shotsHit = const Value.absent(),
    this.swings = const Value.absent(),
    this.swingsHit = const Value.absent(),
    this.hitsHead = const Value.absent(),
    this.hitsTorso = const Value.absent(),
    this.hitsArms = const Value.absent(),
    this.hitsLegs = const Value.absent(),
    this.kills = const Value.absent(),
    this.bloodDealtMl = const Value.absent(),
    this.bloodLostMl = const Value.absent(),
    this.searches = const Value.absent(),
    this.blackouts = const Value.absent(),
  });
  static Insertable<StatsRow> custom({
    Expression<int>? profileId,
    Expression<int>? shotsFired,
    Expression<int>? shotsHit,
    Expression<int>? swings,
    Expression<int>? swingsHit,
    Expression<int>? hitsHead,
    Expression<int>? hitsTorso,
    Expression<int>? hitsArms,
    Expression<int>? hitsLegs,
    Expression<int>? kills,
    Expression<double>? bloodDealtMl,
    Expression<double>? bloodLostMl,
    Expression<int>? searches,
    Expression<int>? blackouts,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (shotsFired != null) 'shots_fired': shotsFired,
      if (shotsHit != null) 'shots_hit': shotsHit,
      if (swings != null) 'swings': swings,
      if (swingsHit != null) 'swings_hit': swingsHit,
      if (hitsHead != null) 'hits_head': hitsHead,
      if (hitsTorso != null) 'hits_torso': hitsTorso,
      if (hitsArms != null) 'hits_arms': hitsArms,
      if (hitsLegs != null) 'hits_legs': hitsLegs,
      if (kills != null) 'kills': kills,
      if (bloodDealtMl != null) 'blood_dealt_ml': bloodDealtMl,
      if (bloodLostMl != null) 'blood_lost_ml': bloodLostMl,
      if (searches != null) 'searches': searches,
      if (blackouts != null) 'blackouts': blackouts,
    });
  }

  ProfileStatsCompanion copyWith({
    Value<int>? profileId,
    Value<int>? shotsFired,
    Value<int>? shotsHit,
    Value<int>? swings,
    Value<int>? swingsHit,
    Value<int>? hitsHead,
    Value<int>? hitsTorso,
    Value<int>? hitsArms,
    Value<int>? hitsLegs,
    Value<int>? kills,
    Value<double>? bloodDealtMl,
    Value<double>? bloodLostMl,
    Value<int>? searches,
    Value<int>? blackouts,
  }) {
    return ProfileStatsCompanion(
      profileId: profileId ?? this.profileId,
      shotsFired: shotsFired ?? this.shotsFired,
      shotsHit: shotsHit ?? this.shotsHit,
      swings: swings ?? this.swings,
      swingsHit: swingsHit ?? this.swingsHit,
      hitsHead: hitsHead ?? this.hitsHead,
      hitsTorso: hitsTorso ?? this.hitsTorso,
      hitsArms: hitsArms ?? this.hitsArms,
      hitsLegs: hitsLegs ?? this.hitsLegs,
      kills: kills ?? this.kills,
      bloodDealtMl: bloodDealtMl ?? this.bloodDealtMl,
      bloodLostMl: bloodLostMl ?? this.bloodLostMl,
      searches: searches ?? this.searches,
      blackouts: blackouts ?? this.blackouts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (shotsFired.present) {
      map['shots_fired'] = Variable<int>(shotsFired.value);
    }
    if (shotsHit.present) {
      map['shots_hit'] = Variable<int>(shotsHit.value);
    }
    if (swings.present) {
      map['swings'] = Variable<int>(swings.value);
    }
    if (swingsHit.present) {
      map['swings_hit'] = Variable<int>(swingsHit.value);
    }
    if (hitsHead.present) {
      map['hits_head'] = Variable<int>(hitsHead.value);
    }
    if (hitsTorso.present) {
      map['hits_torso'] = Variable<int>(hitsTorso.value);
    }
    if (hitsArms.present) {
      map['hits_arms'] = Variable<int>(hitsArms.value);
    }
    if (hitsLegs.present) {
      map['hits_legs'] = Variable<int>(hitsLegs.value);
    }
    if (kills.present) {
      map['kills'] = Variable<int>(kills.value);
    }
    if (bloodDealtMl.present) {
      map['blood_dealt_ml'] = Variable<double>(bloodDealtMl.value);
    }
    if (bloodLostMl.present) {
      map['blood_lost_ml'] = Variable<double>(bloodLostMl.value);
    }
    if (searches.present) {
      map['searches'] = Variable<int>(searches.value);
    }
    if (blackouts.present) {
      map['blackouts'] = Variable<int>(blackouts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileStatsCompanion(')
          ..write('profileId: $profileId, ')
          ..write('shotsFired: $shotsFired, ')
          ..write('shotsHit: $shotsHit, ')
          ..write('swings: $swings, ')
          ..write('swingsHit: $swingsHit, ')
          ..write('hitsHead: $hitsHead, ')
          ..write('hitsTorso: $hitsTorso, ')
          ..write('hitsArms: $hitsArms, ')
          ..write('hitsLegs: $hitsLegs, ')
          ..write('kills: $kills, ')
          ..write('bloodDealtMl: $bloodDealtMl, ')
          ..write('bloodLostMl: $bloodLostMl, ')
          ..write('searches: $searches, ')
          ..write('blackouts: $blackouts')
          ..write(')'))
        .toString();
  }
}

class $ShelterItemsTable extends ShelterItems
    with TableInfo<$ShelterItemsTable, StashRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShelterItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _shelterIdMeta = const VerificationMeta(
    'shelterId',
  );
  @override
  late final GeneratedColumn<int> shelterId = GeneratedColumn<int>(
    'shelter_id',
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
  static const VerificationMeta _roundsMeta = const VerificationMeta('rounds');
  @override
  late final GeneratedColumn<int> rounds = GeneratedColumn<int>(
    'rounds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salvageSecondsMeta = const VerificationMeta(
    'salvageSeconds',
  );
  @override
  late final GeneratedColumn<int> salvageSeconds = GeneratedColumn<int>(
    'salvage_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    shelterId,
    itemId,
    count,
    condition,
    pagesTotal,
    pagesRead,
    noteId,
    portion,
    attachments,
    rounds,
    salvageSeconds,
    uid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelter_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<StashRow> instance, {
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
    if (data.containsKey('shelter_id')) {
      context.handle(
        _shelterIdMeta,
        shelterId.isAcceptableOrUnknown(data['shelter_id']!, _shelterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shelterIdMeta);
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
    if (data.containsKey('rounds')) {
      context.handle(
        _roundsMeta,
        rounds.isAcceptableOrUnknown(data['rounds']!, _roundsMeta),
      );
    }
    if (data.containsKey('salvage_seconds')) {
      context.handle(
        _salvageSecondsMeta,
        salvageSeconds.isAcceptableOrUnknown(
          data['salvage_seconds']!,
          _salvageSecondsMeta,
        ),
      );
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StashRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StashRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      shelterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shelter_id'],
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
      rounds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounds'],
      ),
      salvageSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salvage_seconds'],
      ),
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      ),
    );
  }

  @override
  $ShelterItemsTable createAlias(String alias) {
    return $ShelterItemsTable(attachedDatabase, alias);
  }
}

class StashRow extends DataClass implements Insertable<StashRow> {
  final int id;
  final int profileId;
  final int shelterId;

  /// Catalogue id (§4.1). Not a foreign key, for the reason in
  /// [InventoryLines]: the catalogue is data files, not tables.
  final String itemId;
  final int count;
  final double? condition;
  final int? pagesTotal;
  final int pagesRead;
  final String? noteId;
  final double portion;
  final String attachments;

  /// §5.3: how many rounds are in this piece.
  ///
  /// ⚠️ On the item because that is where they are. It was one integer in the
  /// interface — what is in the gun — and nothing wrote it down: reloading
  /// took thirty rounds out of the pack, put them in a field in memory, and
  /// closing the app destroyed them. A player lost a magazine every restart.
  ///
  /// Null for everything that cannot hold rounds, which is nearly everything.
  final int? rounds;

  /// §18.6: seconds of taking-apart already spent on this piece.
  ///
  /// Null for everything nobody has started on, which is nearly everything.
  /// Anything else means it has been opened up and no longer works.
  final int? salvageSeconds;

  /// Which piece this is, across a save (§11.1).
  ///
  /// ⚠️ Object identity does not survive a load, and every edit rebuilds the
  /// line anyway — so without this the only way to ask "is this the same
  /// rifle" was to ask "is this the same object", which is a different
  /// question that happens to agree until an await lands in between.
  ///
  /// Null on a row written before this existed; the loader gives it one.
  final String? uid;
  const StashRow({
    required this.id,
    required this.profileId,
    required this.shelterId,
    required this.itemId,
    required this.count,
    this.condition,
    this.pagesTotal,
    required this.pagesRead,
    this.noteId,
    required this.portion,
    required this.attachments,
    this.rounds,
    this.salvageSeconds,
    this.uid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['shelter_id'] = Variable<int>(shelterId);
    map['item_id'] = Variable<String>(itemId);
    map['count'] = Variable<int>(count);
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
    if (!nullToAbsent || rounds != null) {
      map['rounds'] = Variable<int>(rounds);
    }
    if (!nullToAbsent || salvageSeconds != null) {
      map['salvage_seconds'] = Variable<int>(salvageSeconds);
    }
    if (!nullToAbsent || uid != null) {
      map['uid'] = Variable<String>(uid);
    }
    return map;
  }

  ShelterItemsCompanion toCompanion(bool nullToAbsent) {
    return ShelterItemsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      shelterId: Value(shelterId),
      itemId: Value(itemId),
      count: Value(count),
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
      rounds: rounds == null && nullToAbsent
          ? const Value.absent()
          : Value(rounds),
      salvageSeconds: salvageSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(salvageSeconds),
      uid: uid == null && nullToAbsent ? const Value.absent() : Value(uid),
    );
  }

  factory StashRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StashRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      shelterId: serializer.fromJson<int>(json['shelterId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      count: serializer.fromJson<int>(json['count']),
      condition: serializer.fromJson<double?>(json['condition']),
      pagesTotal: serializer.fromJson<int?>(json['pagesTotal']),
      pagesRead: serializer.fromJson<int>(json['pagesRead']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      portion: serializer.fromJson<double>(json['portion']),
      attachments: serializer.fromJson<String>(json['attachments']),
      rounds: serializer.fromJson<int?>(json['rounds']),
      salvageSeconds: serializer.fromJson<int?>(json['salvageSeconds']),
      uid: serializer.fromJson<String?>(json['uid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'shelterId': serializer.toJson<int>(shelterId),
      'itemId': serializer.toJson<String>(itemId),
      'count': serializer.toJson<int>(count),
      'condition': serializer.toJson<double?>(condition),
      'pagesTotal': serializer.toJson<int?>(pagesTotal),
      'pagesRead': serializer.toJson<int>(pagesRead),
      'noteId': serializer.toJson<String?>(noteId),
      'portion': serializer.toJson<double>(portion),
      'attachments': serializer.toJson<String>(attachments),
      'rounds': serializer.toJson<int?>(rounds),
      'salvageSeconds': serializer.toJson<int?>(salvageSeconds),
      'uid': serializer.toJson<String?>(uid),
    };
  }

  StashRow copyWith({
    int? id,
    int? profileId,
    int? shelterId,
    String? itemId,
    int? count,
    Value<double?> condition = const Value.absent(),
    Value<int?> pagesTotal = const Value.absent(),
    int? pagesRead,
    Value<String?> noteId = const Value.absent(),
    double? portion,
    String? attachments,
    Value<int?> rounds = const Value.absent(),
    Value<int?> salvageSeconds = const Value.absent(),
    Value<String?> uid = const Value.absent(),
  }) => StashRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    shelterId: shelterId ?? this.shelterId,
    itemId: itemId ?? this.itemId,
    count: count ?? this.count,
    condition: condition.present ? condition.value : this.condition,
    pagesTotal: pagesTotal.present ? pagesTotal.value : this.pagesTotal,
    pagesRead: pagesRead ?? this.pagesRead,
    noteId: noteId.present ? noteId.value : this.noteId,
    portion: portion ?? this.portion,
    attachments: attachments ?? this.attachments,
    rounds: rounds.present ? rounds.value : this.rounds,
    salvageSeconds: salvageSeconds.present
        ? salvageSeconds.value
        : this.salvageSeconds,
    uid: uid.present ? uid.value : this.uid,
  );
  StashRow copyWithCompanion(ShelterItemsCompanion data) {
    return StashRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      shelterId: data.shelterId.present ? data.shelterId.value : this.shelterId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      count: data.count.present ? data.count.value : this.count,
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
      rounds: data.rounds.present ? data.rounds.value : this.rounds,
      salvageSeconds: data.salvageSeconds.present
          ? data.salvageSeconds.value
          : this.salvageSeconds,
      uid: data.uid.present ? data.uid.value : this.uid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StashRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('shelterId: $shelterId, ')
          ..write('itemId: $itemId, ')
          ..write('count: $count, ')
          ..write('condition: $condition, ')
          ..write('pagesTotal: $pagesTotal, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('noteId: $noteId, ')
          ..write('portion: $portion, ')
          ..write('attachments: $attachments, ')
          ..write('rounds: $rounds, ')
          ..write('salvageSeconds: $salvageSeconds, ')
          ..write('uid: $uid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    shelterId,
    itemId,
    count,
    condition,
    pagesTotal,
    pagesRead,
    noteId,
    portion,
    attachments,
    rounds,
    salvageSeconds,
    uid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StashRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.shelterId == this.shelterId &&
          other.itemId == this.itemId &&
          other.count == this.count &&
          other.condition == this.condition &&
          other.pagesTotal == this.pagesTotal &&
          other.pagesRead == this.pagesRead &&
          other.noteId == this.noteId &&
          other.portion == this.portion &&
          other.attachments == this.attachments &&
          other.rounds == this.rounds &&
          other.salvageSeconds == this.salvageSeconds &&
          other.uid == this.uid);
}

class ShelterItemsCompanion extends UpdateCompanion<StashRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<int> shelterId;
  final Value<String> itemId;
  final Value<int> count;
  final Value<double?> condition;
  final Value<int?> pagesTotal;
  final Value<int> pagesRead;
  final Value<String?> noteId;
  final Value<double> portion;
  final Value<String> attachments;
  final Value<int?> rounds;
  final Value<int?> salvageSeconds;
  final Value<String?> uid;
  const ShelterItemsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.shelterId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.count = const Value.absent(),
    this.condition = const Value.absent(),
    this.pagesTotal = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.noteId = const Value.absent(),
    this.portion = const Value.absent(),
    this.attachments = const Value.absent(),
    this.rounds = const Value.absent(),
    this.salvageSeconds = const Value.absent(),
    this.uid = const Value.absent(),
  });
  ShelterItemsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required int shelterId,
    required String itemId,
    this.count = const Value.absent(),
    this.condition = const Value.absent(),
    this.pagesTotal = const Value.absent(),
    this.pagesRead = const Value.absent(),
    this.noteId = const Value.absent(),
    this.portion = const Value.absent(),
    this.attachments = const Value.absent(),
    this.rounds = const Value.absent(),
    this.salvageSeconds = const Value.absent(),
    this.uid = const Value.absent(),
  }) : profileId = Value(profileId),
       shelterId = Value(shelterId),
       itemId = Value(itemId);
  static Insertable<StashRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<int>? shelterId,
    Expression<String>? itemId,
    Expression<int>? count,
    Expression<double>? condition,
    Expression<int>? pagesTotal,
    Expression<int>? pagesRead,
    Expression<String>? noteId,
    Expression<double>? portion,
    Expression<String>? attachments,
    Expression<int>? rounds,
    Expression<int>? salvageSeconds,
    Expression<String>? uid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (shelterId != null) 'shelter_id': shelterId,
      if (itemId != null) 'item_id': itemId,
      if (count != null) 'count': count,
      if (condition != null) 'condition': condition,
      if (pagesTotal != null) 'pages_total': pagesTotal,
      if (pagesRead != null) 'pages_read': pagesRead,
      if (noteId != null) 'note_id': noteId,
      if (portion != null) 'portion': portion,
      if (attachments != null) 'attachments': attachments,
      if (rounds != null) 'rounds': rounds,
      if (salvageSeconds != null) 'salvage_seconds': salvageSeconds,
      if (uid != null) 'uid': uid,
    });
  }

  ShelterItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<int>? shelterId,
    Value<String>? itemId,
    Value<int>? count,
    Value<double?>? condition,
    Value<int?>? pagesTotal,
    Value<int>? pagesRead,
    Value<String?>? noteId,
    Value<double>? portion,
    Value<String>? attachments,
    Value<int?>? rounds,
    Value<int?>? salvageSeconds,
    Value<String?>? uid,
  }) {
    return ShelterItemsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      shelterId: shelterId ?? this.shelterId,
      itemId: itemId ?? this.itemId,
      count: count ?? this.count,
      condition: condition ?? this.condition,
      pagesTotal: pagesTotal ?? this.pagesTotal,
      pagesRead: pagesRead ?? this.pagesRead,
      noteId: noteId ?? this.noteId,
      portion: portion ?? this.portion,
      attachments: attachments ?? this.attachments,
      rounds: rounds ?? this.rounds,
      salvageSeconds: salvageSeconds ?? this.salvageSeconds,
      uid: uid ?? this.uid,
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
    if (shelterId.present) {
      map['shelter_id'] = Variable<int>(shelterId.value);
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
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (portion.present) {
      map['portion'] = Variable<double>(portion.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(attachments.value);
    }
    if (rounds.present) {
      map['rounds'] = Variable<int>(rounds.value);
    }
    if (salvageSeconds.present) {
      map['salvage_seconds'] = Variable<int>(salvageSeconds.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelterItemsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('shelterId: $shelterId, ')
          ..write('itemId: $itemId, ')
          ..write('count: $count, ')
          ..write('condition: $condition, ')
          ..write('pagesTotal: $pagesTotal, ')
          ..write('pagesRead: $pagesRead, ')
          ..write('noteId: $noteId, ')
          ..write('portion: $portion, ')
          ..write('attachments: $attachments, ')
          ..write('rounds: $rounds, ')
          ..write('salvageSeconds: $salvageSeconds, ')
          ..write('uid: $uid')
          ..write(')'))
        .toString();
  }
}

class $CraftJobsTable extends CraftJobs
    with TableInfo<$CraftJobsTable, CraftJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CraftJobsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salvageItemIdMeta = const VerificationMeta(
    'salvageItemId',
  );
  @override
  late final GeneratedColumn<String> salvageItemId = GeneratedColumn<String>(
    'salvage_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salvageConditionMeta = const VerificationMeta(
    'salvageCondition',
  );
  @override
  late final GeneratedColumn<double> salvageCondition = GeneratedColumn<double>(
    'salvage_condition',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salvageBatchMeta = const VerificationMeta(
    'salvageBatch',
  );
  @override
  late final GeneratedColumn<String> salvageBatch = GeneratedColumn<String>(
    'salvage_batch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _readyAtMeta = const VerificationMeta(
    'readyAt',
  );
  @override
  late final GeneratedColumn<DateTime> readyAt = GeneratedColumn<DateTime>(
    'ready_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    recipeId,
    salvageItemId,
    salvageCondition,
    salvageBatch,
    startedAt,
    readyAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'craft_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CraftJobRow> instance, {
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
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('salvage_item_id')) {
      context.handle(
        _salvageItemIdMeta,
        salvageItemId.isAcceptableOrUnknown(
          data['salvage_item_id']!,
          _salvageItemIdMeta,
        ),
      );
    }
    if (data.containsKey('salvage_condition')) {
      context.handle(
        _salvageConditionMeta,
        salvageCondition.isAcceptableOrUnknown(
          data['salvage_condition']!,
          _salvageConditionMeta,
        ),
      );
    }
    if (data.containsKey('salvage_batch')) {
      context.handle(
        _salvageBatchMeta,
        salvageBatch.isAcceptableOrUnknown(
          data['salvage_batch']!,
          _salvageBatchMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ready_at')) {
      context.handle(
        _readyAtMeta,
        readyAt.isAcceptableOrUnknown(data['ready_at']!, _readyAtMeta),
      );
    } else if (isInserting) {
      context.missing(_readyAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CraftJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CraftJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      ),
      salvageItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salvage_item_id'],
      ),
      salvageCondition: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salvage_condition'],
      ),
      salvageBatch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salvage_batch'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      readyAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ready_at'],
      )!,
    );
  }

  @override
  $CraftJobsTable createAlias(String alias) {
    return $CraftJobsTable(attachedDatabase, alias);
  }
}

class CraftJobRow extends DataClass implements Insertable<CraftJobRow> {
  final int id;
  final int profileId;

  /// The recipe being made (§18.4), or null when this is a dismantling.
  final String? recipeId;

  /// What is being taken apart (§18.6), or null when this is a making.
  ///
  /// Exactly one of the two is set. The item is **already gone from the pack**
  /// when the job starts: leaving it there until the job finished would let a
  /// player dismantle a rifle and shoot it for the next quarter of an hour.
  final String? salvageItemId;

  /// §18.6: how worn it was, because the return is scaled by it and the item
  /// itself is no longer around to ask.
  final double? salvageCondition;

  /// §18.6: several things taken apart in one sitting, in the order they come
  /// apart. JSON, null for anything else.
  ///
  /// ⚠️ **Still one job, not a queue.** The comment above is unchanged: a
  /// person has one pair of hands, and this row is still the one thing they
  /// are doing. What the list adds is that the sitting has parts — the rifle
  /// first, then the vest — so that stopping half way through leaves every
  /// piece either finished or untouched, and never something in between.
  ///
  /// The pieces named here are **still in the pack**, locked, waiting their
  /// turn. Only the one at the head is being worked on, which is why only it
  /// carries a bar and why the others can be given back untouched.
  final String? salvageBatch;
  final DateTime startedAt;
  final DateTime readyAt;
  const CraftJobRow({
    required this.id,
    required this.profileId,
    this.recipeId,
    this.salvageItemId,
    this.salvageCondition,
    this.salvageBatch,
    required this.startedAt,
    required this.readyAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<String>(recipeId);
    }
    if (!nullToAbsent || salvageItemId != null) {
      map['salvage_item_id'] = Variable<String>(salvageItemId);
    }
    if (!nullToAbsent || salvageCondition != null) {
      map['salvage_condition'] = Variable<double>(salvageCondition);
    }
    if (!nullToAbsent || salvageBatch != null) {
      map['salvage_batch'] = Variable<String>(salvageBatch);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ready_at'] = Variable<DateTime>(readyAt);
    return map;
  }

  CraftJobsCompanion toCompanion(bool nullToAbsent) {
    return CraftJobsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      salvageItemId: salvageItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(salvageItemId),
      salvageCondition: salvageCondition == null && nullToAbsent
          ? const Value.absent()
          : Value(salvageCondition),
      salvageBatch: salvageBatch == null && nullToAbsent
          ? const Value.absent()
          : Value(salvageBatch),
      startedAt: Value(startedAt),
      readyAt: Value(readyAt),
    );
  }

  factory CraftJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CraftJobRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      recipeId: serializer.fromJson<String?>(json['recipeId']),
      salvageItemId: serializer.fromJson<String?>(json['salvageItemId']),
      salvageCondition: serializer.fromJson<double?>(json['salvageCondition']),
      salvageBatch: serializer.fromJson<String?>(json['salvageBatch']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      readyAt: serializer.fromJson<DateTime>(json['readyAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'recipeId': serializer.toJson<String?>(recipeId),
      'salvageItemId': serializer.toJson<String?>(salvageItemId),
      'salvageCondition': serializer.toJson<double?>(salvageCondition),
      'salvageBatch': serializer.toJson<String?>(salvageBatch),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'readyAt': serializer.toJson<DateTime>(readyAt),
    };
  }

  CraftJobRow copyWith({
    int? id,
    int? profileId,
    Value<String?> recipeId = const Value.absent(),
    Value<String?> salvageItemId = const Value.absent(),
    Value<double?> salvageCondition = const Value.absent(),
    Value<String?> salvageBatch = const Value.absent(),
    DateTime? startedAt,
    DateTime? readyAt,
  }) => CraftJobRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    salvageItemId: salvageItemId.present
        ? salvageItemId.value
        : this.salvageItemId,
    salvageCondition: salvageCondition.present
        ? salvageCondition.value
        : this.salvageCondition,
    salvageBatch: salvageBatch.present ? salvageBatch.value : this.salvageBatch,
    startedAt: startedAt ?? this.startedAt,
    readyAt: readyAt ?? this.readyAt,
  );
  CraftJobRow copyWithCompanion(CraftJobsCompanion data) {
    return CraftJobRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      salvageItemId: data.salvageItemId.present
          ? data.salvageItemId.value
          : this.salvageItemId,
      salvageCondition: data.salvageCondition.present
          ? data.salvageCondition.value
          : this.salvageCondition,
      salvageBatch: data.salvageBatch.present
          ? data.salvageBatch.value
          : this.salvageBatch,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      readyAt: data.readyAt.present ? data.readyAt.value : this.readyAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CraftJobRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('recipeId: $recipeId, ')
          ..write('salvageItemId: $salvageItemId, ')
          ..write('salvageCondition: $salvageCondition, ')
          ..write('salvageBatch: $salvageBatch, ')
          ..write('startedAt: $startedAt, ')
          ..write('readyAt: $readyAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    recipeId,
    salvageItemId,
    salvageCondition,
    salvageBatch,
    startedAt,
    readyAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CraftJobRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.recipeId == this.recipeId &&
          other.salvageItemId == this.salvageItemId &&
          other.salvageCondition == this.salvageCondition &&
          other.salvageBatch == this.salvageBatch &&
          other.startedAt == this.startedAt &&
          other.readyAt == this.readyAt);
}

class CraftJobsCompanion extends UpdateCompanion<CraftJobRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String?> recipeId;
  final Value<String?> salvageItemId;
  final Value<double?> salvageCondition;
  final Value<String?> salvageBatch;
  final Value<DateTime> startedAt;
  final Value<DateTime> readyAt;
  const CraftJobsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.salvageItemId = const Value.absent(),
    this.salvageCondition = const Value.absent(),
    this.salvageBatch = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.readyAt = const Value.absent(),
  });
  CraftJobsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    this.recipeId = const Value.absent(),
    this.salvageItemId = const Value.absent(),
    this.salvageCondition = const Value.absent(),
    this.salvageBatch = const Value.absent(),
    required DateTime startedAt,
    required DateTime readyAt,
  }) : profileId = Value(profileId),
       startedAt = Value(startedAt),
       readyAt = Value(readyAt);
  static Insertable<CraftJobRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? recipeId,
    Expression<String>? salvageItemId,
    Expression<double>? salvageCondition,
    Expression<String>? salvageBatch,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? readyAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (recipeId != null) 'recipe_id': recipeId,
      if (salvageItemId != null) 'salvage_item_id': salvageItemId,
      if (salvageCondition != null) 'salvage_condition': salvageCondition,
      if (salvageBatch != null) 'salvage_batch': salvageBatch,
      if (startedAt != null) 'started_at': startedAt,
      if (readyAt != null) 'ready_at': readyAt,
    });
  }

  CraftJobsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String?>? recipeId,
    Value<String?>? salvageItemId,
    Value<double?>? salvageCondition,
    Value<String?>? salvageBatch,
    Value<DateTime>? startedAt,
    Value<DateTime>? readyAt,
  }) {
    return CraftJobsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      recipeId: recipeId ?? this.recipeId,
      salvageItemId: salvageItemId ?? this.salvageItemId,
      salvageCondition: salvageCondition ?? this.salvageCondition,
      salvageBatch: salvageBatch ?? this.salvageBatch,
      startedAt: startedAt ?? this.startedAt,
      readyAt: readyAt ?? this.readyAt,
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
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (salvageItemId.present) {
      map['salvage_item_id'] = Variable<String>(salvageItemId.value);
    }
    if (salvageCondition.present) {
      map['salvage_condition'] = Variable<double>(salvageCondition.value);
    }
    if (salvageBatch.present) {
      map['salvage_batch'] = Variable<String>(salvageBatch.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (readyAt.present) {
      map['ready_at'] = Variable<DateTime>(readyAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CraftJobsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('recipeId: $recipeId, ')
          ..write('salvageItemId: $salvageItemId, ')
          ..write('salvageCondition: $salvageCondition, ')
          ..write('salvageBatch: $salvageBatch, ')
          ..write('startedAt: $startedAt, ')
          ..write('readyAt: $readyAt')
          ..write(')'))
        .toString();
  }
}

class $ActiveActionsTable extends ActiveActions
    with TableInfo<$ActiveActionsTable, ActiveActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveActionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _subjectUidMeta = const VerificationMeta(
    'subjectUid',
  );
  @override
  late final GeneratedColumn<String> subjectUid = GeneratedColumn<String>(
    'subject_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _totalSecondsMeta = const VerificationMeta(
    'totalSeconds',
  );
  @override
  late final GeneratedColumn<int> totalSeconds = GeneratedColumn<int>(
    'total_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creditedSecondsMeta = const VerificationMeta(
    'creditedSeconds',
  );
  @override
  late final GeneratedColumn<int> creditedSeconds = GeneratedColumn<int>(
    'credited_seconds',
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
  static const VerificationMeta _extraJsonMeta = const VerificationMeta(
    'extraJson',
  );
  @override
  late final GeneratedColumn<String> extraJson = GeneratedColumn<String>(
    'extra_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    kind,
    subjectUid,
    startedAt,
    totalSeconds,
    creditedSeconds,
    latitude,
    longitude,
    extraJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActiveActionRow> instance, {
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
    if (data.containsKey('subject_uid')) {
      context.handle(
        _subjectUidMeta,
        subjectUid.isAcceptableOrUnknown(data['subject_uid']!, _subjectUidMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('total_seconds')) {
      context.handle(
        _totalSecondsMeta,
        totalSeconds.isAcceptableOrUnknown(
          data['total_seconds']!,
          _totalSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSecondsMeta);
    }
    if (data.containsKey('credited_seconds')) {
      context.handle(
        _creditedSecondsMeta,
        creditedSeconds.isAcceptableOrUnknown(
          data['credited_seconds']!,
          _creditedSecondsMeta,
        ),
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
    if (data.containsKey('extra_json')) {
      context.handle(
        _extraJsonMeta,
        extraJson.isAcceptableOrUnknown(data['extra_json']!, _extraJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveActionRow(
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
      subjectUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_uid'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      totalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seconds'],
      )!,
      creditedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credited_seconds'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      extraJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_json'],
      ),
    );
  }

  @override
  $ActiveActionsTable createAlias(String alias) {
    return $ActiveActionsTable(attachedDatabase, alias);
  }
}

class ActiveActionRow extends DataClass implements Insertable<ActiveActionRow> {
  final int id;
  final int profileId;

  /// What is being done: an ActionKind's name, or one of ActionKinds'.
  final String kind;

  /// §11.1: which piece it is being done to, by uid. Never the item id — a
  /// half-eaten sandwich must not come back as a bite out of its neighbour.
  final String? subjectUid;
  final DateTime startedAt;
  final int totalSeconds;

  /// ⚠️ How much has been **earned**, which is not how much has passed.
  ///
  /// §4.7 and §10.2 give an action a rate: a dressing walked away from has
  /// been running ten minutes and earned six, and a search whose owner stepped
  /// off the spot has been running and earned nothing. Storing the elapsed
  /// time instead would hand both of them back finished.
  final int creditedSeconds;

  /// §10.2: where it began, for anything that has to stay put.
  final double? latitude;
  final double? longitude;

  /// Whatever else this kind needs — a recipe id, a POI, a search depth.
  /// Opaque for the reason §2.1a's occupation column is: new kinds arrive with
  /// new fields, and each would otherwise be a migration.
  final String? extraJson;
  const ActiveActionRow({
    required this.id,
    required this.profileId,
    required this.kind,
    this.subjectUid,
    required this.startedAt,
    required this.totalSeconds,
    required this.creditedSeconds,
    this.latitude,
    this.longitude,
    this.extraJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || subjectUid != null) {
      map['subject_uid'] = Variable<String>(subjectUid);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['total_seconds'] = Variable<int>(totalSeconds);
    map['credited_seconds'] = Variable<int>(creditedSeconds);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || extraJson != null) {
      map['extra_json'] = Variable<String>(extraJson);
    }
    return map;
  }

  ActiveActionsCompanion toCompanion(bool nullToAbsent) {
    return ActiveActionsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      kind: Value(kind),
      subjectUid: subjectUid == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectUid),
      startedAt: Value(startedAt),
      totalSeconds: Value(totalSeconds),
      creditedSeconds: Value(creditedSeconds),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      extraJson: extraJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extraJson),
    );
  }

  factory ActiveActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveActionRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      kind: serializer.fromJson<String>(json['kind']),
      subjectUid: serializer.fromJson<String?>(json['subjectUid']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      totalSeconds: serializer.fromJson<int>(json['totalSeconds']),
      creditedSeconds: serializer.fromJson<int>(json['creditedSeconds']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      extraJson: serializer.fromJson<String?>(json['extraJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'kind': serializer.toJson<String>(kind),
      'subjectUid': serializer.toJson<String?>(subjectUid),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'totalSeconds': serializer.toJson<int>(totalSeconds),
      'creditedSeconds': serializer.toJson<int>(creditedSeconds),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'extraJson': serializer.toJson<String?>(extraJson),
    };
  }

  ActiveActionRow copyWith({
    int? id,
    int? profileId,
    String? kind,
    Value<String?> subjectUid = const Value.absent(),
    DateTime? startedAt,
    int? totalSeconds,
    int? creditedSeconds,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> extraJson = const Value.absent(),
  }) => ActiveActionRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    kind: kind ?? this.kind,
    subjectUid: subjectUid.present ? subjectUid.value : this.subjectUid,
    startedAt: startedAt ?? this.startedAt,
    totalSeconds: totalSeconds ?? this.totalSeconds,
    creditedSeconds: creditedSeconds ?? this.creditedSeconds,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    extraJson: extraJson.present ? extraJson.value : this.extraJson,
  );
  ActiveActionRow copyWithCompanion(ActiveActionsCompanion data) {
    return ActiveActionRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      kind: data.kind.present ? data.kind.value : this.kind,
      subjectUid: data.subjectUid.present
          ? data.subjectUid.value
          : this.subjectUid,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      totalSeconds: data.totalSeconds.present
          ? data.totalSeconds.value
          : this.totalSeconds,
      creditedSeconds: data.creditedSeconds.present
          ? data.creditedSeconds.value
          : this.creditedSeconds,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      extraJson: data.extraJson.present ? data.extraJson.value : this.extraJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveActionRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('subjectUid: $subjectUid, ')
          ..write('startedAt: $startedAt, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('creditedSeconds: $creditedSeconds, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('extraJson: $extraJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    kind,
    subjectUid,
    startedAt,
    totalSeconds,
    creditedSeconds,
    latitude,
    longitude,
    extraJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveActionRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.kind == this.kind &&
          other.subjectUid == this.subjectUid &&
          other.startedAt == this.startedAt &&
          other.totalSeconds == this.totalSeconds &&
          other.creditedSeconds == this.creditedSeconds &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.extraJson == this.extraJson);
}

class ActiveActionsCompanion extends UpdateCompanion<ActiveActionRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> kind;
  final Value<String?> subjectUid;
  final Value<DateTime> startedAt;
  final Value<int> totalSeconds;
  final Value<int> creditedSeconds;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> extraJson;
  const ActiveActionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.kind = const Value.absent(),
    this.subjectUid = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.creditedSeconds = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.extraJson = const Value.absent(),
  });
  ActiveActionsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String kind,
    this.subjectUid = const Value.absent(),
    required DateTime startedAt,
    required int totalSeconds,
    this.creditedSeconds = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.extraJson = const Value.absent(),
  }) : profileId = Value(profileId),
       kind = Value(kind),
       startedAt = Value(startedAt),
       totalSeconds = Value(totalSeconds);
  static Insertable<ActiveActionRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? kind,
    Expression<String>? subjectUid,
    Expression<DateTime>? startedAt,
    Expression<int>? totalSeconds,
    Expression<int>? creditedSeconds,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? extraJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (kind != null) 'kind': kind,
      if (subjectUid != null) 'subject_uid': subjectUid,
      if (startedAt != null) 'started_at': startedAt,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (creditedSeconds != null) 'credited_seconds': creditedSeconds,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (extraJson != null) 'extra_json': extraJson,
    });
  }

  ActiveActionsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? kind,
    Value<String?>? subjectUid,
    Value<DateTime>? startedAt,
    Value<int>? totalSeconds,
    Value<int>? creditedSeconds,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? extraJson,
  }) {
    return ActiveActionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      kind: kind ?? this.kind,
      subjectUid: subjectUid ?? this.subjectUid,
      startedAt: startedAt ?? this.startedAt,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      creditedSeconds: creditedSeconds ?? this.creditedSeconds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      extraJson: extraJson ?? this.extraJson,
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
    if (subjectUid.present) {
      map['subject_uid'] = Variable<String>(subjectUid.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (totalSeconds.present) {
      map['total_seconds'] = Variable<int>(totalSeconds.value);
    }
    if (creditedSeconds.present) {
      map['credited_seconds'] = Variable<int>(creditedSeconds.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (extraJson.present) {
      map['extra_json'] = Variable<String>(extraJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveActionsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('subjectUid: $subjectUid, ')
          ..write('startedAt: $startedAt, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('creditedSeconds: $creditedSeconds, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('extraJson: $extraJson')
          ..write(')'))
        .toString();
  }
}

class $SkillRowsTable extends SkillRows
    with TableInfo<$SkillRowsTable, SkillRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkillRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _skillMeta = const VerificationMeta('skill');
  @override
  late final GeneratedColumn<String> skill = GeneratedColumn<String>(
    'skill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [profileId, skill, xp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skills';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkillRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('skill')) {
      context.handle(
        _skillMeta,
        skill.isAcceptableOrUnknown(data['skill']!, _skillMeta),
      );
    } else if (isInserting) {
      context.missing(_skillMeta);
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId, skill};
  @override
  SkillRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkillRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      skill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
    );
  }

  @override
  $SkillRowsTable createAlias(String alias) {
    return $SkillRowsTable(attachedDatabase, alias);
  }
}

class SkillRow extends DataClass implements Insertable<SkillRow> {
  final int profileId;

  /// The wire name from [Skill]: 'scouting' | 'weapons' | 'medicine' |
  /// 'engineering'. Text rather than an index, because it also appears in
  /// `assets/data/literature.json` and the two must not drift apart.
  final String skill;

  /// Everything earned in this skill, ever. The level is derived (§7.2) and
  /// never stored — a stored level and a stored total can disagree, and then
  /// nobody knows which one the player earned.
  final int xp;
  const SkillRow({
    required this.profileId,
    required this.skill,
    required this.xp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['skill'] = Variable<String>(skill);
    map['xp'] = Variable<int>(xp);
    return map;
  }

  SkillRowsCompanion toCompanion(bool nullToAbsent) {
    return SkillRowsCompanion(
      profileId: Value(profileId),
      skill: Value(skill),
      xp: Value(xp),
    );
  }

  factory SkillRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkillRow(
      profileId: serializer.fromJson<int>(json['profileId']),
      skill: serializer.fromJson<String>(json['skill']),
      xp: serializer.fromJson<int>(json['xp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'skill': serializer.toJson<String>(skill),
      'xp': serializer.toJson<int>(xp),
    };
  }

  SkillRow copyWith({int? profileId, String? skill, int? xp}) => SkillRow(
    profileId: profileId ?? this.profileId,
    skill: skill ?? this.skill,
    xp: xp ?? this.xp,
  );
  SkillRow copyWithCompanion(SkillRowsCompanion data) {
    return SkillRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      skill: data.skill.present ? data.skill.value : this.skill,
      xp: data.xp.present ? data.xp.value : this.xp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkillRow(')
          ..write('profileId: $profileId, ')
          ..write('skill: $skill, ')
          ..write('xp: $xp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, skill, xp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkillRow &&
          other.profileId == this.profileId &&
          other.skill == this.skill &&
          other.xp == this.xp);
}

class SkillRowsCompanion extends UpdateCompanion<SkillRow> {
  final Value<int> profileId;
  final Value<String> skill;
  final Value<int> xp;
  final Value<int> rowid;
  const SkillRowsCompanion({
    this.profileId = const Value.absent(),
    this.skill = const Value.absent(),
    this.xp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkillRowsCompanion.insert({
    required int profileId,
    required String skill,
    this.xp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       skill = Value(skill);
  static Insertable<SkillRow> custom({
    Expression<int>? profileId,
    Expression<String>? skill,
    Expression<int>? xp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (skill != null) 'skill': skill,
      if (xp != null) 'xp': xp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkillRowsCompanion copyWith({
    Value<int>? profileId,
    Value<String>? skill,
    Value<int>? xp,
    Value<int>? rowid,
  }) {
    return SkillRowsCompanion(
      profileId: profileId ?? this.profileId,
      skill: skill ?? this.skill,
      xp: xp ?? this.xp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (skill.present) {
      map['skill'] = Variable<String>(skill.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkillRowsCompanion(')
          ..write('profileId: $profileId, ')
          ..write('skill: $skill, ')
          ..write('xp: $xp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HotspotRowsTable extends HotspotRows
    with TableInfo<$HotspotRowsTable, HotspotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HotspotRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _integrityMeta = const VerificationMeta(
    'integrity',
  );
  @override
  late final GeneratedColumn<double> integrity = GeneratedColumn<double>(
    'integrity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bornAtMeta = const VerificationMeta('bornAt');
  @override
  late final GeneratedColumn<DateTime> bornAt = GeneratedColumn<DateTime>(
    'born_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextLevelAtMeta = const VerificationMeta(
    'nextLevelAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextLevelAt = GeneratedColumn<DateTime>(
    'next_level_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agitatedUntilMeta = const VerificationMeta(
    'agitatedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> agitatedUntil =
      GeneratedColumn<DateTime>(
        'agitated_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _restingUntilMeta = const VerificationMeta(
    'restingUntil',
  );
  @override
  late final GeneratedColumn<DateTime> restingUntil = GeneratedColumn<DateTime>(
    'resting_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    slot,
    seed,
    latitude,
    longitude,
    level,
    integrity,
    bornAt,
    nextLevelAt,
    agitatedUntil,
    restingUntil,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hotspots';
  @override
  VerificationContext validateIntegrity(
    Insertable<HotspotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    } else if (isInserting) {
      context.missing(_seedMeta);
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
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('integrity')) {
      context.handle(
        _integrityMeta,
        integrity.isAcceptableOrUnknown(data['integrity']!, _integrityMeta),
      );
    } else if (isInserting) {
      context.missing(_integrityMeta);
    }
    if (data.containsKey('born_at')) {
      context.handle(
        _bornAtMeta,
        bornAt.isAcceptableOrUnknown(data['born_at']!, _bornAtMeta),
      );
    } else if (isInserting) {
      context.missing(_bornAtMeta);
    }
    if (data.containsKey('next_level_at')) {
      context.handle(
        _nextLevelAtMeta,
        nextLevelAt.isAcceptableOrUnknown(
          data['next_level_at']!,
          _nextLevelAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextLevelAtMeta);
    }
    if (data.containsKey('agitated_until')) {
      context.handle(
        _agitatedUntilMeta,
        agitatedUntil.isAcceptableOrUnknown(
          data['agitated_until']!,
          _agitatedUntilMeta,
        ),
      );
    }
    if (data.containsKey('resting_until')) {
      context.handle(
        _restingUntilMeta,
        restingUntil.isAcceptableOrUnknown(
          data['resting_until']!,
          _restingUntilMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId, slot};
  @override
  HotspotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HotspotRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      integrity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}integrity'],
      )!,
      bornAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}born_at'],
      )!,
      nextLevelAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_level_at'],
      )!,
      agitatedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}agitated_until'],
      ),
      restingUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resting_until'],
      ),
    );
  }

  @override
  $HotspotRowsTable createAlias(String alias) {
    return $HotspotRowsTable(attachedDatabase, alias);
  }
}

class HotspotRow extends DataClass implements Insertable<HotspotRow> {
  final int profileId;

  /// 0, 1, 2 — §6.5.1 allows three. The slot outlives the hotspot in it.
  final int slot;

  /// What the radius is drawn from, stable for the life of this hotspot.
  final int seed;
  final double latitude;
  final double longitude;

  /// 1–10 while it exists, 0 while the slot is resting.
  final int level;
  final double integrity;
  final DateTime bornAt;

  /// §6.5.3: when it grows next. Against the clock — a hotspot promotes with
  /// the app shut, which is the whole point of it being pressure.
  final DateTime nextLevelAt;

  /// §6.5.4: furious until this moment, or null.
  final DateTime? agitatedUntil;

  /// §6.5.4: the slot is empty until this moment, or null.
  final DateTime? restingUntil;
  const HotspotRow({
    required this.profileId,
    required this.slot,
    required this.seed,
    required this.latitude,
    required this.longitude,
    required this.level,
    required this.integrity,
    required this.bornAt,
    required this.nextLevelAt,
    this.agitatedUntil,
    this.restingUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['slot'] = Variable<int>(slot);
    map['seed'] = Variable<int>(seed);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['level'] = Variable<int>(level);
    map['integrity'] = Variable<double>(integrity);
    map['born_at'] = Variable<DateTime>(bornAt);
    map['next_level_at'] = Variable<DateTime>(nextLevelAt);
    if (!nullToAbsent || agitatedUntil != null) {
      map['agitated_until'] = Variable<DateTime>(agitatedUntil);
    }
    if (!nullToAbsent || restingUntil != null) {
      map['resting_until'] = Variable<DateTime>(restingUntil);
    }
    return map;
  }

  HotspotRowsCompanion toCompanion(bool nullToAbsent) {
    return HotspotRowsCompanion(
      profileId: Value(profileId),
      slot: Value(slot),
      seed: Value(seed),
      latitude: Value(latitude),
      longitude: Value(longitude),
      level: Value(level),
      integrity: Value(integrity),
      bornAt: Value(bornAt),
      nextLevelAt: Value(nextLevelAt),
      agitatedUntil: agitatedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(agitatedUntil),
      restingUntil: restingUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(restingUntil),
    );
  }

  factory HotspotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HotspotRow(
      profileId: serializer.fromJson<int>(json['profileId']),
      slot: serializer.fromJson<int>(json['slot']),
      seed: serializer.fromJson<int>(json['seed']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      level: serializer.fromJson<int>(json['level']),
      integrity: serializer.fromJson<double>(json['integrity']),
      bornAt: serializer.fromJson<DateTime>(json['bornAt']),
      nextLevelAt: serializer.fromJson<DateTime>(json['nextLevelAt']),
      agitatedUntil: serializer.fromJson<DateTime?>(json['agitatedUntil']),
      restingUntil: serializer.fromJson<DateTime?>(json['restingUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'slot': serializer.toJson<int>(slot),
      'seed': serializer.toJson<int>(seed),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'level': serializer.toJson<int>(level),
      'integrity': serializer.toJson<double>(integrity),
      'bornAt': serializer.toJson<DateTime>(bornAt),
      'nextLevelAt': serializer.toJson<DateTime>(nextLevelAt),
      'agitatedUntil': serializer.toJson<DateTime?>(agitatedUntil),
      'restingUntil': serializer.toJson<DateTime?>(restingUntil),
    };
  }

  HotspotRow copyWith({
    int? profileId,
    int? slot,
    int? seed,
    double? latitude,
    double? longitude,
    int? level,
    double? integrity,
    DateTime? bornAt,
    DateTime? nextLevelAt,
    Value<DateTime?> agitatedUntil = const Value.absent(),
    Value<DateTime?> restingUntil = const Value.absent(),
  }) => HotspotRow(
    profileId: profileId ?? this.profileId,
    slot: slot ?? this.slot,
    seed: seed ?? this.seed,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    level: level ?? this.level,
    integrity: integrity ?? this.integrity,
    bornAt: bornAt ?? this.bornAt,
    nextLevelAt: nextLevelAt ?? this.nextLevelAt,
    agitatedUntil: agitatedUntil.present
        ? agitatedUntil.value
        : this.agitatedUntil,
    restingUntil: restingUntil.present ? restingUntil.value : this.restingUntil,
  );
  HotspotRow copyWithCompanion(HotspotRowsCompanion data) {
    return HotspotRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      slot: data.slot.present ? data.slot.value : this.slot,
      seed: data.seed.present ? data.seed.value : this.seed,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      level: data.level.present ? data.level.value : this.level,
      integrity: data.integrity.present ? data.integrity.value : this.integrity,
      bornAt: data.bornAt.present ? data.bornAt.value : this.bornAt,
      nextLevelAt: data.nextLevelAt.present
          ? data.nextLevelAt.value
          : this.nextLevelAt,
      agitatedUntil: data.agitatedUntil.present
          ? data.agitatedUntil.value
          : this.agitatedUntil,
      restingUntil: data.restingUntil.present
          ? data.restingUntil.value
          : this.restingUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HotspotRow(')
          ..write('profileId: $profileId, ')
          ..write('slot: $slot, ')
          ..write('seed: $seed, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('level: $level, ')
          ..write('integrity: $integrity, ')
          ..write('bornAt: $bornAt, ')
          ..write('nextLevelAt: $nextLevelAt, ')
          ..write('agitatedUntil: $agitatedUntil, ')
          ..write('restingUntil: $restingUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    profileId,
    slot,
    seed,
    latitude,
    longitude,
    level,
    integrity,
    bornAt,
    nextLevelAt,
    agitatedUntil,
    restingUntil,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HotspotRow &&
          other.profileId == this.profileId &&
          other.slot == this.slot &&
          other.seed == this.seed &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.level == this.level &&
          other.integrity == this.integrity &&
          other.bornAt == this.bornAt &&
          other.nextLevelAt == this.nextLevelAt &&
          other.agitatedUntil == this.agitatedUntil &&
          other.restingUntil == this.restingUntil);
}

class HotspotRowsCompanion extends UpdateCompanion<HotspotRow> {
  final Value<int> profileId;
  final Value<int> slot;
  final Value<int> seed;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> level;
  final Value<double> integrity;
  final Value<DateTime> bornAt;
  final Value<DateTime> nextLevelAt;
  final Value<DateTime?> agitatedUntil;
  final Value<DateTime?> restingUntil;
  final Value<int> rowid;
  const HotspotRowsCompanion({
    this.profileId = const Value.absent(),
    this.slot = const Value.absent(),
    this.seed = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.level = const Value.absent(),
    this.integrity = const Value.absent(),
    this.bornAt = const Value.absent(),
    this.nextLevelAt = const Value.absent(),
    this.agitatedUntil = const Value.absent(),
    this.restingUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HotspotRowsCompanion.insert({
    required int profileId,
    required int slot,
    required int seed,
    required double latitude,
    required double longitude,
    required int level,
    required double integrity,
    required DateTime bornAt,
    required DateTime nextLevelAt,
    this.agitatedUntil = const Value.absent(),
    this.restingUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       slot = Value(slot),
       seed = Value(seed),
       latitude = Value(latitude),
       longitude = Value(longitude),
       level = Value(level),
       integrity = Value(integrity),
       bornAt = Value(bornAt),
       nextLevelAt = Value(nextLevelAt);
  static Insertable<HotspotRow> custom({
    Expression<int>? profileId,
    Expression<int>? slot,
    Expression<int>? seed,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? level,
    Expression<double>? integrity,
    Expression<DateTime>? bornAt,
    Expression<DateTime>? nextLevelAt,
    Expression<DateTime>? agitatedUntil,
    Expression<DateTime>? restingUntil,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (slot != null) 'slot': slot,
      if (seed != null) 'seed': seed,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (level != null) 'level': level,
      if (integrity != null) 'integrity': integrity,
      if (bornAt != null) 'born_at': bornAt,
      if (nextLevelAt != null) 'next_level_at': nextLevelAt,
      if (agitatedUntil != null) 'agitated_until': agitatedUntil,
      if (restingUntil != null) 'resting_until': restingUntil,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HotspotRowsCompanion copyWith({
    Value<int>? profileId,
    Value<int>? slot,
    Value<int>? seed,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int>? level,
    Value<double>? integrity,
    Value<DateTime>? bornAt,
    Value<DateTime>? nextLevelAt,
    Value<DateTime?>? agitatedUntil,
    Value<DateTime?>? restingUntil,
    Value<int>? rowid,
  }) {
    return HotspotRowsCompanion(
      profileId: profileId ?? this.profileId,
      slot: slot ?? this.slot,
      seed: seed ?? this.seed,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      level: level ?? this.level,
      integrity: integrity ?? this.integrity,
      bornAt: bornAt ?? this.bornAt,
      nextLevelAt: nextLevelAt ?? this.nextLevelAt,
      agitatedUntil: agitatedUntil ?? this.agitatedUntil,
      restingUntil: restingUntil ?? this.restingUntil,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (integrity.present) {
      map['integrity'] = Variable<double>(integrity.value);
    }
    if (bornAt.present) {
      map['born_at'] = Variable<DateTime>(bornAt.value);
    }
    if (nextLevelAt.present) {
      map['next_level_at'] = Variable<DateTime>(nextLevelAt.value);
    }
    if (agitatedUntil.present) {
      map['agitated_until'] = Variable<DateTime>(agitatedUntil.value);
    }
    if (restingUntil.present) {
      map['resting_until'] = Variable<DateTime>(restingUntil.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HotspotRowsCompanion(')
          ..write('profileId: $profileId, ')
          ..write('slot: $slot, ')
          ..write('seed: $seed, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('level: $level, ')
          ..write('integrity: $integrity, ')
          ..write('bornAt: $bornAt, ')
          ..write('nextLevelAt: $nextLevelAt, ')
          ..write('agitatedUntil: $agitatedUntil, ')
          ..write('restingUntil: $restingUntil, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalRowsTable extends JournalRows
    with TableInfo<$JournalRowsTable, JournalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, profileId, at, kind, subject];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalRow> instance, {
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
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
    );
  }

  @override
  $JournalRowsTable createAlias(String alias) {
    return $JournalRowsTable(attachedDatabase, alias);
  }
}

class JournalRow extends DataClass implements Insertable<JournalRow> {
  final int id;
  final int profileId;
  final DateTime at;

  /// [JournalKind.wire]. Text rather than an index, so adding a kind in the
  /// middle of the enum does not rewrite everything already on disk.
  final String kind;
  final String? subject;
  const JournalRow({
    required this.id,
    required this.profileId,
    required this.at,
    required this.kind,
    this.subject,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['at'] = Variable<DateTime>(at);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    return map;
  }

  JournalRowsCompanion toCompanion(bool nullToAbsent) {
    return JournalRowsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      at: Value(at),
      kind: Value(kind),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
    );
  }

  factory JournalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalRow(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      at: serializer.fromJson<DateTime>(json['at']),
      kind: serializer.fromJson<String>(json['kind']),
      subject: serializer.fromJson<String?>(json['subject']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'at': serializer.toJson<DateTime>(at),
      'kind': serializer.toJson<String>(kind),
      'subject': serializer.toJson<String?>(subject),
    };
  }

  JournalRow copyWith({
    int? id,
    int? profileId,
    DateTime? at,
    String? kind,
    Value<String?> subject = const Value.absent(),
  }) => JournalRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    at: at ?? this.at,
    kind: kind ?? this.kind,
    subject: subject.present ? subject.value : this.subject,
  );
  JournalRow copyWithCompanion(JournalRowsCompanion data) {
    return JournalRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      at: data.at.present ? data.at.value : this.at,
      kind: data.kind.present ? data.kind.value : this.kind,
      subject: data.subject.present ? data.subject.value : this.subject,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, at, kind, subject);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.at == this.at &&
          other.kind == this.kind &&
          other.subject == this.subject);
}

class JournalRowsCompanion extends UpdateCompanion<JournalRow> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<DateTime> at;
  final Value<String> kind;
  final Value<String?> subject;
  const JournalRowsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.at = const Value.absent(),
    this.kind = const Value.absent(),
    this.subject = const Value.absent(),
  });
  JournalRowsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required DateTime at,
    required String kind,
    this.subject = const Value.absent(),
  }) : profileId = Value(profileId),
       at = Value(at),
       kind = Value(kind);
  static Insertable<JournalRow> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<DateTime>? at,
    Expression<String>? kind,
    Expression<String>? subject,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (at != null) 'at': at,
      if (kind != null) 'kind': kind,
      if (subject != null) 'subject': subject,
    });
  }

  JournalRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<DateTime>? at,
    Value<String>? kind,
    Value<String?>? subject,
  }) {
    return JournalRowsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      at: at ?? this.at,
      kind: kind ?? this.kind,
      subject: subject ?? this.subject,
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
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalRowsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }
}

class $ReadTitlesTable extends ReadTitles
    with TableInfo<$ReadTitlesTable, ReadTitle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadTitlesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _copiesMeta = const VerificationMeta('copies');
  @override
  late final GeneratedColumn<int> copies = GeneratedColumn<int>(
    'copies',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [profileId, itemId, copies];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_titles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadTitle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('copies')) {
      context.handle(
        _copiesMeta,
        copies.isAcceptableOrUnknown(data['copies']!, _copiesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId, itemId};
  @override
  ReadTitle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadTitle(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      copies: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}copies'],
      )!,
    );
  }

  @override
  $ReadTitlesTable createAlias(String alias) {
    return $ReadTitlesTable(attachedDatabase, alias);
  }
}

class ReadTitle extends DataClass implements Insertable<ReadTitle> {
  final int profileId;

  /// The catalogue id, so a title outlives any rename of the thing it names.
  final String itemId;

  /// How many copies of it have been read to the last page.
  final int copies;
  const ReadTitle({
    required this.profileId,
    required this.itemId,
    required this.copies,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['item_id'] = Variable<String>(itemId);
    map['copies'] = Variable<int>(copies);
    return map;
  }

  ReadTitlesCompanion toCompanion(bool nullToAbsent) {
    return ReadTitlesCompanion(
      profileId: Value(profileId),
      itemId: Value(itemId),
      copies: Value(copies),
    );
  }

  factory ReadTitle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadTitle(
      profileId: serializer.fromJson<int>(json['profileId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      copies: serializer.fromJson<int>(json['copies']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'itemId': serializer.toJson<String>(itemId),
      'copies': serializer.toJson<int>(copies),
    };
  }

  ReadTitle copyWith({int? profileId, String? itemId, int? copies}) =>
      ReadTitle(
        profileId: profileId ?? this.profileId,
        itemId: itemId ?? this.itemId,
        copies: copies ?? this.copies,
      );
  ReadTitle copyWithCompanion(ReadTitlesCompanion data) {
    return ReadTitle(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      copies: data.copies.present ? data.copies.value : this.copies,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadTitle(')
          ..write('profileId: $profileId, ')
          ..write('itemId: $itemId, ')
          ..write('copies: $copies')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, itemId, copies);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadTitle &&
          other.profileId == this.profileId &&
          other.itemId == this.itemId &&
          other.copies == this.copies);
}

class ReadTitlesCompanion extends UpdateCompanion<ReadTitle> {
  final Value<int> profileId;
  final Value<String> itemId;
  final Value<int> copies;
  final Value<int> rowid;
  const ReadTitlesCompanion({
    this.profileId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.copies = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadTitlesCompanion.insert({
    required int profileId,
    required String itemId,
    this.copies = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       itemId = Value(itemId);
  static Insertable<ReadTitle> custom({
    Expression<int>? profileId,
    Expression<String>? itemId,
    Expression<int>? copies,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (itemId != null) 'item_id': itemId,
      if (copies != null) 'copies': copies,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadTitlesCompanion copyWith({
    Value<int>? profileId,
    Value<String>? itemId,
    Value<int>? copies,
    Value<int>? rowid,
  }) {
    return ReadTitlesCompanion(
      profileId: profileId ?? this.profileId,
      itemId: itemId ?? this.itemId,
      copies: copies ?? this.copies,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (copies.present) {
      map['copies'] = Variable<int>(copies.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadTitlesCompanion(')
          ..write('profileId: $profileId, ')
          ..write('itemId: $itemId, ')
          ..write('copies: $copies, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayDaysTable extends PlayDays
    with TableInfo<$PlayDaysTable, PlayDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayDaysTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMinutesMeta = const VerificationMeta(
    'activeMinutes',
  );
  @override
  late final GeneratedColumn<int> activeMinutes = GeneratedColumn<int>(
    'active_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [profileId, day, activeMinutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('active_minutes')) {
      context.handle(
        _activeMinutesMeta,
        activeMinutes.isAcceptableOrUnknown(
          data['active_minutes']!,
          _activeMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId, day};
  @override
  PlayDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayDayRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      activeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_minutes'],
      )!,
    );
  }

  @override
  $PlayDaysTable createAlias(String alias) {
    return $PlayDaysTable(attachedDatabase, alias);
  }
}

class PlayDayRow extends DataClass implements Insertable<PlayDayRow> {
  final int profileId;

  /// The local calendar day, `YYYY-MM-DD`. Local, not UTC: a habit is formed
  /// in evenings, and an evening belongs to the day the player calls it.
  final String day;

  /// Minutes with the game awake and ticking on that day.
  final int activeMinutes;
  const PlayDayRow({
    required this.profileId,
    required this.day,
    required this.activeMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['day'] = Variable<String>(day);
    map['active_minutes'] = Variable<int>(activeMinutes);
    return map;
  }

  PlayDaysCompanion toCompanion(bool nullToAbsent) {
    return PlayDaysCompanion(
      profileId: Value(profileId),
      day: Value(day),
      activeMinutes: Value(activeMinutes),
    );
  }

  factory PlayDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayDayRow(
      profileId: serializer.fromJson<int>(json['profileId']),
      day: serializer.fromJson<String>(json['day']),
      activeMinutes: serializer.fromJson<int>(json['activeMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'day': serializer.toJson<String>(day),
      'activeMinutes': serializer.toJson<int>(activeMinutes),
    };
  }

  PlayDayRow copyWith({int? profileId, String? day, int? activeMinutes}) =>
      PlayDayRow(
        profileId: profileId ?? this.profileId,
        day: day ?? this.day,
        activeMinutes: activeMinutes ?? this.activeMinutes,
      );
  PlayDayRow copyWithCompanion(PlayDaysCompanion data) {
    return PlayDayRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      day: data.day.present ? data.day.value : this.day,
      activeMinutes: data.activeMinutes.present
          ? data.activeMinutes.value
          : this.activeMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayDayRow(')
          ..write('profileId: $profileId, ')
          ..write('day: $day, ')
          ..write('activeMinutes: $activeMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, day, activeMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayDayRow &&
          other.profileId == this.profileId &&
          other.day == this.day &&
          other.activeMinutes == this.activeMinutes);
}

class PlayDaysCompanion extends UpdateCompanion<PlayDayRow> {
  final Value<int> profileId;
  final Value<String> day;
  final Value<int> activeMinutes;
  final Value<int> rowid;
  const PlayDaysCompanion({
    this.profileId = const Value.absent(),
    this.day = const Value.absent(),
    this.activeMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayDaysCompanion.insert({
    required int profileId,
    required String day,
    this.activeMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       day = Value(day);
  static Insertable<PlayDayRow> custom({
    Expression<int>? profileId,
    Expression<String>? day,
    Expression<int>? activeMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (day != null) 'day': day,
      if (activeMinutes != null) 'active_minutes': activeMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayDaysCompanion copyWith({
    Value<int>? profileId,
    Value<String>? day,
    Value<int>? activeMinutes,
    Value<int>? rowid,
  }) {
    return PlayDaysCompanion(
      profileId: profileId ?? this.profileId,
      day: day ?? this.day,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (activeMinutes.present) {
      map['active_minutes'] = Variable<int>(activeMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayDaysCompanion(')
          ..write('profileId: $profileId, ')
          ..write('day: $day, ')
          ..write('activeMinutes: $activeMinutes, ')
          ..write('rowid: $rowid')
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
  late final $ProfileStatsTable profileStats = $ProfileStatsTable(this);
  late final $ShelterItemsTable shelterItems = $ShelterItemsTable(this);
  late final $CraftJobsTable craftJobs = $CraftJobsTable(this);
  late final $ActiveActionsTable activeActions = $ActiveActionsTable(this);
  late final $SkillRowsTable skillRows = $SkillRowsTable(this);
  late final $HotspotRowsTable hotspotRows = $HotspotRowsTable(this);
  late final $JournalRowsTable journalRows = $JournalRowsTable(this);
  late final $ReadTitlesTable readTitles = $ReadTitlesTable(this);
  late final $PlayDaysTable playDays = $PlayDaysTable(this);
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
    profileStats,
    shelterItems,
    craftJobs,
    activeActions,
    skillRows,
    hotspotRows,
    journalRows,
    readTitles,
    playDays,
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
      Value<DateTime?> graceUntil,
      Value<DateTime?> huntUntil,
      Value<double?> huntLatitude,
      Value<double?> huntLongitude,
      Value<int> huntCount,
      Value<String?> occupationJson,
      Value<double> speedKmh,
      Value<double> carriedKg,
      Value<double> pendingKcal,
      Value<double> pendingWaterMl,
      Value<int> dryStreakSeconds,
      Value<int> starvedStreakSeconds,
      Value<double> bodyMassKg,
      Value<double> sleepStrain,
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
      Value<DateTime?> graceUntil,
      Value<DateTime?> huntUntil,
      Value<double?> huntLatitude,
      Value<double?> huntLongitude,
      Value<int> huntCount,
      Value<String?> occupationJson,
      Value<double> speedKmh,
      Value<double> carriedKg,
      Value<double> pendingKcal,
      Value<double> pendingWaterMl,
      Value<int> dryStreakSeconds,
      Value<int> starvedStreakSeconds,
      Value<double> bodyMassKg,
      Value<double> sleepStrain,
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

  ColumnFilters<DateTime> get graceUntil => $composableBuilder(
    column: $table.graceUntil,
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

  ColumnFilters<int> get dryStreakSeconds => $composableBuilder(
    column: $table.dryStreakSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get starvedStreakSeconds => $composableBuilder(
    column: $table.starvedStreakSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyMassKg => $composableBuilder(
    column: $table.bodyMassKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sleepStrain => $composableBuilder(
    column: $table.sleepStrain,
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

  ColumnOrderings<DateTime> get graceUntil => $composableBuilder(
    column: $table.graceUntil,
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

  ColumnOrderings<int> get dryStreakSeconds => $composableBuilder(
    column: $table.dryStreakSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get starvedStreakSeconds => $composableBuilder(
    column: $table.starvedStreakSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyMassKg => $composableBuilder(
    column: $table.bodyMassKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sleepStrain => $composableBuilder(
    column: $table.sleepStrain,
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

  GeneratedColumn<DateTime> get graceUntil => $composableBuilder(
    column: $table.graceUntil,
    builder: (column) => column,
  );

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

  GeneratedColumn<int> get dryStreakSeconds => $composableBuilder(
    column: $table.dryStreakSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get starvedStreakSeconds => $composableBuilder(
    column: $table.starvedStreakSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bodyMassKg => $composableBuilder(
    column: $table.bodyMassKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sleepStrain => $composableBuilder(
    column: $table.sleepStrain,
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
                Value<DateTime?> graceUntil = const Value.absent(),
                Value<DateTime?> huntUntil = const Value.absent(),
                Value<double?> huntLatitude = const Value.absent(),
                Value<double?> huntLongitude = const Value.absent(),
                Value<int> huntCount = const Value.absent(),
                Value<String?> occupationJson = const Value.absent(),
                Value<double> speedKmh = const Value.absent(),
                Value<double> carriedKg = const Value.absent(),
                Value<double> pendingKcal = const Value.absent(),
                Value<double> pendingWaterMl = const Value.absent(),
                Value<int> dryStreakSeconds = const Value.absent(),
                Value<int> starvedStreakSeconds = const Value.absent(),
                Value<double> bodyMassKg = const Value.absent(),
                Value<double> sleepStrain = const Value.absent(),
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
                graceUntil: graceUntil,
                huntUntil: huntUntil,
                huntLatitude: huntLatitude,
                huntLongitude: huntLongitude,
                huntCount: huntCount,
                occupationJson: occupationJson,
                speedKmh: speedKmh,
                carriedKg: carriedKg,
                pendingKcal: pendingKcal,
                pendingWaterMl: pendingWaterMl,
                dryStreakSeconds: dryStreakSeconds,
                starvedStreakSeconds: starvedStreakSeconds,
                bodyMassKg: bodyMassKg,
                sleepStrain: sleepStrain,
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
                Value<DateTime?> graceUntil = const Value.absent(),
                Value<DateTime?> huntUntil = const Value.absent(),
                Value<double?> huntLatitude = const Value.absent(),
                Value<double?> huntLongitude = const Value.absent(),
                Value<int> huntCount = const Value.absent(),
                Value<String?> occupationJson = const Value.absent(),
                Value<double> speedKmh = const Value.absent(),
                Value<double> carriedKg = const Value.absent(),
                Value<double> pendingKcal = const Value.absent(),
                Value<double> pendingWaterMl = const Value.absent(),
                Value<int> dryStreakSeconds = const Value.absent(),
                Value<int> starvedStreakSeconds = const Value.absent(),
                Value<double> bodyMassKg = const Value.absent(),
                Value<double> sleepStrain = const Value.absent(),
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
                graceUntil: graceUntil,
                huntUntil: huntUntil,
                huntLatitude: huntLatitude,
                huntLongitude: huntLongitude,
                huntCount: huntCount,
                occupationJson: occupationJson,
                speedKmh: speedKmh,
                carriedKg: carriedKg,
                pendingKcal: pendingKcal,
                pendingWaterMl: pendingWaterMl,
                dryStreakSeconds: dryStreakSeconds,
                starvedStreakSeconds: starvedStreakSeconds,
                bodyMassKg: bodyMassKg,
                sleepStrain: sleepStrain,
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
      Value<int?> rounds,
      Value<int?> salvageSeconds,
      Value<String?> uid,
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
      Value<int?> rounds,
      Value<int?> salvageSeconds,
      Value<String?> uid,
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

  ColumnFilters<int> get rounds => $composableBuilder(
    column: $table.rounds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
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

  ColumnOrderings<int> get rounds => $composableBuilder(
    column: $table.rounds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
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

  GeneratedColumn<int> get rounds =>
      $composableBuilder(column: $table.rounds, builder: (column) => column);

  GeneratedColumn<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);
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
                Value<int?> rounds = const Value.absent(),
                Value<int?> salvageSeconds = const Value.absent(),
                Value<String?> uid = const Value.absent(),
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
                rounds: rounds,
                salvageSeconds: salvageSeconds,
                uid: uid,
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
                Value<int?> rounds = const Value.absent(),
                Value<int?> salvageSeconds = const Value.absent(),
                Value<String?> uid = const Value.absent(),
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
                rounds: rounds,
                salvageSeconds: salvageSeconds,
                uid: uid,
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
      Value<String> attachments,
      Value<int?> rounds,
      required double latitude,
      required double longitude,
      required DateTime droppedAt,
      Value<int?> salvageSeconds,
      Value<String?> uid,
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
      Value<String> attachments,
      Value<int?> rounds,
      Value<double> latitude,
      Value<double> longitude,
      Value<DateTime> droppedAt,
      Value<int?> salvageSeconds,
      Value<String?> uid,
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

  ColumnFilters<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rounds => $composableBuilder(
    column: $table.rounds,
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

  ColumnFilters<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
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

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rounds => $composableBuilder(
    column: $table.rounds,
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

  ColumnOrderings<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
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

  GeneratedColumn<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rounds =>
      $composableBuilder(column: $table.rounds, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get droppedAt =>
      $composableBuilder(column: $table.droppedAt, builder: (column) => column);

  GeneratedColumn<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);
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
                Value<String> attachments = const Value.absent(),
                Value<int?> rounds = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<DateTime> droppedAt = const Value.absent(),
                Value<int?> salvageSeconds = const Value.absent(),
                Value<String?> uid = const Value.absent(),
              }) => GroundItemsCompanion(
                id: id,
                profileId: profileId,
                itemId: itemId,
                count: count,
                condition: condition,
                pagesTotal: pagesTotal,
                pagesRead: pagesRead,
                attachments: attachments,
                rounds: rounds,
                latitude: latitude,
                longitude: longitude,
                droppedAt: droppedAt,
                salvageSeconds: salvageSeconds,
                uid: uid,
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
                Value<String> attachments = const Value.absent(),
                Value<int?> rounds = const Value.absent(),
                required double latitude,
                required double longitude,
                required DateTime droppedAt,
                Value<int?> salvageSeconds = const Value.absent(),
                Value<String?> uid = const Value.absent(),
              }) => GroundItemsCompanion.insert(
                id: id,
                profileId: profileId,
                itemId: itemId,
                count: count,
                condition: condition,
                pagesTotal: pagesTotal,
                pagesRead: pagesRead,
                attachments: attachments,
                rounds: rounds,
                latitude: latitude,
                longitude: longitude,
                droppedAt: droppedAt,
                salvageSeconds: salvageSeconds,
                uid: uid,
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
      Value<bool> paused,
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
      Value<bool> paused,
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

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
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

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
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

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);
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
                Value<bool> paused = const Value.absent(),
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
                paused: paused,
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
                Value<bool> paused = const Value.absent(),
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
                paused: paused,
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
typedef $$ProfileStatsTableCreateCompanionBuilder =
    ProfileStatsCompanion Function({
      Value<int> profileId,
      Value<int> shotsFired,
      Value<int> shotsHit,
      Value<int> swings,
      Value<int> swingsHit,
      Value<int> hitsHead,
      Value<int> hitsTorso,
      Value<int> hitsArms,
      Value<int> hitsLegs,
      Value<int> kills,
      Value<double> bloodDealtMl,
      Value<double> bloodLostMl,
      Value<int> searches,
      Value<int> blackouts,
    });
typedef $$ProfileStatsTableUpdateCompanionBuilder =
    ProfileStatsCompanion Function({
      Value<int> profileId,
      Value<int> shotsFired,
      Value<int> shotsHit,
      Value<int> swings,
      Value<int> swingsHit,
      Value<int> hitsHead,
      Value<int> hitsTorso,
      Value<int> hitsArms,
      Value<int> hitsLegs,
      Value<int> kills,
      Value<double> bloodDealtMl,
      Value<double> bloodLostMl,
      Value<int> searches,
      Value<int> blackouts,
    });

class $$ProfileStatsTableFilterComposer
    extends Composer<_$SaveDatabase, $ProfileStatsTable> {
  $$ProfileStatsTableFilterComposer({
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

  ColumnFilters<int> get shotsFired => $composableBuilder(
    column: $table.shotsFired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shotsHit => $composableBuilder(
    column: $table.shotsHit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get swings => $composableBuilder(
    column: $table.swings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get swingsHit => $composableBuilder(
    column: $table.swingsHit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hitsHead => $composableBuilder(
    column: $table.hitsHead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hitsTorso => $composableBuilder(
    column: $table.hitsTorso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hitsArms => $composableBuilder(
    column: $table.hitsArms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hitsLegs => $composableBuilder(
    column: $table.hitsLegs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kills => $composableBuilder(
    column: $table.kills,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bloodDealtMl => $composableBuilder(
    column: $table.bloodDealtMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bloodLostMl => $composableBuilder(
    column: $table.bloodLostMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get searches => $composableBuilder(
    column: $table.searches,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blackouts => $composableBuilder(
    column: $table.blackouts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileStatsTableOrderingComposer
    extends Composer<_$SaveDatabase, $ProfileStatsTable> {
  $$ProfileStatsTableOrderingComposer({
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

  ColumnOrderings<int> get shotsFired => $composableBuilder(
    column: $table.shotsFired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shotsHit => $composableBuilder(
    column: $table.shotsHit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get swings => $composableBuilder(
    column: $table.swings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get swingsHit => $composableBuilder(
    column: $table.swingsHit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hitsHead => $composableBuilder(
    column: $table.hitsHead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hitsTorso => $composableBuilder(
    column: $table.hitsTorso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hitsArms => $composableBuilder(
    column: $table.hitsArms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hitsLegs => $composableBuilder(
    column: $table.hitsLegs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kills => $composableBuilder(
    column: $table.kills,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bloodDealtMl => $composableBuilder(
    column: $table.bloodDealtMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bloodLostMl => $composableBuilder(
    column: $table.bloodLostMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get searches => $composableBuilder(
    column: $table.searches,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blackouts => $composableBuilder(
    column: $table.blackouts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileStatsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $ProfileStatsTable> {
  $$ProfileStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get shotsFired => $composableBuilder(
    column: $table.shotsFired,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shotsHit =>
      $composableBuilder(column: $table.shotsHit, builder: (column) => column);

  GeneratedColumn<int> get swings =>
      $composableBuilder(column: $table.swings, builder: (column) => column);

  GeneratedColumn<int> get swingsHit =>
      $composableBuilder(column: $table.swingsHit, builder: (column) => column);

  GeneratedColumn<int> get hitsHead =>
      $composableBuilder(column: $table.hitsHead, builder: (column) => column);

  GeneratedColumn<int> get hitsTorso =>
      $composableBuilder(column: $table.hitsTorso, builder: (column) => column);

  GeneratedColumn<int> get hitsArms =>
      $composableBuilder(column: $table.hitsArms, builder: (column) => column);

  GeneratedColumn<int> get hitsLegs =>
      $composableBuilder(column: $table.hitsLegs, builder: (column) => column);

  GeneratedColumn<int> get kills =>
      $composableBuilder(column: $table.kills, builder: (column) => column);

  GeneratedColumn<double> get bloodDealtMl => $composableBuilder(
    column: $table.bloodDealtMl,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bloodLostMl => $composableBuilder(
    column: $table.bloodLostMl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get searches =>
      $composableBuilder(column: $table.searches, builder: (column) => column);

  GeneratedColumn<int> get blackouts =>
      $composableBuilder(column: $table.blackouts, builder: (column) => column);
}

class $$ProfileStatsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $ProfileStatsTable,
          StatsRow,
          $$ProfileStatsTableFilterComposer,
          $$ProfileStatsTableOrderingComposer,
          $$ProfileStatsTableAnnotationComposer,
          $$ProfileStatsTableCreateCompanionBuilder,
          $$ProfileStatsTableUpdateCompanionBuilder,
          (
            StatsRow,
            BaseReferences<_$SaveDatabase, $ProfileStatsTable, StatsRow>,
          ),
          StatsRow,
          PrefetchHooks Function()
        > {
  $$ProfileStatsTableTableManager(_$SaveDatabase db, $ProfileStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<int> shotsFired = const Value.absent(),
                Value<int> shotsHit = const Value.absent(),
                Value<int> swings = const Value.absent(),
                Value<int> swingsHit = const Value.absent(),
                Value<int> hitsHead = const Value.absent(),
                Value<int> hitsTorso = const Value.absent(),
                Value<int> hitsArms = const Value.absent(),
                Value<int> hitsLegs = const Value.absent(),
                Value<int> kills = const Value.absent(),
                Value<double> bloodDealtMl = const Value.absent(),
                Value<double> bloodLostMl = const Value.absent(),
                Value<int> searches = const Value.absent(),
                Value<int> blackouts = const Value.absent(),
              }) => ProfileStatsCompanion(
                profileId: profileId,
                shotsFired: shotsFired,
                shotsHit: shotsHit,
                swings: swings,
                swingsHit: swingsHit,
                hitsHead: hitsHead,
                hitsTorso: hitsTorso,
                hitsArms: hitsArms,
                hitsLegs: hitsLegs,
                kills: kills,
                bloodDealtMl: bloodDealtMl,
                bloodLostMl: bloodLostMl,
                searches: searches,
                blackouts: blackouts,
              ),
          createCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<int> shotsFired = const Value.absent(),
                Value<int> shotsHit = const Value.absent(),
                Value<int> swings = const Value.absent(),
                Value<int> swingsHit = const Value.absent(),
                Value<int> hitsHead = const Value.absent(),
                Value<int> hitsTorso = const Value.absent(),
                Value<int> hitsArms = const Value.absent(),
                Value<int> hitsLegs = const Value.absent(),
                Value<int> kills = const Value.absent(),
                Value<double> bloodDealtMl = const Value.absent(),
                Value<double> bloodLostMl = const Value.absent(),
                Value<int> searches = const Value.absent(),
                Value<int> blackouts = const Value.absent(),
              }) => ProfileStatsCompanion.insert(
                profileId: profileId,
                shotsFired: shotsFired,
                shotsHit: shotsHit,
                swings: swings,
                swingsHit: swingsHit,
                hitsHead: hitsHead,
                hitsTorso: hitsTorso,
                hitsArms: hitsArms,
                hitsLegs: hitsLegs,
                kills: kills,
                bloodDealtMl: bloodDealtMl,
                bloodLostMl: bloodLostMl,
                searches: searches,
                blackouts: blackouts,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $ProfileStatsTable,
      StatsRow,
      $$ProfileStatsTableFilterComposer,
      $$ProfileStatsTableOrderingComposer,
      $$ProfileStatsTableAnnotationComposer,
      $$ProfileStatsTableCreateCompanionBuilder,
      $$ProfileStatsTableUpdateCompanionBuilder,
      (StatsRow, BaseReferences<_$SaveDatabase, $ProfileStatsTable, StatsRow>),
      StatsRow,
      PrefetchHooks Function()
    >;
typedef $$ShelterItemsTableCreateCompanionBuilder =
    ShelterItemsCompanion Function({
      Value<int> id,
      required int profileId,
      required int shelterId,
      required String itemId,
      Value<int> count,
      Value<double?> condition,
      Value<int?> pagesTotal,
      Value<int> pagesRead,
      Value<String?> noteId,
      Value<double> portion,
      Value<String> attachments,
      Value<int?> rounds,
      Value<int?> salvageSeconds,
      Value<String?> uid,
    });
typedef $$ShelterItemsTableUpdateCompanionBuilder =
    ShelterItemsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<int> shelterId,
      Value<String> itemId,
      Value<int> count,
      Value<double?> condition,
      Value<int?> pagesTotal,
      Value<int> pagesRead,
      Value<String?> noteId,
      Value<double> portion,
      Value<String> attachments,
      Value<int?> rounds,
      Value<int?> salvageSeconds,
      Value<String?> uid,
    });

class $$ShelterItemsTableFilterComposer
    extends Composer<_$SaveDatabase, $ShelterItemsTable> {
  $$ShelterItemsTableFilterComposer({
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

  ColumnFilters<int> get shelterId => $composableBuilder(
    column: $table.shelterId,
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

  ColumnFilters<int> get rounds => $composableBuilder(
    column: $table.rounds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShelterItemsTableOrderingComposer
    extends Composer<_$SaveDatabase, $ShelterItemsTable> {
  $$ShelterItemsTableOrderingComposer({
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

  ColumnOrderings<int> get shelterId => $composableBuilder(
    column: $table.shelterId,
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

  ColumnOrderings<int> get rounds => $composableBuilder(
    column: $table.rounds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShelterItemsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $ShelterItemsTable> {
  $$ShelterItemsTableAnnotationComposer({
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

  GeneratedColumn<int> get shelterId =>
      $composableBuilder(column: $table.shelterId, builder: (column) => column);

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

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<double> get portion =>
      $composableBuilder(column: $table.portion, builder: (column) => column);

  GeneratedColumn<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rounds =>
      $composableBuilder(column: $table.rounds, builder: (column) => column);

  GeneratedColumn<int> get salvageSeconds => $composableBuilder(
    column: $table.salvageSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);
}

class $$ShelterItemsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $ShelterItemsTable,
          StashRow,
          $$ShelterItemsTableFilterComposer,
          $$ShelterItemsTableOrderingComposer,
          $$ShelterItemsTableAnnotationComposer,
          $$ShelterItemsTableCreateCompanionBuilder,
          $$ShelterItemsTableUpdateCompanionBuilder,
          (
            StashRow,
            BaseReferences<_$SaveDatabase, $ShelterItemsTable, StashRow>,
          ),
          StashRow,
          PrefetchHooks Function()
        > {
  $$ShelterItemsTableTableManager(_$SaveDatabase db, $ShelterItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShelterItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShelterItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShelterItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> shelterId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<double?> condition = const Value.absent(),
                Value<int?> pagesTotal = const Value.absent(),
                Value<int> pagesRead = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<double> portion = const Value.absent(),
                Value<String> attachments = const Value.absent(),
                Value<int?> rounds = const Value.absent(),
                Value<int?> salvageSeconds = const Value.absent(),
                Value<String?> uid = const Value.absent(),
              }) => ShelterItemsCompanion(
                id: id,
                profileId: profileId,
                shelterId: shelterId,
                itemId: itemId,
                count: count,
                condition: condition,
                pagesTotal: pagesTotal,
                pagesRead: pagesRead,
                noteId: noteId,
                portion: portion,
                attachments: attachments,
                rounds: rounds,
                salvageSeconds: salvageSeconds,
                uid: uid,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required int shelterId,
                required String itemId,
                Value<int> count = const Value.absent(),
                Value<double?> condition = const Value.absent(),
                Value<int?> pagesTotal = const Value.absent(),
                Value<int> pagesRead = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<double> portion = const Value.absent(),
                Value<String> attachments = const Value.absent(),
                Value<int?> rounds = const Value.absent(),
                Value<int?> salvageSeconds = const Value.absent(),
                Value<String?> uid = const Value.absent(),
              }) => ShelterItemsCompanion.insert(
                id: id,
                profileId: profileId,
                shelterId: shelterId,
                itemId: itemId,
                count: count,
                condition: condition,
                pagesTotal: pagesTotal,
                pagesRead: pagesRead,
                noteId: noteId,
                portion: portion,
                attachments: attachments,
                rounds: rounds,
                salvageSeconds: salvageSeconds,
                uid: uid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShelterItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $ShelterItemsTable,
      StashRow,
      $$ShelterItemsTableFilterComposer,
      $$ShelterItemsTableOrderingComposer,
      $$ShelterItemsTableAnnotationComposer,
      $$ShelterItemsTableCreateCompanionBuilder,
      $$ShelterItemsTableUpdateCompanionBuilder,
      (StashRow, BaseReferences<_$SaveDatabase, $ShelterItemsTable, StashRow>),
      StashRow,
      PrefetchHooks Function()
    >;
typedef $$CraftJobsTableCreateCompanionBuilder =
    CraftJobsCompanion Function({
      Value<int> id,
      required int profileId,
      Value<String?> recipeId,
      Value<String?> salvageItemId,
      Value<double?> salvageCondition,
      Value<String?> salvageBatch,
      required DateTime startedAt,
      required DateTime readyAt,
    });
typedef $$CraftJobsTableUpdateCompanionBuilder =
    CraftJobsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String?> recipeId,
      Value<String?> salvageItemId,
      Value<double?> salvageCondition,
      Value<String?> salvageBatch,
      Value<DateTime> startedAt,
      Value<DateTime> readyAt,
    });

class $$CraftJobsTableFilterComposer
    extends Composer<_$SaveDatabase, $CraftJobsTable> {
  $$CraftJobsTableFilterComposer({
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

  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salvageItemId => $composableBuilder(
    column: $table.salvageItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salvageCondition => $composableBuilder(
    column: $table.salvageCondition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salvageBatch => $composableBuilder(
    column: $table.salvageBatch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readyAt => $composableBuilder(
    column: $table.readyAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CraftJobsTableOrderingComposer
    extends Composer<_$SaveDatabase, $CraftJobsTable> {
  $$CraftJobsTableOrderingComposer({
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

  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salvageItemId => $composableBuilder(
    column: $table.salvageItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salvageCondition => $composableBuilder(
    column: $table.salvageCondition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salvageBatch => $composableBuilder(
    column: $table.salvageBatch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readyAt => $composableBuilder(
    column: $table.readyAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CraftJobsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $CraftJobsTable> {
  $$CraftJobsTableAnnotationComposer({
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

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get salvageItemId => $composableBuilder(
    column: $table.salvageItemId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get salvageCondition => $composableBuilder(
    column: $table.salvageCondition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salvageBatch => $composableBuilder(
    column: $table.salvageBatch,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readyAt =>
      $composableBuilder(column: $table.readyAt, builder: (column) => column);
}

class $$CraftJobsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $CraftJobsTable,
          CraftJobRow,
          $$CraftJobsTableFilterComposer,
          $$CraftJobsTableOrderingComposer,
          $$CraftJobsTableAnnotationComposer,
          $$CraftJobsTableCreateCompanionBuilder,
          $$CraftJobsTableUpdateCompanionBuilder,
          (
            CraftJobRow,
            BaseReferences<_$SaveDatabase, $CraftJobsTable, CraftJobRow>,
          ),
          CraftJobRow,
          PrefetchHooks Function()
        > {
  $$CraftJobsTableTableManager(_$SaveDatabase db, $CraftJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CraftJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CraftJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CraftJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String?> recipeId = const Value.absent(),
                Value<String?> salvageItemId = const Value.absent(),
                Value<double?> salvageCondition = const Value.absent(),
                Value<String?> salvageBatch = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> readyAt = const Value.absent(),
              }) => CraftJobsCompanion(
                id: id,
                profileId: profileId,
                recipeId: recipeId,
                salvageItemId: salvageItemId,
                salvageCondition: salvageCondition,
                salvageBatch: salvageBatch,
                startedAt: startedAt,
                readyAt: readyAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                Value<String?> recipeId = const Value.absent(),
                Value<String?> salvageItemId = const Value.absent(),
                Value<double?> salvageCondition = const Value.absent(),
                Value<String?> salvageBatch = const Value.absent(),
                required DateTime startedAt,
                required DateTime readyAt,
              }) => CraftJobsCompanion.insert(
                id: id,
                profileId: profileId,
                recipeId: recipeId,
                salvageItemId: salvageItemId,
                salvageCondition: salvageCondition,
                salvageBatch: salvageBatch,
                startedAt: startedAt,
                readyAt: readyAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CraftJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $CraftJobsTable,
      CraftJobRow,
      $$CraftJobsTableFilterComposer,
      $$CraftJobsTableOrderingComposer,
      $$CraftJobsTableAnnotationComposer,
      $$CraftJobsTableCreateCompanionBuilder,
      $$CraftJobsTableUpdateCompanionBuilder,
      (
        CraftJobRow,
        BaseReferences<_$SaveDatabase, $CraftJobsTable, CraftJobRow>,
      ),
      CraftJobRow,
      PrefetchHooks Function()
    >;
typedef $$ActiveActionsTableCreateCompanionBuilder =
    ActiveActionsCompanion Function({
      Value<int> id,
      required int profileId,
      required String kind,
      Value<String?> subjectUid,
      required DateTime startedAt,
      required int totalSeconds,
      Value<int> creditedSeconds,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> extraJson,
    });
typedef $$ActiveActionsTableUpdateCompanionBuilder =
    ActiveActionsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> kind,
      Value<String?> subjectUid,
      Value<DateTime> startedAt,
      Value<int> totalSeconds,
      Value<int> creditedSeconds,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> extraJson,
    });

class $$ActiveActionsTableFilterComposer
    extends Composer<_$SaveDatabase, $ActiveActionsTable> {
  $$ActiveActionsTableFilterComposer({
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

  ColumnFilters<String> get subjectUid => $composableBuilder(
    column: $table.subjectUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditedSeconds => $composableBuilder(
    column: $table.creditedSeconds,
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

  ColumnFilters<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActiveActionsTableOrderingComposer
    extends Composer<_$SaveDatabase, $ActiveActionsTable> {
  $$ActiveActionsTableOrderingComposer({
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

  ColumnOrderings<String> get subjectUid => $composableBuilder(
    column: $table.subjectUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditedSeconds => $composableBuilder(
    column: $table.creditedSeconds,
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

  ColumnOrderings<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActiveActionsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $ActiveActionsTable> {
  $$ActiveActionsTableAnnotationComposer({
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

  GeneratedColumn<String> get subjectUid => $composableBuilder(
    column: $table.subjectUid,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditedSeconds => $composableBuilder(
    column: $table.creditedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get extraJson =>
      $composableBuilder(column: $table.extraJson, builder: (column) => column);
}

class $$ActiveActionsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $ActiveActionsTable,
          ActiveActionRow,
          $$ActiveActionsTableFilterComposer,
          $$ActiveActionsTableOrderingComposer,
          $$ActiveActionsTableAnnotationComposer,
          $$ActiveActionsTableCreateCompanionBuilder,
          $$ActiveActionsTableUpdateCompanionBuilder,
          (
            ActiveActionRow,
            BaseReferences<
              _$SaveDatabase,
              $ActiveActionsTable,
              ActiveActionRow
            >,
          ),
          ActiveActionRow,
          PrefetchHooks Function()
        > {
  $$ActiveActionsTableTableManager(_$SaveDatabase db, $ActiveActionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActiveActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> subjectUid = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> totalSeconds = const Value.absent(),
                Value<int> creditedSeconds = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> extraJson = const Value.absent(),
              }) => ActiveActionsCompanion(
                id: id,
                profileId: profileId,
                kind: kind,
                subjectUid: subjectUid,
                startedAt: startedAt,
                totalSeconds: totalSeconds,
                creditedSeconds: creditedSeconds,
                latitude: latitude,
                longitude: longitude,
                extraJson: extraJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String kind,
                Value<String?> subjectUid = const Value.absent(),
                required DateTime startedAt,
                required int totalSeconds,
                Value<int> creditedSeconds = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> extraJson = const Value.absent(),
              }) => ActiveActionsCompanion.insert(
                id: id,
                profileId: profileId,
                kind: kind,
                subjectUid: subjectUid,
                startedAt: startedAt,
                totalSeconds: totalSeconds,
                creditedSeconds: creditedSeconds,
                latitude: latitude,
                longitude: longitude,
                extraJson: extraJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActiveActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $ActiveActionsTable,
      ActiveActionRow,
      $$ActiveActionsTableFilterComposer,
      $$ActiveActionsTableOrderingComposer,
      $$ActiveActionsTableAnnotationComposer,
      $$ActiveActionsTableCreateCompanionBuilder,
      $$ActiveActionsTableUpdateCompanionBuilder,
      (
        ActiveActionRow,
        BaseReferences<_$SaveDatabase, $ActiveActionsTable, ActiveActionRow>,
      ),
      ActiveActionRow,
      PrefetchHooks Function()
    >;
typedef $$SkillRowsTableCreateCompanionBuilder =
    SkillRowsCompanion Function({
      required int profileId,
      required String skill,
      Value<int> xp,
      Value<int> rowid,
    });
typedef $$SkillRowsTableUpdateCompanionBuilder =
    SkillRowsCompanion Function({
      Value<int> profileId,
      Value<String> skill,
      Value<int> xp,
      Value<int> rowid,
    });

class $$SkillRowsTableFilterComposer
    extends Composer<_$SaveDatabase, $SkillRowsTable> {
  $$SkillRowsTableFilterComposer({
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

  ColumnFilters<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SkillRowsTableOrderingComposer
    extends Composer<_$SaveDatabase, $SkillRowsTable> {
  $$SkillRowsTableOrderingComposer({
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

  ColumnOrderings<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SkillRowsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $SkillRowsTable> {
  $$SkillRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get skill =>
      $composableBuilder(column: $table.skill, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);
}

class $$SkillRowsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $SkillRowsTable,
          SkillRow,
          $$SkillRowsTableFilterComposer,
          $$SkillRowsTableOrderingComposer,
          $$SkillRowsTableAnnotationComposer,
          $$SkillRowsTableCreateCompanionBuilder,
          $$SkillRowsTableUpdateCompanionBuilder,
          (SkillRow, BaseReferences<_$SaveDatabase, $SkillRowsTable, SkillRow>),
          SkillRow,
          PrefetchHooks Function()
        > {
  $$SkillRowsTableTableManager(_$SaveDatabase db, $SkillRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkillRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkillRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkillRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> skill = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillRowsCompanion(
                profileId: profileId,
                skill: skill,
                xp: xp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String skill,
                Value<int> xp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillRowsCompanion.insert(
                profileId: profileId,
                skill: skill,
                xp: xp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SkillRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $SkillRowsTable,
      SkillRow,
      $$SkillRowsTableFilterComposer,
      $$SkillRowsTableOrderingComposer,
      $$SkillRowsTableAnnotationComposer,
      $$SkillRowsTableCreateCompanionBuilder,
      $$SkillRowsTableUpdateCompanionBuilder,
      (SkillRow, BaseReferences<_$SaveDatabase, $SkillRowsTable, SkillRow>),
      SkillRow,
      PrefetchHooks Function()
    >;
typedef $$HotspotRowsTableCreateCompanionBuilder =
    HotspotRowsCompanion Function({
      required int profileId,
      required int slot,
      required int seed,
      required double latitude,
      required double longitude,
      required int level,
      required double integrity,
      required DateTime bornAt,
      required DateTime nextLevelAt,
      Value<DateTime?> agitatedUntil,
      Value<DateTime?> restingUntil,
      Value<int> rowid,
    });
typedef $$HotspotRowsTableUpdateCompanionBuilder =
    HotspotRowsCompanion Function({
      Value<int> profileId,
      Value<int> slot,
      Value<int> seed,
      Value<double> latitude,
      Value<double> longitude,
      Value<int> level,
      Value<double> integrity,
      Value<DateTime> bornAt,
      Value<DateTime> nextLevelAt,
      Value<DateTime?> agitatedUntil,
      Value<DateTime?> restingUntil,
      Value<int> rowid,
    });

class $$HotspotRowsTableFilterComposer
    extends Composer<_$SaveDatabase, $HotspotRowsTable> {
  $$HotspotRowsTableFilterComposer({
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

  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
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

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get integrity => $composableBuilder(
    column: $table.integrity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get bornAt => $composableBuilder(
    column: $table.bornAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextLevelAt => $composableBuilder(
    column: $table.nextLevelAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get agitatedUntil => $composableBuilder(
    column: $table.agitatedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get restingUntil => $composableBuilder(
    column: $table.restingUntil,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HotspotRowsTableOrderingComposer
    extends Composer<_$SaveDatabase, $HotspotRowsTable> {
  $$HotspotRowsTableOrderingComposer({
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

  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
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

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get integrity => $composableBuilder(
    column: $table.integrity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get bornAt => $composableBuilder(
    column: $table.bornAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextLevelAt => $composableBuilder(
    column: $table.nextLevelAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get agitatedUntil => $composableBuilder(
    column: $table.agitatedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get restingUntil => $composableBuilder(
    column: $table.restingUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HotspotRowsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $HotspotRowsTable> {
  $$HotspotRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<double> get integrity =>
      $composableBuilder(column: $table.integrity, builder: (column) => column);

  GeneratedColumn<DateTime> get bornAt =>
      $composableBuilder(column: $table.bornAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextLevelAt => $composableBuilder(
    column: $table.nextLevelAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get agitatedUntil => $composableBuilder(
    column: $table.agitatedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get restingUntil => $composableBuilder(
    column: $table.restingUntil,
    builder: (column) => column,
  );
}

class $$HotspotRowsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $HotspotRowsTable,
          HotspotRow,
          $$HotspotRowsTableFilterComposer,
          $$HotspotRowsTableOrderingComposer,
          $$HotspotRowsTableAnnotationComposer,
          $$HotspotRowsTableCreateCompanionBuilder,
          $$HotspotRowsTableUpdateCompanionBuilder,
          (
            HotspotRow,
            BaseReferences<_$SaveDatabase, $HotspotRowsTable, HotspotRow>,
          ),
          HotspotRow,
          PrefetchHooks Function()
        > {
  $$HotspotRowsTableTableManager(_$SaveDatabase db, $HotspotRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HotspotRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HotspotRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HotspotRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<int> slot = const Value.absent(),
                Value<int> seed = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<double> integrity = const Value.absent(),
                Value<DateTime> bornAt = const Value.absent(),
                Value<DateTime> nextLevelAt = const Value.absent(),
                Value<DateTime?> agitatedUntil = const Value.absent(),
                Value<DateTime?> restingUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HotspotRowsCompanion(
                profileId: profileId,
                slot: slot,
                seed: seed,
                latitude: latitude,
                longitude: longitude,
                level: level,
                integrity: integrity,
                bornAt: bornAt,
                nextLevelAt: nextLevelAt,
                agitatedUntil: agitatedUntil,
                restingUntil: restingUntil,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required int slot,
                required int seed,
                required double latitude,
                required double longitude,
                required int level,
                required double integrity,
                required DateTime bornAt,
                required DateTime nextLevelAt,
                Value<DateTime?> agitatedUntil = const Value.absent(),
                Value<DateTime?> restingUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HotspotRowsCompanion.insert(
                profileId: profileId,
                slot: slot,
                seed: seed,
                latitude: latitude,
                longitude: longitude,
                level: level,
                integrity: integrity,
                bornAt: bornAt,
                nextLevelAt: nextLevelAt,
                agitatedUntil: agitatedUntil,
                restingUntil: restingUntil,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HotspotRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $HotspotRowsTable,
      HotspotRow,
      $$HotspotRowsTableFilterComposer,
      $$HotspotRowsTableOrderingComposer,
      $$HotspotRowsTableAnnotationComposer,
      $$HotspotRowsTableCreateCompanionBuilder,
      $$HotspotRowsTableUpdateCompanionBuilder,
      (
        HotspotRow,
        BaseReferences<_$SaveDatabase, $HotspotRowsTable, HotspotRow>,
      ),
      HotspotRow,
      PrefetchHooks Function()
    >;
typedef $$JournalRowsTableCreateCompanionBuilder =
    JournalRowsCompanion Function({
      Value<int> id,
      required int profileId,
      required DateTime at,
      required String kind,
      Value<String?> subject,
    });
typedef $$JournalRowsTableUpdateCompanionBuilder =
    JournalRowsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<DateTime> at,
      Value<String> kind,
      Value<String?> subject,
    });

class $$JournalRowsTableFilterComposer
    extends Composer<_$SaveDatabase, $JournalRowsTable> {
  $$JournalRowsTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalRowsTableOrderingComposer
    extends Composer<_$SaveDatabase, $JournalRowsTable> {
  $$JournalRowsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalRowsTableAnnotationComposer
    extends Composer<_$SaveDatabase, $JournalRowsTable> {
  $$JournalRowsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);
}

class $$JournalRowsTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $JournalRowsTable,
          JournalRow,
          $$JournalRowsTableFilterComposer,
          $$JournalRowsTableOrderingComposer,
          $$JournalRowsTableAnnotationComposer,
          $$JournalRowsTableCreateCompanionBuilder,
          $$JournalRowsTableUpdateCompanionBuilder,
          (
            JournalRow,
            BaseReferences<_$SaveDatabase, $JournalRowsTable, JournalRow>,
          ),
          JournalRow,
          PrefetchHooks Function()
        > {
  $$JournalRowsTableTableManager(_$SaveDatabase db, $JournalRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> subject = const Value.absent(),
              }) => JournalRowsCompanion(
                id: id,
                profileId: profileId,
                at: at,
                kind: kind,
                subject: subject,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required DateTime at,
                required String kind,
                Value<String?> subject = const Value.absent(),
              }) => JournalRowsCompanion.insert(
                id: id,
                profileId: profileId,
                at: at,
                kind: kind,
                subject: subject,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $JournalRowsTable,
      JournalRow,
      $$JournalRowsTableFilterComposer,
      $$JournalRowsTableOrderingComposer,
      $$JournalRowsTableAnnotationComposer,
      $$JournalRowsTableCreateCompanionBuilder,
      $$JournalRowsTableUpdateCompanionBuilder,
      (
        JournalRow,
        BaseReferences<_$SaveDatabase, $JournalRowsTable, JournalRow>,
      ),
      JournalRow,
      PrefetchHooks Function()
    >;
typedef $$ReadTitlesTableCreateCompanionBuilder =
    ReadTitlesCompanion Function({
      required int profileId,
      required String itemId,
      Value<int> copies,
      Value<int> rowid,
    });
typedef $$ReadTitlesTableUpdateCompanionBuilder =
    ReadTitlesCompanion Function({
      Value<int> profileId,
      Value<String> itemId,
      Value<int> copies,
      Value<int> rowid,
    });

class $$ReadTitlesTableFilterComposer
    extends Composer<_$SaveDatabase, $ReadTitlesTable> {
  $$ReadTitlesTableFilterComposer({
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

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get copies => $composableBuilder(
    column: $table.copies,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadTitlesTableOrderingComposer
    extends Composer<_$SaveDatabase, $ReadTitlesTable> {
  $$ReadTitlesTableOrderingComposer({
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

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get copies => $composableBuilder(
    column: $table.copies,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadTitlesTableAnnotationComposer
    extends Composer<_$SaveDatabase, $ReadTitlesTable> {
  $$ReadTitlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get copies =>
      $composableBuilder(column: $table.copies, builder: (column) => column);
}

class $$ReadTitlesTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $ReadTitlesTable,
          ReadTitle,
          $$ReadTitlesTableFilterComposer,
          $$ReadTitlesTableOrderingComposer,
          $$ReadTitlesTableAnnotationComposer,
          $$ReadTitlesTableCreateCompanionBuilder,
          $$ReadTitlesTableUpdateCompanionBuilder,
          (
            ReadTitle,
            BaseReferences<_$SaveDatabase, $ReadTitlesTable, ReadTitle>,
          ),
          ReadTitle,
          PrefetchHooks Function()
        > {
  $$ReadTitlesTableTableManager(_$SaveDatabase db, $ReadTitlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadTitlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadTitlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadTitlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> copies = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadTitlesCompanion(
                profileId: profileId,
                itemId: itemId,
                copies: copies,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String itemId,
                Value<int> copies = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadTitlesCompanion.insert(
                profileId: profileId,
                itemId: itemId,
                copies: copies,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadTitlesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $ReadTitlesTable,
      ReadTitle,
      $$ReadTitlesTableFilterComposer,
      $$ReadTitlesTableOrderingComposer,
      $$ReadTitlesTableAnnotationComposer,
      $$ReadTitlesTableCreateCompanionBuilder,
      $$ReadTitlesTableUpdateCompanionBuilder,
      (ReadTitle, BaseReferences<_$SaveDatabase, $ReadTitlesTable, ReadTitle>),
      ReadTitle,
      PrefetchHooks Function()
    >;
typedef $$PlayDaysTableCreateCompanionBuilder =
    PlayDaysCompanion Function({
      required int profileId,
      required String day,
      Value<int> activeMinutes,
      Value<int> rowid,
    });
typedef $$PlayDaysTableUpdateCompanionBuilder =
    PlayDaysCompanion Function({
      Value<int> profileId,
      Value<String> day,
      Value<int> activeMinutes,
      Value<int> rowid,
    });

class $$PlayDaysTableFilterComposer
    extends Composer<_$SaveDatabase, $PlayDaysTable> {
  $$PlayDaysTableFilterComposer({
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

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayDaysTableOrderingComposer
    extends Composer<_$SaveDatabase, $PlayDaysTable> {
  $$PlayDaysTableOrderingComposer({
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

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayDaysTableAnnotationComposer
    extends Composer<_$SaveDatabase, $PlayDaysTable> {
  $$PlayDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => column,
  );
}

class $$PlayDaysTableTableManager
    extends
        RootTableManager<
          _$SaveDatabase,
          $PlayDaysTable,
          PlayDayRow,
          $$PlayDaysTableFilterComposer,
          $$PlayDaysTableOrderingComposer,
          $$PlayDaysTableAnnotationComposer,
          $$PlayDaysTableCreateCompanionBuilder,
          $$PlayDaysTableUpdateCompanionBuilder,
          (
            PlayDayRow,
            BaseReferences<_$SaveDatabase, $PlayDaysTable, PlayDayRow>,
          ),
          PlayDayRow,
          PrefetchHooks Function()
        > {
  $$PlayDaysTableTableManager(_$SaveDatabase db, $PlayDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> activeMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayDaysCompanion(
                profileId: profileId,
                day: day,
                activeMinutes: activeMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String day,
                Value<int> activeMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayDaysCompanion.insert(
                profileId: profileId,
                day: day,
                activeMinutes: activeMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$SaveDatabase,
      $PlayDaysTable,
      PlayDayRow,
      $$PlayDaysTableFilterComposer,
      $$PlayDaysTableOrderingComposer,
      $$PlayDaysTableAnnotationComposer,
      $$PlayDaysTableCreateCompanionBuilder,
      $$PlayDaysTableUpdateCompanionBuilder,
      (PlayDayRow, BaseReferences<_$SaveDatabase, $PlayDaysTable, PlayDayRow>),
      PlayDayRow,
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
  $$ProfileStatsTableTableManager get profileStats =>
      $$ProfileStatsTableTableManager(_db, _db.profileStats);
  $$ShelterItemsTableTableManager get shelterItems =>
      $$ShelterItemsTableTableManager(_db, _db.shelterItems);
  $$CraftJobsTableTableManager get craftJobs =>
      $$CraftJobsTableTableManager(_db, _db.craftJobs);
  $$ActiveActionsTableTableManager get activeActions =>
      $$ActiveActionsTableTableManager(_db, _db.activeActions);
  $$SkillRowsTableTableManager get skillRows =>
      $$SkillRowsTableTableManager(_db, _db.skillRows);
  $$HotspotRowsTableTableManager get hotspotRows =>
      $$HotspotRowsTableTableManager(_db, _db.hotspotRows);
  $$JournalRowsTableTableManager get journalRows =>
      $$JournalRowsTableTableManager(_db, _db.journalRows);
  $$ReadTitlesTableTableManager get readTitles =>
      $$ReadTitlesTableTableManager(_db, _db.readTitles);
  $$PlayDaysTableTableManager get playDays =>
      $$PlayDaysTableTableManager(_db, _db.playDays);
}
