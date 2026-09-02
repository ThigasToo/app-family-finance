import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class CardNotesService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _activeUserKey = 'planning_active_user_id';
  static const String _fallbackUser = 'default';

  Future<String> _storageKey() async {
    final userId = await _storage.read(key: _activeUserKey);
    final scope = (userId == null || userId.trim().isEmpty)
        ? _fallbackUser
        : userId.trim();
    return 'card_general_notes_$scope';
  }

  Future<String> load() async {
    final key = await _storageKey();
    return (await _storage.read(key: key))?.trim() ?? '';
  }

  Future<void> save(String value) async {
    final key = await _storageKey();
    final clean = value.trim();

    if (clean.isEmpty) {
      await _storage.delete(key: key);
      return;
    }

    await _storage.write(key: key, value: clean);
  }
}
