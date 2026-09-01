import 'dart:convert';

import 'package:http/http.dart'
    as http;

import '../config/api_config.dart';
import 'auth_service.dart';


class FinanceService {
  final _authService =
      AuthService();

  Future<Map<String, String>>
      _authenticatedHeaders() async {
    final token =
        await _authService.getToken();

    return {
      'Authorization':
          'Bearer $token',
      'Content-Type':
          'application/json',
    };
  }

  Future<Map<String, dynamic>>
      getSummary() async {
    final headers =
        await _authenticatedHeaders();

    final response =
        await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/finance/summary',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar resumo financeiro',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Resposta inválida do resumo financeiro',
      );
    }

    // Os totais mensais corrigidos usam o ciclo de cartão do dia 5.
    // Se o backend ainda não tiver esse endpoint (durante deploy),
    // mantemos o summary original para não quebrar a Home.
    try {
      final totalsResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/finance/monthly-totals',
        ),
        headers: headers,
      );

      if (totalsResponse.statusCode == 200) {
        final totals = jsonDecode(totalsResponse.body);
        final payload = decoded['payload'];

        if (totals is Map && payload is Map) {
          if (totals['credit_card_commitments_by_month'] != null) {
            payload['credit_card_commitments_by_month'] =
                totals['credit_card_commitments_by_month'];
          }

          if (totals['pix_sent_by_month'] != null) {
            payload['pix_sent_by_month'] =
                totals['pix_sent_by_month'];
          }

          if (totals['pix_received_by_month'] != null) {
            payload['pix_received_by_month'] =
                totals['pix_received_by_month'];
          }
        }
      }
    } catch (_) {
      // Compatibilidade temporária com versões anteriores do backend.
    }

    return decoded;
  }

  Future<Map<String, dynamic>>
      getMonthlyBreakdown({
    required String month,
  }) async {
    final headers =
        await _authenticatedHeaders();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/finance/monthly-breakdown',
    ).replace(
      queryParameters: {
        'month': month,
      },
    );

    final response =
        await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode != 200) {
      String message =
          'Erro ao buscar detalhamento do mês';

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
      throw Exception(
        'Resposta inválida do detalhamento mensal',
      );
    }

    return data;
  }

  Future<Map<String, dynamic>>
      refresh() async {
    final headers =
        await _authenticatedHeaders();

    final response =
        await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/finance/refresh',
      ),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 429) {
      throw Exception(
        data['detail'] ??
            'Aguarde antes de atualizar novamente',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao atualizar dados financeiros',
      );
    }

    return data;
  }

  Future<List<dynamic>>
      getManualInvestments() async {
    final headers =
        await _authenticatedHeaders();

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/investments/manual',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar investimentos manuais',
      );
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>>
      createManualInvestment({
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
    final headers =
        await _authenticatedHeaders();

    final payload = <String, dynamic>{
      'name': name,
      'type': type,
      'institution': institution,
      'current_value': currentValue,
      'currency': currency,
    };

    if (ticker != null && ticker.trim().isNotEmpty) {
      payload['ticker'] = ticker.trim();
    }

    if (quantity != null) {
      payload['quantity'] = quantity;
    }

    if (averagePrice != null) {
      payload['average_price'] = averagePrice;
    }

    if (investedValue != null) {
      payload['invested_value'] = investedValue;
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/investments/manual',
      ),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Erro ao adicionar investimento',
      );
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>>
      updateManualInvestment({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final headers =
        await _authenticatedHeaders();

    final response = await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/investments/manual/$id',
      ),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao atualizar investimento',
      );
    }

    return jsonDecode(response.body);
  }

  Future<void> deleteManualInvestment(
    int id,
  ) async {
    final headers =
        await _authenticatedHeaders();

    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/investments/manual/$id',
      ),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Erro ao excluir investimento',
      );
    }
  }
}
