import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/pending_sale.dart';
import '../models/product.dart';
import '../models/sale_request.dart';
import '../models/sale_response.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../utils/ghana_tin_validator.dart';
import 'receipt_screen.dart';

class SaleScreen extends StatefulWidget {
  final Product product;

  const SaleScreen({super.key, required this.product});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final ApiService apiService = ApiService();
  final LocalDbService localDbService = LocalDbService();

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerTinController = TextEditingController();

  final String agentName = 'agent1';

  bool isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _initLocalDb();
  }

  Future<void> _initLocalDb() async {
    try {
      await localDbService.database;
    } catch (e) {
      debugPrint('Local DB init failed: $e');
    }
  }

  Future<bool> canSellOffline(int productId, int quantity) async {
    final allocationItem = await localDbService.getAllocationItemByProductId(
      productId,
    );

    if (allocationItem == null) {
      return false;
    }

    return allocationItem.remainingQuantity >= quantity;
  }

  Future<void> submitSale() async {
    final quantity = int.tryParse(quantityController.text);
    final customerName = customerNameController.text.trim();
    final customerTin = GhanaTinValidator.normalize(customerTinController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }

    if (quantity > widget.product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity exceeds available stock')),
      );
      return;
    }

    if (customerName.isEmpty || customerTin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name and TIN are required')),
      );
      return;
    }

    if (!GhanaTinValidator.isValidBusinessTin(customerTin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(GhanaTinValidator.formatHint)),
      );
      return;
    }

    customerTinController.value = customerTinController.value.copyWith(
      text: customerTin,
      selection: TextSelection.collapsed(offset: customerTin.length),
    );

    setState(() {
      isLoading = true;
    });

    try {
      final saleRequest = SaleRequest(
        productId: widget.product.id,
        quantity: quantity,
        customerName: customerName,
        customerTin: customerTin,
      );

      final SaleResponse response = await apiService.createSale(saleRequest);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReceiptScreen(response: response)),
      );

      if (!mounted) return;

      Navigator.pop(context, 'online_success');
    } catch (e) {
      debugPrint('Online sale failed: $e');

      final allowed = await canSellOffline(widget.product.id, quantity);
      debugPrint('Can sell offline: $allowed');

      if (!allowed) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline sale exceeds remaining allocation'),
          ),
        );
        return;
      }

      final pendingSale = PendingSale(
        offlineSaleId: DateTime.now().millisecondsSinceEpoch.toString(),
        agentName: agentName,
        productId: widget.product.id,
        quantity: quantity,
        customerName: customerName,
        customerTin: customerTin,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );

      await localDbService.insertPendingSale(pendingSale);
      await localDbService.reduceRemainingAllocation(
        widget.product.id,
        quantity,
      );

      debugPrint('Pending sale saved');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale saved offline as pending')),
      );

      Navigator.pop(context, 'offline_saved');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    customerNameController.dispose();
    customerTinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sell ${widget.product.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatBottleSize(widget.product.bottleSizeLiters),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit Price',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatMoney(widget.product.unitPrice),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Stock',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.product.stockQuantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.numbers_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customerTinController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(
                    text: newValue.text.toUpperCase(),
                    selection: newValue.selection,
                  );
                }),
              ],
              decoration: const InputDecoration(
                labelText: 'Customer TIN',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              GhanaTinValidator.formatHint,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : submitSale,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
