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

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        operation,
        payload,
        status,
        lastError,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final String status;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncQueueItem(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payload,
      required this.status,
      this.lastError,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItem(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncQueueItem copyWith(
          {int? id,
          String? entityType,
          String? entityId,
          String? operation,
          String? payload,
          String? status,
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SyncQueueItem(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        status: status ?? this.status,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncQueueItem copyWithCompanion(SyncQueueItemsCompanion data) {
    return SyncQueueItem(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItem(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, entityId, operation, payload,
      status, lastError, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItem &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SyncQueueItemsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payload = Value(payload);
  static Insertable<SyncQueueItem> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncQueueItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payload,
      Value<String>? status,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SyncQueueItemsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedInventoryStocksTable extends CachedInventoryStocks
    with TableInfo<$CachedInventoryStocksTable, CachedInventoryStock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedInventoryStocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _materialIdMeta =
      const VerificationMeta('materialId');
  @override
  late final GeneratedColumn<String> materialId = GeneratedColumn<String>(
      'material_id', aliasedName, false,
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
  static const VerificationMeta _qtyOnHandMeta =
      const VerificationMeta('qtyOnHand');
  @override
  late final GeneratedColumn<int> qtyOnHand = GeneratedColumn<int>(
      'qty_on_hand', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reorderLevelMeta =
      const VerificationMeta('reorderLevel');
  @override
  late final GeneratedColumn<int> reorderLevel = GeneratedColumn<int>(
      'reorder_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [materialId, barcode, name, category, qtyOnHand, reorderLevel, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_inventory_stocks';
  @override
  VerificationContext validateIntegrity(
      Insertable<CachedInventoryStock> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('material_id')) {
      context.handle(
          _materialIdMeta,
          materialId.isAcceptableOrUnknown(
              data['material_id']!, _materialIdMeta));
    } else if (isInserting) {
      context.missing(_materialIdMeta);
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
    if (data.containsKey('qty_on_hand')) {
      context.handle(
          _qtyOnHandMeta,
          qtyOnHand.isAcceptableOrUnknown(
              data['qty_on_hand']!, _qtyOnHandMeta));
    } else if (isInserting) {
      context.missing(_qtyOnHandMeta);
    }
    if (data.containsKey('reorder_level')) {
      context.handle(
          _reorderLevelMeta,
          reorderLevel.isAcceptableOrUnknown(
              data['reorder_level']!, _reorderLevelMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {materialId};
  @override
  CachedInventoryStock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedInventoryStock(
      materialId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}material_id'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      qtyOnHand: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}qty_on_hand'])!,
      reorderLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reorder_level'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CachedInventoryStocksTable createAlias(String alias) {
    return $CachedInventoryStocksTable(attachedDatabase, alias);
  }
}

class CachedInventoryStock extends DataClass
    implements Insertable<CachedInventoryStock> {
  final String materialId;
  final String barcode;
  final String name;
  final String category;
  final int qtyOnHand;
  final int reorderLevel;
  final DateTime updatedAt;
  const CachedInventoryStock(
      {required this.materialId,
      required this.barcode,
      required this.name,
      required this.category,
      required this.qtyOnHand,
      required this.reorderLevel,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['material_id'] = Variable<String>(materialId);
    map['barcode'] = Variable<String>(barcode);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['qty_on_hand'] = Variable<int>(qtyOnHand);
    map['reorder_level'] = Variable<int>(reorderLevel);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedInventoryStocksCompanion toCompanion(bool nullToAbsent) {
    return CachedInventoryStocksCompanion(
      materialId: Value(materialId),
      barcode: Value(barcode),
      name: Value(name),
      category: Value(category),
      qtyOnHand: Value(qtyOnHand),
      reorderLevel: Value(reorderLevel),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedInventoryStock.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedInventoryStock(
      materialId: serializer.fromJson<String>(json['materialId']),
      barcode: serializer.fromJson<String>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      qtyOnHand: serializer.fromJson<int>(json['qtyOnHand']),
      reorderLevel: serializer.fromJson<int>(json['reorderLevel']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'materialId': serializer.toJson<String>(materialId),
      'barcode': serializer.toJson<String>(barcode),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'qtyOnHand': serializer.toJson<int>(qtyOnHand),
      'reorderLevel': serializer.toJson<int>(reorderLevel),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedInventoryStock copyWith(
          {String? materialId,
          String? barcode,
          String? name,
          String? category,
          int? qtyOnHand,
          int? reorderLevel,
          DateTime? updatedAt}) =>
      CachedInventoryStock(
        materialId: materialId ?? this.materialId,
        barcode: barcode ?? this.barcode,
        name: name ?? this.name,
        category: category ?? this.category,
        qtyOnHand: qtyOnHand ?? this.qtyOnHand,
        reorderLevel: reorderLevel ?? this.reorderLevel,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedInventoryStock copyWithCompanion(CachedInventoryStocksCompanion data) {
    return CachedInventoryStock(
      materialId:
          data.materialId.present ? data.materialId.value : this.materialId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      qtyOnHand: data.qtyOnHand.present ? data.qtyOnHand.value : this.qtyOnHand,
      reorderLevel: data.reorderLevel.present
          ? data.reorderLevel.value
          : this.reorderLevel,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedInventoryStock(')
          ..write('materialId: $materialId, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('qtyOnHand: $qtyOnHand, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      materialId, barcode, name, category, qtyOnHand, reorderLevel, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedInventoryStock &&
          other.materialId == this.materialId &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.category == this.category &&
          other.qtyOnHand == this.qtyOnHand &&
          other.reorderLevel == this.reorderLevel &&
          other.updatedAt == this.updatedAt);
}

class CachedInventoryStocksCompanion
    extends UpdateCompanion<CachedInventoryStock> {
  final Value<String> materialId;
  final Value<String> barcode;
  final Value<String> name;
  final Value<String> category;
  final Value<int> qtyOnHand;
  final Value<int> reorderLevel;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedInventoryStocksCompanion({
    this.materialId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.qtyOnHand = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedInventoryStocksCompanion.insert({
    required String materialId,
    required String barcode,
    required String name,
    required String category,
    required int qtyOnHand,
    this.reorderLevel = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : materialId = Value(materialId),
        barcode = Value(barcode),
        name = Value(name),
        category = Value(category),
        qtyOnHand = Value(qtyOnHand);
  static Insertable<CachedInventoryStock> custom({
    Expression<String>? materialId,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? qtyOnHand,
    Expression<int>? reorderLevel,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (materialId != null) 'material_id': materialId,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (qtyOnHand != null) 'qty_on_hand': qtyOnHand,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedInventoryStocksCompanion copyWith(
      {Value<String>? materialId,
      Value<String>? barcode,
      Value<String>? name,
      Value<String>? category,
      Value<int>? qtyOnHand,
      Value<int>? reorderLevel,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CachedInventoryStocksCompanion(
      materialId: materialId ?? this.materialId,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      qtyOnHand: qtyOnHand ?? this.qtyOnHand,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (materialId.present) {
      map['material_id'] = Variable<String>(materialId.value);
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
    if (qtyOnHand.present) {
      map['qty_on_hand'] = Variable<int>(qtyOnHand.value);
    }
    if (reorderLevel.present) {
      map['reorder_level'] = Variable<int>(reorderLevel.value);
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
    return (StringBuffer('CachedInventoryStocksCompanion(')
          ..write('materialId: $materialId, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('qtyOnHand: $qtyOnHand, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSalesBillsTable extends CachedSalesBills
    with TableInfo<$CachedSalesBillsTable, CachedSalesBill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSalesBillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _billNoMeta = const VerificationMeta('billNo');
  @override
  late final GeneratedColumn<String> billNo = GeneratedColumn<String>(
      'bill_no', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _payModeMeta =
      const VerificationMeta('payMode');
  @override
  late final GeneratedColumn<String> payMode = GeneratedColumn<String>(
      'pay_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _balanceDueMeta =
      const VerificationMeta('balanceDue');
  @override
  late final GeneratedColumn<double> balanceDue = GeneratedColumn<double>(
      'balance_due', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalTaxMeta =
      const VerificationMeta('totalTax');
  @override
  late final GeneratedColumn<double> totalTax = GeneratedColumn<double>(
      'total_tax', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _billDateMeta =
      const VerificationMeta('billDate');
  @override
  late final GeneratedColumn<DateTime> billDate = GeneratedColumn<DateTime>(
      'bill_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        billNo,
        customerId,
        payMode,
        status,
        totalAmount,
        balanceDue,
        totalTax,
        syncStatus,
        billDate,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_sales_bills';
  @override
  VerificationContext validateIntegrity(Insertable<CachedSalesBill> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_no')) {
      context.handle(_billNoMeta,
          billNo.isAcceptableOrUnknown(data['bill_no']!, _billNoMeta));
    } else if (isInserting) {
      context.missing(_billNoMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('pay_mode')) {
      context.handle(_payModeMeta,
          payMode.isAcceptableOrUnknown(data['pay_mode']!, _payModeMeta));
    } else if (isInserting) {
      context.missing(_payModeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('balance_due')) {
      context.handle(
          _balanceDueMeta,
          balanceDue.isAcceptableOrUnknown(
              data['balance_due']!, _balanceDueMeta));
    } else if (isInserting) {
      context.missing(_balanceDueMeta);
    }
    if (data.containsKey('total_tax')) {
      context.handle(_totalTaxMeta,
          totalTax.isAcceptableOrUnknown(data['total_tax']!, _totalTaxMeta));
    } else if (isInserting) {
      context.missing(_totalTaxMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('bill_date')) {
      context.handle(_billDateMeta,
          billDate.isAcceptableOrUnknown(data['bill_date']!, _billDateMeta));
    } else if (isInserting) {
      context.missing(_billDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSalesBill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSalesBill(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      billNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_no'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      payMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pay_mode'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      balanceDue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}balance_due'])!,
      totalTax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_tax'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      billDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}bill_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CachedSalesBillsTable createAlias(String alias) {
    return $CachedSalesBillsTable(attachedDatabase, alias);
  }
}

class CachedSalesBill extends DataClass implements Insertable<CachedSalesBill> {
  final String id;
  final String billNo;
  final String? customerId;
  final String payMode;
  final String status;
  final double totalAmount;
  final double balanceDue;
  final double totalTax;
  final String syncStatus;
  final DateTime billDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedSalesBill(
      {required this.id,
      required this.billNo,
      this.customerId,
      required this.payMode,
      required this.status,
      required this.totalAmount,
      required this.balanceDue,
      required this.totalTax,
      required this.syncStatus,
      required this.billDate,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_no'] = Variable<String>(billNo);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['pay_mode'] = Variable<String>(payMode);
    map['status'] = Variable<String>(status);
    map['total_amount'] = Variable<double>(totalAmount);
    map['balance_due'] = Variable<double>(balanceDue);
    map['total_tax'] = Variable<double>(totalTax);
    map['sync_status'] = Variable<String>(syncStatus);
    map['bill_date'] = Variable<DateTime>(billDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedSalesBillsCompanion toCompanion(bool nullToAbsent) {
    return CachedSalesBillsCompanion(
      id: Value(id),
      billNo: Value(billNo),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      payMode: Value(payMode),
      status: Value(status),
      totalAmount: Value(totalAmount),
      balanceDue: Value(balanceDue),
      totalTax: Value(totalTax),
      syncStatus: Value(syncStatus),
      billDate: Value(billDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedSalesBill.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSalesBill(
      id: serializer.fromJson<String>(json['id']),
      billNo: serializer.fromJson<String>(json['billNo']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      payMode: serializer.fromJson<String>(json['payMode']),
      status: serializer.fromJson<String>(json['status']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      balanceDue: serializer.fromJson<double>(json['balanceDue']),
      totalTax: serializer.fromJson<double>(json['totalTax']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      billDate: serializer.fromJson<DateTime>(json['billDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billNo': serializer.toJson<String>(billNo),
      'customerId': serializer.toJson<String?>(customerId),
      'payMode': serializer.toJson<String>(payMode),
      'status': serializer.toJson<String>(status),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'balanceDue': serializer.toJson<double>(balanceDue),
      'totalTax': serializer.toJson<double>(totalTax),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'billDate': serializer.toJson<DateTime>(billDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedSalesBill copyWith(
          {String? id,
          String? billNo,
          Value<String?> customerId = const Value.absent(),
          String? payMode,
          String? status,
          double? totalAmount,
          double? balanceDue,
          double? totalTax,
          String? syncStatus,
          DateTime? billDate,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CachedSalesBill(
        id: id ?? this.id,
        billNo: billNo ?? this.billNo,
        customerId: customerId.present ? customerId.value : this.customerId,
        payMode: payMode ?? this.payMode,
        status: status ?? this.status,
        totalAmount: totalAmount ?? this.totalAmount,
        balanceDue: balanceDue ?? this.balanceDue,
        totalTax: totalTax ?? this.totalTax,
        syncStatus: syncStatus ?? this.syncStatus,
        billDate: billDate ?? this.billDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedSalesBill copyWithCompanion(CachedSalesBillsCompanion data) {
    return CachedSalesBill(
      id: data.id.present ? data.id.value : this.id,
      billNo: data.billNo.present ? data.billNo.value : this.billNo,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      payMode: data.payMode.present ? data.payMode.value : this.payMode,
      status: data.status.present ? data.status.value : this.status,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      balanceDue:
          data.balanceDue.present ? data.balanceDue.value : this.balanceDue,
      totalTax: data.totalTax.present ? data.totalTax.value : this.totalTax,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      billDate: data.billDate.present ? data.billDate.value : this.billDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSalesBill(')
          ..write('id: $id, ')
          ..write('billNo: $billNo, ')
          ..write('customerId: $customerId, ')
          ..write('payMode: $payMode, ')
          ..write('status: $status, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('balanceDue: $balanceDue, ')
          ..write('totalTax: $totalTax, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('billDate: $billDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      billNo,
      customerId,
      payMode,
      status,
      totalAmount,
      balanceDue,
      totalTax,
      syncStatus,
      billDate,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSalesBill &&
          other.id == this.id &&
          other.billNo == this.billNo &&
          other.customerId == this.customerId &&
          other.payMode == this.payMode &&
          other.status == this.status &&
          other.totalAmount == this.totalAmount &&
          other.balanceDue == this.balanceDue &&
          other.totalTax == this.totalTax &&
          other.syncStatus == this.syncStatus &&
          other.billDate == this.billDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedSalesBillsCompanion extends UpdateCompanion<CachedSalesBill> {
  final Value<String> id;
  final Value<String> billNo;
  final Value<String?> customerId;
  final Value<String> payMode;
  final Value<String> status;
  final Value<double> totalAmount;
  final Value<double> balanceDue;
  final Value<double> totalTax;
  final Value<String> syncStatus;
  final Value<DateTime> billDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedSalesBillsCompanion({
    this.id = const Value.absent(),
    this.billNo = const Value.absent(),
    this.customerId = const Value.absent(),
    this.payMode = const Value.absent(),
    this.status = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.balanceDue = const Value.absent(),
    this.totalTax = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.billDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSalesBillsCompanion.insert({
    required String id,
    required String billNo,
    this.customerId = const Value.absent(),
    required String payMode,
    required String status,
    required double totalAmount,
    required double balanceDue,
    required double totalTax,
    this.syncStatus = const Value.absent(),
    required DateTime billDate,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        billNo = Value(billNo),
        payMode = Value(payMode),
        status = Value(status),
        totalAmount = Value(totalAmount),
        balanceDue = Value(balanceDue),
        totalTax = Value(totalTax),
        billDate = Value(billDate);
  static Insertable<CachedSalesBill> custom({
    Expression<String>? id,
    Expression<String>? billNo,
    Expression<String>? customerId,
    Expression<String>? payMode,
    Expression<String>? status,
    Expression<double>? totalAmount,
    Expression<double>? balanceDue,
    Expression<double>? totalTax,
    Expression<String>? syncStatus,
    Expression<DateTime>? billDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billNo != null) 'bill_no': billNo,
      if (customerId != null) 'customer_id': customerId,
      if (payMode != null) 'pay_mode': payMode,
      if (status != null) 'status': status,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (balanceDue != null) 'balance_due': balanceDue,
      if (totalTax != null) 'total_tax': totalTax,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (billDate != null) 'bill_date': billDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSalesBillsCompanion copyWith(
      {Value<String>? id,
      Value<String>? billNo,
      Value<String?>? customerId,
      Value<String>? payMode,
      Value<String>? status,
      Value<double>? totalAmount,
      Value<double>? balanceDue,
      Value<double>? totalTax,
      Value<String>? syncStatus,
      Value<DateTime>? billDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CachedSalesBillsCompanion(
      id: id ?? this.id,
      billNo: billNo ?? this.billNo,
      customerId: customerId ?? this.customerId,
      payMode: payMode ?? this.payMode,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      totalTax: totalTax ?? this.totalTax,
      syncStatus: syncStatus ?? this.syncStatus,
      billDate: billDate ?? this.billDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (billNo.present) {
      map['bill_no'] = Variable<String>(billNo.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (payMode.present) {
      map['pay_mode'] = Variable<String>(payMode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (balanceDue.present) {
      map['balance_due'] = Variable<double>(balanceDue.value);
    }
    if (totalTax.present) {
      map['total_tax'] = Variable<double>(totalTax.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (billDate.present) {
      map['bill_date'] = Variable<DateTime>(billDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('CachedSalesBillsCompanion(')
          ..write('id: $id, ')
          ..write('billNo: $billNo, ')
          ..write('customerId: $customerId, ')
          ..write('payMode: $payMode, ')
          ..write('status: $status, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('balanceDue: $balanceDue, ')
          ..write('totalTax: $totalTax, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('billDate: $billDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSaleLineItemsTable extends CachedSaleLineItems
    with TableInfo<$CachedSaleLineItemsTable, CachedSaleLineItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSaleLineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _salesBillIdMeta =
      const VerificationMeta('salesBillId');
  @override
  late final GeneratedColumn<String> salesBillId = GeneratedColumn<String>(
      'sales_bill_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _materialIdMeta =
      const VerificationMeta('materialId');
  @override
  late final GeneratedColumn<String> materialId = GeneratedColumn<String>(
      'material_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _barcodeNoMeta =
      const VerificationMeta('barcodeNo');
  @override
  late final GeneratedColumn<String> barcodeNo = GeneratedColumn<String>(
      'barcode_no', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _materialTypeMeta =
      const VerificationMeta('materialType');
  @override
  late final GeneratedColumn<String> materialType = GeneratedColumn<String>(
      'material_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _materialNameMeta =
      const VerificationMeta('materialName');
  @override
  late final GeneratedColumn<String> materialName = GeneratedColumn<String>(
      'material_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _batchNoMeta =
      const VerificationMeta('batchNo');
  @override
  late final GeneratedColumn<String> batchNo = GeneratedColumn<String>(
      'batch_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _packingMeta =
      const VerificationMeta('packing');
  @override
  late final GeneratedColumn<String> packing = GeneratedColumn<String>(
      'packing', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _qtyCaseMeta =
      const VerificationMeta('qtyCase');
  @override
  late final GeneratedColumn<int> qtyCase = GeneratedColumn<int>(
      'qty_case', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _discountPercentMeta =
      const VerificationMeta('discountPercent');
  @override
  late final GeneratedColumn<double> discountPercent = GeneratedColumn<double>(
      'discount_percent', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _discountAmountMeta =
      const VerificationMeta('discountAmount');
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
      'discount_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _taxPercentMeta =
      const VerificationMeta('taxPercent');
  @override
  late final GeneratedColumn<double> taxPercent = GeneratedColumn<double>(
      'tax_percent', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _taxAmountMeta =
      const VerificationMeta('taxAmount');
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
      'tax_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lineNumberMeta =
      const VerificationMeta('lineNumber');
  @override
  late final GeneratedColumn<int> lineNumber = GeneratedColumn<int>(
      'line_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        salesBillId,
        materialId,
        barcodeNo,
        materialType,
        materialName,
        batchNo,
        packing,
        quantity,
        qtyCase,
        rate,
        discountPercent,
        discountAmount,
        taxPercent,
        taxAmount,
        amount,
        lineNumber
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_sale_line_items';
  @override
  VerificationContext validateIntegrity(Insertable<CachedSaleLineItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sales_bill_id')) {
      context.handle(
          _salesBillIdMeta,
          salesBillId.isAcceptableOrUnknown(
              data['sales_bill_id']!, _salesBillIdMeta));
    } else if (isInserting) {
      context.missing(_salesBillIdMeta);
    }
    if (data.containsKey('material_id')) {
      context.handle(
          _materialIdMeta,
          materialId.isAcceptableOrUnknown(
              data['material_id']!, _materialIdMeta));
    }
    if (data.containsKey('barcode_no')) {
      context.handle(_barcodeNoMeta,
          barcodeNo.isAcceptableOrUnknown(data['barcode_no']!, _barcodeNoMeta));
    } else if (isInserting) {
      context.missing(_barcodeNoMeta);
    }
    if (data.containsKey('material_type')) {
      context.handle(
          _materialTypeMeta,
          materialType.isAcceptableOrUnknown(
              data['material_type']!, _materialTypeMeta));
    } else if (isInserting) {
      context.missing(_materialTypeMeta);
    }
    if (data.containsKey('material_name')) {
      context.handle(
          _materialNameMeta,
          materialName.isAcceptableOrUnknown(
              data['material_name']!, _materialNameMeta));
    } else if (isInserting) {
      context.missing(_materialNameMeta);
    }
    if (data.containsKey('batch_no')) {
      context.handle(_batchNoMeta,
          batchNo.isAcceptableOrUnknown(data['batch_no']!, _batchNoMeta));
    }
    if (data.containsKey('packing')) {
      context.handle(_packingMeta,
          packing.isAcceptableOrUnknown(data['packing']!, _packingMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('qty_case')) {
      context.handle(_qtyCaseMeta,
          qtyCase.isAcceptableOrUnknown(data['qty_case']!, _qtyCaseMeta));
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('discount_percent')) {
      context.handle(
          _discountPercentMeta,
          discountPercent.isAcceptableOrUnknown(
              data['discount_percent']!, _discountPercentMeta));
    } else if (isInserting) {
      context.missing(_discountPercentMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
          _discountAmountMeta,
          discountAmount.isAcceptableOrUnknown(
              data['discount_amount']!, _discountAmountMeta));
    } else if (isInserting) {
      context.missing(_discountAmountMeta);
    }
    if (data.containsKey('tax_percent')) {
      context.handle(
          _taxPercentMeta,
          taxPercent.isAcceptableOrUnknown(
              data['tax_percent']!, _taxPercentMeta));
    } else if (isInserting) {
      context.missing(_taxPercentMeta);
    }
    if (data.containsKey('tax_amount')) {
      context.handle(_taxAmountMeta,
          taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta));
    } else if (isInserting) {
      context.missing(_taxAmountMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('line_number')) {
      context.handle(
          _lineNumberMeta,
          lineNumber.isAcceptableOrUnknown(
              data['line_number']!, _lineNumberMeta));
    } else if (isInserting) {
      context.missing(_lineNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSaleLineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSaleLineItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      salesBillId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sales_bill_id'])!,
      materialId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}material_id']),
      barcodeNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode_no'])!,
      materialType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}material_type'])!,
      materialName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}material_name'])!,
      batchNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_no']),
      packing: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}packing']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      qtyCase: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}qty_case'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate'])!,
      discountPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}discount_percent'])!,
      discountAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}discount_amount'])!,
      taxPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_percent'])!,
      taxAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_amount'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      lineNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_number'])!,
    );
  }

  @override
  $CachedSaleLineItemsTable createAlias(String alias) {
    return $CachedSaleLineItemsTable(attachedDatabase, alias);
  }
}

class CachedSaleLineItem extends DataClass
    implements Insertable<CachedSaleLineItem> {
  final String id;
  final String salesBillId;
  final String? materialId;
  final String barcodeNo;
  final String materialType;
  final String materialName;
  final String? batchNo;
  final String? packing;
  final int quantity;
  final int qtyCase;
  final double rate;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double amount;
  final int lineNumber;
  const CachedSaleLineItem(
      {required this.id,
      required this.salesBillId,
      this.materialId,
      required this.barcodeNo,
      required this.materialType,
      required this.materialName,
      this.batchNo,
      this.packing,
      required this.quantity,
      required this.qtyCase,
      required this.rate,
      required this.discountPercent,
      required this.discountAmount,
      required this.taxPercent,
      required this.taxAmount,
      required this.amount,
      required this.lineNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sales_bill_id'] = Variable<String>(salesBillId);
    if (!nullToAbsent || materialId != null) {
      map['material_id'] = Variable<String>(materialId);
    }
    map['barcode_no'] = Variable<String>(barcodeNo);
    map['material_type'] = Variable<String>(materialType);
    map['material_name'] = Variable<String>(materialName);
    if (!nullToAbsent || batchNo != null) {
      map['batch_no'] = Variable<String>(batchNo);
    }
    if (!nullToAbsent || packing != null) {
      map['packing'] = Variable<String>(packing);
    }
    map['quantity'] = Variable<int>(quantity);
    map['qty_case'] = Variable<int>(qtyCase);
    map['rate'] = Variable<double>(rate);
    map['discount_percent'] = Variable<double>(discountPercent);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['tax_percent'] = Variable<double>(taxPercent);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['amount'] = Variable<double>(amount);
    map['line_number'] = Variable<int>(lineNumber);
    return map;
  }

  CachedSaleLineItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedSaleLineItemsCompanion(
      id: Value(id),
      salesBillId: Value(salesBillId),
      materialId: materialId == null && nullToAbsent
          ? const Value.absent()
          : Value(materialId),
      barcodeNo: Value(barcodeNo),
      materialType: Value(materialType),
      materialName: Value(materialName),
      batchNo: batchNo == null && nullToAbsent
          ? const Value.absent()
          : Value(batchNo),
      packing: packing == null && nullToAbsent
          ? const Value.absent()
          : Value(packing),
      quantity: Value(quantity),
      qtyCase: Value(qtyCase),
      rate: Value(rate),
      discountPercent: Value(discountPercent),
      discountAmount: Value(discountAmount),
      taxPercent: Value(taxPercent),
      taxAmount: Value(taxAmount),
      amount: Value(amount),
      lineNumber: Value(lineNumber),
    );
  }

  factory CachedSaleLineItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSaleLineItem(
      id: serializer.fromJson<String>(json['id']),
      salesBillId: serializer.fromJson<String>(json['salesBillId']),
      materialId: serializer.fromJson<String?>(json['materialId']),
      barcodeNo: serializer.fromJson<String>(json['barcodeNo']),
      materialType: serializer.fromJson<String>(json['materialType']),
      materialName: serializer.fromJson<String>(json['materialName']),
      batchNo: serializer.fromJson<String?>(json['batchNo']),
      packing: serializer.fromJson<String?>(json['packing']),
      quantity: serializer.fromJson<int>(json['quantity']),
      qtyCase: serializer.fromJson<int>(json['qtyCase']),
      rate: serializer.fromJson<double>(json['rate']),
      discountPercent: serializer.fromJson<double>(json['discountPercent']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      taxPercent: serializer.fromJson<double>(json['taxPercent']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      amount: serializer.fromJson<double>(json['amount']),
      lineNumber: serializer.fromJson<int>(json['lineNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'salesBillId': serializer.toJson<String>(salesBillId),
      'materialId': serializer.toJson<String?>(materialId),
      'barcodeNo': serializer.toJson<String>(barcodeNo),
      'materialType': serializer.toJson<String>(materialType),
      'materialName': serializer.toJson<String>(materialName),
      'batchNo': serializer.toJson<String?>(batchNo),
      'packing': serializer.toJson<String?>(packing),
      'quantity': serializer.toJson<int>(quantity),
      'qtyCase': serializer.toJson<int>(qtyCase),
      'rate': serializer.toJson<double>(rate),
      'discountPercent': serializer.toJson<double>(discountPercent),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'taxPercent': serializer.toJson<double>(taxPercent),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'amount': serializer.toJson<double>(amount),
      'lineNumber': serializer.toJson<int>(lineNumber),
    };
  }

  CachedSaleLineItem copyWith(
          {String? id,
          String? salesBillId,
          Value<String?> materialId = const Value.absent(),
          String? barcodeNo,
          String? materialType,
          String? materialName,
          Value<String?> batchNo = const Value.absent(),
          Value<String?> packing = const Value.absent(),
          int? quantity,
          int? qtyCase,
          double? rate,
          double? discountPercent,
          double? discountAmount,
          double? taxPercent,
          double? taxAmount,
          double? amount,
          int? lineNumber}) =>
      CachedSaleLineItem(
        id: id ?? this.id,
        salesBillId: salesBillId ?? this.salesBillId,
        materialId: materialId.present ? materialId.value : this.materialId,
        barcodeNo: barcodeNo ?? this.barcodeNo,
        materialType: materialType ?? this.materialType,
        materialName: materialName ?? this.materialName,
        batchNo: batchNo.present ? batchNo.value : this.batchNo,
        packing: packing.present ? packing.value : this.packing,
        quantity: quantity ?? this.quantity,
        qtyCase: qtyCase ?? this.qtyCase,
        rate: rate ?? this.rate,
        discountPercent: discountPercent ?? this.discountPercent,
        discountAmount: discountAmount ?? this.discountAmount,
        taxPercent: taxPercent ?? this.taxPercent,
        taxAmount: taxAmount ?? this.taxAmount,
        amount: amount ?? this.amount,
        lineNumber: lineNumber ?? this.lineNumber,
      );
  CachedSaleLineItem copyWithCompanion(CachedSaleLineItemsCompanion data) {
    return CachedSaleLineItem(
      id: data.id.present ? data.id.value : this.id,
      salesBillId:
          data.salesBillId.present ? data.salesBillId.value : this.salesBillId,
      materialId:
          data.materialId.present ? data.materialId.value : this.materialId,
      barcodeNo: data.barcodeNo.present ? data.barcodeNo.value : this.barcodeNo,
      materialType: data.materialType.present
          ? data.materialType.value
          : this.materialType,
      materialName: data.materialName.present
          ? data.materialName.value
          : this.materialName,
      batchNo: data.batchNo.present ? data.batchNo.value : this.batchNo,
      packing: data.packing.present ? data.packing.value : this.packing,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      qtyCase: data.qtyCase.present ? data.qtyCase.value : this.qtyCase,
      rate: data.rate.present ? data.rate.value : this.rate,
      discountPercent: data.discountPercent.present
          ? data.discountPercent.value
          : this.discountPercent,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      taxPercent:
          data.taxPercent.present ? data.taxPercent.value : this.taxPercent,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      amount: data.amount.present ? data.amount.value : this.amount,
      lineNumber:
          data.lineNumber.present ? data.lineNumber.value : this.lineNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSaleLineItem(')
          ..write('id: $id, ')
          ..write('salesBillId: $salesBillId, ')
          ..write('materialId: $materialId, ')
          ..write('barcodeNo: $barcodeNo, ')
          ..write('materialType: $materialType, ')
          ..write('materialName: $materialName, ')
          ..write('batchNo: $batchNo, ')
          ..write('packing: $packing, ')
          ..write('quantity: $quantity, ')
          ..write('qtyCase: $qtyCase, ')
          ..write('rate: $rate, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxPercent: $taxPercent, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('amount: $amount, ')
          ..write('lineNumber: $lineNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      salesBillId,
      materialId,
      barcodeNo,
      materialType,
      materialName,
      batchNo,
      packing,
      quantity,
      qtyCase,
      rate,
      discountPercent,
      discountAmount,
      taxPercent,
      taxAmount,
      amount,
      lineNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSaleLineItem &&
          other.id == this.id &&
          other.salesBillId == this.salesBillId &&
          other.materialId == this.materialId &&
          other.barcodeNo == this.barcodeNo &&
          other.materialType == this.materialType &&
          other.materialName == this.materialName &&
          other.batchNo == this.batchNo &&
          other.packing == this.packing &&
          other.quantity == this.quantity &&
          other.qtyCase == this.qtyCase &&
          other.rate == this.rate &&
          other.discountPercent == this.discountPercent &&
          other.discountAmount == this.discountAmount &&
          other.taxPercent == this.taxPercent &&
          other.taxAmount == this.taxAmount &&
          other.amount == this.amount &&
          other.lineNumber == this.lineNumber);
}

class CachedSaleLineItemsCompanion extends UpdateCompanion<CachedSaleLineItem> {
  final Value<String> id;
  final Value<String> salesBillId;
  final Value<String?> materialId;
  final Value<String> barcodeNo;
  final Value<String> materialType;
  final Value<String> materialName;
  final Value<String?> batchNo;
  final Value<String?> packing;
  final Value<int> quantity;
  final Value<int> qtyCase;
  final Value<double> rate;
  final Value<double> discountPercent;
  final Value<double> discountAmount;
  final Value<double> taxPercent;
  final Value<double> taxAmount;
  final Value<double> amount;
  final Value<int> lineNumber;
  final Value<int> rowid;
  const CachedSaleLineItemsCompanion({
    this.id = const Value.absent(),
    this.salesBillId = const Value.absent(),
    this.materialId = const Value.absent(),
    this.barcodeNo = const Value.absent(),
    this.materialType = const Value.absent(),
    this.materialName = const Value.absent(),
    this.batchNo = const Value.absent(),
    this.packing = const Value.absent(),
    this.quantity = const Value.absent(),
    this.qtyCase = const Value.absent(),
    this.rate = const Value.absent(),
    this.discountPercent = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxPercent = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.amount = const Value.absent(),
    this.lineNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSaleLineItemsCompanion.insert({
    required String id,
    required String salesBillId,
    this.materialId = const Value.absent(),
    required String barcodeNo,
    required String materialType,
    required String materialName,
    this.batchNo = const Value.absent(),
    this.packing = const Value.absent(),
    required int quantity,
    this.qtyCase = const Value.absent(),
    required double rate,
    required double discountPercent,
    required double discountAmount,
    required double taxPercent,
    required double taxAmount,
    required double amount,
    required int lineNumber,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        salesBillId = Value(salesBillId),
        barcodeNo = Value(barcodeNo),
        materialType = Value(materialType),
        materialName = Value(materialName),
        quantity = Value(quantity),
        rate = Value(rate),
        discountPercent = Value(discountPercent),
        discountAmount = Value(discountAmount),
        taxPercent = Value(taxPercent),
        taxAmount = Value(taxAmount),
        amount = Value(amount),
        lineNumber = Value(lineNumber);
  static Insertable<CachedSaleLineItem> custom({
    Expression<String>? id,
    Expression<String>? salesBillId,
    Expression<String>? materialId,
    Expression<String>? barcodeNo,
    Expression<String>? materialType,
    Expression<String>? materialName,
    Expression<String>? batchNo,
    Expression<String>? packing,
    Expression<int>? quantity,
    Expression<int>? qtyCase,
    Expression<double>? rate,
    Expression<double>? discountPercent,
    Expression<double>? discountAmount,
    Expression<double>? taxPercent,
    Expression<double>? taxAmount,
    Expression<double>? amount,
    Expression<int>? lineNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (salesBillId != null) 'sales_bill_id': salesBillId,
      if (materialId != null) 'material_id': materialId,
      if (barcodeNo != null) 'barcode_no': barcodeNo,
      if (materialType != null) 'material_type': materialType,
      if (materialName != null) 'material_name': materialName,
      if (batchNo != null) 'batch_no': batchNo,
      if (packing != null) 'packing': packing,
      if (quantity != null) 'quantity': quantity,
      if (qtyCase != null) 'qty_case': qtyCase,
      if (rate != null) 'rate': rate,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (amount != null) 'amount': amount,
      if (lineNumber != null) 'line_number': lineNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSaleLineItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? salesBillId,
      Value<String?>? materialId,
      Value<String>? barcodeNo,
      Value<String>? materialType,
      Value<String>? materialName,
      Value<String?>? batchNo,
      Value<String?>? packing,
      Value<int>? quantity,
      Value<int>? qtyCase,
      Value<double>? rate,
      Value<double>? discountPercent,
      Value<double>? discountAmount,
      Value<double>? taxPercent,
      Value<double>? taxAmount,
      Value<double>? amount,
      Value<int>? lineNumber,
      Value<int>? rowid}) {
    return CachedSaleLineItemsCompanion(
      id: id ?? this.id,
      salesBillId: salesBillId ?? this.salesBillId,
      materialId: materialId ?? this.materialId,
      barcodeNo: barcodeNo ?? this.barcodeNo,
      materialType: materialType ?? this.materialType,
      materialName: materialName ?? this.materialName,
      batchNo: batchNo ?? this.batchNo,
      packing: packing ?? this.packing,
      quantity: quantity ?? this.quantity,
      qtyCase: qtyCase ?? this.qtyCase,
      rate: rate ?? this.rate,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      amount: amount ?? this.amount,
      lineNumber: lineNumber ?? this.lineNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (salesBillId.present) {
      map['sales_bill_id'] = Variable<String>(salesBillId.value);
    }
    if (materialId.present) {
      map['material_id'] = Variable<String>(materialId.value);
    }
    if (barcodeNo.present) {
      map['barcode_no'] = Variable<String>(barcodeNo.value);
    }
    if (materialType.present) {
      map['material_type'] = Variable<String>(materialType.value);
    }
    if (materialName.present) {
      map['material_name'] = Variable<String>(materialName.value);
    }
    if (batchNo.present) {
      map['batch_no'] = Variable<String>(batchNo.value);
    }
    if (packing.present) {
      map['packing'] = Variable<String>(packing.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (qtyCase.present) {
      map['qty_case'] = Variable<int>(qtyCase.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (discountPercent.present) {
      map['discount_percent'] = Variable<double>(discountPercent.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (taxPercent.present) {
      map['tax_percent'] = Variable<double>(taxPercent.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (lineNumber.present) {
      map['line_number'] = Variable<int>(lineNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSaleLineItemsCompanion(')
          ..write('id: $id, ')
          ..write('salesBillId: $salesBillId, ')
          ..write('materialId: $materialId, ')
          ..write('barcodeNo: $barcodeNo, ')
          ..write('materialType: $materialType, ')
          ..write('materialName: $materialName, ')
          ..write('batchNo: $batchNo, ')
          ..write('packing: $packing, ')
          ..write('quantity: $quantity, ')
          ..write('qtyCase: $qtyCase, ')
          ..write('rate: $rate, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxPercent: $taxPercent, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('amount: $amount, ')
          ..write('lineNumber: $lineNumber, ')
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
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);
  late final $CachedInventoryStocksTable cachedInventoryStocks =
      $CachedInventoryStocksTable(this);
  late final $CachedSalesBillsTable cachedSalesBills =
      $CachedSalesBillsTable(this);
  late final $CachedSaleLineItemsTable cachedSaleLineItems =
      $CachedSaleLineItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cachedMaterials,
        cachedSuppliers,
        syncQueueItems,
        cachedInventoryStocks,
        cachedSalesBills,
        cachedSaleLineItems
      ];
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
typedef $$SyncQueueItemsTableCreateCompanionBuilder = SyncQueueItemsCompanion
    Function({
  Value<int> id,
  required String entityType,
  required String entityId,
  required String operation,
  required String payload,
  Value<String> status,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$SyncQueueItemsTableUpdateCompanionBuilder = SyncQueueItemsCompanion
    Function({
  Value<int> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payload,
  Value<String> status,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$SyncQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncQueueItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueItemsTable,
    SyncQueueItem,
    $$SyncQueueItemsTableFilterComposer,
    $$SyncQueueItemsTableOrderingComposer,
    $$SyncQueueItemsTableAnnotationComposer,
    $$SyncQueueItemsTableCreateCompanionBuilder,
    $$SyncQueueItemsTableUpdateCompanionBuilder,
    (
      SyncQueueItem,
      BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>
    ),
    SyncQueueItem,
    PrefetchHooks Function()> {
  $$SyncQueueItemsTableTableManager(
      _$AppDatabase db, $SyncQueueItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncQueueItemsCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
            status: status,
            lastError: lastError,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required String entityId,
            required String operation,
            required String payload,
            Value<String> status = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncQueueItemsCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
            status: status,
            lastError: lastError,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueItemsTable,
    SyncQueueItem,
    $$SyncQueueItemsTableFilterComposer,
    $$SyncQueueItemsTableOrderingComposer,
    $$SyncQueueItemsTableAnnotationComposer,
    $$SyncQueueItemsTableCreateCompanionBuilder,
    $$SyncQueueItemsTableUpdateCompanionBuilder,
    (
      SyncQueueItem,
      BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>
    ),
    SyncQueueItem,
    PrefetchHooks Function()>;
typedef $$CachedInventoryStocksTableCreateCompanionBuilder
    = CachedInventoryStocksCompanion Function({
  required String materialId,
  required String barcode,
  required String name,
  required String category,
  required int qtyOnHand,
  Value<int> reorderLevel,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$CachedInventoryStocksTableUpdateCompanionBuilder
    = CachedInventoryStocksCompanion Function({
  Value<String> materialId,
  Value<String> barcode,
  Value<String> name,
  Value<String> category,
  Value<int> qtyOnHand,
  Value<int> reorderLevel,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CachedInventoryStocksTableFilterComposer
    extends Composer<_$AppDatabase, $CachedInventoryStocksTable> {
  $$CachedInventoryStocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qtyOnHand => $composableBuilder(
      column: $table.qtyOnHand, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reorderLevel => $composableBuilder(
      column: $table.reorderLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedInventoryStocksTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedInventoryStocksTable> {
  $$CachedInventoryStocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qtyOnHand => $composableBuilder(
      column: $table.qtyOnHand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reorderLevel => $composableBuilder(
      column: $table.reorderLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedInventoryStocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedInventoryStocksTable> {
  $$CachedInventoryStocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get qtyOnHand =>
      $composableBuilder(column: $table.qtyOnHand, builder: (column) => column);

  GeneratedColumn<int> get reorderLevel => $composableBuilder(
      column: $table.reorderLevel, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedInventoryStocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedInventoryStocksTable,
    CachedInventoryStock,
    $$CachedInventoryStocksTableFilterComposer,
    $$CachedInventoryStocksTableOrderingComposer,
    $$CachedInventoryStocksTableAnnotationComposer,
    $$CachedInventoryStocksTableCreateCompanionBuilder,
    $$CachedInventoryStocksTableUpdateCompanionBuilder,
    (
      CachedInventoryStock,
      BaseReferences<_$AppDatabase, $CachedInventoryStocksTable,
          CachedInventoryStock>
    ),
    CachedInventoryStock,
    PrefetchHooks Function()> {
  $$CachedInventoryStocksTableTableManager(
      _$AppDatabase db, $CachedInventoryStocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedInventoryStocksTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedInventoryStocksTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedInventoryStocksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> materialId = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<int> qtyOnHand = const Value.absent(),
            Value<int> reorderLevel = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedInventoryStocksCompanion(
            materialId: materialId,
            barcode: barcode,
            name: name,
            category: category,
            qtyOnHand: qtyOnHand,
            reorderLevel: reorderLevel,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String materialId,
            required String barcode,
            required String name,
            required String category,
            required int qtyOnHand,
            Value<int> reorderLevel = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedInventoryStocksCompanion.insert(
            materialId: materialId,
            barcode: barcode,
            name: name,
            category: category,
            qtyOnHand: qtyOnHand,
            reorderLevel: reorderLevel,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedInventoryStocksTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CachedInventoryStocksTable,
        CachedInventoryStock,
        $$CachedInventoryStocksTableFilterComposer,
        $$CachedInventoryStocksTableOrderingComposer,
        $$CachedInventoryStocksTableAnnotationComposer,
        $$CachedInventoryStocksTableCreateCompanionBuilder,
        $$CachedInventoryStocksTableUpdateCompanionBuilder,
        (
          CachedInventoryStock,
          BaseReferences<_$AppDatabase, $CachedInventoryStocksTable,
              CachedInventoryStock>
        ),
        CachedInventoryStock,
        PrefetchHooks Function()>;
typedef $$CachedSalesBillsTableCreateCompanionBuilder
    = CachedSalesBillsCompanion Function({
  required String id,
  required String billNo,
  Value<String?> customerId,
  required String payMode,
  required String status,
  required double totalAmount,
  required double balanceDue,
  required double totalTax,
  Value<String> syncStatus,
  required DateTime billDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$CachedSalesBillsTableUpdateCompanionBuilder
    = CachedSalesBillsCompanion Function({
  Value<String> id,
  Value<String> billNo,
  Value<String?> customerId,
  Value<String> payMode,
  Value<String> status,
  Value<double> totalAmount,
  Value<double> balanceDue,
  Value<double> totalTax,
  Value<String> syncStatus,
  Value<DateTime> billDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CachedSalesBillsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSalesBillsTable> {
  $$CachedSalesBillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get billNo => $composableBuilder(
      column: $table.billNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payMode => $composableBuilder(
      column: $table.payMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get balanceDue => $composableBuilder(
      column: $table.balanceDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalTax => $composableBuilder(
      column: $table.totalTax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get billDate => $composableBuilder(
      column: $table.billDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedSalesBillsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSalesBillsTable> {
  $$CachedSalesBillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get billNo => $composableBuilder(
      column: $table.billNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payMode => $composableBuilder(
      column: $table.payMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get balanceDue => $composableBuilder(
      column: $table.balanceDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalTax => $composableBuilder(
      column: $table.totalTax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get billDate => $composableBuilder(
      column: $table.billDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedSalesBillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSalesBillsTable> {
  $$CachedSalesBillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get billNo =>
      $composableBuilder(column: $table.billNo, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get payMode =>
      $composableBuilder(column: $table.payMode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<double> get balanceDue => $composableBuilder(
      column: $table.balanceDue, builder: (column) => column);

  GeneratedColumn<double> get totalTax =>
      $composableBuilder(column: $table.totalTax, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get billDate =>
      $composableBuilder(column: $table.billDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedSalesBillsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedSalesBillsTable,
    CachedSalesBill,
    $$CachedSalesBillsTableFilterComposer,
    $$CachedSalesBillsTableOrderingComposer,
    $$CachedSalesBillsTableAnnotationComposer,
    $$CachedSalesBillsTableCreateCompanionBuilder,
    $$CachedSalesBillsTableUpdateCompanionBuilder,
    (
      CachedSalesBill,
      BaseReferences<_$AppDatabase, $CachedSalesBillsTable, CachedSalesBill>
    ),
    CachedSalesBill,
    PrefetchHooks Function()> {
  $$CachedSalesBillsTableTableManager(
      _$AppDatabase db, $CachedSalesBillsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSalesBillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSalesBillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSalesBillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> billNo = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String> payMode = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<double> balanceDue = const Value.absent(),
            Value<double> totalTax = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> billDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedSalesBillsCompanion(
            id: id,
            billNo: billNo,
            customerId: customerId,
            payMode: payMode,
            status: status,
            totalAmount: totalAmount,
            balanceDue: balanceDue,
            totalTax: totalTax,
            syncStatus: syncStatus,
            billDate: billDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String billNo,
            Value<String?> customerId = const Value.absent(),
            required String payMode,
            required String status,
            required double totalAmount,
            required double balanceDue,
            required double totalTax,
            Value<String> syncStatus = const Value.absent(),
            required DateTime billDate,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedSalesBillsCompanion.insert(
            id: id,
            billNo: billNo,
            customerId: customerId,
            payMode: payMode,
            status: status,
            totalAmount: totalAmount,
            balanceDue: balanceDue,
            totalTax: totalTax,
            syncStatus: syncStatus,
            billDate: billDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedSalesBillsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedSalesBillsTable,
    CachedSalesBill,
    $$CachedSalesBillsTableFilterComposer,
    $$CachedSalesBillsTableOrderingComposer,
    $$CachedSalesBillsTableAnnotationComposer,
    $$CachedSalesBillsTableCreateCompanionBuilder,
    $$CachedSalesBillsTableUpdateCompanionBuilder,
    (
      CachedSalesBill,
      BaseReferences<_$AppDatabase, $CachedSalesBillsTable, CachedSalesBill>
    ),
    CachedSalesBill,
    PrefetchHooks Function()>;
typedef $$CachedSaleLineItemsTableCreateCompanionBuilder
    = CachedSaleLineItemsCompanion Function({
  required String id,
  required String salesBillId,
  Value<String?> materialId,
  required String barcodeNo,
  required String materialType,
  required String materialName,
  Value<String?> batchNo,
  Value<String?> packing,
  required int quantity,
  Value<int> qtyCase,
  required double rate,
  required double discountPercent,
  required double discountAmount,
  required double taxPercent,
  required double taxAmount,
  required double amount,
  required int lineNumber,
  Value<int> rowid,
});
typedef $$CachedSaleLineItemsTableUpdateCompanionBuilder
    = CachedSaleLineItemsCompanion Function({
  Value<String> id,
  Value<String> salesBillId,
  Value<String?> materialId,
  Value<String> barcodeNo,
  Value<String> materialType,
  Value<String> materialName,
  Value<String?> batchNo,
  Value<String?> packing,
  Value<int> quantity,
  Value<int> qtyCase,
  Value<double> rate,
  Value<double> discountPercent,
  Value<double> discountAmount,
  Value<double> taxPercent,
  Value<double> taxAmount,
  Value<double> amount,
  Value<int> lineNumber,
  Value<int> rowid,
});

class $$CachedSaleLineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSaleLineItemsTable> {
  $$CachedSaleLineItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get salesBillId => $composableBuilder(
      column: $table.salesBillId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcodeNo => $composableBuilder(
      column: $table.barcodeNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get materialType => $composableBuilder(
      column: $table.materialType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get materialName => $composableBuilder(
      column: $table.materialName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get batchNo => $composableBuilder(
      column: $table.batchNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packing => $composableBuilder(
      column: $table.packing, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qtyCase => $composableBuilder(
      column: $table.qtyCase, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountPercent => $composableBuilder(
      column: $table.discountPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxAmount => $composableBuilder(
      column: $table.taxAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => ColumnFilters(column));
}

class $$CachedSaleLineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSaleLineItemsTable> {
  $$CachedSaleLineItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get salesBillId => $composableBuilder(
      column: $table.salesBillId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcodeNo => $composableBuilder(
      column: $table.barcodeNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get materialType => $composableBuilder(
      column: $table.materialType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get materialName => $composableBuilder(
      column: $table.materialName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get batchNo => $composableBuilder(
      column: $table.batchNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packing => $composableBuilder(
      column: $table.packing, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qtyCase => $composableBuilder(
      column: $table.qtyCase, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountPercent => $composableBuilder(
      column: $table.discountPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxAmount => $composableBuilder(
      column: $table.taxAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => ColumnOrderings(column));
}

class $$CachedSaleLineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSaleLineItemsTable> {
  $$CachedSaleLineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get salesBillId => $composableBuilder(
      column: $table.salesBillId, builder: (column) => column);

  GeneratedColumn<String> get materialId => $composableBuilder(
      column: $table.materialId, builder: (column) => column);

  GeneratedColumn<String> get barcodeNo =>
      $composableBuilder(column: $table.barcodeNo, builder: (column) => column);

  GeneratedColumn<String> get materialType => $composableBuilder(
      column: $table.materialType, builder: (column) => column);

  GeneratedColumn<String> get materialName => $composableBuilder(
      column: $table.materialName, builder: (column) => column);

  GeneratedColumn<String> get batchNo =>
      $composableBuilder(column: $table.batchNo, builder: (column) => column);

  GeneratedColumn<String> get packing =>
      $composableBuilder(column: $table.packing, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get qtyCase =>
      $composableBuilder(column: $table.qtyCase, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<double> get discountPercent => $composableBuilder(
      column: $table.discountPercent, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount, builder: (column) => column);

  GeneratedColumn<double> get taxPercent => $composableBuilder(
      column: $table.taxPercent, builder: (column) => column);

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => column);
}

class $$CachedSaleLineItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedSaleLineItemsTable,
    CachedSaleLineItem,
    $$CachedSaleLineItemsTableFilterComposer,
    $$CachedSaleLineItemsTableOrderingComposer,
    $$CachedSaleLineItemsTableAnnotationComposer,
    $$CachedSaleLineItemsTableCreateCompanionBuilder,
    $$CachedSaleLineItemsTableUpdateCompanionBuilder,
    (
      CachedSaleLineItem,
      BaseReferences<_$AppDatabase, $CachedSaleLineItemsTable,
          CachedSaleLineItem>
    ),
    CachedSaleLineItem,
    PrefetchHooks Function()> {
  $$CachedSaleLineItemsTableTableManager(
      _$AppDatabase db, $CachedSaleLineItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSaleLineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSaleLineItemsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSaleLineItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> salesBillId = const Value.absent(),
            Value<String?> materialId = const Value.absent(),
            Value<String> barcodeNo = const Value.absent(),
            Value<String> materialType = const Value.absent(),
            Value<String> materialName = const Value.absent(),
            Value<String?> batchNo = const Value.absent(),
            Value<String?> packing = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<int> qtyCase = const Value.absent(),
            Value<double> rate = const Value.absent(),
            Value<double> discountPercent = const Value.absent(),
            Value<double> discountAmount = const Value.absent(),
            Value<double> taxPercent = const Value.absent(),
            Value<double> taxAmount = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<int> lineNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedSaleLineItemsCompanion(
            id: id,
            salesBillId: salesBillId,
            materialId: materialId,
            barcodeNo: barcodeNo,
            materialType: materialType,
            materialName: materialName,
            batchNo: batchNo,
            packing: packing,
            quantity: quantity,
            qtyCase: qtyCase,
            rate: rate,
            discountPercent: discountPercent,
            discountAmount: discountAmount,
            taxPercent: taxPercent,
            taxAmount: taxAmount,
            amount: amount,
            lineNumber: lineNumber,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String salesBillId,
            Value<String?> materialId = const Value.absent(),
            required String barcodeNo,
            required String materialType,
            required String materialName,
            Value<String?> batchNo = const Value.absent(),
            Value<String?> packing = const Value.absent(),
            required int quantity,
            Value<int> qtyCase = const Value.absent(),
            required double rate,
            required double discountPercent,
            required double discountAmount,
            required double taxPercent,
            required double taxAmount,
            required double amount,
            required int lineNumber,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedSaleLineItemsCompanion.insert(
            id: id,
            salesBillId: salesBillId,
            materialId: materialId,
            barcodeNo: barcodeNo,
            materialType: materialType,
            materialName: materialName,
            batchNo: batchNo,
            packing: packing,
            quantity: quantity,
            qtyCase: qtyCase,
            rate: rate,
            discountPercent: discountPercent,
            discountAmount: discountAmount,
            taxPercent: taxPercent,
            taxAmount: taxAmount,
            amount: amount,
            lineNumber: lineNumber,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedSaleLineItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedSaleLineItemsTable,
    CachedSaleLineItem,
    $$CachedSaleLineItemsTableFilterComposer,
    $$CachedSaleLineItemsTableOrderingComposer,
    $$CachedSaleLineItemsTableAnnotationComposer,
    $$CachedSaleLineItemsTableCreateCompanionBuilder,
    $$CachedSaleLineItemsTableUpdateCompanionBuilder,
    (
      CachedSaleLineItem,
      BaseReferences<_$AppDatabase, $CachedSaleLineItemsTable,
          CachedSaleLineItem>
    ),
    CachedSaleLineItem,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedMaterialsTableTableManager get cachedMaterials =>
      $$CachedMaterialsTableTableManager(_db, _db.cachedMaterials);
  $$CachedSuppliersTableTableManager get cachedSuppliers =>
      $$CachedSuppliersTableTableManager(_db, _db.cachedSuppliers);
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
  $$CachedInventoryStocksTableTableManager get cachedInventoryStocks =>
      $$CachedInventoryStocksTableTableManager(_db, _db.cachedInventoryStocks);
  $$CachedSalesBillsTableTableManager get cachedSalesBills =>
      $$CachedSalesBillsTableTableManager(_db, _db.cachedSalesBills);
  $$CachedSaleLineItemsTableTableManager get cachedSaleLineItems =>
      $$CachedSaleLineItemsTableTableManager(_db, _db.cachedSaleLineItems);
}
