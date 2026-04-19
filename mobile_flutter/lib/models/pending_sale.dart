class PendingSale {
  final int? id;
  final String offlineSaleId;
  final String agentName;
  final int productId;
  final int quantity;
  final String customerName;
  final String customerTin;
  final String status;
  final String createdAt;

  PendingSale({
    this.id,
    required this.offlineSaleId,
    required this.agentName,
    required this.productId,
    required this.quantity,
    required this.customerName,
    required this.customerTin,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'offline_sale_id': offlineSaleId,
      'agent_name': agentName,
      'product_id': productId,
      'quantity': quantity,
      'customer_name': customerName,
      'customer_tin': customerTin,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory PendingSale.fromMap(Map<String, dynamic> map) {
    return PendingSale(
      id: map['id'],
      offlineSaleId: map['offline_sale_id'],
      agentName: map['agent_name'],
      productId: map['product_id'],
      quantity: map['quantity'],
      customerName: map['customer_name'],
      customerTin: map['customer_tin'],
      status: map['status'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'offline_sale_id': offlineSaleId,
      'agent_name': agentName,
      'product_id': productId,
      'quantity': quantity,
      'customer_name': customerName,
      'customer_tin': customerTin,
    };
  }
}
