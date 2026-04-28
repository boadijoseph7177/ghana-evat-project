import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/sale_request.dart';
import '../models/sale_response.dart';
import '../models/allocation.dart';
import '../models/pending_sale.dart';
import '../models/sale_record.dart';
import '../models/dashboard_summary.dart';

class ApiService {
  // For Chrome (web)
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://localhost:8080';
  }

  // Common headers
  static const Map<String, String> baseHeaders = {
    'Content-Type': 'application/json',
    'X-User-Role': 'agent',
  };

  // =========================
  // PRODUCTS
  // =========================

  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: baseHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load products: ${response.statusCode} ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((item) => Product.fromJson(item)).toList();
  }

  // =========================
  // SALES
  // =========================

  Future<SaleResponse> createSale(SaleRequest saleRequest) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sales'),
      headers: baseHeaders,
      body: jsonEncode(saleRequest.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create sale: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return SaleResponse.fromJson(data);
  }

  // =========================
  // ALLOCATION
  // =========================

  Future<AgentAllocation> getAllocation(String agentName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/allocations?agent_name=$agentName'),
      headers: baseHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load allocation: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return AgentAllocation.fromJson(data);
  }

  // =========================
  // SYNC SALES
  // =========================

  Future<void> syncPendingSales({
    required String agentName,
    required List<PendingSale> sales,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync-sales'),
      headers: baseHeaders,
      body: jsonEncode({
        'agent_name': agentName,
        'sales': sales.map((sale) => sale.toSyncJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync sales: ${response.body}');
    }
  }

  // Sales record
  Future<List<SaleRecord>> getSalesHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sales'),
      headers: {'Content-Type': 'application/json', 'X-User-Role': 'admin'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load sales history: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded == null) {
      return [];
    }

    final List<dynamic> data = decoded as List<dynamic>;
    return data.map((item) => SaleRecord.fromJson(item)).toList();
  }

  // dashboard summary
  Future<DashboardSummary> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard-summary'),
      headers: {'Content-Type': 'application/json', 'X-User-Role': 'admin'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard summary: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return DashboardSummary.fromJson(data);
  }
}
