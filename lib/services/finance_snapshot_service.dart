import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FinanceSnapshotService {
  FinanceSnapshotService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _snapshotKey = 'finance_snapshot_v2';

  final FlutterSecureStorage _storage;

  Future<void> saveSnapshot(
    Map<String, dynamic> summary, {
    required int userId,
  }) async {
    final snapshot = <String, dynamic>{
      'version': 2,
      'user_id': userId,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'summary': summary,
    };

    await _storage.write(
      key: _snapshotKey,
      value: jsonEncode(snapshot),
    );
  }

  Future<Map<String, dynamic>?> getSnapshot({required int userId}) async {
    final raw = await _storage.read(key: _snapshotKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final snapshot = Map<String, dynamic>.from(decoded);
      if (snapshot['version'] != 2) return null;
      if (snapshot['user_id'] != userId) return null;

      final summary = snapshot['summary'];
      if (summary is! Map) return null;

      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSummary({required int userId}) async {
    final snapshot = await getSnapshot(userId: userId);
    if (snapshot == null) return null;

    final summary = snapshot['summary'];
    if (summary is! Map) return null;

    return Map<String, dynamic>.from(summary);
  }

  Future<DateTime?> getSavedAt({required int userId}) async {
    final snapshot = await getSnapshot(userId: userId);
    final value = snapshot?['saved_at']?.toString();
    if (value == null || value.isEmpty) return null;

    return DateTime.tryParse(value)?.toLocal();
  }

  Future<void> clearSnapshot() async {
    await _storage.delete(key: _snapshotKey);
  }
}
