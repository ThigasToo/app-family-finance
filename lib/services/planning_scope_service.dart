import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class PlanningScopeService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _activeUserKey = 'planning_active_user_id';
  static const String _salaryPrefix = 'expected_salary_';
  static const String _receiptsPrefix = 'expected_receipts_';

  Future<int?> getActiveUserId() async {
    final value = await _storage.read(key: _activeUserKey);
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  Future<void> activateUser(int userId) async {
    final currentId = userId.toString();
    final activeId = await _storage.read(key: _activeUserKey);

    if (activeId == currentId) {
      return;
    }

    final all = await _storage.readAll();

    if (activeId != null && activeId.isNotEmpty) {
      await _persistGenericPlanningForUser(activeId, all);
      await _clearGenericPlanning(all);
      await _restorePlanningForUser(currentId);
    } else {
      // Primeira ativação após a introdução do escopo por usuário.
      // Os valores genéricos existentes pertencem à sessão autenticada atual,
      // então os preservamos também no namespace desse usuário.
      await _persistGenericPlanningForUser(currentId, all);
    }

    await _storage.write(
      key: _activeUserKey,
      value: currentId,
    );
  }

  Future<void> _persistGenericPlanningForUser(
    String userId,
    Map<String, String> values,
  ) async {
    for (final entry in values.entries) {
      if (!_isGenericPlanningKey(entry.key)) {
        continue;
      }

      await _storage.write(
        key: _scopedKey(userId, entry.key),
        value: entry.value,
      );
    }
  }

  Future<void> _clearGenericPlanning(
    Map<String, String> values,
  ) async {
    for (final key in values.keys) {
      if (_isGenericPlanningKey(key)) {
        await _storage.delete(key: key);
      }
    }
  }

  Future<void> _restorePlanningForUser(String userId) async {
    final values = await _storage.readAll();
    final scopedPrefix = 'planning_user_${userId}_';

    for (final entry in values.entries) {
      if (!entry.key.startsWith(scopedPrefix)) {
        continue;
      }

      final genericKey = entry.key.substring(scopedPrefix.length);
      if (!_isGenericPlanningKey(genericKey)) {
        continue;
      }

      await _storage.write(
        key: genericKey,
        value: entry.value,
      );
    }
  }

  bool _isGenericPlanningKey(String key) {
    return key.startsWith(_salaryPrefix) ||
        key.startsWith(_receiptsPrefix);
  }

  String _scopedKey(String userId, String genericKey) {
    return 'planning_user_${userId}_$genericKey';
  }
}
