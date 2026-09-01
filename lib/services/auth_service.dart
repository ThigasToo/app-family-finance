import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user.dart';
import 'planning_scope_service.dart';


class AuthService {
  final _storage = const FlutterSecureStorage();
  final _planningScope = PlanningScopeService();

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erro ao registrar');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Email ou senha inválidos');
    }

    final data = jsonDecode(response.body);
    await _storage.write(
      key: 'access_token',
      value: data['access_token'],
    );
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  Future<AppUser?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      return null;
    }

    if (response.statusCode != 200) {
      // Preserva o token em falhas transitórias do backend.
      return null;
    }

    final user = AppUser.fromJson(jsonDecode(response.body));
    await _planningScope.activateUser(user.id);
    return user;
  }
}
