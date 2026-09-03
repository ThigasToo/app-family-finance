import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';
import 'monthly_snapshot_service.dart';
import 'planning_scope_service.dart';

class MonthlyDetailLoader {
  final _authService = AuthService();
  final _snapshotService = MonthlySnapshotService();
  final _planningScopeService = PlanningScopeService();

  Future<int?> getActiveUserId() => _planningScopeService.getActiveUserId();

  Future<Map<String, String>> _authenticatedHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<Map<String, dynamic>?> getCachedBreakdown({
    required int userId,
    required String month,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) => _snapshotService.getBreakdown(
        userId: userId,
        month: month,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<Map<String, dynamic>?> getCachedCardPeriod({
    required int userId,
    required String month,
  }) => _snapshotService.getCardPeriod(userId: userId, month: month);

  Future<double?> getCachedManualCommitment({
    required int userId,
    required String month,
  }) => _snapshotService.getManualCommitment(userId: userId, month: month);

  Future<Map<String, dynamic>> fetchBreakdownFresh({
    int? userId,
    required String month,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final headers = await _authenticatedHeaders();
    final query = <String, String>{'month': month};
    if (dateFrom != null) query['date_from'] = _formatDate(dateFrom);
    if (dateTo != null) query['date_to'] = _formatDate(dateTo);

    final uri = Uri.parse('${ApiConfig.baseUrl}/finance/monthly-breakdown')
        .replace(queryParameters: query);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      String message = 'Erro ao buscar detalhamento do mês';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do detalhamento mensal');
    }
    if (userId != null) {
      await _snapshotService.saveBreakdown(
        userId: userId,
        month: month,
        dateFrom: dateFrom,
        dateTo: dateTo,
        data: decoded,
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> fetchCardPeriodFresh({
    int? userId,
    required String month,
  }) async {
    final headers = await _authenticatedHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/finance/card-period')
        .replace(queryParameters: {'month': month});
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar período dos cartões');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do período dos cartões');
    }
    if (userId != null) {
      await _snapshotService.saveCardPeriod(
        userId: userId,
        month: month,
        data: decoded,
      );
    }
    return decoded;
  }

  Future<double> fetchManualCommitmentFresh({
    int? userId,
    required String month,
  }) async {
    final headers = await _authenticatedHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/finance/manual-commitment')
        .replace(queryParameters: {'month': month});
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar compromisso manual do mês');
    }

    final decoded = jsonDecode(response.body);
    final raw = decoded is Map ? decoded['amount'] : null;
    final amount = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '') ?? 0.0;
    if (userId != null) {
      await _snapshotService.saveManualCommitment(
        userId: userId,
        month: month,
        amount: amount,
      );
    }
    return amount;
  }
}
