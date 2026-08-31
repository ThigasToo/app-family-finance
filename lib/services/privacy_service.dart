import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class PrivacyService {
  PrivacyService._();

  static final PrivacyService instance =
      PrivacyService._();

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  static const String storageKey =
      'home_values_visible';

  final ValueNotifier<bool> valuesVisible =
      ValueNotifier<bool>(true);


  Future<void> initialize() async {
    final value =
        await _storage.read(
      key: storageKey,
    );

    valuesVisible.value =
        value != 'false';
  }


  Future<void> setValuesVisible(
    bool visible,
  ) async {
    valuesVisible.value =
        visible;

    await _storage.write(
      key: storageKey,
      value:
          visible.toString(),
    );
  }


  Future<void> toggle() async {
    await setValuesVisible(
      !valuesVisible.value,
    );
  }
}