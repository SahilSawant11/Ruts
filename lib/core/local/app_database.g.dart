// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedMaterialsTable extends CachedMaterials
    with TableInfo<$CachedMaterialsTable, CachedMaterial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _packingMeta =
      const VerificationMeta('packing');
  @override
  late final GeneratedColumn<String> packing = GeneratedColumn<String>(
      'packing', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saleRateMeta =
      const VerificationMeta('saleRate');
  @override
  late final GeneratedColumn<double> saleRate = GeneratedColumn<double>(
      'sale_rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _taxPercentMeta =
      const VerificationMeta('taxPercent');
  @override
  late final GeneratedColumn<double> taxPercent = GeneratedColumn<double>(
      'tax_percent', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stockQtyMeta =
      const VerificationMeta('stockQty');
  @override
  late final GeneratedColumn<int> stockQty = GeneratedColumn<int>(
      'stock_qty', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        barcode,
        name,
        category,
        packing,
        saleRate,
        taxPercent,
        stockQty,
        syncStatus,
        createdAt,
        updatedAt,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_materials';
  @override
  VerificationContext validateIntegrity(Insertable<CachedMaterial> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('packing')) {
      context.handle(_packingMeta,
          packing.isAcceptableOrUnknown(data['packing']!, _packingMeta));
    } else if (isInserting) {
      context.missing(_packingMeta);
    }
    if (data.containsKey('sale_rate')) {
      context.handle(_saleRateMeta,
          saleRate.isAcceptableOrUnknown(data['sale_rate']!, _saleRateMeta));
    } else if (isInserting) {
      context.missing(_saleRateMeta);
    }
    if (data.containsKey('tax_percent')) {
      context.handle(
          _taxPercentMeta,
          taxPercent.isAcceptableOrUnknown(
              data['tax_percent']!, _taxPercentMeta));
    } else if (isInserting) {
      context.missing(_taxPercentMeta);
    }
    if (data.containsKey('stock_qty')) {
      context.handle(_stockQtyMeta,
          stockQty.isAcceptableOrUnknown(data['stock_qty']!, _stockQtyMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMaterial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMaterial(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      packing: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}packing'])!,
      saleRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sale_rate'])!,
      taxPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_percent'])!,
      stockQty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_qty'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $CachedMaterialsTable createAlias(String alias) {
    return $CachedMaterialsTable(attachedDatabase, alias);
  }
}

class CachedMaterial extends DataClass implements Insertable<CachedMaterial> {
  final String id;
  final String barcode;
  final String name;
  final String category;
  final String packing;
  final double saleRate;
  final double taxPercent;
  final int stockQty;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  const CachedMaterial(
      {required this.id,
      required this.barcode,
      required this.name,
      required this.category,
      required this.packing,
      required this.saleRate,
      required this.taxPercent,
      required this.stockQty,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['barcode'] = Variable<String>(barcode);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['packing'] = Variable<String>(packing);
    map['sale_rate'] = Variable<double>(saleRate);
    map['tax_percent'] = Variable<double>(taxPercent);
    map['stock_qty'] = Variable<int>(stockQty);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  CachedMaterialsCompanion toCompanion(bool nullToAbsent) {
    return CachedMaterialsCompanion(
      id: Value(id),
      barcode: Value(barcode),
      name: Value(name),
      category: Value(category),
      packing: Value(packing),
      saleRate: Value(saleRate),
      taxPercent: Value(taxPercent),
      stockQty: Value(stockQty),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory CachedMaterial.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMaterial(
      id: serializer.fromJson<String>(json['id']),
      barcode: serializer.fromJson<String>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      packing: serializer.fromJson<String>(json['packing']),
      saleRate: serializer.fromJson<double>(json['saleRate']),
      taxPercent: serializer.fromJson<double>(json['taxPercent']),
      stockQty: serializer.fromJson<int>(json['stockQty']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'barcode': serializer.toJson<String>(barcode),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'packing': serializer.toJson<String>(packing),
      'saleRate': serializer.toJson<double>(saleRate),
      'taxPercent': serializer.toJson<double>(taxPercent),
      'stockQty': serializer.toJson<int>(stockQty),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  CachedMaterial copyWith(
          {String? id,
          String? barcode,
          String? name,
          String? category,
          String? packing,
          double? saleRate,
          double? taxPercent,
          int? stockQty,
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      CachedMaterial(
        id: id ?? this.id,
        barcode: barcode ?? this.barcode,
        name: name ?? this.name,
        category: category ?? this.category,
        packing: packing ?? this.packing,
        saleRate: saleRate ?? this.saleRate,
        taxPercent: taxPercent ?? this.taxPercent,
        stockQty: stockQty ?? this.stockQty,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  CachedMaterial copyWithCompanion(CachedMaterialsCompanion data) {
    return CachedMaterial(
      id: data.id.present ? data.id.value : this.id,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      packing: data.packing.present ? data.packing.value : this.packing,
      saleRate: data.saleRate.present ? data.saleRate.value : this.saleRate,
      taxPercent:
          data.taxPercent.present ? data.taxPercent.value : this.taxPercent,
      stockQty: data.stockQty.present ? data.stockQty.value : this.stockQty,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMaterial(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('packing: $packing, ')
          ..write('saleRate: $saleRate, ')
          ..write('taxPercent: $taxPercent, ')
          ..write('stockQty: $stockQty, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      barcode,
      name,
      category,
      packing,
      saleRate,
      taxPercent,
      stockQty,
      syncStatus,
      createdAt,
      updatedAt,
      lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMaterial &&
          other.id == this.id &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.category == this.category &&
          other.packing == this.packing &&
          other.saleRate == this.saleRate &&
          other.taxPercent == this.taxPercent &&
          other.stockQty == this.stockQty &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CachedMaterialsCompanion extends UpdateCompanion<CachedMaterial> {
  final Value<String> id;
  final Value<String> barcode;
  final Value<String> name;
  final Value<String> category;
  final Value<String> packing;
  final Value<double> saleRate;
  final Value<double> taxPercent;
  final Value<int> stockQty;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const CachedMaterialsCompanion({
    this.id = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.packing = const Value.absent(),
    this.saleRate = const Value.absent(),
    this.taxPercent = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMaterialsCompanion.insert({
    required String id,
    required String barcode,
    required String name,
    required String category,
    required String packing,
    required double saleRate,
    required double taxPercent,
    this.stockQty = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        barcode = Value(barcode),
        name = Value(name),
        category = Value(category),
        packing = Value(packing),
        saleRate = Value(saleRate),
        taxPercent = Value(taxPercent);
  static Insertable<CachedMaterial> custom({
    Expression<String>? id,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? packing,
    Expression<double>? saleRate,
    Expression<double>? taxPercent,
    Expression<int>? stockQty,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (packing != null) 'packing': packing,
      if (saleRate != null) 'sale_rate': saleRate,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (stockQty != null) 'stock_qty': stockQty,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMaterialsCompanion copyWith(
      {Value<String>? id,
      Value<String>? barcode,
      Value<String>? name,
      Value<String>? category,
      Value<String>? packing,
      Value<double>? saleRate,
      Value<double>? taxPercent,
      Value<int>? stockQty,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? rowid}) {
    return CachedMaterialsCompanion(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      packing: packing ?? this.packing,
      saleRate: saleRate ?? this.saleRate,
      taxPercent: taxPercent ?? this.taxPercent,
      stockQty: stockQty ?? this.stockQty,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (packing.present) {
      map['packing'] = Variable<String>(packing.value);
    }
    if (saleRate.present) {
      map['sale_rate'] = Variable<double>(saleRate.value);
    }
    if (taxPercent.present) {
      map['tax_percent'] = Variable<double>(taxPercent.value);
    }
    if (stockQty.present) {
      map['stock_qty'] = Variable<int>(stockQty.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMaterialsCompanion(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('packing: $packing, ')
          ..write('saleRate: $saleRate, ')
          ..write('taxPercent: $taxPercent, ')
          ..write('stockQty: $stockQty, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSuppliersTable extends CachedSuppliers
    with TableInfo<$CachedSuppliersTable, CachedSupplier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSuppliersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contactNoMeta =
      const VerificationMeta('contactNo');
  @override
  late final GeneratedColumn<String> contactNo = GeneratedColumn<String>(
      'contact_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vatNoMeta = const VerificationMeta('vatNo');
  @override
  late final GeneratedColumn<String> vatNo = GeneratedColumn<String>(
      'vat_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bankDetailsMeta =
      const VerificationMeta('bankDetails');
  @override
  late final GeneratedColumn<String> bankDetails = GeneratedColumn<String>(
      'bank_details', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _disPercentMeta =
      const VerificationMeta('disPercent');
  @override
  late final GeneratedColumn<double> disPercent = GeneratedColumn<double>(
      'dis_percent', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _openingBalanceMeta =
      const VerificationMeta('openingBalance');
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
      'opening_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _balanceTypeMeta =
      const VerificationMeta('balanceType');
  @override
  late final GeneratedColumn<String> balanceType = GeneratedColumn<String>(
      'balance_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Credit'));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        address,
        contactNo,
        email,
        vatNo,
        bankDetails,
        disPercent,
        openingBalance,
        balanceType,
        syncStatus,
        createdAt,
        updatedAt,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_suppliers';
  @override
  VerificationContext validateIntegrity(Insertable<CachedSupplier> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('contact_no')) {
      context.handle(_contactNoMeta,
          contactNo.isAcceptableOrUnknown(data['contact_no']!, _contactNoMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('vat_no')) {
      context.handle(
          _vatNoMeta, vatNo.isAcceptableOrUnknown(data['vat_no']!, _vatNoMeta));
    }
    if (data.containsKey('bank_details')) {
      context.handle(
          _bankDetailsMeta,
          bankDetails.isAcceptableOrUnknown(
              data['bank_details']!, _bankDetailsMeta));
    }
    if (data.containsKey('dis_percent')) {
      context.handle(
          _disPercentMeta,
          disPercent.isAcceptableOrUnknown(
              data['dis_percent']!, _disPercentMeta));
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
          _openingBalanceMeta,
          openingBalance.isAcceptableOrUnknown(
              data['opening_balance']!, _openingBalanceMeta));
    }
    if (data.containsKey('balance_type')) {
      context.handle(
          _balanceTypeMeta,
          balanceType.isAcceptableOrUnknown(
              data['balance_type']!, _balanceTypeMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSupplier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSupplier(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      contactNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_no']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      vatNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vat_no']),
      bankDetails: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_details']),
      disPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}dis_percent'])!,
      openingBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}opening_balance'])!,
      balanceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}balance_type'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $CachedSuppliersTable createAlias(String alias) {
    return $CachedSuppliersTable(attachedDatabase, alias);
  }
}

class CachedSupplier extends DataClass implements Insertable<CachedSupplier> {
  final String id;
  final String name;
  final String? address;
  final String? contactNo;
  final String? email;
  final String? vatNo;
  final String? bankDetails;
  final double disPercent;
  final double openingBalance;
  final String balanceType;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  const CachedSupplier(
      {required this.id,
      required this.name,
      this.address,
      this.contactNo,
      this.email,
      this.vatNo,
      this.bankDetails,
      required this.disPercent,
      required this.openingBalance,
      required this.balanceType,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || contactNo != null) {
      map['contact_no'] = Variable<String>(contactNo);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || vatNo != null) {
      map['vat_no'] = Variable<String>(vatNo);
    }
    if (!nullToAbsent || bankDetails != null) {
      map['bank_details'] = Variable<String>(bankDetails);
    }
    map['dis_percent'] = Variable<double>(disPercent);
    map['opening_balance'] = Variable<double>(openingBalance);
    map['balance_type'] = Variable<String>(balanceType);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  CachedSuppliersCompanion toCompanion(bool nullToAbsent) {
    return CachedSuppliersCompanion(
      id: Value(id),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      contactNo: contactNo == null && nullToAbsent
          ? const Value.absent()
          : Value(contactNo),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      vatNo:
          vatNo == null && nullToAbsent ? const Value.absent() : Value(vatNo),
      bankDetails: bankDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(bankDetails),
      disPercent: Value(disPercent),
      openingBalance: Value(openingBalance),
      balanceType: Value(balanceType),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory CachedSupplier.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSupplier(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      contactNo: serializer.fromJson<String?>(json['contactNo']),
      email: serializer.fromJson<String?>(json['email']),
      vatNo: serializer.fromJson<String?>(json['vatNo']),
      bankDetails: serializer.fromJson<String?>(json['bankDetails']),
      disPercent: serializer.fromJson<double>(json['disPercent']),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      balanceType: serializer.fromJson<String>(json['balanceType']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'contactNo': serializer.toJson<String?>(contactNo),
      'email': serializer.toJson<String?>(email),
      'vatNo': serializer.toJson<String?>(vatNo),
      'bankDetails': serializer.toJson<String?>(bankDetails),
      'disPercent': serializer.toJson<double>(disPercent),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'balanceType': serializer.toJson<String>(balanceType),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  CachedSupplier copyWith(
          {String? id,
          String? name,
          Value<String?> address = const Value.absent(),
          Value<String?> contactNo = const Value.absent(),
          Value<String?> email = const Value.absent(),
          Value<String?> vatNo = const Value.absent(),
          Value<String?> bankDetails = const Value.absent(),
          double? disPercent,
          double? openingBalance,
          String? balanceType,
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      CachedSupplier(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address.present ? address.value : this.address,
        contactNo: contactNo.present ? contactNo.value : this.contactNo,
        email: email.present ? email.value : this.email,
        vatNo: vatNo.present ? vatNo.value : this.vatNo,
        bankDetails: bankDetails.present ? bankDetails.value : this.bankDetails,
        disPercent: disPercent ?? this.disPercent,
        openingBalance: openingBalance ?? this.openingBalance,
        balanceType: balanceType ?? this.balanceType,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  CachedSupplier copyWithCompanion(CachedSuppliersCompanion data) {
    return CachedSupplier(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      contactNo: data.contactNo.present ? data.contactNo.value : this.contactNo,
      email: data.email.present ? data.email.value : this.email,
      vatNo: data.vatNo.present ? data.vatNo.value : this.vatNo,
      bankDetails:
          data.bankDetails.present ? data.bankDetails.value : this.bankDetails,
      disPercent:
          data.disPercent.present ? data.disPercent.value : this.disPercent,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      balanceType:
          data.balanceType.present ? data.balanceType.value : this.balanceType,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSupplier(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('contactNo: $contactNo, ')
          ..write('email: $email, ')
          ..write('vatNo: $vatNo, ')
          ..write('bankDetails: $bankDetails, ')
          ..write('disPercent: $disPercent, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('balanceType: $balanceType, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      address,
      contactNo,
      email,
      vatNo,
      bankDetails,
      disPercent,
      openingBalance,
      balanceType,
      syncStatus,
      createdAt,
      updatedAt,
      lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSupplier &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.contactNo == this.contactNo &&
          other.email == this.email &&
          other.vatNo == this.vatNo &&
          other.bankDetails == this.bankDetails &&
          other.disPercent == this.disPercent &&
          other.openingBalance == this.openingBalance &&
          other.balanceType == this.balanceType &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CachedSuppliersCompanion extends UpdateCompanion<CachedSupplier> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> address;
  final Value<String?> contactNo;
  final Value<String?> email;
  final Value<String?> vatNo;
  final Value<String?> bankDetails;
  final Value<double> disPercent;
  final Value<double> openingBalance;
  final Value<String> balanceType;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const CachedSuppliersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.contactNo = const Value.absent(),
    this.email = const Value.absent(),
    this.vatNo = const Value.absent(),
    this.bankDetails = const Value.absent(),
    this.disPercent = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.balanceType = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSuppliersCompanion.insert({
    required String id,
    required String name,
    this.address = const Value.absent(),
    this.contactNo = const Value.absent(),
    this.email = const Value.absent(),
    this.vatNo = const Value.absent(),
    this.bankDetails = const Value.absent(),
    this.disPercent = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.balanceType = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<CachedSupplier> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? contactNo,
    Expression<String>? email,
    Expression<String>? vatNo,
    Expression<String>? bankDetails,
    Expression<double>? disPercent,
    Expression<double>? openingBalance,
    Expression<String>? balanceType,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (contactNo != null) 'contact_no': contactNo,
      if (email != null) 'email': email,
      if (vatNo != null) 'vat_no': vatNo,
      if (bankDetails != null) 'bank_details': bankDetails,
      if (disPercent != null) 'dis_percent': disPercent,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (balanceType != null) 'balance_type': balanceType,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSuppliersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? address,
      Value<String?>? contactNo,
      Value<String?>? email,
      Value<String?>? vatNo,
      Value<String?>? bankDetails,
      Value<double>? disPercent,
      Value<double>? openingBalance,
      Value<String>? balanceType,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? rowid}) {
    return CachedSuppliersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactNo: contactNo ?? this.contactNo,
      email: email ?? this.email,
      vatNo: vatNo ?? this.vatNo,
      bankDetails: bankDetails ?? this.bankDetails,
      disPercent: disPercent ?? this.disPercent,
      openingBalance: openingBalance ?? this.openingBalance,
      balanceType: balanceType ?? this.balanceType,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (contactNo.present) {
      map['contact_no'] = Variable<String>(contactNo.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (vatNo.present) {
      map['vat_no'] = Variable<String>(vatNo.value);
    }
    if (bankDetails.present) {
      map['bank_details'] = Variable<String>(bankDetails.value);
    }
    if (disPercent.present) {
      map['dis_percent'] = Variable<double>(disPercent.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (balanceType.present) {
      map['balance_type'] = Variable<String>(balanceType.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSuppliersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('contactNo: $contactNo, ')
          ..write('email: $email, ')
          ..write('vatNo: $vatNo, ')
          ..write('bankDetails: $bankDetails, ')
          ..write('disPercent: $disPercent, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('balanceType: $balanceType, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedMaterialsTable cachedMaterials =
      $CachedMaterialsTable(this);
  late final $CachedSuppliersTable cachedSuppliers =
      $CachedSuppliersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedMaterials, cachedSuppliers];
}

typedef $$CachedMaterialsTableCreateCompanionBuilder = CachedMaterialsCompanion
    Function({
  required String id,
  required String barcode,
  required String name,
  required String category,
  required String packing,
  required double saleRate,
  required double taxPercent,
  Value<int> stockQty,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$CachedMaterialsTableUpdateCompanionBuilder = CachedMaterialsCompanion
    Function({
  Value<String> id,
  Value<String> barcode,
  Value<String> name,
  Value<String> category,
  Value<String> packing,
  Value<double> saleRate,
  Value<double> taxPercent,
  Value<int> stockQty,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});

class $$CachedMaterialsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMaterialsTable> {
  $$CachedMaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packing => $composableBuilder(
      column: $table.packing, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saleRate => $composableBuilder(
      column: $table.saleRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stockQty => $composableBuilder(
      column: $table.stockQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedMaterialsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMaterialsTable> {
  $$CachedMaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packing => $composableBuilder(
      column: $table.packing, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saleRate => $composableBuilder(
      column: $table.saleRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stockQty => $composableBuilder(
      column: $table.stockQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedMaterialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMaterialsTable> {
  $$CachedMaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get packing =>
      $composableBuilder(column: $table.packing, builder: (column) => column);

  GeneratedColumn<double> get saleRate =>
      $composableBuilder(column: $table.saleRate, builder: (column) => column);

  GeneratedColumn<double> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => column);

  GeneratedColumn<int> get stockQty =>
      $composableBuilder(column: $table.stockQty, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);
}

class $$CachedMaterialsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedMaterialsTable,
    CachedMaterial,
    $$CachedMaterialsTableFilterComposer,
    $$CachedMaterialsTableOrderingComposer,
    $$CachedMaterialsTableAnnotationComposer,
    $$CachedMaterialsTableCreateCompanionBuilder,
    $$CachedMaterialsTableUpdateCompanionBuilder,
    (
      CachedMaterial,
      BaseReferences<_$AppDatabase, $CachedMaterialsTable, CachedMaterial>
    ),
    CachedMaterial,
    PrefetchHooks Function()> {
  $$CachedMaterialsTableTableManager(
      _$AppDatabase db, $CachedMaterialsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMaterialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMaterialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> packing = const Value.absent(),
            Value<double> saleRate = const Value.absent(),
            Value<double> taxPercent = const Value.absent(),
            Value<int> stockQty = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedMaterialsCompanion(
            id: id,
            barcode: barcode,
            name: name,
            category: category,
            packing: packing,
            saleRate: saleRate,
            taxPercent: taxPercent,
            stockQty: stockQty,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String barcode,
            required String name,
            required String category,
            required String packing,
            required double saleRate,
            required double taxPercent,
            Value<int> stockQty = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedMaterialsCompanion.insert(
            id: id,
            barcode: barcode,
            name: name,
            category: category,
            packing: packing,
            saleRate: saleRate,
            taxPercent: taxPercent,
            stockQty: stockQty,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedMaterialsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedMaterialsTable,
    CachedMaterial,
    $$CachedMaterialsTableFilterComposer,
    $$CachedMaterialsTableOrderingComposer,
    $$CachedMaterialsTableAnnotationComposer,
    $$CachedMaterialsTableCreateCompanionBuilder,
    $$CachedMaterialsTableUpdateCompanionBuilder,
    (
      CachedMaterial,
      BaseReferences<_$AppDatabase, $CachedMaterialsTable, CachedMaterial>
    ),
    CachedMaterial,
    PrefetchHooks Function()>;
typedef $$CachedSuppliersTableCreateCompanionBuilder = CachedSuppliersCompanion
    Function({
  required String id,
  required String name,
  Value<String?> address,
  Value<String?> contactNo,
  Value<String?> email,
  Value<String?> vatNo,
  Value<String?> bankDetails,
  Value<double> disPercent,
  Value<double> openingBalance,
  Value<String> balanceType,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$CachedSuppliersTableUpdateCompanionBuilder = CachedSuppliersCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> address,
  Value<String?> contactNo,
  Value<String?> email,
  Value<String?> vatNo,
  Value<String?> bankDetails,
  Value<double> disPercent,
  Value<double> openingBalance,
  Value<String> balanceType,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});

class $$CachedSuppliersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSuppliersTable> {
  $$CachedSuppliersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactNo => $composableBuilder(
      column: $table.contactNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vatNo => $composableBuilder(
      column: $table.vatNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankDetails => $composableBuilder(
      column: $table.bankDetails, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get disPercent => $composableBuilder(
      column: $table.disPercent, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get balanceType => $composableBuilder(
      column: $table.balanceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedSuppliersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSuppliersTable> {
  $$CachedSuppliersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactNo => $composableBuilder(
      column: $table.contactNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vatNo => $composableBuilder(
      column: $table.vatNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankDetails => $composableBuilder(
      column: $table.bankDetails, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get disPercent => $composableBuilder(
      column: $table.disPercent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get balanceType => $composableBuilder(
      column: $table.balanceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedSuppliersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSuppliersTable> {
  $$CachedSuppliersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get contactNo =>
      $composableBuilder(column: $table.contactNo, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get vatNo =>
      $composableBuilder(column: $table.vatNo, builder: (column) => column);

  GeneratedColumn<String> get bankDetails => $composableBuilder(
      column: $table.bankDetails, builder: (column) => column);

  GeneratedColumn<double> get disPercent => $composableBuilder(
      column: $table.disPercent, builder: (column) => column);

  GeneratedColumn<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance, builder: (column) => column);

  GeneratedColumn<String> get balanceType => $composableBuilder(
      column: $table.balanceType, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);
}

class $$CachedSuppliersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedSuppliersTable,
    CachedSupplier,
    $$CachedSuppliersTableFilterComposer,
    $$CachedSuppliersTableOrderingComposer,
    $$CachedSuppliersTableAnnotationComposer,
    $$CachedSuppliersTableCreateCompanionBuilder,
    $$CachedSuppliersTableUpdateCompanionBuilder,
    (
      CachedSupplier,
      BaseReferences<_$AppDatabase, $CachedSuppliersTable, CachedSupplier>
    ),
    CachedSupplier,
    PrefetchHooks Function()> {
  $$CachedSuppliersTableTableManager(
      _$AppDatabase db, $CachedSuppliersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSuppliersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSuppliersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSuppliersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> contactNo = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> vatNo = const Value.absent(),
            Value<String?> bankDetails = const Value.absent(),
            Value<double> disPercent = const Value.absent(),
            Value<double> openingBalance = const Value.absent(),
            Value<String> balanceType = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedSuppliersCompanion(
            id: id,
            name: name,
            address: address,
            contactNo: contactNo,
            email: email,
            vatNo: vatNo,
            bankDetails: bankDetails,
            disPercent: disPercent,
            openingBalance: openingBalance,
            balanceType: balanceType,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> address = const Value.absent(),
            Value<String?> contactNo = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> vatNo = const Value.absent(),
            Value<String?> bankDetails = const Value.absent(),
            Value<double> disPercent = const Value.absent(),
            Value<double> openingBalance = const Value.absent(),
            Value<String> balanceType = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedSuppliersCompanion.insert(
            id: id,
            name: name,
            address: address,
            contactNo: contactNo,
            email: email,
            vatNo: vatNo,
            bankDetails: bankDetails,
            disPercent: disPercent,
            openingBalance: openingBalance,
            balanceType: balanceType,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedSuppliersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedSuppliersTable,
    CachedSupplier,
    $$CachedSuppliersTableFilterComposer,
    $$CachedSuppliersTableOrderingComposer,
    $$CachedSuppliersTableAnnotationComposer,
    $$CachedSuppliersTableCreateCompanionBuilder,
    $$CachedSuppliersTableUpdateCompanionBuilder,
    (
      CachedSupplier,
      BaseReferences<_$AppDatabase, $CachedSuppliersTable, CachedSupplier>
    ),
    CachedSupplier,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedMaterialsTableTableManager get cachedMaterials =>
      $$CachedMaterialsTableTableManager(_db, _db.cachedMaterials);
  $$CachedSuppliersTableTableManager get cachedSuppliers =>
      $$CachedSuppliersTableTableManager(_db, _db.cachedSuppliers);
}
