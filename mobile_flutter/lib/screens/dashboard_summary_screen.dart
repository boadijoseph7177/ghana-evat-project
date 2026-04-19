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

  Widget buildSummaryCard({
    required String title,
    required String value,
    IconData? icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: icon != null ? Icon(icon) : null,
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.inventory_2),
        title: Text(product.name),
        subtitle: Text(
          '${product.bottleSizeLiters}L • Price: GHS ${formatMoney(product.unitPrice)}',
        ),
        trailing: Text(
          'Stock: ${product.stockQuantity}',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
      appBar: AppBar(title: const Text('Dashboard Summary')),
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
                      ...products.map(buildProductCard),
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
