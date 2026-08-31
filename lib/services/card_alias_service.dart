import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class CardAliasService {
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  static const String _storageKey =
      'card_aliases';


  Future<Map<String, String>>
      _loadAliases() async {
    final raw =
        await _storage.read(
      key: _storageKey,
    );

    if (raw == null ||
        raw.trim().isEmpty) {
      return {};
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! Map) {
        return {};
      }

      return decoded.map(
        (key, value) =>
            MapEntry(
          key.toString(),
          value.toString(),
        ),
      );
    } catch (_) {
      return {};
    }
  }


  Future<String?> getAlias(
    String cardKey,
  ) async {
    final aliases =
        await _loadAliases();

    final value =
        aliases[cardKey]
            ?.trim();

    if (value == null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }


  Future<void> saveAlias({
    required String cardKey,
    required String alias,
  }) async {
    final aliases =
        await _loadAliases();

    final clean =
        alias.trim();

    if (clean.isEmpty) {
      aliases.remove(
        cardKey,
      );
    } else {
      aliases[cardKey] =
          clean;
    }

    await _storage.write(
      key: _storageKey,
      value:
          jsonEncode(
        aliases,
      ),
    );
  }


  Future<void> removeAlias(
    String cardKey,
  ) async {
    final aliases =
        await _loadAliases();

    aliases.remove(
      cardKey,
    );

    await _storage.write(
      key: _storageKey,
      value:
          jsonEncode(
        aliases,
      ),
    );
  }
}