import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';


class FinanceService {
  final _authService = AuthService();

  static Map<String, dynamic>? _lastMonthlyTotals;

  Future<Map<String, String>> _authenticatedHeaders() async {
    final token = await _authService.getToken();

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String _formatDate(DateTime value) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }

  void _normalizeCardBilling(Map<String, dynamic> decoded) {
    final payload = decoded['payload'];
    if (payload is! Map) return;

    final accounts = payload['accounts'];
    if (accounts is! List) return;

    for (final rawAccount in accounts) {
      if (rawAccount is! Map) continue;
      if (rawAccount['type']?.toString().toUpperCase() != 'CREDIT') continue;

      final nextDue = rawAccount['next_due'];
      if (nextDue is! Map) continue;

      final dueDate = nextDue['due_date'];
      if (dueDate == null) continue;

      final rawCreditData = rawAccount['creditData'];
      final creditData = rawCreditData is Map
          ? Map<String, dynamic>.from(rawCreditData)
          : <String, dynamic>{};

      creditData['balanceDueDate'] = dueDate;
      creditData['balanceDueDateSource'] = nextDue['source'];
      creditData['balanceDueDateEstimated'] = nextDue['estimated'] == true;

      if (nextDue['source'] == 'bill' && nextDue['minimum_payment'] != null) {
        creditData['minimumPayment'] = nextDue['minimum_payment'];
      }

      rawAccount['creditData'] = creditData;
    }
  }

  void _normalizeProjectedCardItems(Map<String, dynamic> data) {
    final section = data['credit_cards'];
    if (section is! Map) return;
    final items = section['items'];
    if (items is! List) return;

    for (final raw in items) {
      if (raw is! Map || raw['projected'] != true) continue;
      final description = raw['description']?.toString().trim() ?? '';
      if (!description.toUpperCase().contains('PROJETADO')) {
        raw['description'] = description.isEmpty
            ? 'PROJETADO'
            : '$description • PROJETADO';
      }
    }
  }

  void _applyMonthlyTotals(
    Map<dynamic, dynamic> payload,
    Map<dynamic, dynamic> totals,
  ) {
    if (totals['credit_card_commitments_by_month'] != null) {
      payload['credit_card_commitments_by_month'] =
          totals['credit_card_commitments_by_month'];
    }

    if (totals['card_periods_by_month'] != null) {
      payload['card_periods_by_month'] = totals['card_periods_by_month'];
    }

    if (totals['manual_commitments_by_month'] != null) {
      payload['manual_commitments_by_month'] =
          totals['manual_commitments_by_month'];
    }

    if (totals['pix_sent_by_month'] != null) {
      payload['pix_sent_by_month'] = totals['pix_sent_by_month'];
    }
  }

  Future<Map<String, dynamic>> getSummary() async {
    final headers = await _authenticatedHeaders();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/finance/summary'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar resumo financeiro');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do resumo financeiro');
    }

    _normalizeCardBilling(decoded);

    final payload = decoded['payload'];
    if (payload is Map) {
      payload['manual_commitments_by_month'] = <String, dynamic>{};
      payload['pix_sent_by_month'] = <String, dynamic>{};
      payload['credit_card_commitments_by_month'] = <String, dynamic>{};
      payload['card_periods_by_month'] = <String, dynamic>{};
    }

    try {
      final totalsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/finance/monthly-totals'),
        headers: headers,
      );

      if (totalsResponse.statusCode == 200) {
        final totals = jsonDecode(totalsResponse.body);
        if (totals is Map) {
          _lastMonthlyTotals = Map<String, dynamic>.from(totals);
          if (payload is Map) {
            _applyMonthlyTotals(payload, totals);
          }
        }
      } else if (payload is Map && _lastMonthlyTotals != null) {
        _applyMonthlyTotals(payload, _lastMonthlyTotals!);
      }
    } catch (_) {
      if (payload is Map && _lastMonthlyTotals != null) {
        _applyMonthlyTotals(payload, _lastMonthlyTotals!);
      }
    }

    return decoded;
  }

  Future<Map<String, dynamic>> getMonthlyBreakdown({
    required String month,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final headers = await _authenticatedHeaders();

    final query = <String, String>{'month': month};
    if (dateFrom != null) query['date_from'] = _formatDate(dateFrom);
    if (dateTo != null) query['date_to'] = _formatDate(dateTo);

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/finance/monthly-breakdown',
    ).replace(queryParameters: query);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      String message = 'Erro ao buscar detalhamento do mês';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['detail'] != null) {
          message = data['detail'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do detalhamento mensal');
    }

    _normalizeProjectedCardItems(data);
    return data;
  }

  Future<Map<String, dynamic>> getCardPeriod({
    required String month,
  }) async {
    final headers = await _authenticatedHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/finance/card-period',
    ).replace(queryParameters: {'month': month});

    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar período dos cartões');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do período dos cartões');
    }
    return data;
  }

  Future<Map<String, dynamic>> saveCardPeriod({
    required String month,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final headers = await _authenticatedHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/finance/card-period',
    ).replace(queryParameters: {'month': month});

    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({
        'date_from': _formatDate(dateFrom),
        'date_to': _formatDate(dateTo),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao salvar período dos cartões');
    }

    _lastMonthlyTotals = null;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao salvar período dos cartões');
    }
    return data;
  }

  Future<Map<String, dynamic>> resetCardPeriod({
    required String month,
  }) async {
    final headers = await _authenticatedHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/finance/card-period',
    ).replace(queryParameters: {'month': month});

    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Erro ao restaurar período mensal dos cartões');
    }

    _lastMonthlyTotals = null;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida ao restaurar período dos cartões');
    }
    return data;
  }

  Future<double> getManualCommitment({
    required String month,
  }) async {
    final headers = await _authenticatedHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/finance/manual-commitment',
    ).replace(queryParameters: {'month': month});

    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar compromisso manual do mês');
    }

    final data = jsonDecode(response.body);
    if (data is! Map) return 0;
    final value = data['amount'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<double> saveManualCommitment({
    required String month,
    required double amount,
  }) async {
    final headers = await _authenticatedHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/finance/manual-commitment',
    ).replace(queryParameters: {'month': month});

    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode != 200) {
      String message = 'Erro ao salvar compromisso do mês';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['detail'] != null) {
          message = data['detail'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    _lastMonthlyTotals = null;
    final data = jsonDecode(response.body);
    final value = data is Map ? data['amount'] : null;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? amount;
  }

  Future<Map<String, dynamic>> refresh() async {
    final headers = await _authenticatedHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/finance/refresh'),
      headers: headers,
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 429) {
      throw Exception(data['detail'] ?? 'Aguarde antes de atualizar novamente');
    }
    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar dados financeiros');
    }
    _lastMonthlyTotals = null;
    return data;
  }

  Future<List<dynamic>> getManualInvestments() async {
    final headers = await _authenticatedHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/investments/manual'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar investimentos manuais');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createManualInvestment({
    required String name,
    required String type,
    required String institution,
    required double currentValue,
    String currency = 'BRL',
    String? ticker,
    double? quantity,
    double? averagePrice,
    double? investedValue,
  }) async {
    final headers = await _authenticatedHeaders();
    final payload = <String, dynamic>{
      'name': name,
      'type': type,
      'institution': institution,
      'current_value': currentValue,
      'currency': currency,
    };

    if (ticker != null && ticker.trim().isNotEmpty) payload['ticker'] = ticker.trim();
    if (quantity != null) payload['quantity'] = quantity;
    if (averagePrice != null) payload['average_price'] = averagePrice;
    if (investedValue != null) payload['invested_value'] = investedValue;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/investments/manual'),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao adicionar investimento');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateManualInvestment({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final headers = await _authenticatedHeaders();
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/investments/manual/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar investimento');
    }
    return jsonDecode(response.body);
  }

  Future<void> deleteManualInvestment(int id) async {
    final headers = await _authenticatedHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/investments/manual/$id'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Erro ao excluir investimento');
    }
  }
}
