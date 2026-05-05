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
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  void loadSales() {
    salesFuture = apiService.getSalesHistory();
  }

  String formatMoney(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_GH',
      symbol: 'GHS ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) return 'Unknown date';
    try {
      final dateTime = DateTime.parse(rawDate).toLocal();
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (_) {
      return rawDate;
    }
  }

  bool isSyncedToCompliance(SaleRecord sale) {
    return sale.sdcId.trim().isNotEmpty || sale.qrCode.trim().isNotEmpty;
  }

  List<SaleRecord> applyStatusFilter(List<SaleRecord> sales) {
    if (_statusFilter == 'synced') {
      return sales.where(isSyncedToCompliance).toList();
    }
    if (_statusFilter == 'pending') {
      return sales.where((sale) => !isSyncedToCompliance(sale)).toList();
    }
    return sales;
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
          final filteredSales = applyStatusFilter(sales);

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
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _statusFilter == 'all',
                      onSelected: (_) => setState(() => _statusFilter = 'all'),
                    ),
                    ChoiceChip(
                      label: const Text('Synced'),
                      selected: _statusFilter == 'synced',
                      onSelected: (_) => setState(() => _statusFilter = 'synced'),
                    ),
                    ChoiceChip(
                      label: const Text('Pending Sync'),
                      selected: _statusFilter == 'pending',
                      onSelected: (_) => setState(() => _statusFilter = 'pending'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (filteredSales.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.filter_alt_off,
                    title: 'No matching sales',
                    subtitle: 'Try changing the selected status filter.',
                  )
                else
                  ...filteredSales.map((sale) {
                    final synced = isSyncedToCompliance(sale);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        title: Text(
                          sale.customerName.trim().isEmpty
                              ? 'Walk-in customer'
                              : sale.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${sale.productName} • Qty: ${sale.quantity}'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      synced ? 'Synced' : 'Pending sync',
                                      style: TextStyle(
                                        color: synced
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                    avatar: Icon(
                                      synced ? Icons.cloud_done : Icons.cloud_off,
                                      size: 16,
                                      color: synced
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                    backgroundColor: synced
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                  ),
                                  Text(formatDate(sale.createdAt)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Text(
                          formatMoney(sale.totalWithTax),
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
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
