import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../services/api_service.dart';

class DashboardSummaryScreen extends StatefulWidget {
  const DashboardSummaryScreen({super.key});

  @override
  State<DashboardSummaryScreen> createState() => _DashboardSummaryScreenState();
}

class _DashboardSummaryScreenState extends State<DashboardSummaryScreen> {
  final ApiService apiService = ApiService();

  late Future<DashboardSummary> summaryFuture;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  void loadSummary() {
    summaryFuture = apiService.getDashboardSummary();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Summary')),
      body: FutureBuilder<DashboardSummary>(
        future: summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final summary = snapshot.data;
          if (summary == null) {
            return const Center(child: Text('No summary data found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                loadSummary();
              });
              await summaryFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
              ],
            ),
          );
        },
      ),
    );
  }
}
