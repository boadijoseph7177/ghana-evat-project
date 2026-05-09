import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_flutter/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final dbPath = await getDatabasesPath();
    await deleteDatabase(join(dbPath, 'evat_local.db'));
  });

  testWidgets('shows the products screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EvatApp());

    expect(find.text('E-VAT Sales App'), findsOneWidget);
    expect(find.text('Products'), findsNothing);

    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Products'), findsOneWidget);
  });
}
