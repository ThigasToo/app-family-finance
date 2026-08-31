import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';


class StartupScreen extends StatefulWidget {
  const StartupScreen({
    super.key,
  });

  @override
  State<StartupScreen> createState() =>
      _StartupScreenState();
}


class _StartupScreenState
    extends State<StartupScreen> {
  final _authService =
      AuthService();

  final _biometricService =
      BiometricService();

  final _storage =
      const FlutterSecureStorage();


  static const String _onboardingKey =
      'onboarding_completed';


  bool _showUnlockButton = false;


  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _initialize();
  }


  // =========================================================
  // FLUXO INICIAL
  // =========================================================

  Future<void> _initialize() async {
    // =======================================================
    // 1. ONBOARDING
    // =======================================================

    final onboardingCompleted =
        await _storage.read(
      key:
          _onboardingKey,
    );


    if (!mounted) {
      return;
    }


    if (onboardingCompleted !=
        'true') {
      Navigator.of(context)
          .pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              const OnboardingScreen(),
        ),
      );

      return;
    }


    // =======================================================
    // 2. SESSÃO
    // =======================================================

    final user =
        await _authService
            .getCurrentUser();


    if (!mounted) {
      return;
    }


    if (user == null) {
      _goToLogin();

      return;
    }


    // =======================================================
    // 3. BIOMETRIA
    // =======================================================

    final biometricEnabled =
        await _biometricService
            .isEnabled();


    if (!mounted) {
      return;
    }


    if (!biometricEnabled) {
      _goToHome();

      return;
    }


    await _authenticate();
  }


  // =========================================================
  // BIOMETRIA
  // =========================================================

  Future<void> _authenticate() async {
    setState(() {
      _showUnlockButton =
          false;
    });


    final success =
        await _biometricService
            .authenticate(
      reason:
          'Confirme sua identidade para acessar o Family Finance',
    );


    if (!mounted) {
      return;
    }


    if (success) {
      _goToHome();

      return;
    }


    setState(() {
      _showUnlockButton =
          true;
    });
  }


  // =========================================================
  // NAVEGAÇÃO
  // =========================================================

  void _goToHome() {
    Navigator.of(context)
        .pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            const HomeScreen(),
      ),
    );
  }


  void _goToLogin() {
    Navigator.of(context)
        .pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
    );
  }


  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body:
          Container(
        width:
            double.infinity,
        height:
            double.infinity,
        decoration:
            const BoxDecoration(
          gradient:
              AppTheme.loginGradient,
        ),
        child:
            SafeArea(
          child:
              Center(
            child:
                Padding(
              padding:
                  const EdgeInsets.all(
                30,
              ),
              child:
                  AnimatedSwitcher(
                duration:
                    const Duration(
                  milliseconds:
                      250,
                ),
                child:
                    _showUnlockButton
                        ? _buildLockedState()
                        : _buildLoadingState(),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoadingState() {
    return Column(
      key:
          const ValueKey(
        'loading',
      ),
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width:
              82,
          height:
              82,
          decoration:
              BoxDecoration(
            gradient:
                AppTheme.primaryGradient,
            borderRadius:
                BorderRadius.circular(
              27,
            ),
            boxShadow:
                AppTheme.floatingShadow,
          ),
          child:
              const Icon(
            Icons
                .account_balance_wallet_rounded,
            color:
                Colors.white,
            size:
                38,
          ),
        ),

        const SizedBox(
          height:
              24,
        ),

        const Text(
          'Family Finance',
          style:
              TextStyle(
            color:
                AppTheme.ink,
            fontSize:
                25,
            fontWeight:
                FontWeight.w900,
            letterSpacing:
                -0.7,
          ),
        ),

        const SizedBox(
          height:
              20,
        ),

        const SizedBox(
          width:
              24,
          height:
              24,
          child:
              CircularProgressIndicator(
            strokeWidth:
                2.5,
          ),
        ),
      ],
    );
  }


  // =========================================================
  // BLOQUEADO
  // =========================================================

  Widget _buildLockedState() {
    return Column(
      key:
          const ValueKey(
        'locked',
      ),
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width:
              84,
          height:
              84,
          decoration:
              BoxDecoration(
            color:
                Colors.white
                    .withValues(
              alpha:
                  0.48,
            ),
            borderRadius:
                BorderRadius.circular(
              28,
            ),
            border:
                Border.all(
              color:
                  Colors.white
                      .withValues(
                alpha:
                    0.70,
              ),
            ),
          ),
          child:
              const Icon(
            Icons
                .fingerprint_rounded,
            color:
                AppTheme.primary,
            size:
                42,
          ),
        ),

        const SizedBox(
          height:
              24,
        ),

        const Text(
          'Family Finance bloqueado',
          textAlign:
              TextAlign.center,
          style:
              TextStyle(
            color:
                AppTheme.ink,
            fontSize:
                21,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(
          height:
              8,
        ),

        const Text(
          'Use sua biometria para continuar.',
          textAlign:
              TextAlign.center,
          style:
              TextStyle(
            color:
                AppTheme.inkSoft,
            fontSize:
                13,
          ),
        ),

        const SizedBox(
          height:
              26,
        ),

        SizedBox(
          width:
              double.infinity,
          height:
              52,
          child:
              FilledButton.icon(
            onPressed:
                _authenticate,
            icon:
                const Icon(
              Icons
                  .fingerprint_rounded,
            ),
            label:
                const Text(
              'Desbloquear',
            ),
          ),
        ),

        const SizedBox(
          height:
              10,
        ),

        TextButton(
          onPressed:
              _goToLogin,
          child:
              const Text(
            'Entrar com outra conta',
          ),
        ),
      ],
    );
  }
}