class SaleRequest {
  final int productId;
  final int quantity;
  final String customerName;
  final String customerTin;

  SaleRequest({
    required this.productId,
    required this.quantity,
    required this.customerName,
    required this.customerTin,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'customer_name': customerName,
      'customer_tin': customerTin,
    };
  }
}
