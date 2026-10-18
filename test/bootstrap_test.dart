import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/local/app_database.dart';
import 'package:pos_app/core/local/material_lookup_cache.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  test('test migrations from 1 to 10 and null columns', () async {
    for (int v = 1; v <= 10; v++) {
      final rawDb = sql.sqlite3.openInMemory();
      rawDb.execute('''
        CREATE TABLE cached_materials (
          id TEXT NOT NULL PRIMARY KEY,
          barcode TEXT NOT NULL,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          packing TEXT NOT NULL,
          sale_rate REAL NOT NULL,
          tax_percent REAL NOT NULL,
          stock_qty INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_synced_at INTEGER
        );
        CREATE TABLE cached_suppliers (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT,
          contact_no TEXT,
          email TEXT,
          vat_no TEXT,
          bank_details TEXT,
          dis_percent REAL NOT NULL DEFAULT 0.0,
          opening_balance REAL NOT NULL DEFAULT 0.0,
          balance_type TEXT NOT NULL DEFAULT 'Credit',
          sync_status TEXT NOT NULL DEFAULT 'synced',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_synced_at INTEGER
        );
        PRAGMA user_version = $v;
      ''');
      if (v >= 2) {
        rawDb.execute('''
          CREATE TABLE sync_queue_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            operation TEXT NOT NULL,
            status TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            error_message TEXT,
            created_at INTEGER NOT NULL
          );
        ''');
      }
      if (v >= 3) {
        rawDb.execute('''
          CREATE TABLE cached_inventory_stocks (
            material_id TEXT NOT NULL PRIMARY KEY,
            barcode TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            qty_on_hand INTEGER NOT NULL,
            reorder_level INTEGER NOT NULL DEFAULT 10,
            updated_at INTEGER NOT NULL
          );
        ''');
      }
      if (v >= 4) {
        rawDb.execute('''
          CREATE TABLE cached_sales_bills (
            id TEXT NOT NULL PRIMARY KEY,
            bill_no TEXT NOT NULL,
            customer_id TEXT,
            pay_mode TEXT NOT NULL,
            status TEXT NOT NULL,
            total_amount REAL NOT NULL,
            balance_due REAL NOT NULL,
            total_tax REAL NOT NULL,
            sync_status TEXT NOT NULL,
            bill_date INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
          CREATE TABLE cached_sale_line_items (
            id TEXT NOT NULL PRIMARY KEY,
            sales_bill_id TEXT NOT NULL,
            material_id TEXT,
            barcode_no TEXT NOT NULL,
            material_type TEXT NOT NULL,
            material_name TEXT NOT NULL,
            batch_no TEXT,
            packing TEXT,
            quantity INTEGER NOT NULL,
            qty_case INTEGER,
            rate REAL NOT NULL,
            discount_percent REAL NOT NULL,
            discount_amount REAL NOT NULL,
            tax_percent REAL NOT NULL,
            tax_amount REAL NOT NULL,
            amount REAL NOT NULL,
            line_number INTEGER NOT NULL
          );
        ''');
      }
      if (v >= 5) {
        rawDb.execute('''
          CREATE TABLE cached_categories (
            name TEXT NOT NULL PRIMARY KEY,
            description TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
      }
      if (v >= 6) {
        rawDb.execute('''
          CREATE TABLE cached_manufacturers (
            name TEXT NOT NULL PRIMARY KEY,
            description TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
          ALTER TABLE cached_materials ADD COLUMN manufacturer TEXT NOT NULL DEFAULT '';
        ''');
      }
      if (v >= 7) {
        rawDb.execute('''
          CREATE TABLE cached_purchase_bills (
            id TEXT NOT NULL PRIMARY KEY,
            bill_no TEXT,
            supplier_id TEXT NOT NULL,
            challan_no TEXT,
            note_no TEXT,
            pay_mode TEXT NOT NULL,
            tp_no TEXT,
            tp_date TEXT,
            st_no TEXT,
            discount REAL NOT NULL,
            vat REAL NOT NULL,
            stamp REAL NOT NULL,
            tcs REAL NOT NULL,
            loading_freight REAL NOT NULL,
            net_amount REAL NOT NULL,
            total_amount REAL NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            bill_date INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
          CREATE TABLE cached_purchase_line_items (
            id TEXT NOT NULL PRIMARY KEY,
            purchase_bill_id TEXT NOT NULL,
            material_id TEXT NOT NULL,
            material_name TEXT NOT NULL,
            barcode TEXT NOT NULL,
            packaging TEXT NOT NULL,
            batch_no TEXT NOT NULL,
            expiry_date INTEGER,
            quantity INTEGER NOT NULL,
            cost_price REAL NOT NULL,
            mrp REAL NOT NULL,
            vat_percent REAL NOT NULL,
            vat_amount REAL NOT NULL,
            total_amount REAL NOT NULL
          );
        ''');
      }
      if (v >= 8) {
        rawDb.execute('''
          CREATE TABLE cached_packings (
            name TEXT NOT NULL PRIMARY KEY,
            description TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
      }

      // Add a sample material
      if (v < 6) {
        rawDb.execute('''
          INSERT INTO cached_materials (id, barcode, name, category, packing, sale_rate, tax_percent, stock_qty, sync_status, created_at, updated_at)
          VALUES ('MAT001', '123456789', 'Old Monk Rum', 'Rum', '750 ML', 400.0, 18.0, 10, 'synced', 1000000, 1000000);
        ''');
      } else {
        rawDb.execute('''
          INSERT INTO cached_materials (id, barcode, name, manufacturer, category, packing, sale_rate, tax_percent, stock_qty, sync_status, created_at, updated_at)
          VALUES ('MAT001', '123456789', 'Old Monk Rum', 'Old Monk', 'Rum', '750 ML', 400.0, 18.0, 10, 'synced', 1000000, 1000000);
        ''');
      }

      final db = AppDatabase(NativeDatabase.opened(rawDb));
      await db.ensureStarterData();
      final cache = await MaterialLookupCache.load(db);
      expect(cache.length, greaterThan(0));
      await db.close();
    }
  });
}
