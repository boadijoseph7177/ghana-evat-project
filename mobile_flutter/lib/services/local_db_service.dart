import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/allocation.dart';
import '../models/pending_sale.dart';
import '../models/product.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'evat_local.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            offline_sale_id TEXT,
            agent_name TEXT NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            customer_name TEXT NOT NULL,
            customer_tin TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE allocation_items (
            id INTEGER PRIMARY KEY,
            product_id INTEGER NOT NULL,
            allocated_quantity INTEGER NOT NULL,
            remaining_quantity INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS local_products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            bottle_size_liters REAL NOT NULL,
            unit_price REAL NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Create local_products table if it doesn't exist (for upgrades from earlier versions)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_products (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              bottle_size_liters REAL NOT NULL,
              unit_price REAL NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> saveAllocationItems(List<AllocationItem> items) async {
    final db = await database;

    await db.delete('allocation_items');

    for (final item in items) {
      await db.insert('allocation_items', item.toMap());
    }
  }

  Future<List<AllocationItem>> getAllocationItems() async {
    final db = await database;

    final result = await db.query(
      'allocation_items',
      orderBy: 'product_id ASC',
    );

    return result.map((row) => AllocationItem.fromMap(row)).toList();
  }

  Future<AllocationItem?> getAllocationItemByProductId(int productId) async {
    final db = await database;

    final result = await db.query(
      'allocation_items',
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return AllocationItem.fromMap(result.first);
  }

  Future<void> reduceRemainingAllocation(int productId, int quantity) async {
    final db = await database;

    await db.rawUpdate(
      '''
      UPDATE allocation_items
      SET remaining_quantity = remaining_quantity - ?
      WHERE product_id = ?
        AND remaining_quantity >= ?
      ''',
      [quantity, productId, quantity],
    );
  }

  Future<int> insertPendingSale(PendingSale sale) async {
    final db = await database;
    return await db.insert('pending_sales', sale.toMap());
  }

  Future<List<PendingSale>> getPendingSales() async {
    final db = await database;

    final result = await db.query('pending_sales', orderBy: 'created_at DESC');

    return result.map((row) => PendingSale.fromMap(row)).toList();
  }

  Future<int> deletePendingSale(int id) async {
    final db = await database;

    return await db.delete('pending_sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePendingSaleByOfflineId(String offlineSaleId) async {
    final db = await database;

    await db.delete(
      'pending_sales',
      where: 'offline_sale_id = ?',
      whereArgs: [offlineSaleId],
    );
  }

  Future<void> deletePendingSales(List<String> offlineSaleIds) async {
    final db = await database;

    for (final id in offlineSaleIds) {
      await db.delete(
        'pending_sales',
        where: 'offline_sale_id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> saveProducts(List<Product> products) async {
    final db = await database;

    for (final product in products) {
      await db.insert('local_products', {
        'id': product.id,
        'name': product.name,
        'bottle_size_liters': product.bottleSizeLiters,
        'unit_price': product.unitPrice,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Product>> getOfflineProducts() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        lp.id,
        lp.name,
        lp.bottle_size_liters,
        a.remaining_quantity AS stock_quantity,
        lp.unit_price
      FROM local_products lp
      INNER JOIN allocation_items a
        ON lp.id = a.product_id
      WHERE a.remaining_quantity > 0
      ORDER BY lp.name
    ''');

    return result.map((row) {
      return Product(
        id: row['id'] as int,
        name: row['name'] as String,
        bottleSizeLiters: (row['bottle_size_liters'] as num).toDouble(),
        stockQuantity: row['stock_quantity'] as int,
        unitPrice: (row['unit_price'] as num).toDouble(),
      );
    }).toList();
  }
}
