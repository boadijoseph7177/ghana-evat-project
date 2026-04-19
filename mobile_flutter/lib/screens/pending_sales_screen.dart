import 'package:flutter/material.dart';

import '../models/pending_sale.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

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
      ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSyncing ? null : syncSales,
                child: isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sync Pending Sales'),
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
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final sales = snapshot.data ?? [];

                  if (sales.isEmpty) {
                    return const Center(child: Text('No pending sales'));
                  }

                  return ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(sale.customerName),
                          subtitle: Text(
                            'Product ID: ${sale.productId} • Qty: ${sale.quantity}\nTIN: ${sale.customerTin}',
                          ),
                          trailing: const Text('Pending'),
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
