import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'pending_sales_screen.dart';
import 'sale_screen.dart';
import 'sales_history_screen.dart';
import 'dashboard_summary_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ApiService apiService = ApiService();
  final LocalDbService localDbService = LocalDbService();

  late Future<List<Product>> productsFuture;
  String agentName = 'agent1';
  bool _isOfflineMode = false;
  int _pendingSalesCount = 0;

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadPendingSalesCount();
  }

  void loadProducts() {
    productsFuture = loadProductsWithFallback();
  }

  Future<void> downloadAllocation() async {
    try {
      final allocation = await apiService.getAllocation(agentName);
      await localDbService.saveAllocationItems(allocation.items);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allocation downloaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download allocation: $e')),
      );
    }
  }

  Future<List<Product>> loadProductsWithFallback() async {
    try {
      final products = await apiService.getProducts();
      await localDbService.saveProducts(products);
      _isOfflineMode = false;
      return products;
    } catch (e) {
      final offlineProducts = await localDbService.getOfflineProducts();
      _isOfflineMode = true;
      return offlineProducts;
    }
  }

  Future<void> openPendingSales() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PendingSalesScreen()),
    );

    await loadPendingSalesCount();
  }

  Future<void> openSalesHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
    );
  }

  Future<void> openDashboardSummary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DashboardSummaryScreen()),
    );
  }

  Future<void> loadPendingSalesCount() async {
    final pendingSales = await localDbService.getPendingSales();

    if (!mounted) return;

    setState(() {
      _pendingSalesCount = pendingSales.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOfflineMode ? 'Products (Offline)' : 'Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: downloadAllocation,
          ),
          IconButton(icon: const Icon(Icons.sync), onPressed: openPendingSales),
          IconButton(
            onPressed: openPendingSales,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.sync),
                if (_pendingSalesCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _pendingSalesCount > 9 ? '9+' : '$_pendingSalesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: openDashboardSummary,
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Text(
                _isOfflineMode
                    ? 'No offline products available'
                    : 'No products found',
              ),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.bottleSizeLiters}L • Stock: ${product.stockQuantity} • Price: GHS ${product.unitPrice}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleScreen(product: product),
                        ),
                      );

                      if (result == 'online_success' ||
                          result == 'offline_saved') {
                        setState(() {
                          loadProducts();
                        });

                        await loadPendingSalesCount();
                      }
                    },
                    child: const Text('Sell'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
