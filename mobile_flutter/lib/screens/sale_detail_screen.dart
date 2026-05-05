import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/sale_record.dart';

class SaleDetailScreen extends StatelessWidget {
  final SaleRecord sale;

  const SaleDetailScreen({super.key, required this.sale});

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

  bool get isSyncedToCompliance =>
      sale.sdcId.trim().isNotEmpty || sale.qrCode.trim().isNotEmpty;

  Widget buildSyncStatusChip() {
    final synced = isSyncedToCompliance;
    return Chip(
      avatar: Icon(
        synced ? Icons.cloud_done : Icons.cloud_off,
        size: 16,
        color: synced ? Colors.green.shade700 : Colors.orange.shade700,
      ),
      label: Text(synced ? 'Synced to GRA' : 'Pending sync'),
      backgroundColor: synced ? Colors.green.shade50 : Colors.orange.shade50,
      side: BorderSide(
        color: synced ? Colors.green.shade200 : Colors.orange.shade200,
      ),
    );
  }

  Future<void> copyValue(
    BuildContext context,
    String label,
    String value,
  ) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  Widget buildCopyableValue(BuildContext context, String label, String value) {
    final hasValue = value.trim().isNotEmpty;
    return Row(
      children: [
        Expanded(child: buildRow(label, hasValue ? value : 'Not available')),
        if (hasValue)
          IconButton(
            tooltip: 'Copy $label',
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => copyValue(context, label, value),
          ),
      ],
    );
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

  Widget buildQrCodeDisplay() {
    if (sale.qrCode.isEmpty) {
      return const Text('No QR code available');
    }

    final isImageUrl =
        sale.qrCode.startsWith('http://') || sale.qrCode.startsWith('https://');

    if (isImageUrl) {
      return Center(
        child: Image.network(
          sale.qrCode,
          height: 160,
          errorBuilder: (context, error, stackTrace) {
            return Text(sale.qrCode);
          },
        ),
      );
    }

    return SelectableText(sale.qrCode);
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
                    sale.customerName.trim().isEmpty
                        ? 'Walk-in customer'
                        : sale.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(formatDate(sale.createdAt)),
                  const SizedBox(height: 12),
                  buildSyncStatusChip(),
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
              buildRow('Unit Price', formatMoney(sale.unitPrice)),
            ],
          ),
          buildSectionCard(
            title: 'Tax Breakdown',
            children: [
              buildRow('Total Amount', formatMoney(sale.totalAmount)),
              buildRow('VAT (15%)', formatMoney(sale.vatAmount)),
              buildRow('NHIL (2.5%)', formatMoney(sale.nhilAmount)),
              buildRow('GETFund (2.5%)', formatMoney(sale.getfundAmount)),
              const Divider(),
              buildRow('Total With Tax', formatMoney(sale.totalWithTax), bold: true),
            ],
          ),
          buildSectionCard(
            title: 'Compliance Details',
            children: [
              buildCopyableValue(context, 'SDC ID', sale.sdcId),
              const SizedBox(height: 8),
              const Text(
                'QR Code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildQrCodeDisplay(),
            ],
          ),
        ],
      ),
    );
  }
}
