import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pending_sale.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../utils/ghana_tin_validator.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';

class PendingSalesScreen extends StatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {
  final LocalDbService localDbService = LocalDbService();
  final ApiService apiService = ApiService();

  final String agentName = 'agent1';

  late Future<List<PendingSale>> pendingSalesFuture;
  bool isSyncing = false;

  String formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) return 'Unknown date';
    try {
      final dateTime = DateTime.parse(rawDate).toLocal();
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (_) {
      return rawDate;
    }
  }

  Future<List<PendingSale>> _getInvalidSales(List<PendingSale> sales) async {
    return sales
        .where(
          (sale) =>
              !GhanaTinValidator.isValidBusinessTin(sale.customerTin),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    loadPendingSales();
  }

  void loadPendingSales() {
    pendingSalesFuture = localDbService.getPendingSales();
  }

  Future<void> syncSales() async {
    setState(() {
      isSyncing = true;
    });

    try {
      final pendingSales = await localDbService.getPendingSales();

      if (pendingSales.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pending sales to sync')),
        );
        return;
      }

      final invalidSales = await _getInvalidSales(pendingSales);
      if (invalidSales.isNotEmpty) {
        if (!mounted) return;

        final customerList = invalidSales
            .take(3)
            .map((sale) => sale.customerName)
            .join(', ');
        final suffix = invalidSales.length > 3 ? ' and more' : '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fix invalid Ghana TINs before sync: $customerList$suffix.',
            ),
          ),
        );
        return;
      }

      await apiService.syncPendingSales(
        agentName: agentName,
        sales: pendingSales,
      );

      final ids = pendingSales.map((sale) => sale.offlineSaleId).toList();
      await localDbService.deletePendingSales(ids);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pending sales synced successfully')),
      );

      setState(() {
        loadPendingSales();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Sales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline Sync Queue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sales saved offline stay here until you sync them successfully.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSyncing ? null : syncSales,
                        icon: isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(
                          isSyncing ? 'Syncing...' : 'Sync Pending Sales',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<PendingSale>>(
                future: pendingSalesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ErrorStateWidget(
                      message:
                          'Could not load pending sales. Please try again.',
                      onRetry: () {
                        setState(() {
                          loadPendingSales();
                        });
                      },
                    );
                  }

                  final sales = snapshot.data ?? [];

                  if (sales.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.sync_outlined,
                      title: 'No pending sales',
                      subtitle:
                          'Offline sales waiting to sync will appear here.',
                    );
                  }

                  return ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      final normalizedTin = GhanaTinValidator.normalize(
                        sale.customerTin,
                      );
                      final isTinValid = GhanaTinValidator.isValidBusinessTin(
                        normalizedTin,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sale.customerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatDate(sale.createdAt),
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Pending',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    label: Text('Product ID: ${sale.productId}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Chip(
                                    label: Text('Qty: ${sale.quantity}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'TIN: $normalizedTin',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isTinValid
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isTinValid
                                          ? Icons.verified_outlined
                                          : Icons.error_outline,
                                      size: 18,
                                      color: isTinValid
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isTinValid
                                            ? 'TIN format looks valid for Ghana business/corporate sync.'
                                            : GhanaTinValidator.formatHint,
                                        style: TextStyle(
                                          color: isTinValid
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
