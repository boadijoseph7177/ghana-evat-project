import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';

class DashboardSummaryScreen extends StatefulWidget {
  const DashboardSummaryScreen({super.key});

  @override
  State<DashboardSummaryScreen> createState() => _DashboardSummaryScreenState();
}

class _DashboardSummaryScreenState extends State<DashboardSummaryScreen> {
  final ApiService apiService = ApiService();

  late Future<DashboardSummary> summaryFuture;
  late Future<List<Product>> productsFuture;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  void loadDashboardData() {
    summaryFuture = apiService.getDashboardSummary();
    productsFuture = apiService.getProducts();
  }

  String formatMoney(double amount) {
    return amount.toStringAsFixed(2);
  }

  // Simple clean summary card
  Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced product card for inventory section
  Widget buildInventoryCard(Product product) {
    final maxStock = 100; // Reference for visual progress
    final stockPercentage = (product.stockQuantity / maxStock).clamp(0.0, 1.0);

    Color statusColor;
    if (product.stockQuantity > 50) {
      statusColor = Colors.green;
    } else if (product.stockQuantity > 20) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.blue.shade700,
                    size: 24,
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
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.bottleSizeLiters}L • GHS ${formatMoney(product.unitPrice)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${product.stockQuantity} units',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stock progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stockPercentage,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Future<void> refreshAll() async {
    setState(() {
      loadDashboardData();
    });

    await Future.wait([summaryFuture, productsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Summary'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: refreshAll,
        child: FutureBuilder<DashboardSummary>(
          future: summaryFuture,
          builder: (context, summarySnapshot) {
            if (summarySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (summarySnapshot.hasError) {
              return ErrorStateWidget(
                message: 'Could not load dashboard data. Please try again.',
                onRetry: () {
                  setState(() {
                    loadDashboardData();
                  });
                },
              );
            }

            final summary = summarySnapshot.data;
            if (summary == null) {
              return const EmptyStateWidget(
                icon: Icons.dashboard_outlined,
                title: 'No summary data found',
                subtitle: 'Dashboard information is not available right now.',
              );
            }

            return FutureBuilder<List<Product>>(
              future: productsFuture,
              builder: (context, productsSnapshot) {
                if (productsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productsSnapshot.hasError) {
                  return ErrorStateWidget(
                    message:
                        'Could not load inventory snapshot. Please try again.',
                    onRetry: () {
                      setState(() {
                        loadDashboardData();
                      });
                    },
                  );
                }

                final products = productsSnapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    buildSectionTitle('Overview'),
                    buildSummaryCard(
                      title: 'Total Products',
                      value: summary.totalProducts.toString(),
                      icon: Icons.inventory_2,
                    ),
                    buildSummaryCard(
                      title: 'Total Stock Units',
                      value: summary.totalStockUnits.toString(),
                      icon: Icons.warehouse,
                    ),
                    buildSummaryCard(
                      title: 'Total Sales Count',
                      value: summary.totalSalesCount.toString(),
                      icon: Icons.point_of_sale,
                    ),
                    buildSummaryCard(
                      title: 'Total Sales Amount',
                      value: 'GHS ${formatMoney(summary.totalSalesAmount)}',
                      icon: Icons.attach_money,
                    ),
                    buildSummaryCard(
                      title: 'Total VAT',
                      value: 'GHS ${formatMoney(summary.totalVAT)}',
                      icon: Icons.receipt_long,
                    ),
                    buildSummaryCard(
                      title: 'Production Warnings',
                      value: summary.productionWarningsCount.toString(),
                      icon: Icons.warning_amber,
                    ),
                    buildSectionTitle('Inventory Snapshot'),
                    if (products.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products available',
                        subtitle: 'Inventory items will appear here.',
                      )
                    else
                      ...products.map(buildInventoryCard),
                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
