import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class MonthlySnapshotService {
  MonthlySnapshotService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _date(DateTime? value) {
    if (value == null) return 'none';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _breakdownKey({
    required int userId,
    required String month,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return 'monthly_breakdown_v1_${userId}_${month}_${_date(dateFrom)}_${_date(dateTo)}';
  }

  String _cardPeriodKey({required int userId, required String month}) =>
      'monthly_card_period_v1_${userId}_$month';

  String _manualCommitmentKey({required int userId, required String month}) =>
      'monthly_manual_commitment_v1_${userId}_$month';

  Future<void> _writeJson(String key, Object value) async {
    await _storage.write(key: key, value: jsonEncode(value));
  }

  Future<Map<String, dynamic>?> _readMap(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBreakdown({
    required int userId,
    required String month,
    DateTime? dateFrom,
    DateTime? dateTo,
    required Map<String, dynamic> data,
  }) async {
    await _writeJson(
      _breakdownKey(
        userId: userId,
        month: month,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ),
      {
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'data': data,
      },
    );
  }

  Future<Map<String, dynamic>?> getBreakdown({
    required int userId,
    required String month,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final snapshot = await _readMap(
      _breakdownKey(
        userId: userId,
        month: month,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ),
    );
    final data = snapshot?['data'];
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveCardPeriod({
    required int userId,
    required String month,
    required Map<String, dynamic> data,
  }) async {
    await _writeJson(
      _cardPeriodKey(userId: userId, month: month),
      {
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'data': data,
      },
    );
  }

  Future<Map<String, dynamic>?> getCardPeriod({
    required int userId,
    required String month,
  }) async {
    final snapshot = await _readMap(
      _cardPeriodKey(userId: userId, month: month),
    );
    final data = snapshot?['data'];
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveManualCommitment({
    required int userId,
    required String month,
    required double amount,
  }) async {
    await _writeJson(
      _manualCommitmentKey(userId: userId, month: month),
      {
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'amount': amount,
      },
    );
  }

  Future<double?> getManualCommitment({
    required int userId,
    required String month,
  }) async {
    final snapshot = await _readMap(
      _manualCommitmentKey(userId: userId, month: month),
    );
    final value = snapshot?['amount'];
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}
