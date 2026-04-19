import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sale_record.dart';

class SaleDetailScreen extends StatelessWidget {
  final SaleRecord sale;

  const SaleDetailScreen({super.key, required this.sale});

  String formatMoney(double amount) {
    return amount.toStringAsFixed(2);
  }

  String formatDate(String rawDate) {
    final dateTime = DateTime.parse(rawDate).toLocal();
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  Widget buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    sale.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(formatDate(sale.createdAt)),
                ],
              ),
            ),
          ),
          buildSectionCard(
            title: 'Sale Information',
            children: [
              buildRow('Sale ID', sale.id.toString()),
              buildRow('Product', sale.productName),
              buildRow('Product ID', sale.productId.toString()),
              buildRow('Quantity', sale.quantity.toString()),
              buildRow('Unit Price', 'GHS ${formatMoney(sale.unitPrice)}'),
            ],
          ),
          buildSectionCard(
            title: 'Tax Breakdown',
            children: [
              buildRow('Total Amount', 'GHS ${formatMoney(sale.totalAmount)}'),
              buildRow('VAT', 'GHS ${formatMoney(sale.vatAmount)}'),
              buildRow('NHIL', 'GHS ${formatMoney(sale.nhilAmount)}'),
              buildRow('GETFund', 'GHS ${formatMoney(sale.getfundAmount)}'),
              const Divider(),
              buildRow(
                'Total With Tax',
                'GHS ${formatMoney(sale.totalWithTax)}',
                bold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
