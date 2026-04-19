class Product {
  final int id;
  final String name;
  final double bottleSizeLiters;
  final int stockQuantity;
  final double unitPrice;

  Product({
    required this.id,
    required this.name,
    required this.bottleSizeLiters,
    required this.stockQuantity,
    required this.unitPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      bottleSizeLiters: (json['bottle_size_liters'] as num).toDouble(),
      stockQuantity: json['stock_quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }
}
