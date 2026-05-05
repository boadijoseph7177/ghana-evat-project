class SaleRecord {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double vatAmount;
  final double nhilAmount;
  final double getfundAmount;
  final double totalWithTax;
  final String customerName;
  final String createdAt;
  final String sdcId;
  final String qrCode;

  SaleRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.vatAmount,
    required this.nhilAmount,
    required this.getfundAmount,
    required this.totalWithTax,
    required this.customerName,
    required this.createdAt,
    required this.sdcId,
    required this.qrCode,
  });

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: _asInt(json['id']),
      productId: _asInt(json['product_id']),
      productName: json['product_name'] ?? '',
      quantity: _asInt(json['quantity']),
      unitPrice: _asDouble(json['unit_price']),
      totalAmount: _asDouble(json['total_amount']),
      vatAmount: _asDouble(json['vat_amount']),
      nhilAmount: _asDouble(json['nhil_amount']),
      getfundAmount: _asDouble(json['getfund_amount']),
      totalWithTax: _asDouble(json['total_with_tax']),
      customerName: json['customer_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      sdcId: json['sdc_id'] ?? '',
      qrCode: json['qr_code'] ?? '',
    );
  }
}
