import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';


class BiometricService {
  final LocalAuthentication _auth =
      LocalAuthentication();

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  static const String _enabledKey =
      'biometric_enabled';


  // =========================================================
  // DISPONIBILIDADE
  // =========================================================

  Future<bool> isAvailable() async {
    try {
      final canCheck =
          await _auth.canCheckBiometrics;

      final supported =
          await _auth.isDeviceSupported();

      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }


  Future<List<BiometricType>>
      getAvailableBiometrics() async {
    try {
      return await _auth
          .getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }


  // =========================================================
  // PREFERÊNCIA
  // =========================================================

  Future<bool> isEnabled() async {
    final value =
        await _storage.read(
      key: _enabledKey,
    );

    return value == 'true';
  }


  Future<void> setEnabled(
    bool enabled,
  ) async {
    await _storage.write(
      key: _enabledKey,
      value: enabled.toString(),
    );
  }


  // =========================================================
  // AUTENTICAÇÃO
  // =========================================================

  Future<bool> authenticate({
    String reason =
        'Confirme sua identidade para acessar o Family Finance',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options:
            const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}