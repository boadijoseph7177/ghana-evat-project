class SaleResponse {
  final String message;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double vatAmount;
  final double nhilAmount;
  final double getfundAmount;
  final double totalWithTax;
  final String customerName;
  final String customerTin;
  final String sdcId;
  final String qrCode;

  SaleResponse({
    required this.message,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.vatAmount,
    required this.nhilAmount,
    required this.getfundAmount,
    required this.totalWithTax,
    required this.customerName,
    required this.customerTin,
    required this.sdcId,
    required this.qrCode,
  });

  factory SaleResponse.fromJson(Map<String, dynamic> json) {
    return SaleResponse(
      message: json['message'],
      productId: json['product_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      vatAmount: (json['vat_amount'] as num).toDouble(),
      nhilAmount: (json['nhil_amount'] as num).toDouble(),
      getfundAmount: (json['getfund_amount'] as num).toDouble(),
      totalWithTax: (json['total_with_tax'] as num).toDouble(),
      customerName: json['customer_name'],
      customerTin: json['customer_tin'],
      sdcId: json['sdc_id'],
      qrCode: json['qr_code'],
    );
  }
}
