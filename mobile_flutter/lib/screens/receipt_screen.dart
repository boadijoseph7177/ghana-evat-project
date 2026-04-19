import 'package:flutter/material.dart';

import '../models/sale_response.dart';

class ReceiptScreen extends StatelessWidget {
  final SaleResponse response;

  const ReceiptScreen({super.key, required this.response});

  String formatMoney(double amount) {
    return amount.toStringAsFixed(2);
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
      appBar: AppBar(title: const Text('Sale Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      response.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            buildSectionCard(
              title: 'Sale Details',
              children: [
                buildRow('Product ID', response.productId.toString()),
                buildRow('Quantity', response.quantity.toString()),
                buildRow(
                  'Unit Price',
                  'GHS ${formatMoney(response.unitPrice)}',
                ),
                buildRow(
                  'Total Amount',
                  'GHS ${formatMoney(response.totalAmount)}',
                  bold: true,
                ),
              ],
            ),

            buildSectionCard(
              title: 'Tax Breakdown',
              children: [
                buildRow('VAT', 'GHS ${formatMoney(response.vatAmount)}'),
                buildRow('NHIL', 'GHS ${formatMoney(response.nhilAmount)}'),
                buildRow(
                  'GETFund',
                  'GHS ${formatMoney(response.getfundAmount)}',
                ),
                const Divider(),
                buildRow(
                  'Total With Tax',
                  'GHS ${formatMoney(response.totalWithTax)}',
                  bold: true,
                ),
              ],
            ),

            buildSectionCard(
              title: 'Customer Details',
              children: [
                buildRow('Customer Name', response.customerName),
                buildRow('Customer TIN', response.customerTin),
              ],
            ),

            buildSectionCard(
              title: 'Compliance Details',
              children: [
                buildRow('SDC ID', response.sdcId),
                buildRow('QR Code', response.qrCode),
              ],
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
