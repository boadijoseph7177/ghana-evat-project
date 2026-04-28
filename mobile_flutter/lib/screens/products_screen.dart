import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import 'allocation_screen.dart';
import 'dashboard_summary_screen.dart';
import 'pending_sales_screen.dart';
import 'sale_screen.dart';
import 'sales_history_screen.dart';

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

      if (mounted && _isOfflineMode) {
        setState(() {
          _isOfflineMode = false;
        });
      } else {
        _isOfflineMode = false;
      }

      return products;
    } catch (e) {
      final offlineProducts = await localDbService.getOfflineProducts();

      if (mounted && !_isOfflineMode) {
        setState(() {
          _isOfflineMode = true;
        });
      } else {
        _isOfflineMode = true;
      }

      return offlineProducts;
    }
  }

  Future<void> openAllocationScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllocationScreen()),
    );
  }

  Future<void> downloadAllocation() async {
    try {
      final allocation = await apiService.getAllocation(agentName);
      await localDbService.saveAllocationItems(allocation.items);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allocation downloaded successfully')),
      );

      setState(() {
        loadProducts();
      });
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

  String formatMoney(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_GH',
      symbol: 'GHS ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    String? badgeText,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        if (badgeText != null)
          Positioned(
            right: -4,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildQuickActionsCard() {
    final pendingBadge = _pendingSalesCount > 0
        ? (_pendingSalesCount > 99 ? '99+' : _pendingSalesCount.toString())
        : null;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            buildActionButton(
              icon: Icons.download_rounded,
              label: 'Download Allocation',
              onPressed: downloadAllocation,
            ),
            const SizedBox(height: 8),
            buildActionButton(
              icon: Icons.inventory_2_rounded,
              label: 'View Allocation',
              onPressed: openAllocationScreen,
            ),
            const SizedBox(height: 8),
            buildActionButton(
              icon: Icons.sync_rounded,
              label: 'Pending Sync Sales',
              onPressed: openPendingSales,
              badgeText: pendingBadge,
            ),
            const SizedBox(height: 8),
            buildActionButton(
              icon: Icons.history_rounded,
              label: 'Sales Records',
              onPressed: openSalesHistory,
            ),
            const SizedBox(height: 8),
            buildActionButton(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard Summary',
              onPressed: openDashboardSummary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOfflineMode ? 'Products (Offline)' : 'Products'),
        actions: [
          IconButton(
            tooltip: 'Pending Sync Sales',
            onPressed: openPendingSales,
            icon: Badge.count(
              count: _pendingSalesCount,
              isLabelVisible: _pendingSalesCount > 0,
              child: const Icon(Icons.sync_rounded),
            ),
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
              child: const Row(
                children: [
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
          buildQuickActionsCard(),
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
                          '${product.bottleSizeLiters}L • Stock: ${product.stockQuantity} • Price: ${formatMoney(product.unitPrice)}',
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
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
