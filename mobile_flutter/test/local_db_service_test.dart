import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:evat_app/models/allocation.dart';
import 'package:evat_app/services/local_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDbService localDbService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final dbPath = await getDatabasesPath();
    await deleteDatabase(join(dbPath, 'evat_local.db'));
    localDbService = LocalDbService();
  });

  test('downloaded allocation product details are available offline', () async {
    await localDbService.saveAllocationItems([
      AllocationItem(
        id: 1,
        productId: 7,
        productName: 'Sunflower Oil 1L',
        bottleSizeLiters: 1,
        unitPrice: 25.5,
        allocatedQuantity: 12,
        remainingQuantity: 8,
      ),
    ]);

    final offlineProducts = await localDbService.getOfflineProducts();

    expect(offlineProducts, hasLength(1));
    expect(offlineProducts.single.id, 7);
    expect(offlineProducts.single.name, 'Sunflower Oil 1L');
    expect(offlineProducts.single.bottleSizeLiters, 1);
    expect(offlineProducts.single.unitPrice, 25.5);
    expect(offlineProducts.single.stockQuantity, 8);
  });
}
