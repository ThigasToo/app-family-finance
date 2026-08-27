import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class FinanceService {
  final _authService = AuthService();

  Future<Map<String, dynamic>> getSummary() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/finance/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar resumo financeiro');
    }

    return jsonDecode(response.body);
  }

  /// Retorna o corpo da resposta em caso de sucesso.
  /// Lança exceção com a mensagem de cooldown se ainda não passou o tempo.
  Future<Map<String, dynamic>> refresh() async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/finance/refresh'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 429) {
      throw Exception(data['detail'] ?? 'Aguarde antes de atualizar novamente');
    }

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar dados financeiros');
    }

    return data;
  }
}