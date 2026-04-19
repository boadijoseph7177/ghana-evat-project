class SaleRecord {
  final int id;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double vatAmount;
  final double nhilAmount;
  final double getfundAmount;
  final double totalWithTax;
  final String customerName;
  final String createdAt;

  SaleRecord({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.vatAmount,
    required this.nhilAmount,
    required this.getfundAmount,
    required this.totalWithTax,
    required this.customerName,
    required this.createdAt,
  });

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      vatAmount: (json['vat_amount'] as num).toDouble(),
      nhilAmount: (json['nhil_amount'] as num).toDouble(),
      getfundAmount: (json['getfund_amount'] as num).toDouble(),
      totalWithTax: (json['total_with_tax'] as num).toDouble(),
      customerName: json['customer_name'],
      createdAt: json['created_at'],
    );
  }
}
