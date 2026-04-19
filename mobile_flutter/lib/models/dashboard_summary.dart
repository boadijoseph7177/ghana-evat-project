class DashboardSummary {
  final int totalProducts;
  final int totalStockUnits;
  final int totalSalesCount;
  final double totalSalesAmount;
  final double totalVAT;
  final int productionWarningsCount;

  DashboardSummary({
    required this.totalProducts,
    required this.totalStockUnits,
    required this.totalSalesCount,
    required this.totalSalesAmount,
    required this.totalVAT,
    required this.productionWarningsCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalProducts: json['total_products'],
      totalStockUnits: json['total_stock_units'],
      totalSalesCount: json['total_sales_count'],
      totalSalesAmount: (json['total_sales_amount'] as num).toDouble(),
      totalVAT: (json['total_vat'] as num).toDouble(),
      productionWarningsCount: json['production_warnings_count'],
    );
  }
}
