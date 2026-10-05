// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VenuesTable extends Venues with TableInfo<$VenuesTable, VenueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VenuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 2),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 120),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _reportNameMeta =
      const VerificationMeta('reportName');
  @override
  late final GeneratedColumn<String> reportName = GeneratedColumn<String>(
      'report_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Моё заведение'));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 8),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _logoPathMeta =
      const VerificationMeta('logoPath');
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
      'logo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _showShiftDessertsMeta =
      const VerificationMeta('showShiftDesserts');
  @override
  late final GeneratedColumn<bool> showShiftDesserts = GeneratedColumn<bool>(
      'show_shift_desserts', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_shift_desserts" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        code,
        name,
        reportName,
        currency,
        logoPath,
        showShiftDesserts
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'venues';
  @override
  VerificationContext validateIntegrity(Insertable<VenueRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('report_name')) {
      context.handle(
          _reportNameMeta,
          reportName.isAcceptableOrUnknown(
              data['report_name']!, _reportNameMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('logo_path')) {
      context.handle(_logoPathMeta,
          logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta));
    }
    if (data.containsKey('show_shift_desserts')) {
      context.handle(
          _showShiftDessertsMeta,
          showShiftDesserts.isAcceptableOrUnknown(
              data['show_shift_desserts']!, _showShiftDessertsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VenueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VenueRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      reportName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}report_name'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      logoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_path']),
      showShiftDesserts: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}show_shift_desserts'])!,
    );
  }

  @override
  $VenuesTable createAlias(String alias) {
    return $VenuesTable(attachedDatabase, alias);
  }
}

class VenueRow extends DataClass implements Insertable<VenueRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Двузначный код для входа по PIN ('01'..'05').
  final String code;

  /// Название в списке заведений.
  final String name;

  /// Название, которое печатается в заявках и отчётах.
  final String reportName;
  final String currency;
  final String? logoPath;
  final bool showShiftDesserts;
  const VenueRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.code,
      required this.name,
      required this.reportName,
      required this.currency,
      this.logoPath,
      required this.showShiftDesserts});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['report_name'] = Variable<String>(reportName);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    map['show_shift_desserts'] = Variable<bool>(showShiftDesserts);
    return map;
  }

  VenuesCompanion toCompanion(bool nullToAbsent) {
    return VenuesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      code: Value(code),
      name: Value(name),
      reportName: Value(reportName),
      currency: Value(currency),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      showShiftDesserts: Value(showShiftDesserts),
    );
  }

  factory VenueRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VenueRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      reportName: serializer.fromJson<String>(json['reportName']),
      currency: serializer.fromJson<String>(json['currency']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      showShiftDesserts: serializer.fromJson<bool>(json['showShiftDesserts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'reportName': serializer.toJson<String>(reportName),
      'currency': serializer.toJson<String>(currency),
      'logoPath': serializer.toJson<String?>(logoPath),
      'showShiftDesserts': serializer.toJson<bool>(showShiftDesserts),
    };
  }

  VenueRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? code,
          String? name,
          String? reportName,
          String? currency,
          Value<String?> logoPath = const Value.absent(),
          bool? showShiftDesserts}) =>
      VenueRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        code: code ?? this.code,
        name: name ?? this.name,
        reportName: reportName ?? this.reportName,
        currency: currency ?? this.currency,
        logoPath: logoPath.present ? logoPath.value : this.logoPath,
        showShiftDesserts: showShiftDesserts ?? this.showShiftDesserts,
      );
  VenueRow copyWithCompanion(VenuesCompanion data) {
    return VenueRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      reportName:
          data.reportName.present ? data.reportName.value : this.reportName,
      currency: data.currency.present ? data.currency.value : this.currency,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      showShiftDesserts: data.showShiftDesserts.present
          ? data.showShiftDesserts.value
          : this.showShiftDesserts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VenueRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('reportName: $reportName, ')
          ..write('currency: $currency, ')
          ..write('logoPath: $logoPath, ')
          ..write('showShiftDesserts: $showShiftDesserts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, code,
      name, reportName, currency, logoPath, showShiftDesserts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VenueRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.code == this.code &&
          other.name == this.name &&
          other.reportName == this.reportName &&
          other.currency == this.currency &&
          other.logoPath == this.logoPath &&
          other.showShiftDesserts == this.showShiftDesserts);
}

class VenuesCompanion extends UpdateCompanion<VenueRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> code;
  final Value<String> name;
  final Value<String> reportName;
  final Value<String> currency;
  final Value<String?> logoPath;
  final Value<bool> showShiftDesserts;
  final Value<int> rowid;
  const VenuesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.reportName = const Value.absent(),
    this.currency = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.showShiftDesserts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VenuesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String code,
    required String name,
    this.reportName = const Value.absent(),
    required String currency,
    this.logoPath = const Value.absent(),
    this.showShiftDesserts = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        code = Value(code),
        name = Value(name),
        currency = Value(currency);
  static Insertable<VenueRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? reportName,
    Expression<String>? currency,
    Expression<String>? logoPath,
    Expression<bool>? showShiftDesserts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (reportName != null) 'report_name': reportName,
      if (currency != null) 'currency': currency,
      if (logoPath != null) 'logo_path': logoPath,
      if (showShiftDesserts != null) 'show_shift_desserts': showShiftDesserts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VenuesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? code,
      Value<String>? name,
      Value<String>? reportName,
      Value<String>? currency,
      Value<String?>? logoPath,
      Value<bool>? showShiftDesserts,
      Value<int>? rowid}) {
    return VenuesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      code: code ?? this.code,
      name: name ?? this.name,
      reportName: reportName ?? this.reportName,
      currency: currency ?? this.currency,
      logoPath: logoPath ?? this.logoPath,
      showShiftDesserts: showShiftDesserts ?? this.showShiftDesserts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (reportName.present) {
      map['report_name'] = Variable<String>(reportName.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (showShiftDesserts.present) {
      map['show_shift_desserts'] = Variable<bool>(showShiftDesserts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VenuesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('reportName: $reportName, ')
          ..write('currency: $currency, ')
          ..write('logoPath: $logoPath, ')
          ..write('showShiftDesserts: $showShiftDesserts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DepartmentsTable extends Departments
    with TableInfo<$DepartmentsTable, DepartmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DepartmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 120),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('category'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, createdAt, updatedAt, deletedAt, venueId, name, iconKey, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'departments';
  @override
  VerificationContext validateIntegrity(Insertable<DepartmentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DepartmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DepartmentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $DepartmentsTable createAlias(String alias) {
    return $DepartmentsTable(attachedDatabase, alias);
  }
}

class DepartmentRow extends DataClass implements Insertable<DepartmentRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String venueId;
  final String name;

  /// Строковый ключ иконки, а не codePoint: динамический IconData
  /// ломает tree-shaking иконок в релизной сборке.
  final String iconKey;
  final int sortOrder;
  const DepartmentRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.venueId,
      required this.name,
      required this.iconKey,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['venue_id'] = Variable<String>(venueId);
    map['name'] = Variable<String>(name);
    map['icon_key'] = Variable<String>(iconKey);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DepartmentsCompanion toCompanion(bool nullToAbsent) {
    return DepartmentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      venueId: Value(venueId),
      name: Value(name),
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory DepartmentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DepartmentRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      venueId: serializer.fromJson<String>(json['venueId']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'venueId': serializer.toJson<String>(venueId),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String>(iconKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DepartmentRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? venueId,
          String? name,
          String? iconKey,
          int? sortOrder}) =>
      DepartmentRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        venueId: venueId ?? this.venueId,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  DepartmentRow copyWithCompanion(DepartmentsCompanion data) {
    return DepartmentRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DepartmentRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, createdAt, updatedAt, deletedAt, venueId, name, iconKey, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DepartmentRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.venueId == this.venueId &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.sortOrder == this.sortOrder);
}

class DepartmentsCompanion extends UpdateCompanion<DepartmentRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> venueId;
  final Value<String> name;
  final Value<String> iconKey;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DepartmentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.venueId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DepartmentsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String venueId,
    required String name,
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        venueId = Value(venueId),
        name = Value(name);
  static Insertable<DepartmentRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? venueId,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (venueId != null) 'venue_id': venueId,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DepartmentsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? venueId,
      Value<String>? name,
      Value<String>? iconKey,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return DepartmentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      venueId: venueId ?? this.venueId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DepartmentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _departmentIdMeta =
      const VerificationMeta('departmentId');
  @override
  late final GeneratedColumn<String> departmentId = GeneratedColumn<String>(
      'department_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 120),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isDessertMeta =
      const VerificationMeta('isDessert');
  @override
  late final GeneratedColumn<bool> isDessert = GeneratedColumn<bool>(
      'is_dessert', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_dessert" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        venueId,
        departmentId,
        name,
        isDessert,
        sortOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('department_id')) {
      context.handle(
          _departmentIdMeta,
          departmentId.isAcceptableOrUnknown(
              data['department_id']!, _departmentIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_dessert')) {
      context.handle(_isDessertMeta,
          isDessert.isAcceptableOrUnknown(data['is_dessert']!, _isDessertMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      departmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}department_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isDessert: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_dessert'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String venueId;
  final String? departmentId;
  final String name;

  /// Товары категории показываются в шаге «Смена и списания».
  final bool isDessert;
  final int sortOrder;
  const CategoryRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.venueId,
      this.departmentId,
      required this.name,
      required this.isDessert,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['venue_id'] = Variable<String>(venueId);
    if (!nullToAbsent || departmentId != null) {
      map['department_id'] = Variable<String>(departmentId);
    }
    map['name'] = Variable<String>(name);
    map['is_dessert'] = Variable<bool>(isDessert);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      venueId: Value(venueId),
      departmentId: departmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(departmentId),
      name: Value(name),
      isDessert: Value(isDessert),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      venueId: serializer.fromJson<String>(json['venueId']),
      departmentId: serializer.fromJson<String?>(json['departmentId']),
      name: serializer.fromJson<String>(json['name']),
      isDessert: serializer.fromJson<bool>(json['isDessert']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'venueId': serializer.toJson<String>(venueId),
      'departmentId': serializer.toJson<String?>(departmentId),
      'name': serializer.toJson<String>(name),
      'isDessert': serializer.toJson<bool>(isDessert),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? venueId,
          Value<String?> departmentId = const Value.absent(),
          String? name,
          bool? isDessert,
          int? sortOrder}) =>
      CategoryRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        venueId: venueId ?? this.venueId,
        departmentId:
            departmentId.present ? departmentId.value : this.departmentId,
        name: name ?? this.name,
        isDessert: isDessert ?? this.isDessert,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      departmentId: data.departmentId.present
          ? data.departmentId.value
          : this.departmentId,
      name: data.name.present ? data.name.value : this.name,
      isDessert: data.isDessert.present ? data.isDessert.value : this.isDessert,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('departmentId: $departmentId, ')
          ..write('name: $name, ')
          ..write('isDessert: $isDessert, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, venueId,
      departmentId, name, isDessert, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.venueId == this.venueId &&
          other.departmentId == this.departmentId &&
          other.name == this.name &&
          other.isDessert == this.isDessert &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> venueId;
  final Value<String?> departmentId;
  final Value<String> name;
  final Value<bool> isDessert;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.venueId = const Value.absent(),
    this.departmentId = const Value.absent(),
    this.name = const Value.absent(),
    this.isDessert = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String venueId,
    this.departmentId = const Value.absent(),
    required String name,
    this.isDessert = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        venueId = Value(venueId),
        name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? venueId,
    Expression<String>? departmentId,
    Expression<String>? name,
    Expression<bool>? isDessert,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (venueId != null) 'venue_id': venueId,
      if (departmentId != null) 'department_id': departmentId,
      if (name != null) 'name': name,
      if (isDessert != null) 'is_dessert': isDessert,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? venueId,
      Value<String?>? departmentId,
      Value<String>? name,
      Value<bool>? isDessert,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      venueId: venueId ?? this.venueId,
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      isDessert: isDessert ?? this.isDessert,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (departmentId.present) {
      map['department_id'] = Variable<String>(departmentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDessert.present) {
      map['is_dessert'] = Variable<bool>(isDessert.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('departmentId: $departmentId, ')
          ..write('name: $name, ')
          ..write('isDessert: $isDessert, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('шт'));
  static const VerificationMeta _inventoryUnitMeta =
      const VerificationMeta('inventoryUnit');
  @override
  late final GeneratedColumn<String> inventoryUnit = GeneratedColumn<String>(
      'inventory_unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('шт'));
  static const VerificationMeta _unitFactorMeta =
      const VerificationMeta('unitFactor');
  @override
  late final GeneratedColumn<double> unitFactor = GeneratedColumn<double>(
      'unit_factor', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _minStockMeta =
      const VerificationMeta('minStock');
  @override
  late final GeneratedColumn<double> minStock = GeneratedColumn<double>(
      'min_stock', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _iikoProductIdMeta =
      const VerificationMeta('iikoProductId');
  @override
  late final GeneratedColumn<String> iikoProductId = GeneratedColumn<String>(
      'iiko_product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        venueId,
        categoryId,
        name,
        unit,
        inventoryUnit,
        unitFactor,
        minStock,
        iikoProductId,
        sortOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<ProductRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('inventory_unit')) {
      context.handle(
          _inventoryUnitMeta,
          inventoryUnit.isAcceptableOrUnknown(
              data['inventory_unit']!, _inventoryUnitMeta));
    }
    if (data.containsKey('unit_factor')) {
      context.handle(
          _unitFactorMeta,
          unitFactor.isAcceptableOrUnknown(
              data['unit_factor']!, _unitFactorMeta));
    }
    if (data.containsKey('min_stock')) {
      context.handle(_minStockMeta,
          minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta));
    }
    if (data.containsKey('iiko_product_id')) {
      context.handle(
          _iikoProductIdMeta,
          iikoProductId.isAcceptableOrUnknown(
              data['iiko_product_id']!, _iikoProductIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      inventoryUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}inventory_unit'])!,
      unitFactor: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_factor'])!,
      minStock: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_stock']),
      iikoProductId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}iiko_product_id']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String venueId;
  final String? categoryId;
  final String name;

  /// Единица заявки (например, «коробка»).
  final String unit;

  /// Единица инвентаризации (например, «шт»). В ней же ведётся журнал
  /// движений товара.
  final String inventoryUnit;

  /// Сколько единиц инвентаризации в одной единице заявки
  /// («1 коробка = 12 шт» → 12). Нужно, чтобы поставка, принятая
  /// в коробках, легла в журнал в штуках.
  final double unitFactor;
  final double? minStock;

  /// Идентификатор товара в номенклатуре iiko — сопоставление по id,
  /// а не по названию.
  final String? iikoProductId;
  final int sortOrder;
  const ProductRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.venueId,
      this.categoryId,
      required this.name,
      required this.unit,
      required this.inventoryUnit,
      required this.unitFactor,
      this.minStock,
      this.iikoProductId,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['venue_id'] = Variable<String>(venueId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['inventory_unit'] = Variable<String>(inventoryUnit);
    map['unit_factor'] = Variable<double>(unitFactor);
    if (!nullToAbsent || minStock != null) {
      map['min_stock'] = Variable<double>(minStock);
    }
    if (!nullToAbsent || iikoProductId != null) {
      map['iiko_product_id'] = Variable<String>(iikoProductId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      venueId: Value(venueId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      unit: Value(unit),
      inventoryUnit: Value(inventoryUnit),
      unitFactor: Value(unitFactor),
      minStock: minStock == null && nullToAbsent
          ? const Value.absent()
          : Value(minStock),
      iikoProductId: iikoProductId == null && nullToAbsent
          ? const Value.absent()
          : Value(iikoProductId),
      sortOrder: Value(sortOrder),
    );
  }

  factory ProductRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      venueId: serializer.fromJson<String>(json['venueId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      inventoryUnit: serializer.fromJson<String>(json['inventoryUnit']),
      unitFactor: serializer.fromJson<double>(json['unitFactor']),
      minStock: serializer.fromJson<double?>(json['minStock']),
      iikoProductId: serializer.fromJson<String?>(json['iikoProductId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'venueId': serializer.toJson<String>(venueId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'inventoryUnit': serializer.toJson<String>(inventoryUnit),
      'unitFactor': serializer.toJson<double>(unitFactor),
      'minStock': serializer.toJson<double?>(minStock),
      'iikoProductId': serializer.toJson<String?>(iikoProductId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ProductRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? venueId,
          Value<String?> categoryId = const Value.absent(),
          String? name,
          String? unit,
          String? inventoryUnit,
          double? unitFactor,
          Value<double?> minStock = const Value.absent(),
          Value<String?> iikoProductId = const Value.absent(),
          int? sortOrder}) =>
      ProductRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        venueId: venueId ?? this.venueId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        inventoryUnit: inventoryUnit ?? this.inventoryUnit,
        unitFactor: unitFactor ?? this.unitFactor,
        minStock: minStock.present ? minStock.value : this.minStock,
        iikoProductId:
            iikoProductId.present ? iikoProductId.value : this.iikoProductId,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      inventoryUnit: data.inventoryUnit.present
          ? data.inventoryUnit.value
          : this.inventoryUnit,
      unitFactor:
          data.unitFactor.present ? data.unitFactor.value : this.unitFactor,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      iikoProductId: data.iikoProductId.present
          ? data.iikoProductId.value
          : this.iikoProductId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('inventoryUnit: $inventoryUnit, ')
          ..write('unitFactor: $unitFactor, ')
          ..write('minStock: $minStock, ')
          ..write('iikoProductId: $iikoProductId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      venueId,
      categoryId,
      name,
      unit,
      inventoryUnit,
      unitFactor,
      minStock,
      iikoProductId,
      sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.venueId == this.venueId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.inventoryUnit == this.inventoryUnit &&
          other.unitFactor == this.unitFactor &&
          other.minStock == this.minStock &&
          other.iikoProductId == this.iikoProductId &&
          other.sortOrder == this.sortOrder);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> venueId;
  final Value<String?> categoryId;
  final Value<String> name;
  final Value<String> unit;
  final Value<String> inventoryUnit;
  final Value<double> unitFactor;
  final Value<double?> minStock;
  final Value<String?> iikoProductId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.venueId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.inventoryUnit = const Value.absent(),
    this.unitFactor = const Value.absent(),
    this.minStock = const Value.absent(),
    this.iikoProductId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String venueId,
    this.categoryId = const Value.absent(),
    required String name,
    this.unit = const Value.absent(),
    this.inventoryUnit = const Value.absent(),
    this.unitFactor = const Value.absent(),
    this.minStock = const Value.absent(),
    this.iikoProductId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        venueId = Value(venueId),
        name = Value(name);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? venueId,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<String>? inventoryUnit,
    Expression<double>? unitFactor,
    Expression<double>? minStock,
    Expression<String>? iikoProductId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (venueId != null) 'venue_id': venueId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (inventoryUnit != null) 'inventory_unit': inventoryUnit,
      if (unitFactor != null) 'unit_factor': unitFactor,
      if (minStock != null) 'min_stock': minStock,
      if (iikoProductId != null) 'iiko_product_id': iikoProductId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? venueId,
      Value<String?>? categoryId,
      Value<String>? name,
      Value<String>? unit,
      Value<String>? inventoryUnit,
      Value<double>? unitFactor,
      Value<double?>? minStock,
      Value<String?>? iikoProductId,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      venueId: venueId ?? this.venueId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      inventoryUnit: inventoryUnit ?? this.inventoryUnit,
      unitFactor: unitFactor ?? this.unitFactor,
      minStock: minStock ?? this.minStock,
      iikoProductId: iikoProductId ?? this.iikoProductId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (inventoryUnit.present) {
      map['inventory_unit'] = Variable<String>(inventoryUnit.value);
    }
    if (unitFactor.present) {
      map['unit_factor'] = Variable<double>(unitFactor.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<double>(minStock.value);
    }
    if (iikoProductId.present) {
      map['iiko_product_id'] = Variable<String>(iikoProductId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('inventoryUnit: $inventoryUnit, ')
          ..write('unitFactor: $unitFactor, ')
          ..write('minStock: $minStock, ')
          ..write('iikoProductId: $iikoProductId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffMembersTable extends StaffMembers
    with TableInfo<$StaffMembersTable, StaffMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('staff'));
  static const VerificationMeta _pinHashMeta =
      const VerificationMeta('pinHash');
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
      'pin_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pinSaltMeta =
      const VerificationMeta('pinSalt');
  @override
  late final GeneratedColumn<String> pinSalt = GeneratedColumn<String>(
      'pin_salt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        venueId,
        fullName,
        role,
        pinHash,
        pinSalt,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_members';
  @override
  VerificationContext validateIntegrity(Insertable<StaffMemberRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('pin_hash')) {
      context.handle(_pinHashMeta,
          pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta));
    }
    if (data.containsKey('pin_salt')) {
      context.handle(_pinSaltMeta,
          pinSalt.isAcceptableOrUnknown(data['pin_salt']!, _pinSaltMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StaffMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffMemberRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      pinHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_hash']),
      pinSalt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_salt']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $StaffMembersTable createAlias(String alias) {
    return $StaffMembersTable(attachedDatabase, alias);
  }
}

class StaffMemberRow extends DataClass implements Insertable<StaffMemberRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String venueId;
  final String fullName;

  /// 'admin' или 'staff'.
  final String role;
  final String? pinHash;
  final String? pinSalt;
  final bool isActive;
  const StaffMemberRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.venueId,
      required this.fullName,
      required this.role,
      this.pinHash,
      this.pinSalt,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['venue_id'] = Variable<String>(venueId);
    map['full_name'] = Variable<String>(fullName);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || pinHash != null) {
      map['pin_hash'] = Variable<String>(pinHash);
    }
    if (!nullToAbsent || pinSalt != null) {
      map['pin_salt'] = Variable<String>(pinSalt);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  StaffMembersCompanion toCompanion(bool nullToAbsent) {
    return StaffMembersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      venueId: Value(venueId),
      fullName: Value(fullName),
      role: Value(role),
      pinHash: pinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pinHash),
      pinSalt: pinSalt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinSalt),
      isActive: Value(isActive),
    );
  }

  factory StaffMemberRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffMemberRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      venueId: serializer.fromJson<String>(json['venueId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      role: serializer.fromJson<String>(json['role']),
      pinHash: serializer.fromJson<String?>(json['pinHash']),
      pinSalt: serializer.fromJson<String?>(json['pinSalt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'venueId': serializer.toJson<String>(venueId),
      'fullName': serializer.toJson<String>(fullName),
      'role': serializer.toJson<String>(role),
      'pinHash': serializer.toJson<String?>(pinHash),
      'pinSalt': serializer.toJson<String?>(pinSalt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  StaffMemberRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? venueId,
          String? fullName,
          String? role,
          Value<String?> pinHash = const Value.absent(),
          Value<String?> pinSalt = const Value.absent(),
          bool? isActive}) =>
      StaffMemberRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        venueId: venueId ?? this.venueId,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        pinHash: pinHash.present ? pinHash.value : this.pinHash,
        pinSalt: pinSalt.present ? pinSalt.value : this.pinSalt,
        isActive: isActive ?? this.isActive,
      );
  StaffMemberRow copyWithCompanion(StaffMembersCompanion data) {
    return StaffMemberRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      role: data.role.present ? data.role.value : this.role,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      pinSalt: data.pinSalt.present ? data.pinSalt.value : this.pinSalt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffMemberRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('pinHash: $pinHash, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, venueId,
      fullName, role, pinHash, pinSalt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffMemberRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.venueId == this.venueId &&
          other.fullName == this.fullName &&
          other.role == this.role &&
          other.pinHash == this.pinHash &&
          other.pinSalt == this.pinSalt &&
          other.isActive == this.isActive);
}

class StaffMembersCompanion extends UpdateCompanion<StaffMemberRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> venueId;
  final Value<String> fullName;
  final Value<String> role;
  final Value<String?> pinHash;
  final Value<String?> pinSalt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const StaffMembersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.venueId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.role = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.pinSalt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffMembersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String venueId,
    required String fullName,
    this.role = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.pinSalt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        venueId = Value(venueId),
        fullName = Value(fullName);
  static Insertable<StaffMemberRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? venueId,
    Expression<String>? fullName,
    Expression<String>? role,
    Expression<String>? pinHash,
    Expression<String>? pinSalt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (venueId != null) 'venue_id': venueId,
      if (fullName != null) 'full_name': fullName,
      if (role != null) 'role': role,
      if (pinHash != null) 'pin_hash': pinHash,
      if (pinSalt != null) 'pin_salt': pinSalt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffMembersCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? venueId,
      Value<String>? fullName,
      Value<String>? role,
      Value<String?>? pinHash,
      Value<String?>? pinSalt,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return StaffMembersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      venueId: venueId ?? this.venueId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (pinSalt.present) {
      map['pin_salt'] = Variable<String>(pinSalt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffMembersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('pinHash: $pinHash, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryEntriesTable extends HistoryEntries
    with TableInfo<$HistoryEntriesTable, HistoryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _staffIdMeta =
      const VerificationMeta('staffId');
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
      'staff_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
      'ref_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attachmentPathMeta =
      const VerificationMeta('attachmentPath');
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
      'attachment_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        venueId,
        kind,
        title,
        body,
        staffId,
        refId,
        attachmentPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_entries';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(_staffIdMeta,
          staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta));
    }
    if (data.containsKey('ref_id')) {
      context.handle(
          _refIdMeta, refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta));
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
          _attachmentPathMeta,
          attachmentPath.isAcceptableOrUnknown(
              data['attachment_path']!, _attachmentPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      staffId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_id']),
      refId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref_id']),
      attachmentPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachment_path']),
    );
  }

  @override
  $HistoryEntriesTable createAlias(String alias) {
    return $HistoryEntriesTable(attachedDatabase, alias);
  }
}

class HistoryEntryRow extends DataClass implements Insertable<HistoryEntryRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String venueId;

  /// 'request', 'inventory' или 'receipt' (приёмка поставки).
  final String kind;
  final String title;
  final String body;
  final String? staffId;

  /// Связанный документ: для приёмки — заявка, по которой пришла поставка.
  final String? refId;

  /// Путь к файлу-вложению на устройстве (фото накладной).
  final String? attachmentPath;
  const HistoryEntryRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.venueId,
      required this.kind,
      required this.title,
      required this.body,
      this.staffId,
      this.refId,
      this.attachmentPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['venue_id'] = Variable<String>(venueId);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || staffId != null) {
      map['staff_id'] = Variable<String>(staffId);
    }
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<String>(refId);
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    return map;
  }

  HistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return HistoryEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      venueId: Value(venueId),
      kind: Value(kind),
      title: Value(title),
      body: Value(body),
      staffId: staffId == null && nullToAbsent
          ? const Value.absent()
          : Value(staffId),
      refId:
          refId == null && nullToAbsent ? const Value.absent() : Value(refId),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
    );
  }

  factory HistoryEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryEntryRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      venueId: serializer.fromJson<String>(json['venueId']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      staffId: serializer.fromJson<String?>(json['staffId']),
      refId: serializer.fromJson<String?>(json['refId']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'venueId': serializer.toJson<String>(venueId),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'staffId': serializer.toJson<String?>(staffId),
      'refId': serializer.toJson<String?>(refId),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
    };
  }

  HistoryEntryRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? venueId,
          String? kind,
          String? title,
          String? body,
          Value<String?> staffId = const Value.absent(),
          Value<String?> refId = const Value.absent(),
          Value<String?> attachmentPath = const Value.absent()}) =>
      HistoryEntryRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        venueId: venueId ?? this.venueId,
        kind: kind ?? this.kind,
        title: title ?? this.title,
        body: body ?? this.body,
        staffId: staffId.present ? staffId.value : this.staffId,
        refId: refId.present ? refId.value : this.refId,
        attachmentPath:
            attachmentPath.present ? attachmentPath.value : this.attachmentPath,
      );
  HistoryEntryRow copyWithCompanion(HistoryEntriesCompanion data) {
    return HistoryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      refId: data.refId.present ? data.refId.value : this.refId,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntryRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('staffId: $staffId, ')
          ..write('refId: $refId, ')
          ..write('attachmentPath: $attachmentPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt, venueId,
      kind, title, body, staffId, refId, attachmentPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryEntryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.venueId == this.venueId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.body == this.body &&
          other.staffId == this.staffId &&
          other.refId == this.refId &&
          other.attachmentPath == this.attachmentPath);
}

class HistoryEntriesCompanion extends UpdateCompanion<HistoryEntryRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> venueId;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> staffId;
  final Value<String?> refId;
  final Value<String?> attachmentPath;
  final Value<int> rowid;
  const HistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.venueId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.staffId = const Value.absent(),
    this.refId = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryEntriesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String venueId,
    required String kind,
    required String title,
    required String body,
    this.staffId = const Value.absent(),
    this.refId = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        venueId = Value(venueId),
        kind = Value(kind),
        title = Value(title),
        body = Value(body);
  static Insertable<HistoryEntryRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? venueId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? staffId,
    Expression<String>? refId,
    Expression<String>? attachmentPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (venueId != null) 'venue_id': venueId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (staffId != null) 'staff_id': staffId,
      if (refId != null) 'ref_id': refId,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryEntriesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? venueId,
      Value<String>? kind,
      Value<String>? title,
      Value<String>? body,
      Value<String?>? staffId,
      Value<String?>? refId,
      Value<String?>? attachmentPath,
      Value<int>? rowid}) {
    return HistoryEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      venueId: venueId ?? this.venueId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      staffId: staffId ?? this.staffId,
      refId: refId ?? this.refId,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('staffId: $staffId, ')
          ..write('refId: $refId, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentLinesTable extends DocumentLines
    with TableInfo<$DocumentLinesTable, DocumentLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
      'document_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('шт'));
  static const VerificationMeta _orderedMeta =
      const VerificationMeta('ordered');
  @override
  late final GeneratedColumn<double> ordered = GeneratedColumn<double>(
      'ordered', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        venueId,
        documentId,
        productId,
        productName,
        unit,
        ordered,
        quantity,
        price,
        sortOrder,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_lines';
  @override
  VerificationContext validateIntegrity(Insertable<DocumentLineRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['document_id']!, _documentIdMeta));
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('ordered')) {
      context.handle(_orderedMeta,
          ordered.isAcceptableOrUnknown(data['ordered']!, _orderedMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentLineRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      ordered: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ordered']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DocumentLinesTable createAlias(String alias) {
    return $DocumentLinesTable(attachedDatabase, alias);
  }
}

class DocumentLineRow extends DataClass implements Insertable<DocumentLineRow> {
  final String id;
  final String venueId;

  /// id записи HistoryEntries.
  final String documentId;
  final String? productId;

  /// Название на момент документа.
  final String productName;
  final String unit;

  /// Сколько заказали (для приёмки — по заявке; у строк вне заявки пусто).
  final double? ordered;

  /// Основное количество: в заявке — заказ, в приёмке — сколько пришло,
  /// в инвентаризации — остаток.
  final double quantity;

  /// Цена за единицу по накладной/чеку (если известна).
  final double? price;
  final int sortOrder;
  final DateTime createdAt;
  const DocumentLineRow(
      {required this.id,
      required this.venueId,
      required this.documentId,
      this.productId,
      required this.productName,
      required this.unit,
      this.ordered,
      required this.quantity,
      this.price,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['venue_id'] = Variable<String>(venueId);
    map['document_id'] = Variable<String>(documentId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['product_name'] = Variable<String>(productName);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || ordered != null) {
      map['ordered'] = Variable<double>(ordered);
    }
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DocumentLinesCompanion toCompanion(bool nullToAbsent) {
    return DocumentLinesCompanion(
      id: Value(id),
      venueId: Value(venueId),
      documentId: Value(documentId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productName: Value(productName),
      unit: Value(unit),
      ordered: ordered == null && nullToAbsent
          ? const Value.absent()
          : Value(ordered),
      quantity: Value(quantity),
      price:
          price == null && nullToAbsent ? const Value.absent() : Value(price),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory DocumentLineRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentLineRow(
      id: serializer.fromJson<String>(json['id']),
      venueId: serializer.fromJson<String>(json['venueId']),
      documentId: serializer.fromJson<String>(json['documentId']),
      productId: serializer.fromJson<String?>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      unit: serializer.fromJson<String>(json['unit']),
      ordered: serializer.fromJson<double?>(json['ordered']),
      quantity: serializer.fromJson<double>(json['quantity']),
      price: serializer.fromJson<double?>(json['price']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'venueId': serializer.toJson<String>(venueId),
      'documentId': serializer.toJson<String>(documentId),
      'productId': serializer.toJson<String?>(productId),
      'productName': serializer.toJson<String>(productName),
      'unit': serializer.toJson<String>(unit),
      'ordered': serializer.toJson<double?>(ordered),
      'quantity': serializer.toJson<double>(quantity),
      'price': serializer.toJson<double?>(price),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DocumentLineRow copyWith(
          {String? id,
          String? venueId,
          String? documentId,
          Value<String?> productId = const Value.absent(),
          String? productName,
          String? unit,
          Value<double?> ordered = const Value.absent(),
          double? quantity,
          Value<double?> price = const Value.absent(),
          int? sortOrder,
          DateTime? createdAt}) =>
      DocumentLineRow(
        id: id ?? this.id,
        venueId: venueId ?? this.venueId,
        documentId: documentId ?? this.documentId,
        productId: productId.present ? productId.value : this.productId,
        productName: productName ?? this.productName,
        unit: unit ?? this.unit,
        ordered: ordered.present ? ordered.value : this.ordered,
        quantity: quantity ?? this.quantity,
        price: price.present ? price.value : this.price,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  DocumentLineRow copyWithCompanion(DocumentLinesCompanion data) {
    return DocumentLineRow(
      id: data.id.present ? data.id.value : this.id,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      unit: data.unit.present ? data.unit.value : this.unit,
      ordered: data.ordered.present ? data.ordered.value : this.ordered,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      price: data.price.present ? data.price.value : this.price,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentLineRow(')
          ..write('id: $id, ')
          ..write('venueId: $venueId, ')
          ..write('documentId: $documentId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('unit: $unit, ')
          ..write('ordered: $ordered, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, venueId, documentId, productId,
      productName, unit, ordered, quantity, price, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentLineRow &&
          other.id == this.id &&
          other.venueId == this.venueId &&
          other.documentId == this.documentId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.unit == this.unit &&
          other.ordered == this.ordered &&
          other.quantity == this.quantity &&
          other.price == this.price &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class DocumentLinesCompanion extends UpdateCompanion<DocumentLineRow> {
  final Value<String> id;
  final Value<String> venueId;
  final Value<String> documentId;
  final Value<String?> productId;
  final Value<String> productName;
  final Value<String> unit;
  final Value<double?> ordered;
  final Value<double> quantity;
  final Value<double?> price;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DocumentLinesCompanion({
    this.id = const Value.absent(),
    this.venueId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.unit = const Value.absent(),
    this.ordered = const Value.absent(),
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentLinesCompanion.insert({
    required String id,
    required String venueId,
    required String documentId,
    this.productId = const Value.absent(),
    required String productName,
    this.unit = const Value.absent(),
    this.ordered = const Value.absent(),
    required double quantity,
    this.price = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        venueId = Value(venueId),
        documentId = Value(documentId),
        productName = Value(productName),
        quantity = Value(quantity),
        createdAt = Value(createdAt);
  static Insertable<DocumentLineRow> custom({
    Expression<String>? id,
    Expression<String>? venueId,
    Expression<String>? documentId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? unit,
    Expression<double>? ordered,
    Expression<double>? quantity,
    Expression<double>? price,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (venueId != null) 'venue_id': venueId,
      if (documentId != null) 'document_id': documentId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (unit != null) 'unit': unit,
      if (ordered != null) 'ordered': ordered,
      if (quantity != null) 'quantity': quantity,
      if (price != null) 'price': price,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentLinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? venueId,
      Value<String>? documentId,
      Value<String?>? productId,
      Value<String>? productName,
      Value<String>? unit,
      Value<double?>? ordered,
      Value<double>? quantity,
      Value<double?>? price,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DocumentLinesCompanion(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      documentId: documentId ?? this.documentId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      ordered: ordered ?? this.ordered,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (ordered.present) {
      map['ordered'] = Variable<double>(ordered.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentLinesCompanion(')
          ..write('id: $id, ')
          ..write('venueId: $venueId, ')
          ..write('documentId: $documentId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('unit: $unit, ')
          ..write('ordered: $ordered, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftRecordsTable extends ShiftRecords
    with TableInfo<$ShiftRecordsTable, ShiftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _staffNamesMeta =
      const VerificationMeta('staffNames');
  @override
  late final GeneratedColumn<String> staffNames = GeneratedColumn<String>(
      'staff_names', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _closedByStaffIdMeta =
      const VerificationMeta('closedByStaffId');
  @override
  late final GeneratedColumn<String> closedByStaffId = GeneratedColumn<String>(
      'closed_by_staff_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _revenueMinorMeta =
      const VerificationMeta('revenueMinor');
  @override
  late final GeneratedColumn<int> revenueMinor = GeneratedColumn<int>(
      'revenue_minor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _qrMinorMeta =
      const VerificationMeta('qrMinor');
  @override
  late final GeneratedColumn<int> qrMinor = GeneratedColumn<int>(
      'qr_minor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cardMinorMeta =
      const VerificationMeta('cardMinor');
  @override
  late final GeneratedColumn<int> cardMinor = GeneratedColumn<int>(
      'card_minor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cashMinorMeta =
      const VerificationMeta('cashMinor');
  @override
  late final GeneratedColumn<int> cashMinor = GeneratedColumn<int>(
      'cash_minor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _morningCashMinorMeta =
      const VerificationMeta('morningCashMinor');
  @override
  late final GeneratedColumn<int> morningCashMinor = GeneratedColumn<int>(
      'morning_cash_minor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _eveningCashMinorMeta =
      const VerificationMeta('eveningCashMinor');
  @override
  late final GeneratedColumn<int> eveningCashMinor = GeneratedColumn<int>(
      'evening_cash_minor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _inkassMinorMeta =
      const VerificationMeta('inkassMinor');
  @override
  late final GeneratedColumn<int> inkassMinor = GeneratedColumn<int>(
      'inkass_minor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        venueId,
        closedAt,
        staffNames,
        closedByStaffId,
        revenueMinor,
        qrMinor,
        cardMinor,
        cashMinor,
        morningCashMinor,
        eveningCashMinor,
        inkassMinor
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_records';
  @override
  VerificationContext validateIntegrity(Insertable<ShiftRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    } else if (isInserting) {
      context.missing(_closedAtMeta);
    }
    if (data.containsKey('staff_names')) {
      context.handle(
          _staffNamesMeta,
          staffNames.isAcceptableOrUnknown(
              data['staff_names']!, _staffNamesMeta));
    }
    if (data.containsKey('closed_by_staff_id')) {
      context.handle(
          _closedByStaffIdMeta,
          closedByStaffId.isAcceptableOrUnknown(
              data['closed_by_staff_id']!, _closedByStaffIdMeta));
    }
    if (data.containsKey('revenue_minor')) {
      context.handle(
          _revenueMinorMeta,
          revenueMinor.isAcceptableOrUnknown(
              data['revenue_minor']!, _revenueMinorMeta));
    }
    if (data.containsKey('qr_minor')) {
      context.handle(_qrMinorMeta,
          qrMinor.isAcceptableOrUnknown(data['qr_minor']!, _qrMinorMeta));
    }
    if (data.containsKey('card_minor')) {
      context.handle(_cardMinorMeta,
          cardMinor.isAcceptableOrUnknown(data['card_minor']!, _cardMinorMeta));
    }
    if (data.containsKey('cash_minor')) {
      context.handle(_cashMinorMeta,
          cashMinor.isAcceptableOrUnknown(data['cash_minor']!, _cashMinorMeta));
    }
    if (data.containsKey('morning_cash_minor')) {
      context.handle(
          _morningCashMinorMeta,
          morningCashMinor.isAcceptableOrUnknown(
              data['morning_cash_minor']!, _morningCashMinorMeta));
    }
    if (data.containsKey('evening_cash_minor')) {
      context.handle(
          _eveningCashMinorMeta,
          eveningCashMinor.isAcceptableOrUnknown(
              data['evening_cash_minor']!, _eveningCashMinorMeta));
    }
    if (data.containsKey('inkass_minor')) {
      context.handle(
          _inkassMinorMeta,
          inkassMinor.isAcceptableOrUnknown(
              data['inkass_minor']!, _inkassMinorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at'])!,
      staffNames: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_names'])!,
      closedByStaffId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}closed_by_staff_id']),
      revenueMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}revenue_minor'])!,
      qrMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}qr_minor'])!,
      cardMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}card_minor'])!,
      cashMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cash_minor'])!,
      morningCashMinor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}morning_cash_minor'])!,
      eveningCashMinor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}evening_cash_minor'])!,
      inkassMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}inkass_minor'])!,
    );
  }

  @override
  $ShiftRecordsTable createAlias(String alias) {
    return $ShiftRecordsTable(attachedDatabase, alias);
  }
}

class ShiftRow extends DataClass implements Insertable<ShiftRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String venueId;
  final DateTime closedAt;

  /// Имена сотрудников на момент закрытия, через перевод строки.
  /// Снимок, а не ссылки: переименование не должно менять закрытую смену.
  final String staffNames;

  /// Кто закрыл смену (личный PIN).
  final String? closedByStaffId;
  final int revenueMinor;
  final int qrMinor;
  final int cardMinor;
  final int cashMinor;
  final int morningCashMinor;
  final int eveningCashMinor;
  final int inkassMinor;
  const ShiftRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.venueId,
      required this.closedAt,
      required this.staffNames,
      this.closedByStaffId,
      required this.revenueMinor,
      required this.qrMinor,
      required this.cardMinor,
      required this.cashMinor,
      required this.morningCashMinor,
      required this.eveningCashMinor,
      required this.inkassMinor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['venue_id'] = Variable<String>(venueId);
    map['closed_at'] = Variable<DateTime>(closedAt);
    map['staff_names'] = Variable<String>(staffNames);
    if (!nullToAbsent || closedByStaffId != null) {
      map['closed_by_staff_id'] = Variable<String>(closedByStaffId);
    }
    map['revenue_minor'] = Variable<int>(revenueMinor);
    map['qr_minor'] = Variable<int>(qrMinor);
    map['card_minor'] = Variable<int>(cardMinor);
    map['cash_minor'] = Variable<int>(cashMinor);
    map['morning_cash_minor'] = Variable<int>(morningCashMinor);
    map['evening_cash_minor'] = Variable<int>(eveningCashMinor);
    map['inkass_minor'] = Variable<int>(inkassMinor);
    return map;
  }

  ShiftRecordsCompanion toCompanion(bool nullToAbsent) {
    return ShiftRecordsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      venueId: Value(venueId),
      closedAt: Value(closedAt),
      staffNames: Value(staffNames),
      closedByStaffId: closedByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(closedByStaffId),
      revenueMinor: Value(revenueMinor),
      qrMinor: Value(qrMinor),
      cardMinor: Value(cardMinor),
      cashMinor: Value(cashMinor),
      morningCashMinor: Value(morningCashMinor),
      eveningCashMinor: Value(eveningCashMinor),
      inkassMinor: Value(inkassMinor),
    );
  }

  factory ShiftRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      venueId: serializer.fromJson<String>(json['venueId']),
      closedAt: serializer.fromJson<DateTime>(json['closedAt']),
      staffNames: serializer.fromJson<String>(json['staffNames']),
      closedByStaffId: serializer.fromJson<String?>(json['closedByStaffId']),
      revenueMinor: serializer.fromJson<int>(json['revenueMinor']),
      qrMinor: serializer.fromJson<int>(json['qrMinor']),
      cardMinor: serializer.fromJson<int>(json['cardMinor']),
      cashMinor: serializer.fromJson<int>(json['cashMinor']),
      morningCashMinor: serializer.fromJson<int>(json['morningCashMinor']),
      eveningCashMinor: serializer.fromJson<int>(json['eveningCashMinor']),
      inkassMinor: serializer.fromJson<int>(json['inkassMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'venueId': serializer.toJson<String>(venueId),
      'closedAt': serializer.toJson<DateTime>(closedAt),
      'staffNames': serializer.toJson<String>(staffNames),
      'closedByStaffId': serializer.toJson<String?>(closedByStaffId),
      'revenueMinor': serializer.toJson<int>(revenueMinor),
      'qrMinor': serializer.toJson<int>(qrMinor),
      'cardMinor': serializer.toJson<int>(cardMinor),
      'cashMinor': serializer.toJson<int>(cashMinor),
      'morningCashMinor': serializer.toJson<int>(morningCashMinor),
      'eveningCashMinor': serializer.toJson<int>(eveningCashMinor),
      'inkassMinor': serializer.toJson<int>(inkassMinor),
    };
  }

  ShiftRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? venueId,
          DateTime? closedAt,
          String? staffNames,
          Value<String?> closedByStaffId = const Value.absent(),
          int? revenueMinor,
          int? qrMinor,
          int? cardMinor,
          int? cashMinor,
          int? morningCashMinor,
          int? eveningCashMinor,
          int? inkassMinor}) =>
      ShiftRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        venueId: venueId ?? this.venueId,
        closedAt: closedAt ?? this.closedAt,
        staffNames: staffNames ?? this.staffNames,
        closedByStaffId: closedByStaffId.present
            ? closedByStaffId.value
            : this.closedByStaffId,
        revenueMinor: revenueMinor ?? this.revenueMinor,
        qrMinor: qrMinor ?? this.qrMinor,
        cardMinor: cardMinor ?? this.cardMinor,
        cashMinor: cashMinor ?? this.cashMinor,
        morningCashMinor: morningCashMinor ?? this.morningCashMinor,
        eveningCashMinor: eveningCashMinor ?? this.eveningCashMinor,
        inkassMinor: inkassMinor ?? this.inkassMinor,
      );
  ShiftRow copyWithCompanion(ShiftRecordsCompanion data) {
    return ShiftRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      staffNames:
          data.staffNames.present ? data.staffNames.value : this.staffNames,
      closedByStaffId: data.closedByStaffId.present
          ? data.closedByStaffId.value
          : this.closedByStaffId,
      revenueMinor: data.revenueMinor.present
          ? data.revenueMinor.value
          : this.revenueMinor,
      qrMinor: data.qrMinor.present ? data.qrMinor.value : this.qrMinor,
      cardMinor: data.cardMinor.present ? data.cardMinor.value : this.cardMinor,
      cashMinor: data.cashMinor.present ? data.cashMinor.value : this.cashMinor,
      morningCashMinor: data.morningCashMinor.present
          ? data.morningCashMinor.value
          : this.morningCashMinor,
      eveningCashMinor: data.eveningCashMinor.present
          ? data.eveningCashMinor.value
          : this.eveningCashMinor,
      inkassMinor:
          data.inkassMinor.present ? data.inkassMinor.value : this.inkassMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('closedAt: $closedAt, ')
          ..write('staffNames: $staffNames, ')
          ..write('closedByStaffId: $closedByStaffId, ')
          ..write('revenueMinor: $revenueMinor, ')
          ..write('qrMinor: $qrMinor, ')
          ..write('cardMinor: $cardMinor, ')
          ..write('cashMinor: $cashMinor, ')
          ..write('morningCashMinor: $morningCashMinor, ')
          ..write('eveningCashMinor: $eveningCashMinor, ')
          ..write('inkassMinor: $inkassMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      venueId,
      closedAt,
      staffNames,
      closedByStaffId,
      revenueMinor,
      qrMinor,
      cardMinor,
      cashMinor,
      morningCashMinor,
      eveningCashMinor,
      inkassMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.venueId == this.venueId &&
          other.closedAt == this.closedAt &&
          other.staffNames == this.staffNames &&
          other.closedByStaffId == this.closedByStaffId &&
          other.revenueMinor == this.revenueMinor &&
          other.qrMinor == this.qrMinor &&
          other.cardMinor == this.cardMinor &&
          other.cashMinor == this.cashMinor &&
          other.morningCashMinor == this.morningCashMinor &&
          other.eveningCashMinor == this.eveningCashMinor &&
          other.inkassMinor == this.inkassMinor);
}

class ShiftRecordsCompanion extends UpdateCompanion<ShiftRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> venueId;
  final Value<DateTime> closedAt;
  final Value<String> staffNames;
  final Value<String?> closedByStaffId;
  final Value<int> revenueMinor;
  final Value<int> qrMinor;
  final Value<int> cardMinor;
  final Value<int> cashMinor;
  final Value<int> morningCashMinor;
  final Value<int> eveningCashMinor;
  final Value<int> inkassMinor;
  final Value<int> rowid;
  const ShiftRecordsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.venueId = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.staffNames = const Value.absent(),
    this.closedByStaffId = const Value.absent(),
    this.revenueMinor = const Value.absent(),
    this.qrMinor = const Value.absent(),
    this.cardMinor = const Value.absent(),
    this.cashMinor = const Value.absent(),
    this.morningCashMinor = const Value.absent(),
    this.eveningCashMinor = const Value.absent(),
    this.inkassMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftRecordsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String venueId,
    required DateTime closedAt,
    this.staffNames = const Value.absent(),
    this.closedByStaffId = const Value.absent(),
    this.revenueMinor = const Value.absent(),
    this.qrMinor = const Value.absent(),
    this.cardMinor = const Value.absent(),
    this.cashMinor = const Value.absent(),
    this.morningCashMinor = const Value.absent(),
    this.eveningCashMinor = const Value.absent(),
    this.inkassMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        venueId = Value(venueId),
        closedAt = Value(closedAt);
  static Insertable<ShiftRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? venueId,
    Expression<DateTime>? closedAt,
    Expression<String>? staffNames,
    Expression<String>? closedByStaffId,
    Expression<int>? revenueMinor,
    Expression<int>? qrMinor,
    Expression<int>? cardMinor,
    Expression<int>? cashMinor,
    Expression<int>? morningCashMinor,
    Expression<int>? eveningCashMinor,
    Expression<int>? inkassMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (venueId != null) 'venue_id': venueId,
      if (closedAt != null) 'closed_at': closedAt,
      if (staffNames != null) 'staff_names': staffNames,
      if (closedByStaffId != null) 'closed_by_staff_id': closedByStaffId,
      if (revenueMinor != null) 'revenue_minor': revenueMinor,
      if (qrMinor != null) 'qr_minor': qrMinor,
      if (cardMinor != null) 'card_minor': cardMinor,
      if (cashMinor != null) 'cash_minor': cashMinor,
      if (morningCashMinor != null) 'morning_cash_minor': morningCashMinor,
      if (eveningCashMinor != null) 'evening_cash_minor': eveningCashMinor,
      if (inkassMinor != null) 'inkass_minor': inkassMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftRecordsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? venueId,
      Value<DateTime>? closedAt,
      Value<String>? staffNames,
      Value<String?>? closedByStaffId,
      Value<int>? revenueMinor,
      Value<int>? qrMinor,
      Value<int>? cardMinor,
      Value<int>? cashMinor,
      Value<int>? morningCashMinor,
      Value<int>? eveningCashMinor,
      Value<int>? inkassMinor,
      Value<int>? rowid}) {
    return ShiftRecordsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      venueId: venueId ?? this.venueId,
      closedAt: closedAt ?? this.closedAt,
      staffNames: staffNames ?? this.staffNames,
      closedByStaffId: closedByStaffId ?? this.closedByStaffId,
      revenueMinor: revenueMinor ?? this.revenueMinor,
      qrMinor: qrMinor ?? this.qrMinor,
      cardMinor: cardMinor ?? this.cardMinor,
      cashMinor: cashMinor ?? this.cashMinor,
      morningCashMinor: morningCashMinor ?? this.morningCashMinor,
      eveningCashMinor: eveningCashMinor ?? this.eveningCashMinor,
      inkassMinor: inkassMinor ?? this.inkassMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (staffNames.present) {
      map['staff_names'] = Variable<String>(staffNames.value);
    }
    if (closedByStaffId.present) {
      map['closed_by_staff_id'] = Variable<String>(closedByStaffId.value);
    }
    if (revenueMinor.present) {
      map['revenue_minor'] = Variable<int>(revenueMinor.value);
    }
    if (qrMinor.present) {
      map['qr_minor'] = Variable<int>(qrMinor.value);
    }
    if (cardMinor.present) {
      map['card_minor'] = Variable<int>(cardMinor.value);
    }
    if (cashMinor.present) {
      map['cash_minor'] = Variable<int>(cashMinor.value);
    }
    if (morningCashMinor.present) {
      map['morning_cash_minor'] = Variable<int>(morningCashMinor.value);
    }
    if (eveningCashMinor.present) {
      map['evening_cash_minor'] = Variable<int>(eveningCashMinor.value);
    }
    if (inkassMinor.present) {
      map['inkass_minor'] = Variable<int>(inkassMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRecordsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('closedAt: $closedAt, ')
          ..write('staffNames: $staffNames, ')
          ..write('closedByStaffId: $closedByStaffId, ')
          ..write('revenueMinor: $revenueMinor, ')
          ..write('qrMinor: $qrMinor, ')
          ..write('cardMinor: $cardMinor, ')
          ..write('cashMinor: $cashMinor, ')
          ..write('morningCashMinor: $morningCashMinor, ')
          ..write('eveningCashMinor: $eveningCashMinor, ')
          ..write('inkassMinor: $inkassMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftWriteoffsTable extends ShiftWriteoffs
    with TableInfo<$ShiftWriteoffsTable, ShiftWriteoffRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftWriteoffsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
      'shift_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('шт'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, shiftId, productId, productName, quantity, unit, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_writeoffs';
  @override
  VerificationContext validateIntegrity(Insertable<ShiftWriteoffRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftWriteoffRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftWriteoffRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ShiftWriteoffsTable createAlias(String alias) {
    return $ShiftWriteoffsTable(attachedDatabase, alias);
  }
}

class ShiftWriteoffRow extends DataClass
    implements Insertable<ShiftWriteoffRow> {
  final String id;
  final String shiftId;

  /// Ссылка на товар каталога, если списание сделано по товару
  /// (десерты); у ручных списаний её нет.
  final String? productId;

  /// Название на момент списания.
  final String productName;
  final double quantity;
  final String unit;
  final DateTime createdAt;
  const ShiftWriteoffRow(
      {required this.id,
      required this.shiftId,
      this.productId,
      required this.productName,
      required this.quantity,
      required this.unit,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shift_id'] = Variable<String>(shiftId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ShiftWriteoffsCompanion toCompanion(bool nullToAbsent) {
    return ShiftWriteoffsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      unit: Value(unit),
      createdAt: Value(createdAt),
    );
  }

  factory ShiftWriteoffRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftWriteoffRow(
      id: serializer.fromJson<String>(json['id']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      productId: serializer.fromJson<String?>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shiftId': serializer.toJson<String>(shiftId),
      'productId': serializer.toJson<String?>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ShiftWriteoffRow copyWith(
          {String? id,
          String? shiftId,
          Value<String?> productId = const Value.absent(),
          String? productName,
          double? quantity,
          String? unit,
          DateTime? createdAt}) =>
      ShiftWriteoffRow(
        id: id ?? this.id,
        shiftId: shiftId ?? this.shiftId,
        productId: productId.present ? productId.value : this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        createdAt: createdAt ?? this.createdAt,
      );
  ShiftWriteoffRow copyWithCompanion(ShiftWriteoffsCompanion data) {
    return ShiftWriteoffRow(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftWriteoffRow(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, shiftId, productId, productName, quantity, unit, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftWriteoffRow &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.createdAt == this.createdAt);
}

class ShiftWriteoffsCompanion extends UpdateCompanion<ShiftWriteoffRow> {
  final Value<String> id;
  final Value<String> shiftId;
  final Value<String?> productId;
  final Value<String> productName;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ShiftWriteoffsCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftWriteoffsCompanion.insert({
    required String id,
    required String shiftId,
    this.productId = const Value.absent(),
    required String productName,
    required double quantity,
    this.unit = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        shiftId = Value(shiftId),
        productName = Value(productName),
        quantity = Value(quantity),
        createdAt = Value(createdAt);
  static Insertable<ShiftWriteoffRow> custom({
    Expression<String>? id,
    Expression<String>? shiftId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftWriteoffsCompanion copyWith(
      {Value<String>? id,
      Value<String>? shiftId,
      Value<String?>? productId,
      Value<String>? productName,
      Value<double>? quantity,
      Value<String>? unit,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ShiftWriteoffsCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftWriteoffsCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockLevelsTable extends StockLevels
    with TableInfo<$StockLevelsTable, StockLevelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remainingMeta =
      const VerificationMeta('remaining');
  @override
  late final GeneratedColumn<double> remaining = GeneratedColumn<double>(
      'remaining', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _measuredAtMeta =
      const VerificationMeta('measuredAt');
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
      'measured_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [venueId, productId, remaining, measuredAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_levels';
  @override
  VerificationContext validateIntegrity(Insertable<StockLevelRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('remaining')) {
      context.handle(_remainingMeta,
          remaining.isAcceptableOrUnknown(data['remaining']!, _remainingMeta));
    } else if (isInserting) {
      context.missing(_remainingMeta);
    }
    if (data.containsKey('measured_at')) {
      context.handle(
          _measuredAtMeta,
          measuredAt.isAcceptableOrUnknown(
              data['measured_at']!, _measuredAtMeta));
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {venueId, productId};
  @override
  StockLevelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockLevelRow(
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      remaining: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}remaining'])!,
      measuredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}measured_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $StockLevelsTable createAlias(String alias) {
    return $StockLevelsTable(attachedDatabase, alias);
  }
}

class StockLevelRow extends DataClass implements Insertable<StockLevelRow> {
  final String venueId;
  final String productId;
  final double remaining;
  final DateTime measuredAt;
  final DateTime updatedAt;
  const StockLevelRow(
      {required this.venueId,
      required this.productId,
      required this.remaining,
      required this.measuredAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['venue_id'] = Variable<String>(venueId);
    map['product_id'] = Variable<String>(productId);
    map['remaining'] = Variable<double>(remaining);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StockLevelsCompanion toCompanion(bool nullToAbsent) {
    return StockLevelsCompanion(
      venueId: Value(venueId),
      productId: Value(productId),
      remaining: Value(remaining),
      measuredAt: Value(measuredAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StockLevelRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockLevelRow(
      venueId: serializer.fromJson<String>(json['venueId']),
      productId: serializer.fromJson<String>(json['productId']),
      remaining: serializer.fromJson<double>(json['remaining']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'venueId': serializer.toJson<String>(venueId),
      'productId': serializer.toJson<String>(productId),
      'remaining': serializer.toJson<double>(remaining),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StockLevelRow copyWith(
          {String? venueId,
          String? productId,
          double? remaining,
          DateTime? measuredAt,
          DateTime? updatedAt}) =>
      StockLevelRow(
        venueId: venueId ?? this.venueId,
        productId: productId ?? this.productId,
        remaining: remaining ?? this.remaining,
        measuredAt: measuredAt ?? this.measuredAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  StockLevelRow copyWithCompanion(StockLevelsCompanion data) {
    return StockLevelRow(
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      productId: data.productId.present ? data.productId.value : this.productId,
      remaining: data.remaining.present ? data.remaining.value : this.remaining,
      measuredAt:
          data.measuredAt.present ? data.measuredAt.value : this.measuredAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockLevelRow(')
          ..write('venueId: $venueId, ')
          ..write('productId: $productId, ')
          ..write('remaining: $remaining, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(venueId, productId, remaining, measuredAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockLevelRow &&
          other.venueId == this.venueId &&
          other.productId == this.productId &&
          other.remaining == this.remaining &&
          other.measuredAt == this.measuredAt &&
          other.updatedAt == this.updatedAt);
}

class StockLevelsCompanion extends UpdateCompanion<StockLevelRow> {
  final Value<String> venueId;
  final Value<String> productId;
  final Value<double> remaining;
  final Value<DateTime> measuredAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StockLevelsCompanion({
    this.venueId = const Value.absent(),
    this.productId = const Value.absent(),
    this.remaining = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockLevelsCompanion.insert({
    required String venueId,
    required String productId,
    required double remaining,
    required DateTime measuredAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : venueId = Value(venueId),
        productId = Value(productId),
        remaining = Value(remaining),
        measuredAt = Value(measuredAt),
        updatedAt = Value(updatedAt);
  static Insertable<StockLevelRow> custom({
    Expression<String>? venueId,
    Expression<String>? productId,
    Expression<double>? remaining,
    Expression<DateTime>? measuredAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (venueId != null) 'venue_id': venueId,
      if (productId != null) 'product_id': productId,
      if (remaining != null) 'remaining': remaining,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockLevelsCompanion copyWith(
      {Value<String>? venueId,
      Value<String>? productId,
      Value<double>? remaining,
      Value<DateTime>? measuredAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return StockLevelsCompanion(
      venueId: venueId ?? this.venueId,
      productId: productId ?? this.productId,
      remaining: remaining ?? this.remaining,
      measuredAt: measuredAt ?? this.measuredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (remaining.present) {
      map['remaining'] = Variable<double>(remaining.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockLevelsCompanion(')
          ..write('venueId: $venueId, ')
          ..write('productId: $productId, ')
          ..write('remaining: $remaining, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 16),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _staffIdMeta =
      const VerificationMeta('staffId');
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
      'staff_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        venueId,
        productId,
        kind,
        quantity,
        occurredAt,
        sourceType,
        sourceId,
        staffId,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(Insertable<StockMovementRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    }
    if (data.containsKey('staff_id')) {
      context.handle(_staffIdMeta,
          staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovementRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type']),
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id']),
      staffId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class StockMovementRow extends DataClass
    implements Insertable<StockMovementRow> {
  final String id;
  final String venueId;
  final String productId;

  /// 'baseline' — стартовая инвентаризация (точка отсчёта),
  /// 'receipt' — приход по накладной,
  /// 'sale' — расход по продажам,
  /// 'writeoff' — списание,
  /// 'count' — результат инвентаризации,
  /// 'adjustment' — ручная корректировка.
  final String kind;
  final double quantity;
  final DateTime occurredAt;

  /// Документ-источник: накладная, смена, инвентаризация.
  final String? sourceType;
  final String? sourceId;
  final String? staffId;
  final String? note;
  final DateTime createdAt;
  const StockMovementRow(
      {required this.id,
      required this.venueId,
      required this.productId,
      required this.kind,
      required this.quantity,
      required this.occurredAt,
      this.sourceType,
      this.sourceId,
      this.staffId,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['venue_id'] = Variable<String>(venueId);
    map['product_id'] = Variable<String>(productId);
    map['kind'] = Variable<String>(kind);
    map['quantity'] = Variable<double>(quantity);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || sourceType != null) {
      map['source_type'] = Variable<String>(sourceType);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || staffId != null) {
      map['staff_id'] = Variable<String>(staffId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      venueId: Value(venueId),
      productId: Value(productId),
      kind: Value(kind),
      quantity: Value(quantity),
      occurredAt: Value(occurredAt),
      sourceType: sourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceType),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      staffId: staffId == null && nullToAbsent
          ? const Value.absent()
          : Value(staffId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory StockMovementRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovementRow(
      id: serializer.fromJson<String>(json['id']),
      venueId: serializer.fromJson<String>(json['venueId']),
      productId: serializer.fromJson<String>(json['productId']),
      kind: serializer.fromJson<String>(json['kind']),
      quantity: serializer.fromJson<double>(json['quantity']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      sourceType: serializer.fromJson<String?>(json['sourceType']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      staffId: serializer.fromJson<String?>(json['staffId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'venueId': serializer.toJson<String>(venueId),
      'productId': serializer.toJson<String>(productId),
      'kind': serializer.toJson<String>(kind),
      'quantity': serializer.toJson<double>(quantity),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'sourceType': serializer.toJson<String?>(sourceType),
      'sourceId': serializer.toJson<String?>(sourceId),
      'staffId': serializer.toJson<String?>(staffId),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StockMovementRow copyWith(
          {String? id,
          String? venueId,
          String? productId,
          String? kind,
          double? quantity,
          DateTime? occurredAt,
          Value<String?> sourceType = const Value.absent(),
          Value<String?> sourceId = const Value.absent(),
          Value<String?> staffId = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      StockMovementRow(
        id: id ?? this.id,
        venueId: venueId ?? this.venueId,
        productId: productId ?? this.productId,
        kind: kind ?? this.kind,
        quantity: quantity ?? this.quantity,
        occurredAt: occurredAt ?? this.occurredAt,
        sourceType: sourceType.present ? sourceType.value : this.sourceType,
        sourceId: sourceId.present ? sourceId.value : this.sourceId,
        staffId: staffId.present ? staffId.value : this.staffId,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  StockMovementRow copyWithCompanion(StockMovementsCompanion data) {
    return StockMovementRow(
      id: data.id.present ? data.id.value : this.id,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      productId: data.productId.present ? data.productId.value : this.productId,
      kind: data.kind.present ? data.kind.value : this.kind,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementRow(')
          ..write('id: $id, ')
          ..write('venueId: $venueId, ')
          ..write('productId: $productId, ')
          ..write('kind: $kind, ')
          ..write('quantity: $quantity, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('staffId: $staffId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, venueId, productId, kind, quantity,
      occurredAt, sourceType, sourceId, staffId, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovementRow &&
          other.id == this.id &&
          other.venueId == this.venueId &&
          other.productId == this.productId &&
          other.kind == this.kind &&
          other.quantity == this.quantity &&
          other.occurredAt == this.occurredAt &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.staffId == this.staffId &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovementRow> {
  final Value<String> id;
  final Value<String> venueId;
  final Value<String> productId;
  final Value<String> kind;
  final Value<double> quantity;
  final Value<DateTime> occurredAt;
  final Value<String?> sourceType;
  final Value<String?> sourceId;
  final Value<String?> staffId;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.venueId = const Value.absent(),
    this.productId = const Value.absent(),
    this.kind = const Value.absent(),
    this.quantity = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.staffId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    required String id,
    required String venueId,
    required String productId,
    required String kind,
    required double quantity,
    required DateTime occurredAt,
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.staffId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        venueId = Value(venueId),
        productId = Value(productId),
        kind = Value(kind),
        quantity = Value(quantity),
        occurredAt = Value(occurredAt),
        createdAt = Value(createdAt);
  static Insertable<StockMovementRow> custom({
    Expression<String>? id,
    Expression<String>? venueId,
    Expression<String>? productId,
    Expression<String>? kind,
    Expression<double>? quantity,
    Expression<DateTime>? occurredAt,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? staffId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (venueId != null) 'venue_id': venueId,
      if (productId != null) 'product_id': productId,
      if (kind != null) 'kind': kind,
      if (quantity != null) 'quantity': quantity,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (staffId != null) 'staff_id': staffId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? venueId,
      Value<String>? productId,
      Value<String>? kind,
      Value<double>? quantity,
      Value<DateTime>? occurredAt,
      Value<String?>? sourceType,
      Value<String?>? sourceId,
      Value<String?>? staffId,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      productId: productId ?? this.productId,
      kind: kind ?? this.kind,
      quantity: quantity ?? this.quantity,
      occurredAt: occurredAt ?? this.occurredAt,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      staffId: staffId ?? this.staffId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('venueId: $venueId, ')
          ..write('productId: $productId, ')
          ..write('kind: $kind, ')
          ..write('quantity: $quantity, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('staffId: $staffId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
      'at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _staffIdMeta =
      const VerificationMeta('staffId');
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
      'staff_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 16),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _beforeJsonMeta =
      const VerificationMeta('beforeJson');
  @override
  late final GeneratedColumn<String> beforeJson = GeneratedColumn<String>(
      'before_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _afterJsonMeta =
      const VerificationMeta('afterJson');
  @override
  late final GeneratedColumn<String> afterJson = GeneratedColumn<String>(
      'after_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        venueId,
        at,
        staffId,
        entity,
        entityId,
        action,
        beforeJson,
        afterJson,
        reason
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLogRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(_staffIdMeta,
          staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta));
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('before_json')) {
      context.handle(
          _beforeJsonMeta,
          beforeJson.isAcceptableOrUnknown(
              data['before_json']!, _beforeJsonMeta));
    }
    if (data.containsKey('after_json')) {
      context.handle(_afterJsonMeta,
          afterJson.isAcceptableOrUnknown(data['after_json']!, _afterJsonMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      at: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      staffId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_id']),
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      beforeJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}before_json']),
      afterJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}after_json']),
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final String id;
  final String venueId;
  final DateTime at;
  final String? staffId;

  /// Тип объекта ('product', 'receipt', ...) и его id.
  final String entity;
  final String entityId;

  /// 'create', 'update', 'delete'.
  final String action;
  final String? beforeJson;
  final String? afterJson;
  final String? reason;
  const AuditLogRow(
      {required this.id,
      required this.venueId,
      required this.at,
      this.staffId,
      required this.entity,
      required this.entityId,
      required this.action,
      this.beforeJson,
      this.afterJson,
      this.reason});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['venue_id'] = Variable<String>(venueId);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || staffId != null) {
      map['staff_id'] = Variable<String>(staffId);
    }
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || beforeJson != null) {
      map['before_json'] = Variable<String>(beforeJson);
    }
    if (!nullToAbsent || afterJson != null) {
      map['after_json'] = Variable<String>(afterJson);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      venueId: Value(venueId),
      at: Value(at),
      staffId: staffId == null && nullToAbsent
          ? const Value.absent()
          : Value(staffId),
      entity: Value(entity),
      entityId: Value(entityId),
      action: Value(action),
      beforeJson: beforeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(beforeJson),
      afterJson: afterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(afterJson),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
    );
  }

  factory AuditLogRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      id: serializer.fromJson<String>(json['id']),
      venueId: serializer.fromJson<String>(json['venueId']),
      at: serializer.fromJson<DateTime>(json['at']),
      staffId: serializer.fromJson<String?>(json['staffId']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      beforeJson: serializer.fromJson<String?>(json['beforeJson']),
      afterJson: serializer.fromJson<String?>(json['afterJson']),
      reason: serializer.fromJson<String?>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'venueId': serializer.toJson<String>(venueId),
      'at': serializer.toJson<DateTime>(at),
      'staffId': serializer.toJson<String?>(staffId),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'beforeJson': serializer.toJson<String?>(beforeJson),
      'afterJson': serializer.toJson<String?>(afterJson),
      'reason': serializer.toJson<String?>(reason),
    };
  }

  AuditLogRow copyWith(
          {String? id,
          String? venueId,
          DateTime? at,
          Value<String?> staffId = const Value.absent(),
          String? entity,
          String? entityId,
          String? action,
          Value<String?> beforeJson = const Value.absent(),
          Value<String?> afterJson = const Value.absent(),
          Value<String?> reason = const Value.absent()}) =>
      AuditLogRow(
        id: id ?? this.id,
        venueId: venueId ?? this.venueId,
        at: at ?? this.at,
        staffId: staffId.present ? staffId.value : this.staffId,
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
        action: action ?? this.action,
        beforeJson: beforeJson.present ? beforeJson.value : this.beforeJson,
        afterJson: afterJson.present ? afterJson.value : this.afterJson,
        reason: reason.present ? reason.value : this.reason,
      );
  AuditLogRow copyWithCompanion(AuditLogCompanion data) {
    return AuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      at: data.at.present ? data.at.value : this.at,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      beforeJson:
          data.beforeJson.present ? data.beforeJson.value : this.beforeJson,
      afterJson: data.afterJson.present ? data.afterJson.value : this.afterJson,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('id: $id, ')
          ..write('venueId: $venueId, ')
          ..write('at: $at, ')
          ..write('staffId: $staffId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, venueId, at, staffId, entity, entityId,
      action, beforeJson, afterJson, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.id == this.id &&
          other.venueId == this.venueId &&
          other.at == this.at &&
          other.staffId == this.staffId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.beforeJson == this.beforeJson &&
          other.afterJson == this.afterJson &&
          other.reason == this.reason);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<String> id;
  final Value<String> venueId;
  final Value<DateTime> at;
  final Value<String?> staffId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String?> beforeJson;
  final Value<String?> afterJson;
  final Value<String?> reason;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.venueId = const Value.absent(),
    this.at = const Value.absent(),
    this.staffId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    required String id,
    required String venueId,
    required DateTime at,
    this.staffId = const Value.absent(),
    required String entity,
    required String entityId,
    required String action,
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        venueId = Value(venueId),
        at = Value(at),
        entity = Value(entity),
        entityId = Value(entityId),
        action = Value(action);
  static Insertable<AuditLogRow> custom({
    Expression<String>? id,
    Expression<String>? venueId,
    Expression<DateTime>? at,
    Expression<String>? staffId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? beforeJson,
    Expression<String>? afterJson,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (venueId != null) 'venue_id': venueId,
      if (at != null) 'at': at,
      if (staffId != null) 'staff_id': staffId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (beforeJson != null) 'before_json': beforeJson,
      if (afterJson != null) 'after_json': afterJson,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith(
      {Value<String>? id,
      Value<String>? venueId,
      Value<DateTime>? at,
      Value<String?>? staffId,
      Value<String>? entity,
      Value<String>? entityId,
      Value<String>? action,
      Value<String?>? beforeJson,
      Value<String?>? afterJson,
      Value<String?>? reason,
      Value<int>? rowid}) {
    return AuditLogCompanion(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      at: at ?? this.at,
      staffId: staffId ?? this.staffId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (beforeJson.present) {
      map['before_json'] = Variable<String>(beforeJson.value);
    }
    if (afterJson.present) {
      map['after_json'] = Variable<String>(afterJson.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('venueId: $venueId, ')
          ..write('at: $at, ')
          ..write('staffId: $staffId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notificationIdMeta =
      const VerificationMeta('notificationId');
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
      'notification_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 16),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
      'hour', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
      'minute', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weekdayMeta =
      const VerificationMeta('weekday');
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
      'weekday', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dayOfMonthMeta =
      const VerificationMeta('dayOfMonth');
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
      'day_of_month', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _remindDayBeforeMeta =
      const VerificationMeta('remindDayBefore');
  @override
  late final GeneratedColumn<bool> remindDayBefore = GeneratedColumn<bool>(
      'remind_day_before', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("remind_day_before" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        venueId,
        notificationId,
        title,
        frequency,
        hour,
        minute,
        weekday,
        dayOfMonth,
        remindDayBefore,
        isEnabled
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
          _notificationIdMeta,
          notificationId.isAcceptableOrUnknown(
              data['notification_id']!, _notificationIdMeta));
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
          _hourMeta, hour.isAcceptableOrUnknown(data['hour']!, _hourMeta));
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(_minuteMeta,
          minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta));
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(_weekdayMeta,
          weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta));
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
          _dayOfMonthMeta,
          dayOfMonth.isAcceptableOrUnknown(
              data['day_of_month']!, _dayOfMonthMeta));
    }
    if (data.containsKey('remind_day_before')) {
      context.handle(
          _remindDayBeforeMeta,
          remindDayBefore.isAcceptableOrUnknown(
              data['remind_day_before']!, _remindDayBeforeMeta));
    }
    if (data.containsKey('is_enabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      notificationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notification_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      hour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hour'])!,
      minute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minute'])!,
      weekday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weekday']),
      dayOfMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_month']),
      remindDayBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}remind_day_before'])!,
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String venueId;

  /// Числовой идентификатор для flutter_local_notifications.
  final int notificationId;
  final String title;

  /// 'daily', 'weekly' или 'monthly'.
  final String frequency;
  final int hour;
  final int minute;

  /// 1–7, только для еженедельных.
  final int? weekday;

  /// 1–31, только для ежемесячных.
  final int? dayOfMonth;

  /// Для ежемесячного напоминания об инвентаризации — ещё и за день до.
  final bool remindDayBefore;
  final bool isEnabled;
  const ReminderRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.venueId,
      required this.notificationId,
      required this.title,
      required this.frequency,
      required this.hour,
      required this.minute,
      this.weekday,
      this.dayOfMonth,
      required this.remindDayBefore,
      required this.isEnabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['venue_id'] = Variable<String>(venueId);
    map['notification_id'] = Variable<int>(notificationId);
    map['title'] = Variable<String>(title);
    map['frequency'] = Variable<String>(frequency);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    if (!nullToAbsent || weekday != null) {
      map['weekday'] = Variable<int>(weekday);
    }
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    map['remind_day_before'] = Variable<bool>(remindDayBefore);
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      venueId: Value(venueId),
      notificationId: Value(notificationId),
      title: Value(title),
      frequency: Value(frequency),
      hour: Value(hour),
      minute: Value(minute),
      weekday: weekday == null && nullToAbsent
          ? const Value.absent()
          : Value(weekday),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      remindDayBefore: Value(remindDayBefore),
      isEnabled: Value(isEnabled),
    );
  }

  factory ReminderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      venueId: serializer.fromJson<String>(json['venueId']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      title: serializer.fromJson<String>(json['title']),
      frequency: serializer.fromJson<String>(json['frequency']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      weekday: serializer.fromJson<int?>(json['weekday']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      remindDayBefore: serializer.fromJson<bool>(json['remindDayBefore']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'venueId': serializer.toJson<String>(venueId),
      'notificationId': serializer.toJson<int>(notificationId),
      'title': serializer.toJson<String>(title),
      'frequency': serializer.toJson<String>(frequency),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'weekday': serializer.toJson<int?>(weekday),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'remindDayBefore': serializer.toJson<bool>(remindDayBefore),
      'isEnabled': serializer.toJson<bool>(isEnabled),
    };
  }

  ReminderRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? venueId,
          int? notificationId,
          String? title,
          String? frequency,
          int? hour,
          int? minute,
          Value<int?> weekday = const Value.absent(),
          Value<int?> dayOfMonth = const Value.absent(),
          bool? remindDayBefore,
          bool? isEnabled}) =>
      ReminderRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        venueId: venueId ?? this.venueId,
        notificationId: notificationId ?? this.notificationId,
        title: title ?? this.title,
        frequency: frequency ?? this.frequency,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        weekday: weekday.present ? weekday.value : this.weekday,
        dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
        remindDayBefore: remindDayBefore ?? this.remindDayBefore,
        isEnabled: isEnabled ?? this.isEnabled,
      );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      title: data.title.present ? data.title.value : this.title,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      dayOfMonth:
          data.dayOfMonth.present ? data.dayOfMonth.value : this.dayOfMonth,
      remindDayBefore: data.remindDayBefore.present
          ? data.remindDayBefore.value
          : this.remindDayBefore,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('notificationId: $notificationId, ')
          ..write('title: $title, ')
          ..write('frequency: $frequency, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('weekday: $weekday, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('remindDayBefore: $remindDayBefore, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      venueId,
      notificationId,
      title,
      frequency,
      hour,
      minute,
      weekday,
      dayOfMonth,
      remindDayBefore,
      isEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.venueId == this.venueId &&
          other.notificationId == this.notificationId &&
          other.title == this.title &&
          other.frequency == this.frequency &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.weekday == this.weekday &&
          other.dayOfMonth == this.dayOfMonth &&
          other.remindDayBefore == this.remindDayBefore &&
          other.isEnabled == this.isEnabled);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> venueId;
  final Value<int> notificationId;
  final Value<String> title;
  final Value<String> frequency;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int?> weekday;
  final Value<int?> dayOfMonth;
  final Value<bool> remindDayBefore;
  final Value<bool> isEnabled;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.venueId = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.title = const Value.absent(),
    this.frequency = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.weekday = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.remindDayBefore = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String venueId,
    required int notificationId,
    required String title,
    required String frequency,
    required int hour,
    required int minute,
    this.weekday = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.remindDayBefore = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        venueId = Value(venueId),
        notificationId = Value(notificationId),
        title = Value(title),
        frequency = Value(frequency),
        hour = Value(hour),
        minute = Value(minute);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? venueId,
    Expression<int>? notificationId,
    Expression<String>? title,
    Expression<String>? frequency,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? weekday,
    Expression<int>? dayOfMonth,
    Expression<bool>? remindDayBefore,
    Expression<bool>? isEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (venueId != null) 'venue_id': venueId,
      if (notificationId != null) 'notification_id': notificationId,
      if (title != null) 'title': title,
      if (frequency != null) 'frequency': frequency,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (weekday != null) 'weekday': weekday,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (remindDayBefore != null) 'remind_day_before': remindDayBefore,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? venueId,
      Value<int>? notificationId,
      Value<String>? title,
      Value<String>? frequency,
      Value<int>? hour,
      Value<int>? minute,
      Value<int?>? weekday,
      Value<int?>? dayOfMonth,
      Value<bool>? remindDayBefore,
      Value<bool>? isEnabled,
      Value<int>? rowid}) {
    return RemindersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      venueId: venueId ?? this.venueId,
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekday: weekday ?? this.weekday,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      remindDayBefore: remindDayBefore ?? this.remindDayBefore,
      isEnabled: isEnabled ?? this.isEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (remindDayBefore.present) {
      map['remind_day_before'] = Variable<bool>(remindDayBefore.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('notificationId: $notificationId, ')
          ..write('title: $title, ')
          ..write('frequency: $frequency, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('weekday: $weekday, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('remindDayBefore: $remindDayBefore, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportTemplatesTable extends ExportTemplates
    with TableInfo<$ExportTemplatesTable, ExportTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _venueIdMeta =
      const VerificationMeta('venueId');
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
      'venue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _templateJsonMeta =
      const VerificationMeta('templateJson');
  @override
  late final GeneratedColumn<String> templateJson = GeneratedColumn<String>(
      'template_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, createdAt, updatedAt, deletedAt, venueId, name, templateJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_templates';
  @override
  VerificationContext validateIntegrity(Insertable<ExportTemplateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('venue_id')) {
      context.handle(_venueIdMeta,
          venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta));
    } else if (isInserting) {
      context.missing(_venueIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('template_json')) {
      context.handle(
          _templateJsonMeta,
          templateJson.isAcceptableOrUnknown(
              data['template_json']!, _templateJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportTemplateRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      venueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      templateJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_json'])!,
    );
  }

  @override
  $ExportTemplatesTable createAlias(String alias) {
    return $ExportTemplatesTable(attachedDatabase, alias);
  }
}

class ExportTemplateRow extends DataClass
    implements Insertable<ExportTemplateRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String venueId;
  final String name;

  /// Шаблон в том же JSON-формате, что и CustomTemplate.toJson().
  final String templateJson;
  const ExportTemplateRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.venueId,
      required this.name,
      required this.templateJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['venue_id'] = Variable<String>(venueId);
    map['name'] = Variable<String>(name);
    map['template_json'] = Variable<String>(templateJson);
    return map;
  }

  ExportTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ExportTemplatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      venueId: Value(venueId),
      name: Value(name),
      templateJson: Value(templateJson),
    );
  }

  factory ExportTemplateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      venueId: serializer.fromJson<String>(json['venueId']),
      name: serializer.fromJson<String>(json['name']),
      templateJson: serializer.fromJson<String>(json['templateJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'venueId': serializer.toJson<String>(venueId),
      'name': serializer.toJson<String>(name),
      'templateJson': serializer.toJson<String>(templateJson),
    };
  }

  ExportTemplateRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? venueId,
          String? name,
          String? templateJson}) =>
      ExportTemplateRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        venueId: venueId ?? this.venueId,
        name: name ?? this.name,
        templateJson: templateJson ?? this.templateJson,
      );
  ExportTemplateRow copyWithCompanion(ExportTemplatesCompanion data) {
    return ExportTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      name: data.name.present ? data.name.value : this.name,
      templateJson: data.templateJson.present
          ? data.templateJson.value
          : this.templateJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportTemplateRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('name: $name, ')
          ..write('templateJson: $templateJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, createdAt, updatedAt, deletedAt, venueId, name, templateJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportTemplateRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.venueId == this.venueId &&
          other.name == this.name &&
          other.templateJson == this.templateJson);
}

class ExportTemplatesCompanion extends UpdateCompanion<ExportTemplateRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> venueId;
  final Value<String> name;
  final Value<String> templateJson;
  final Value<int> rowid;
  const ExportTemplatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.venueId = const Value.absent(),
    this.name = const Value.absent(),
    this.templateJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportTemplatesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String venueId,
    required String name,
    this.templateJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        venueId = Value(venueId),
        name = Value(name);
  static Insertable<ExportTemplateRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? venueId,
    Expression<String>? name,
    Expression<String>? templateJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (venueId != null) 'venue_id': venueId,
      if (name != null) 'name': name,
      if (templateJson != null) 'template_json': templateJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportTemplatesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? venueId,
      Value<String>? name,
      Value<String>? templateJson,
      Value<int>? rowid}) {
    return ExportTemplatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      venueId: venueId ?? this.venueId,
      name: name ?? this.name,
      templateJson: templateJson ?? this.templateJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (templateJson.present) {
      map['template_json'] = Variable<String>(templateJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('venueId: $venueId, ')
          ..write('name: $name, ')
          ..write('templateJson: $templateJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VenuesTable venues = $VenuesTable(this);
  late final $DepartmentsTable departments = $DepartmentsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $StaffMembersTable staffMembers = $StaffMembersTable(this);
  late final $HistoryEntriesTable historyEntries = $HistoryEntriesTable(this);
  late final $DocumentLinesTable documentLines = $DocumentLinesTable(this);
  late final $ShiftRecordsTable shiftRecords = $ShiftRecordsTable(this);
  late final $ShiftWriteoffsTable shiftWriteoffs = $ShiftWriteoffsTable(this);
  late final $StockLevelsTable stockLevels = $StockLevelsTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $ExportTemplatesTable exportTemplates =
      $ExportTemplatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        venues,
        departments,
        categories,
        products,
        staffMembers,
        historyEntries,
        documentLines,
        shiftRecords,
        shiftWriteoffs,
        stockLevels,
        stockMovements,
        auditLog,
        reminders,
        exportTemplates
      ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$VenuesTableCreateCompanionBuilder = VenuesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String code,
  required String name,
  Value<String> reportName,
  required String currency,
  Value<String?> logoPath,
  Value<bool> showShiftDesserts,
  Value<int> rowid,
});
typedef $$VenuesTableUpdateCompanionBuilder = VenuesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> code,
  Value<String> name,
  Value<String> reportName,
  Value<String> currency,
  Value<String?> logoPath,
  Value<bool> showShiftDesserts,
  Value<int> rowid,
});

class $$VenuesTableFilterComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reportName => $composableBuilder(
      column: $table.reportName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoPath => $composableBuilder(
      column: $table.logoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showShiftDesserts => $composableBuilder(
      column: $table.showShiftDesserts,
      builder: (column) => ColumnFilters(column));
}

class $$VenuesTableOrderingComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reportName => $composableBuilder(
      column: $table.reportName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoPath => $composableBuilder(
      column: $table.logoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showShiftDesserts => $composableBuilder(
      column: $table.showShiftDesserts,
      builder: (column) => ColumnOrderings(column));
}

class $$VenuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VenuesTable> {
  $$VenuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get reportName => $composableBuilder(
      column: $table.reportName, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<bool> get showShiftDesserts => $composableBuilder(
      column: $table.showShiftDesserts, builder: (column) => column);
}

class $$VenuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VenuesTable,
    VenueRow,
    $$VenuesTableFilterComposer,
    $$VenuesTableOrderingComposer,
    $$VenuesTableAnnotationComposer,
    $$VenuesTableCreateCompanionBuilder,
    $$VenuesTableUpdateCompanionBuilder,
    (VenueRow, BaseReferences<_$AppDatabase, $VenuesTable, VenueRow>),
    VenueRow,
    PrefetchHooks Function()> {
  $$VenuesTableTableManager(_$AppDatabase db, $VenuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VenuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VenuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VenuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> reportName = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> logoPath = const Value.absent(),
            Value<bool> showShiftDesserts = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VenuesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            code: code,
            name: name,
            reportName: reportName,
            currency: currency,
            logoPath: logoPath,
            showShiftDesserts: showShiftDesserts,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String code,
            required String name,
            Value<String> reportName = const Value.absent(),
            required String currency,
            Value<String?> logoPath = const Value.absent(),
            Value<bool> showShiftDesserts = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VenuesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            code: code,
            name: name,
            reportName: reportName,
            currency: currency,
            logoPath: logoPath,
            showShiftDesserts: showShiftDesserts,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$VenuesTable, VenueRow>(table),
                    BaseReferences<_$AppDatabase, $VenuesTable, VenueRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VenuesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VenuesTable,
    VenueRow,
    $$VenuesTableFilterComposer,
    $$VenuesTableOrderingComposer,
    $$VenuesTableAnnotationComposer,
    $$VenuesTableCreateCompanionBuilder,
    $$VenuesTableUpdateCompanionBuilder,
    (VenueRow, BaseReferences<_$AppDatabase, $VenuesTable, VenueRow>),
    VenueRow,
    PrefetchHooks Function()>;
typedef $$DepartmentsTableCreateCompanionBuilder = DepartmentsCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String venueId,
  required String name,
  Value<String> iconKey,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$DepartmentsTableUpdateCompanionBuilder = DepartmentsCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> venueId,
  Value<String> name,
  Value<String> iconKey,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$DepartmentsTableFilterComposer
    extends Composer<_$AppDatabase, $DepartmentsTable> {
  $$DepartmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$DepartmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DepartmentsTable> {
  $$DepartmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$DepartmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DepartmentsTable> {
  $$DepartmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DepartmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DepartmentsTable,
    DepartmentRow,
    $$DepartmentsTableFilterComposer,
    $$DepartmentsTableOrderingComposer,
    $$DepartmentsTableAnnotationComposer,
    $$DepartmentsTableCreateCompanionBuilder,
    $$DepartmentsTableUpdateCompanionBuilder,
    (
      DepartmentRow,
      BaseReferences<_$AppDatabase, $DepartmentsTable, DepartmentRow>
    ),
    DepartmentRow,
    PrefetchHooks Function()> {
  $$DepartmentsTableTableManager(_$AppDatabase db, $DepartmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DepartmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DepartmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DepartmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DepartmentsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            name: name,
            iconKey: iconKey,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String venueId,
            required String name,
            Value<String> iconKey = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DepartmentsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            name: name,
            iconKey: iconKey,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DepartmentsTable, DepartmentRow>(table),
                    BaseReferences<_$AppDatabase, $DepartmentsTable,
                        DepartmentRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DepartmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DepartmentsTable,
    DepartmentRow,
    $$DepartmentsTableFilterComposer,
    $$DepartmentsTableOrderingComposer,
    $$DepartmentsTableAnnotationComposer,
    $$DepartmentsTableCreateCompanionBuilder,
    $$DepartmentsTableUpdateCompanionBuilder,
    (
      DepartmentRow,
      BaseReferences<_$AppDatabase, $DepartmentsTable, DepartmentRow>
    ),
    DepartmentRow,
    PrefetchHooks Function()>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String venueId,
  Value<String?> departmentId,
  required String name,
  Value<bool> isDessert,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> venueId,
  Value<String?> departmentId,
  Value<String> name,
  Value<bool> isDessert,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get departmentId => $composableBuilder(
      column: $table.departmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDessert => $composableBuilder(
      column: $table.isDessert, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get departmentId => $composableBuilder(
      column: $table.departmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDessert => $composableBuilder(
      column: $table.isDessert, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get departmentId => $composableBuilder(
      column: $table.departmentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDessert =>
      $composableBuilder(column: $table.isDessert, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<String?> departmentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isDessert = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            departmentId: departmentId,
            name: name,
            isDessert: isDessert,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String venueId,
            Value<String?> departmentId = const Value.absent(),
            required String name,
            Value<bool> isDessert = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            departmentId: departmentId,
            name: name,
            isDessert: isDessert,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CategoriesTable, CategoryRow>(table),
                    BaseReferences<_$AppDatabase, $CategoriesTable,
                        CategoryRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String venueId,
  Value<String?> categoryId,
  required String name,
  Value<String> unit,
  Value<String> inventoryUnit,
  Value<double> unitFactor,
  Value<double?> minStock,
  Value<String?> iikoProductId,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> venueId,
  Value<String?> categoryId,
  Value<String> name,
  Value<String> unit,
  Value<String> inventoryUnit,
  Value<double> unitFactor,
  Value<double?> minStock,
  Value<String?> iikoProductId,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inventoryUnit => $composableBuilder(
      column: $table.inventoryUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitFactor => $composableBuilder(
      column: $table.unitFactor, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minStock => $composableBuilder(
      column: $table.minStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iikoProductId => $composableBuilder(
      column: $table.iikoProductId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inventoryUnit => $composableBuilder(
      column: $table.inventoryUnit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitFactor => $composableBuilder(
      column: $table.unitFactor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minStock => $composableBuilder(
      column: $table.minStock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iikoProductId => $composableBuilder(
      column: $table.iikoProductId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get inventoryUnit => $composableBuilder(
      column: $table.inventoryUnit, builder: (column) => column);

  GeneratedColumn<double> get unitFactor => $composableBuilder(
      column: $table.unitFactor, builder: (column) => column);

  GeneratedColumn<double> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<String> get iikoProductId => $composableBuilder(
      column: $table.iikoProductId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>),
    ProductRow,
    PrefetchHooks Function()> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String> inventoryUnit = const Value.absent(),
            Value<double> unitFactor = const Value.absent(),
            Value<double?> minStock = const Value.absent(),
            Value<String?> iikoProductId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            categoryId: categoryId,
            name: name,
            unit: unit,
            inventoryUnit: inventoryUnit,
            unitFactor: unitFactor,
            minStock: minStock,
            iikoProductId: iikoProductId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String venueId,
            Value<String?> categoryId = const Value.absent(),
            required String name,
            Value<String> unit = const Value.absent(),
            Value<String> inventoryUnit = const Value.absent(),
            Value<double> unitFactor = const Value.absent(),
            Value<double?> minStock = const Value.absent(),
            Value<String?> iikoProductId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            categoryId: categoryId,
            name: name,
            unit: unit,
            inventoryUnit: inventoryUnit,
            unitFactor: unitFactor,
            minStock: minStock,
            iikoProductId: iikoProductId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProductsTable, ProductRow>(table),
                    BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>),
    ProductRow,
    PrefetchHooks Function()>;
typedef $$StaffMembersTableCreateCompanionBuilder = StaffMembersCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String venueId,
  required String fullName,
  Value<String> role,
  Value<String?> pinHash,
  Value<String?> pinSalt,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$StaffMembersTableUpdateCompanionBuilder = StaffMembersCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> venueId,
  Value<String> fullName,
  Value<String> role,
  Value<String?> pinHash,
  Value<String?> pinSalt,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$StaffMembersTableFilterComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinSalt => $composableBuilder(
      column: $table.pinSalt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$StaffMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinSalt => $composableBuilder(
      column: $table.pinSalt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$StaffMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<String> get pinSalt =>
      $composableBuilder(column: $table.pinSalt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$StaffMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StaffMembersTable,
    StaffMemberRow,
    $$StaffMembersTableFilterComposer,
    $$StaffMembersTableOrderingComposer,
    $$StaffMembersTableAnnotationComposer,
    $$StaffMembersTableCreateCompanionBuilder,
    $$StaffMembersTableUpdateCompanionBuilder,
    (
      StaffMemberRow,
      BaseReferences<_$AppDatabase, $StaffMembersTable, StaffMemberRow>
    ),
    StaffMemberRow,
    PrefetchHooks Function()> {
  $$StaffMembersTableTableManager(_$AppDatabase db, $StaffMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StaffMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StaffMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String?> pinHash = const Value.absent(),
            Value<String?> pinSalt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StaffMembersCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            fullName: fullName,
            role: role,
            pinHash: pinHash,
            pinSalt: pinSalt,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String venueId,
            required String fullName,
            Value<String> role = const Value.absent(),
            Value<String?> pinHash = const Value.absent(),
            Value<String?> pinSalt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StaffMembersCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            fullName: fullName,
            role: role,
            pinHash: pinHash,
            pinSalt: pinSalt,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$StaffMembersTable, StaffMemberRow>(table),
                    BaseReferences<_$AppDatabase, $StaffMembersTable,
                        StaffMemberRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StaffMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StaffMembersTable,
    StaffMemberRow,
    $$StaffMembersTableFilterComposer,
    $$StaffMembersTableOrderingComposer,
    $$StaffMembersTableAnnotationComposer,
    $$StaffMembersTableCreateCompanionBuilder,
    $$StaffMembersTableUpdateCompanionBuilder,
    (
      StaffMemberRow,
      BaseReferences<_$AppDatabase, $StaffMembersTable, StaffMemberRow>
    ),
    StaffMemberRow,
    PrefetchHooks Function()>;
typedef $$HistoryEntriesTableCreateCompanionBuilder = HistoryEntriesCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String venueId,
  required String kind,
  required String title,
  required String body,
  Value<String?> staffId,
  Value<String?> refId,
  Value<String?> attachmentPath,
  Value<int> rowid,
});
typedef $$HistoryEntriesTableUpdateCompanionBuilder = HistoryEntriesCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> venueId,
  Value<String> kind,
  Value<String> title,
  Value<String> body,
  Value<String?> staffId,
  Value<String?> refId,
  Value<String?> attachmentPath,
  Value<int> rowid,
});

class $$HistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refId => $composableBuilder(
      column: $table.refId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachmentPath => $composableBuilder(
      column: $table.attachmentPath,
      builder: (column) => ColumnFilters(column));
}

class $$HistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refId => $composableBuilder(
      column: $table.refId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachmentPath => $composableBuilder(
      column: $table.attachmentPath,
      builder: (column) => ColumnOrderings(column));
}

class $$HistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get attachmentPath => $composableBuilder(
      column: $table.attachmentPath, builder: (column) => column);
}

class $$HistoryEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HistoryEntriesTable,
    HistoryEntryRow,
    $$HistoryEntriesTableFilterComposer,
    $$HistoryEntriesTableOrderingComposer,
    $$HistoryEntriesTableAnnotationComposer,
    $$HistoryEntriesTableCreateCompanionBuilder,
    $$HistoryEntriesTableUpdateCompanionBuilder,
    (
      HistoryEntryRow,
      BaseReferences<_$AppDatabase, $HistoryEntriesTable, HistoryEntryRow>
    ),
    HistoryEntryRow,
    PrefetchHooks Function()> {
  $$HistoryEntriesTableTableManager(
      _$AppDatabase db, $HistoryEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String?> staffId = const Value.absent(),
            Value<String?> refId = const Value.absent(),
            Value<String?> attachmentPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HistoryEntriesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            kind: kind,
            title: title,
            body: body,
            staffId: staffId,
            refId: refId,
            attachmentPath: attachmentPath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String venueId,
            required String kind,
            required String title,
            required String body,
            Value<String?> staffId = const Value.absent(),
            Value<String?> refId = const Value.absent(),
            Value<String?> attachmentPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HistoryEntriesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            kind: kind,
            title: title,
            body: body,
            staffId: staffId,
            refId: refId,
            attachmentPath: attachmentPath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$HistoryEntriesTable, HistoryEntryRow>(table),
                    BaseReferences<_$AppDatabase, $HistoryEntriesTable,
                        HistoryEntryRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HistoryEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HistoryEntriesTable,
    HistoryEntryRow,
    $$HistoryEntriesTableFilterComposer,
    $$HistoryEntriesTableOrderingComposer,
    $$HistoryEntriesTableAnnotationComposer,
    $$HistoryEntriesTableCreateCompanionBuilder,
    $$HistoryEntriesTableUpdateCompanionBuilder,
    (
      HistoryEntryRow,
      BaseReferences<_$AppDatabase, $HistoryEntriesTable, HistoryEntryRow>
    ),
    HistoryEntryRow,
    PrefetchHooks Function()>;
typedef $$DocumentLinesTableCreateCompanionBuilder = DocumentLinesCompanion
    Function({
  required String id,
  required String venueId,
  required String documentId,
  Value<String?> productId,
  required String productName,
  Value<String> unit,
  Value<double?> ordered,
  required double quantity,
  Value<double?> price,
  Value<int> sortOrder,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DocumentLinesTableUpdateCompanionBuilder = DocumentLinesCompanion
    Function({
  Value<String> id,
  Value<String> venueId,
  Value<String> documentId,
  Value<String?> productId,
  Value<String> productName,
  Value<String> unit,
  Value<double?> ordered,
  Value<double> quantity,
  Value<double?> price,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DocumentLinesTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentLinesTable> {
  $$DocumentLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ordered => $composableBuilder(
      column: $table.ordered, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DocumentLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentLinesTable> {
  $$DocumentLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ordered => $composableBuilder(
      column: $table.ordered, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DocumentLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentLinesTable> {
  $$DocumentLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get ordered =>
      $composableBuilder(column: $table.ordered, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DocumentLinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentLinesTable,
    DocumentLineRow,
    $$DocumentLinesTableFilterComposer,
    $$DocumentLinesTableOrderingComposer,
    $$DocumentLinesTableAnnotationComposer,
    $$DocumentLinesTableCreateCompanionBuilder,
    $$DocumentLinesTableUpdateCompanionBuilder,
    (
      DocumentLineRow,
      BaseReferences<_$AppDatabase, $DocumentLinesTable, DocumentLineRow>
    ),
    DocumentLineRow,
    PrefetchHooks Function()> {
  $$DocumentLinesTableTableManager(_$AppDatabase db, $DocumentLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<String> documentId = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double?> ordered = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double?> price = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentLinesCompanion(
            id: id,
            venueId: venueId,
            documentId: documentId,
            productId: productId,
            productName: productName,
            unit: unit,
            ordered: ordered,
            quantity: quantity,
            price: price,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String venueId,
            required String documentId,
            Value<String?> productId = const Value.absent(),
            required String productName,
            Value<String> unit = const Value.absent(),
            Value<double?> ordered = const Value.absent(),
            required double quantity,
            Value<double?> price = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentLinesCompanion.insert(
            id: id,
            venueId: venueId,
            documentId: documentId,
            productId: productId,
            productName: productName,
            unit: unit,
            ordered: ordered,
            quantity: quantity,
            price: price,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DocumentLinesTable, DocumentLineRow>(table),
                    BaseReferences<_$AppDatabase, $DocumentLinesTable,
                        DocumentLineRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentLinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentLinesTable,
    DocumentLineRow,
    $$DocumentLinesTableFilterComposer,
    $$DocumentLinesTableOrderingComposer,
    $$DocumentLinesTableAnnotationComposer,
    $$DocumentLinesTableCreateCompanionBuilder,
    $$DocumentLinesTableUpdateCompanionBuilder,
    (
      DocumentLineRow,
      BaseReferences<_$AppDatabase, $DocumentLinesTable, DocumentLineRow>
    ),
    DocumentLineRow,
    PrefetchHooks Function()>;
typedef $$ShiftRecordsTableCreateCompanionBuilder = ShiftRecordsCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String venueId,
  required DateTime closedAt,
  Value<String> staffNames,
  Value<String?> closedByStaffId,
  Value<int> revenueMinor,
  Value<int> qrMinor,
  Value<int> cardMinor,
  Value<int> cashMinor,
  Value<int> morningCashMinor,
  Value<int> eveningCashMinor,
  Value<int> inkassMinor,
  Value<int> rowid,
});
typedef $$ShiftRecordsTableUpdateCompanionBuilder = ShiftRecordsCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> venueId,
  Value<DateTime> closedAt,
  Value<String> staffNames,
  Value<String?> closedByStaffId,
  Value<int> revenueMinor,
  Value<int> qrMinor,
  Value<int> cardMinor,
  Value<int> cashMinor,
  Value<int> morningCashMinor,
  Value<int> eveningCashMinor,
  Value<int> inkassMinor,
  Value<int> rowid,
});

class $$ShiftRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftRecordsTable> {
  $$ShiftRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffNames => $composableBuilder(
      column: $table.staffNames, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get closedByStaffId => $composableBuilder(
      column: $table.closedByStaffId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get revenueMinor => $composableBuilder(
      column: $table.revenueMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qrMinor => $composableBuilder(
      column: $table.qrMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cardMinor => $composableBuilder(
      column: $table.cardMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cashMinor => $composableBuilder(
      column: $table.cashMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get morningCashMinor => $composableBuilder(
      column: $table.morningCashMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eveningCashMinor => $composableBuilder(
      column: $table.eveningCashMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get inkassMinor => $composableBuilder(
      column: $table.inkassMinor, builder: (column) => ColumnFilters(column));
}

class $$ShiftRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftRecordsTable> {
  $$ShiftRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffNames => $composableBuilder(
      column: $table.staffNames, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get closedByStaffId => $composableBuilder(
      column: $table.closedByStaffId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get revenueMinor => $composableBuilder(
      column: $table.revenueMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qrMinor => $composableBuilder(
      column: $table.qrMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cardMinor => $composableBuilder(
      column: $table.cardMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cashMinor => $composableBuilder(
      column: $table.cashMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get morningCashMinor => $composableBuilder(
      column: $table.morningCashMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eveningCashMinor => $composableBuilder(
      column: $table.eveningCashMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get inkassMinor => $composableBuilder(
      column: $table.inkassMinor, builder: (column) => ColumnOrderings(column));
}

class $$ShiftRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftRecordsTable> {
  $$ShiftRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get staffNames => $composableBuilder(
      column: $table.staffNames, builder: (column) => column);

  GeneratedColumn<String> get closedByStaffId => $composableBuilder(
      column: $table.closedByStaffId, builder: (column) => column);

  GeneratedColumn<int> get revenueMinor => $composableBuilder(
      column: $table.revenueMinor, builder: (column) => column);

  GeneratedColumn<int> get qrMinor =>
      $composableBuilder(column: $table.qrMinor, builder: (column) => column);

  GeneratedColumn<int> get cardMinor =>
      $composableBuilder(column: $table.cardMinor, builder: (column) => column);

  GeneratedColumn<int> get cashMinor =>
      $composableBuilder(column: $table.cashMinor, builder: (column) => column);

  GeneratedColumn<int> get morningCashMinor => $composableBuilder(
      column: $table.morningCashMinor, builder: (column) => column);

  GeneratedColumn<int> get eveningCashMinor => $composableBuilder(
      column: $table.eveningCashMinor, builder: (column) => column);

  GeneratedColumn<int> get inkassMinor => $composableBuilder(
      column: $table.inkassMinor, builder: (column) => column);
}

class $$ShiftRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShiftRecordsTable,
    ShiftRow,
    $$ShiftRecordsTableFilterComposer,
    $$ShiftRecordsTableOrderingComposer,
    $$ShiftRecordsTableAnnotationComposer,
    $$ShiftRecordsTableCreateCompanionBuilder,
    $$ShiftRecordsTableUpdateCompanionBuilder,
    (ShiftRow, BaseReferences<_$AppDatabase, $ShiftRecordsTable, ShiftRow>),
    ShiftRow,
    PrefetchHooks Function()> {
  $$ShiftRecordsTableTableManager(_$AppDatabase db, $ShiftRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<DateTime> closedAt = const Value.absent(),
            Value<String> staffNames = const Value.absent(),
            Value<String?> closedByStaffId = const Value.absent(),
            Value<int> revenueMinor = const Value.absent(),
            Value<int> qrMinor = const Value.absent(),
            Value<int> cardMinor = const Value.absent(),
            Value<int> cashMinor = const Value.absent(),
            Value<int> morningCashMinor = const Value.absent(),
            Value<int> eveningCashMinor = const Value.absent(),
            Value<int> inkassMinor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShiftRecordsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            closedAt: closedAt,
            staffNames: staffNames,
            closedByStaffId: closedByStaffId,
            revenueMinor: revenueMinor,
            qrMinor: qrMinor,
            cardMinor: cardMinor,
            cashMinor: cashMinor,
            morningCashMinor: morningCashMinor,
            eveningCashMinor: eveningCashMinor,
            inkassMinor: inkassMinor,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String venueId,
            required DateTime closedAt,
            Value<String> staffNames = const Value.absent(),
            Value<String?> closedByStaffId = const Value.absent(),
            Value<int> revenueMinor = const Value.absent(),
            Value<int> qrMinor = const Value.absent(),
            Value<int> cardMinor = const Value.absent(),
            Value<int> cashMinor = const Value.absent(),
            Value<int> morningCashMinor = const Value.absent(),
            Value<int> eveningCashMinor = const Value.absent(),
            Value<int> inkassMinor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShiftRecordsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            closedAt: closedAt,
            staffNames: staffNames,
            closedByStaffId: closedByStaffId,
            revenueMinor: revenueMinor,
            qrMinor: qrMinor,
            cardMinor: cardMinor,
            cashMinor: cashMinor,
            morningCashMinor: morningCashMinor,
            eveningCashMinor: eveningCashMinor,
            inkassMinor: inkassMinor,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ShiftRecordsTable, ShiftRow>(table),
                    BaseReferences<_$AppDatabase, $ShiftRecordsTable, ShiftRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShiftRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShiftRecordsTable,
    ShiftRow,
    $$ShiftRecordsTableFilterComposer,
    $$ShiftRecordsTableOrderingComposer,
    $$ShiftRecordsTableAnnotationComposer,
    $$ShiftRecordsTableCreateCompanionBuilder,
    $$ShiftRecordsTableUpdateCompanionBuilder,
    (ShiftRow, BaseReferences<_$AppDatabase, $ShiftRecordsTable, ShiftRow>),
    ShiftRow,
    PrefetchHooks Function()>;
typedef $$ShiftWriteoffsTableCreateCompanionBuilder = ShiftWriteoffsCompanion
    Function({
  required String id,
  required String shiftId,
  Value<String?> productId,
  required String productName,
  required double quantity,
  Value<String> unit,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ShiftWriteoffsTableUpdateCompanionBuilder = ShiftWriteoffsCompanion
    Function({
  Value<String> id,
  Value<String> shiftId,
  Value<String?> productId,
  Value<String> productName,
  Value<double> quantity,
  Value<String> unit,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ShiftWriteoffsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftWriteoffsTable> {
  $$ShiftWriteoffsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shiftId => $composableBuilder(
      column: $table.shiftId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ShiftWriteoffsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftWriteoffsTable> {
  $$ShiftWriteoffsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shiftId => $composableBuilder(
      column: $table.shiftId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ShiftWriteoffsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftWriteoffsTable> {
  $$ShiftWriteoffsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ShiftWriteoffsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShiftWriteoffsTable,
    ShiftWriteoffRow,
    $$ShiftWriteoffsTableFilterComposer,
    $$ShiftWriteoffsTableOrderingComposer,
    $$ShiftWriteoffsTableAnnotationComposer,
    $$ShiftWriteoffsTableCreateCompanionBuilder,
    $$ShiftWriteoffsTableUpdateCompanionBuilder,
    (
      ShiftWriteoffRow,
      BaseReferences<_$AppDatabase, $ShiftWriteoffsTable, ShiftWriteoffRow>
    ),
    ShiftWriteoffRow,
    PrefetchHooks Function()> {
  $$ShiftWriteoffsTableTableManager(
      _$AppDatabase db, $ShiftWriteoffsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftWriteoffsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftWriteoffsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftWriteoffsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> shiftId = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShiftWriteoffsCompanion(
            id: id,
            shiftId: shiftId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            unit: unit,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String shiftId,
            Value<String?> productId = const Value.absent(),
            required String productName,
            required double quantity,
            Value<String> unit = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ShiftWriteoffsCompanion.insert(
            id: id,
            shiftId: shiftId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            unit: unit,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ShiftWriteoffsTable, ShiftWriteoffRow>(table),
                    BaseReferences<_$AppDatabase, $ShiftWriteoffsTable,
                        ShiftWriteoffRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShiftWriteoffsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShiftWriteoffsTable,
    ShiftWriteoffRow,
    $$ShiftWriteoffsTableFilterComposer,
    $$ShiftWriteoffsTableOrderingComposer,
    $$ShiftWriteoffsTableAnnotationComposer,
    $$ShiftWriteoffsTableCreateCompanionBuilder,
    $$ShiftWriteoffsTableUpdateCompanionBuilder,
    (
      ShiftWriteoffRow,
      BaseReferences<_$AppDatabase, $ShiftWriteoffsTable, ShiftWriteoffRow>
    ),
    ShiftWriteoffRow,
    PrefetchHooks Function()>;
typedef $$StockLevelsTableCreateCompanionBuilder = StockLevelsCompanion
    Function({
  required String venueId,
  required String productId,
  required double remaining,
  required DateTime measuredAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$StockLevelsTableUpdateCompanionBuilder = StockLevelsCompanion
    Function({
  Value<String> venueId,
  Value<String> productId,
  Value<double> remaining,
  Value<DateTime> measuredAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$StockLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get remaining => $composableBuilder(
      column: $table.remaining, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$StockLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get remaining => $composableBuilder(
      column: $table.remaining, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$StockLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get remaining =>
      $composableBuilder(column: $table.remaining, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StockLevelsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StockLevelsTable,
    StockLevelRow,
    $$StockLevelsTableFilterComposer,
    $$StockLevelsTableOrderingComposer,
    $$StockLevelsTableAnnotationComposer,
    $$StockLevelsTableCreateCompanionBuilder,
    $$StockLevelsTableUpdateCompanionBuilder,
    (
      StockLevelRow,
      BaseReferences<_$AppDatabase, $StockLevelsTable, StockLevelRow>
    ),
    StockLevelRow,
    PrefetchHooks Function()> {
  $$StockLevelsTableTableManager(_$AppDatabase db, $StockLevelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> venueId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<double> remaining = const Value.absent(),
            Value<DateTime> measuredAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StockLevelsCompanion(
            venueId: venueId,
            productId: productId,
            remaining: remaining,
            measuredAt: measuredAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String venueId,
            required String productId,
            required double remaining,
            required DateTime measuredAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StockLevelsCompanion.insert(
            venueId: venueId,
            productId: productId,
            remaining: remaining,
            measuredAt: measuredAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$StockLevelsTable, StockLevelRow>(table),
                    BaseReferences<_$AppDatabase, $StockLevelsTable,
                        StockLevelRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StockLevelsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StockLevelsTable,
    StockLevelRow,
    $$StockLevelsTableFilterComposer,
    $$StockLevelsTableOrderingComposer,
    $$StockLevelsTableAnnotationComposer,
    $$StockLevelsTableCreateCompanionBuilder,
    $$StockLevelsTableUpdateCompanionBuilder,
    (
      StockLevelRow,
      BaseReferences<_$AppDatabase, $StockLevelsTable, StockLevelRow>
    ),
    StockLevelRow,
    PrefetchHooks Function()>;
typedef $$StockMovementsTableCreateCompanionBuilder = StockMovementsCompanion
    Function({
  required String id,
  required String venueId,
  required String productId,
  required String kind,
  required double quantity,
  required DateTime occurredAt,
  Value<String?> sourceType,
  Value<String?> sourceId,
  Value<String?> staffId,
  Value<String?> note,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$StockMovementsTableUpdateCompanionBuilder = StockMovementsCompanion
    Function({
  Value<String> id,
  Value<String> venueId,
  Value<String> productId,
  Value<String> kind,
  Value<double> quantity,
  Value<DateTime> occurredAt,
  Value<String?> sourceType,
  Value<String?> sourceId,
  Value<String?> staffId,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$StockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StockMovementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StockMovementsTable,
    StockMovementRow,
    $$StockMovementsTableFilterComposer,
    $$StockMovementsTableOrderingComposer,
    $$StockMovementsTableAnnotationComposer,
    $$StockMovementsTableCreateCompanionBuilder,
    $$StockMovementsTableUpdateCompanionBuilder,
    (
      StockMovementRow,
      BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovementRow>
    ),
    StockMovementRow,
    PrefetchHooks Function()> {
  $$StockMovementsTableTableManager(
      _$AppDatabase db, $StockMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<String?> sourceType = const Value.absent(),
            Value<String?> sourceId = const Value.absent(),
            Value<String?> staffId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StockMovementsCompanion(
            id: id,
            venueId: venueId,
            productId: productId,
            kind: kind,
            quantity: quantity,
            occurredAt: occurredAt,
            sourceType: sourceType,
            sourceId: sourceId,
            staffId: staffId,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String venueId,
            required String productId,
            required String kind,
            required double quantity,
            required DateTime occurredAt,
            Value<String?> sourceType = const Value.absent(),
            Value<String?> sourceId = const Value.absent(),
            Value<String?> staffId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StockMovementsCompanion.insert(
            id: id,
            venueId: venueId,
            productId: productId,
            kind: kind,
            quantity: quantity,
            occurredAt: occurredAt,
            sourceType: sourceType,
            sourceId: sourceId,
            staffId: staffId,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$StockMovementsTable, StockMovementRow>(table),
                    BaseReferences<_$AppDatabase, $StockMovementsTable,
                        StockMovementRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StockMovementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StockMovementsTable,
    StockMovementRow,
    $$StockMovementsTableFilterComposer,
    $$StockMovementsTableOrderingComposer,
    $$StockMovementsTableAnnotationComposer,
    $$StockMovementsTableCreateCompanionBuilder,
    $$StockMovementsTableUpdateCompanionBuilder,
    (
      StockMovementRow,
      BaseReferences<_$AppDatabase, $StockMovementsTable, StockMovementRow>
    ),
    StockMovementRow,
    PrefetchHooks Function()>;
typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  required String id,
  required String venueId,
  required DateTime at,
  Value<String?> staffId,
  required String entity,
  required String entityId,
  required String action,
  Value<String?> beforeJson,
  Value<String?> afterJson,
  Value<String?> reason,
  Value<int> rowid,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<String> id,
  Value<String> venueId,
  Value<DateTime> at,
  Value<String?> staffId,
  Value<String> entity,
  Value<String> entityId,
  Value<String> action,
  Value<String?> beforeJson,
  Value<String?> afterJson,
  Value<String?> reason,
  Value<int> rowid,
});

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get beforeJson => $composableBuilder(
      column: $table.beforeJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get afterJson => $composableBuilder(
      column: $table.afterJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get beforeJson => $composableBuilder(
      column: $table.beforeJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get afterJson => $composableBuilder(
      column: $table.afterJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get beforeJson => $composableBuilder(
      column: $table.beforeJson, builder: (column) => column);

  GeneratedColumn<String> get afterJson =>
      $composableBuilder(column: $table.afterJson, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$AuditLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogTable,
    AuditLogRow,
    $$AuditLogTableFilterComposer,
    $$AuditLogTableOrderingComposer,
    $$AuditLogTableAnnotationComposer,
    $$AuditLogTableCreateCompanionBuilder,
    $$AuditLogTableUpdateCompanionBuilder,
    (AuditLogRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>),
    AuditLogRow,
    PrefetchHooks Function()> {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String?> staffId = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String?> beforeJson = const Value.absent(),
            Value<String?> afterJson = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogCompanion(
            id: id,
            venueId: venueId,
            at: at,
            staffId: staffId,
            entity: entity,
            entityId: entityId,
            action: action,
            beforeJson: beforeJson,
            afterJson: afterJson,
            reason: reason,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String venueId,
            required DateTime at,
            Value<String?> staffId = const Value.absent(),
            required String entity,
            required String entityId,
            required String action,
            Value<String?> beforeJson = const Value.absent(),
            Value<String?> afterJson = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogCompanion.insert(
            id: id,
            venueId: venueId,
            at: at,
            staffId: staffId,
            entity: entity,
            entityId: entityId,
            action: action,
            beforeJson: beforeJson,
            afterJson: afterJson,
            reason: reason,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AuditLogTable, AuditLogRow>(table),
                    BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AuditLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuditLogTable,
    AuditLogRow,
    $$AuditLogTableFilterComposer,
    $$AuditLogTableOrderingComposer,
    $$AuditLogTableAnnotationComposer,
    $$AuditLogTableCreateCompanionBuilder,
    $$AuditLogTableUpdateCompanionBuilder,
    (AuditLogRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>),
    AuditLogRow,
    PrefetchHooks Function()>;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String venueId,
  required int notificationId,
  required String title,
  required String frequency,
  required int hour,
  required int minute,
  Value<int?> weekday,
  Value<int?> dayOfMonth,
  Value<bool> remindDayBefore,
  Value<bool> isEnabled,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> venueId,
  Value<int> notificationId,
  Value<String> title,
  Value<String> frequency,
  Value<int> hour,
  Value<int> minute,
  Value<int?> weekday,
  Value<int?> dayOfMonth,
  Value<bool> remindDayBefore,
  Value<bool> isEnabled,
  Value<int> rowid,
});

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minute => $composableBuilder(
      column: $table.minute, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekday => $composableBuilder(
      column: $table.weekday, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get remindDayBefore => $composableBuilder(
      column: $table.remindDayBefore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnFilters(column));
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minute => $composableBuilder(
      column: $table.minute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekday => $composableBuilder(
      column: $table.weekday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get remindDayBefore => $composableBuilder(
      column: $table.remindDayBefore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnOrderings(column));
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
      column: $table.notificationId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => column);

  GeneratedColumn<bool> get remindDayBefore => $composableBuilder(
      column: $table.remindDayBefore, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);
}

class $$RemindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemindersTable,
    ReminderRow,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (ReminderRow, BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>),
    ReminderRow,
    PrefetchHooks Function()> {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<int> notificationId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<int> hour = const Value.absent(),
            Value<int> minute = const Value.absent(),
            Value<int?> weekday = const Value.absent(),
            Value<int?> dayOfMonth = const Value.absent(),
            Value<bool> remindDayBefore = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            notificationId: notificationId,
            title: title,
            frequency: frequency,
            hour: hour,
            minute: minute,
            weekday: weekday,
            dayOfMonth: dayOfMonth,
            remindDayBefore: remindDayBefore,
            isEnabled: isEnabled,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String venueId,
            required int notificationId,
            required String title,
            required String frequency,
            required int hour,
            required int minute,
            Value<int?> weekday = const Value.absent(),
            Value<int?> dayOfMonth = const Value.absent(),
            Value<bool> remindDayBefore = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            notificationId: notificationId,
            title: title,
            frequency: frequency,
            hour: hour,
            minute: minute,
            weekday: weekday,
            dayOfMonth: dayOfMonth,
            remindDayBefore: remindDayBefore,
            isEnabled: isEnabled,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RemindersTable, ReminderRow>(table),
                    BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RemindersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemindersTable,
    ReminderRow,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (ReminderRow, BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>),
    ReminderRow,
    PrefetchHooks Function()>;
typedef $$ExportTemplatesTableCreateCompanionBuilder = ExportTemplatesCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String venueId,
  required String name,
  Value<String> templateJson,
  Value<int> rowid,
});
typedef $$ExportTemplatesTableUpdateCompanionBuilder = ExportTemplatesCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> venueId,
  Value<String> name,
  Value<String> templateJson,
  Value<int> rowid,
});

class $$ExportTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExportTemplatesTable> {
  $$ExportTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateJson => $composableBuilder(
      column: $table.templateJson, builder: (column) => ColumnFilters(column));
}

class $$ExportTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExportTemplatesTable> {
  $$ExportTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venueId => $composableBuilder(
      column: $table.venueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateJson => $composableBuilder(
      column: $table.templateJson,
      builder: (column) => ColumnOrderings(column));
}

class $$ExportTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExportTemplatesTable> {
  $$ExportTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get templateJson => $composableBuilder(
      column: $table.templateJson, builder: (column) => column);
}

class $$ExportTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExportTemplatesTable,
    ExportTemplateRow,
    $$ExportTemplatesTableFilterComposer,
    $$ExportTemplatesTableOrderingComposer,
    $$ExportTemplatesTableAnnotationComposer,
    $$ExportTemplatesTableCreateCompanionBuilder,
    $$ExportTemplatesTableUpdateCompanionBuilder,
    (
      ExportTemplateRow,
      BaseReferences<_$AppDatabase, $ExportTemplatesTable, ExportTemplateRow>
    ),
    ExportTemplateRow,
    PrefetchHooks Function()> {
  $$ExportTemplatesTableTableManager(
      _$AppDatabase db, $ExportTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExportTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExportTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExportTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> venueId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> templateJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExportTemplatesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            name: name,
            templateJson: templateJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String venueId,
            required String name,
            Value<String> templateJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExportTemplatesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            venueId: venueId,
            name: name,
            templateJson: templateJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ExportTemplatesTable, ExportTemplateRow>(
                        table),
                    BaseReferences<_$AppDatabase, $ExportTemplatesTable,
                        ExportTemplateRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExportTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExportTemplatesTable,
    ExportTemplateRow,
    $$ExportTemplatesTableFilterComposer,
    $$ExportTemplatesTableOrderingComposer,
    $$ExportTemplatesTableAnnotationComposer,
    $$ExportTemplatesTableCreateCompanionBuilder,
    $$ExportTemplatesTableUpdateCompanionBuilder,
    (
      ExportTemplateRow,
      BaseReferences<_$AppDatabase, $ExportTemplatesTable, ExportTemplateRow>
    ),
    ExportTemplateRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VenuesTableTableManager get venues =>
      $$VenuesTableTableManager(_db, _db.venues);
  $$DepartmentsTableTableManager get departments =>
      $$DepartmentsTableTableManager(_db, _db.departments);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$StaffMembersTableTableManager get staffMembers =>
      $$StaffMembersTableTableManager(_db, _db.staffMembers);
  $$HistoryEntriesTableTableManager get historyEntries =>
      $$HistoryEntriesTableTableManager(_db, _db.historyEntries);
  $$DocumentLinesTableTableManager get documentLines =>
      $$DocumentLinesTableTableManager(_db, _db.documentLines);
  $$ShiftRecordsTableTableManager get shiftRecords =>
      $$ShiftRecordsTableTableManager(_db, _db.shiftRecords);
  $$ShiftWriteoffsTableTableManager get shiftWriteoffs =>
      $$ShiftWriteoffsTableTableManager(_db, _db.shiftWriteoffs);
  $$StockLevelsTableTableManager get stockLevels =>
      $$StockLevelsTableTableManager(_db, _db.stockLevels);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$ExportTemplatesTableTableManager get exportTemplates =>
      $$ExportTemplatesTableTableManager(_db, _db.exportTemplates);
}
