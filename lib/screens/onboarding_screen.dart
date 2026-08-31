import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
  });

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}


class _OnboardingScreenState
    extends State<OnboardingScreen> {
  final PageController _pageController =
      PageController();

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  int _currentPage = 0;

  static const String _onboardingKey =
      'onboarding_completed';


  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon:
          Icons.account_balance_wallet_rounded,
      title:
          'Tudo em um só lugar',
      description:
          'Acompanhe suas contas, cartões e investimentos de forma simples e organizada.',
    ),

    _OnboardingPageData(
      icon:
          Icons.calendar_month_rounded,
      title:
          'Planeje seu mês',
      description:
          'Informe seus recebimentos, PIX e compromissos para saber quanto ficará disponível.',
    ),

    _OnboardingPageData(
      icon:
          Icons.shield_rounded,
      title:
          'Privacidade primeiro',
      description:
          'Use login, biometria e ocultação de valores para manter suas informações protegidas.',
    ),
  ];


  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }


  // =========================================================
  // FINALIZAR
  // =========================================================

  Future<void> _finish() async {
    await _storage.write(
      key:
          _onboardingKey,
      value:
          'true',
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
    );
  }


  // =========================================================
  // PRÓXIMO
  // =========================================================

  void _next() {
    if (_currentPage ==
        _pages.length - 1) {
      _finish();

      return;
    }

    _pageController.nextPage(
      duration:
          const Duration(
        milliseconds: 350,
      ),
      curve:
          Curves.easeOutCubic,
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
              Column(
            children: [
              // ===============================================
              // TOPO
              // ===============================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  0,
                ),
                child:
                    Row(
                  children: [
                    const Text(
                      'Family Finance',
                      style:
                          TextStyle(
                        color:
                            AppTheme.ink,
                        fontSize:
                            18,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing:
                            -0.4,
                      ),
                    ),

                    const Spacer(),

                    if (_currentPage <
                        _pages.length - 1)
                      TextButton(
                        onPressed:
                            _finish,
                        child:
                            const Text(
                          'Pular',
                        ),
                      ),
                  ],
                ),
              ),

              // ===============================================
              // PÁGINAS
              // ===============================================

              Expanded(
                child:
                    PageView.builder(
                  controller:
                      _pageController,

                  itemCount:
                      _pages.length,

                  onPageChanged:
                      (index) {
                    setState(() {
                      _currentPage =
                          index;
                    });
                  },

                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final page =
                        _pages[index];

                    return _buildPage(
                      page,
                    );
                  },
                ),
              ),

              // ===============================================
              // RODAPÉ
              // ===============================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  28,
                ),
                child:
                    Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children:
                          List.generate(
                        _pages.length,
                        (index) =>
                            AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds:
                                220,
                          ),
                          margin:
                              const EdgeInsets.symmetric(
                            horizontal:
                                4,
                          ),
                          width:
                              _currentPage ==
                                      index
                                  ? 24
                                  : 7,
                          height:
                              7,
                          decoration:
                              BoxDecoration(
                            color:
                                _currentPage ==
                                        index
                                    ? AppTheme.primary
                                    : AppTheme.primary
                                        .withValues(
                                        alpha:
                                            0.18,
                                      ),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          24,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height:
                          54,
                      child:
                          FilledButton(
                        onPressed:
                            _next,
                        child:
                            Text(
                          _currentPage ==
                                  _pages.length - 1
                              ? 'Entrar no Family Finance'
                              : 'Continuar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // =========================================================
  // PAGE
  // =========================================================

  Widget _buildPage(
    _OnboardingPageData page,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            28,
      ),
      child:
          Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width:
                132,
            height:
                132,
            decoration:
                BoxDecoration(
              gradient:
                  AppTheme.primaryGradient,
              borderRadius:
                  BorderRadius.circular(
                42,
              ),
              boxShadow:
                  AppTheme.floatingShadow,
            ),
            child:
                Icon(
              page.icon,
              size:
                  58,
              color:
                  Colors.white,
            ),
          ),

          const SizedBox(
            height:
                42,
          ),

          Text(
            page.title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  AppTheme.ink,
              fontSize:
                  29,
              fontWeight:
                  FontWeight.w900,
              letterSpacing:
                  -0.9,
            ),
          ),

          const SizedBox(
            height:
                14,
          ),

          ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  330,
            ),
            child:
                Text(
              page.description,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    AppTheme.inkSoft,
                fontSize:
                    15,
                height:
                    1.5,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ===========================================================
// DATA
// ===========================================================

class _OnboardingPageData {
  final IconData icon;

  final String title;

  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}