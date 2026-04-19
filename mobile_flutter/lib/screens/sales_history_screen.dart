import 'package:flutter/material.dart';
import '../models/sale_record.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'sale_detail_screen.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/empty_state_widget.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final ApiService apiService = ApiService();

  late Future<List<SaleRecord>> salesFuture;

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  void loadSales() {
    salesFuture = apiService.getSalesHistory();
  }

  String formatMoney(double amount) {
    return amount.toStringAsFixed(2);
  }

  String formatDate(String rawDate) {
    final dateTime = DateTime.parse(rawDate).toLocal();
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: FutureBuilder<List<SaleRecord>>(
        future: salesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  loadSales();
                });
              },
            );
          }

          final sales = snapshot.data ?? [];

          if (sales.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No sales found',
              subtitle: 'Completed sales will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                loadSales();
              });
              await salesFuture;
            },
            child: ListView.builder(
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(sale.customerName),
                    subtitle: Text(
                      '${sale.productName} • Qty: ${sale.quantity}\n'
                      'Total: GHS ${formatMoney(sale.totalWithTax)}\n'
                      'Date: ${formatDate(sale.createdAt)}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      'GHS ${formatMoney(sale.totalWithTax)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleDetailScreen(sale: sale),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
