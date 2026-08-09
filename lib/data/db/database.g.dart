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
          ..write('rngCursors: $rngCursors')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  );
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
          other.rngCursors == this.rngCursors);
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
          ..write('rngCursors: $rngCursors')
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
}
