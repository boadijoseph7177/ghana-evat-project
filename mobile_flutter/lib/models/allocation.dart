class AllocationItem {
  final int id;
  final int productId;
  final int allocatedQuantity;
  final int remainingQuantity;

  AllocationItem({
    required this.id,
    required this.productId,
    required this.allocatedQuantity,
    required this.remainingQuantity,
  });

  factory AllocationItem.fromJson(Map<String, dynamic> json) {
    return AllocationItem(
      id: json['id'],
      productId: json['product_id'],
      allocatedQuantity: json['allocated_quantity'],
      remainingQuantity: json['remaining_quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'allocated_quantity': allocatedQuantity,
      'remaining_quantity': remainingQuantity,
    };
  }

  factory AllocationItem.fromMap(Map<String, dynamic> map) {
    return AllocationItem(
      id: map['id'],
      productId: map['product_id'],
      allocatedQuantity: map['allocated_quantity'],
      remainingQuantity: map['remaining_quantity'],
    );
  }
}

class AgentAllocation {
  final int id;
  final String agentName;
  final String status;
  final List<AllocationItem> items;

  AgentAllocation({
    required this.id,
    required this.agentName,
    required this.status,
    required this.items,
  });

  factory AgentAllocation.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>;

    return AgentAllocation(
      id: json['id'],
      agentName: json['agent_name'],
      status: json['status'],
      items: itemsJson.map((item) => AllocationItem.fromJson(item)).toList(),
    );
  }
}
