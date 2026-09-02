import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FinanceSnapshotService {
  FinanceSnapshotService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _snapshotKey = 'finance_snapshot_v1';

  final FlutterSecureStorage _storage;

  Future<void> saveSnapshot(Map<String, dynamic> summary) async {
    final snapshot = <String, dynamic>{
      'version': 1,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'summary': summary,
    };

    await _storage.write(
      key: _snapshotKey,
      value: jsonEncode(snapshot),
    );
  }

  Future<Map<String, dynamic>?> getSnapshot() async {
    final raw = await _storage.read(key: _snapshotKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final snapshot = Map<String, dynamic>.from(decoded);
      if (snapshot['version'] != 1) return null;

      final summary = snapshot['summary'];
      if (summary is! Map) return null;

      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSummary() async {
    final snapshot = await getSnapshot();
    if (snapshot == null) return null;

    final summary = snapshot['summary'];
    if (summary is! Map) return null;

    return Map<String, dynamic>.from(summary);
  }

  Future<DateTime?> getSavedAt() async {
    final snapshot = await getSnapshot();
    final value = snapshot?['saved_at']?.toString();
    if (value == null || value.isEmpty) return null;

    return DateTime.tryParse(value)?.toLocal();
  }

  Future<void> clearSnapshot() async {
    await _storage.delete(key: _snapshotKey);
  }
}
