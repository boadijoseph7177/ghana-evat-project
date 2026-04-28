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
  bool _isOnline = true;
  bool _isCheckingConnection = false;
  int _pendingSalesCount = 0;

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadPendingSalesCount();
    _refreshConnectionStatus();
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

      if (mounted && !_isOnline) {
        setState(() {
          _isOnline = true;
        });
      } else {
        _isOnline = true;
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

      if (mounted && _isOnline) {
        setState(() {
          _isOnline = false;
        });
      } else {
        _isOnline = false;
      }

      return offlineProducts;
    }
  }

  Future<void> _refreshConnectionStatus() async {
    if (_isCheckingConnection) return;

    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final reachable = await apiService.isBackendReachable();

      if (!mounted) return;

      setState(() {
        _isOnline = reachable;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
        });
      }
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
      await _refreshConnectionStatus();

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
    await _refreshConnectionStatus();
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

  String formatBottleSize(double liters) {
    if (liters == liters.roundToDouble()) {
      return '${liters.toStringAsFixed(0)}L';
    }
    return '${liters.toStringAsFixed(1)}L';
  }

  Color getStockColor(int stockQuantity) {
    if (stockQuantity <= 0) return Colors.red.shade700;
    if (stockQuantity <= 10) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  String getStockLabel(int stockQuantity) {
    if (stockQuantity <= 0) return 'Out of stock';
    if (stockQuantity <= 10) return 'Low stock';
    return 'In stock';
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
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        size: 16,
                        color: _isOnline ? Colors.green.shade700 : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? 'Online mode' : 'Offline mode',
                        style: TextStyle(
                          color:
                              _isOnline ? Colors.green.shade800 : Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Check connection',
                  onPressed: _isCheckingConnection ? null : _refreshConnectionStatus,
                  icon: _isCheckingConnection
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
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

  Widget buildProductStatChip({
    required IconData icon,
    required String label,
    required Color color,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductCard(Product product) {
    final stockColor = getStockColor(product.stockQuantity);
    final canSell = product.stockQuantity > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.local_drink_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatBottleSize(product.bottleSizeLiters),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(product.unitPrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'per unit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildProductStatChip(
                  icon: Icons.inventory_2_rounded,
                  label: 'Stock: ${product.stockQuantity}',
                  color: stockColor,
                ),
                buildProductStatChip(
                  icon: Icons.info_outline_rounded,
                  label: getStockLabel(product.stockQuantity),
                  color: stockColor,
                ),
                if (_isOfflineMode)
                  buildProductStatChip(
                    icon: Icons.cloud_off_rounded,
                    label: 'Offline allocation',
                    color: Colors.orange.shade800,
                    backgroundColor: Colors.orange.shade50,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: canSell
                    ? () async {
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
                      }
                    : null,
                icon: Icon(canSell ? Icons.point_of_sale_rounded : Icons.block),
                label: Text(canSell ? 'Sell Product' : 'Unavailable'),
              ),
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
                    return buildProductCard(product);
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
