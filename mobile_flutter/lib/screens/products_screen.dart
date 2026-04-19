import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'dashboard_summary_screen.dart';
import 'pending_sales_screen.dart';
import 'sale_screen.dart';
import 'sales_history_screen.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/empty_state_widget.dart';

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

  Future<void> loadPendingSalesCount() async {
    final pendingSales = await localDbService.getPendingSales();

    if (!mounted) return;

    setState(() {
      _pendingSalesCount = pendingSales.length;
    });
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
            icon: const Icon(Icons.history),
            onPressed: openSalesHistory,
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: openDashboardSummary,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isOfflineMode)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline mode: showing allocated stock',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ErrorStateWidget(
                    message: 'Could not load products. Please try again.',
                    onRetry: () {
                      setState(() {
                        loadProducts();
                      });
                    },
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: _isOfflineMode
                        ? 'No offline products available'
                        : 'No products found',
                    subtitle: _isOfflineMode
                        ? 'Download allocation while online to view products offline.'
                        : 'There are no products to display right now.',
                  );
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
          ),
        ],
      ),
    );
  }
}
