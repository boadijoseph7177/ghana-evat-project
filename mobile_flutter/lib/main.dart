import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/products_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const EvatApp());
}

class EvatApp extends StatelessWidget {
  const EvatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-VAT Sales App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const ProductsScreen(),
    );
  }
}
