import 'package:flutter/material.dart';

import '../models/allocation.dart';
import '../services/local_db_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';

class AllocationScreen extends StatefulWidget {
  const AllocationScreen({super.key});

  @override
  State<AllocationScreen> createState() => _AllocationScreenState();
}

class _AllocationScreenState extends State<AllocationScreen> {
  final LocalDbService localDbService = LocalDbService();

  late Future<List<AllocationItem>> allocationFuture;

  @override
  void initState() {
    super.initState();
    loadAllocation();
  }

  void loadAllocation() {
    allocationFuture = localDbService.getAllocationItems();
  }

  Future<void> refreshAllocation() async {
    setState(() {
      loadAllocation();
    });

    await allocationFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allocation')),
      body: RefreshIndicator(
        onRefresh: refreshAllocation,
        child: FutureBuilder<List<AllocationItem>>(
          future: allocationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ErrorStateWidget(
                message: 'Could not load allocation. Please try again.',
                onRetry: () {
                  setState(() {
                    loadAllocation();
                  });
                },
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.inventory_2_outlined,
                title: 'No allocation found',
                subtitle: 'Download allocation while online to view it here.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: const [
                        Icon(Icons.inventory, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Downloaded allocation for offline sales',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: Text('Product ID: ${item.productId}'),
                      subtitle: Text(
                        'Allocated: ${item.allocatedQuantity}\nRemaining: ${item.remainingQuantity}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
