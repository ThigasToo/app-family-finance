import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

import 'home_screen.dart';
import 'register_screen.dart';


class LoginScreen
    extends StatefulWidget {
  const LoginScreen({
    super.key,
  });


  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}


class _LoginScreenState
    extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _authService =
      AuthService();


  bool _isLoading =
      false;

  bool _obscurePassword =
      true;

  String? _errorMessage;


  late final
      AnimationController
          _animationController;

  late final Animation<double>
      _fadeAnimation;

  late final Animation<Offset>
      _slideAnimation;


  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();


    _animationController =
        AnimationController(
      vsync:
          this,
      duration:
          const Duration(
        milliseconds:
            650,
      ),
    );


    _fadeAnimation =
        CurvedAnimation(
      parent:
          _animationController,
      curve:
          Curves.easeOutCubic,
    );


    _slideAnimation =
        Tween<Offset>(
      begin:
          const Offset(
        0,
        0.045,
      ),
      end:
          Offset.zero,
    ).animate(
      CurvedAnimation(
        parent:
            _animationController,
        curve:
            Curves.easeOutCubic,
      ),
    );


    _animationController
        .forward();
  }


  @override
  void dispose() {
    _emailController
        .dispose();

    _passwordController
        .dispose();

    _animationController
        .dispose();

    super.dispose();
  }


  // =========================================================
  // LOGIN
  // =========================================================

  Future<void>
      _handleLogin() async {

    FocusScope.of(context)
        .unfocus();


    final email =
        _emailController.text
            .trim();

    final password =
        _passwordController
            .text;


    if (
        email.isEmpty ||
        password.isEmpty
    ) {

      setState(() {
        _errorMessage =
            'Preencha seu email e sua senha.';
      });

      return;
    }


    setState(() {
      _isLoading =
          true;

      _errorMessage =
          null;
    });


    try {

      await _authService.login(
        email:
            email,
        password:
            password,
      );


      if (!mounted) return;


      Navigator.of(context)
          .pushReplacement(

        MaterialPageRoute(

          builder:
              (_) =>
                  const HomeScreen(),
        ),
      );

    } catch (e) {

      if (!mounted) return;


      setState(() {

        _errorMessage =
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );
      });

    } finally {

      if (mounted) {

        setState(() {
          _isLoading =
              false;
        });
      }
    }
  }


  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    final keyboardVisible =
        MediaQuery.of(context)
                .viewInsets
                .bottom >
            0;


    return Scaffold(

      resizeToAvoidBottomInset:
          true,

      body:
          GestureDetector(

        behavior:
            HitTestBehavior
                .translucent,

        onTap:
            () {

          FocusScope.of(context)
              .unfocus();
        },

        child:
            Stack(

          children: [

            // =================================================
            // BACKGROUND
            // =================================================

            const Positioned.fill(

              child:
                  DecoratedBox(

                decoration:
                    BoxDecoration(

                  gradient:
                      AppTheme
                          .loginGradient,
                ),
              ),
            ),


            // =================================================
            // GLOW 1
            // =================================================

            const Positioned(
              top:
                  -120,
              left:
                  -90,
              child:
                  _GlowOrb(
                size:
                    320,
                color:
                    Color(
                  0xFF8BCBC1,
                ),
              ),
            ),


            // =================================================
            // GLOW 2
            // =================================================

            const Positioned(
              top:
                  180,
              right:
                  -120,
              child:
                  _GlowOrb(
                size:
                    300,
                color:
                    Color(
                  0xFFAFC4DD,
                ),
              ),
            ),


            // =================================================
            // GLOW 3
            // =================================================

            const Positioned(
              bottom:
                  -120,
              left:
                  40,
              child:
                  _GlowOrb(
                size:
                    280,
                color:
                    Color(
                  0xFFB9DDD1,
                ),
              ),
            ),


            // =================================================
            // CONTEÚDO
            // =================================================

            SafeArea(

              child:
                  Center(

                child:
                    SingleChildScrollView(

                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,

                  padding:
                      EdgeInsets.fromLTRB(
                    24,
                    keyboardVisible
                        ? 20
                        : 38,
                    24,
                    28,
                  ),

                  child:
                      FadeTransition(

                    opacity:
                        _fadeAnimation,

                    child:
                        SlideTransition(

                      position:
                          _slideAnimation,

                      child:
                          ConstrainedBox(

                        constraints:
                            const BoxConstraints(
                          maxWidth:
                              460,
                        ),

                        child:
                            Column(

                          mainAxisSize:
                              MainAxisSize
                                  .min,

                          children: [

                            // =====================================
                            // LOGO
                            // =====================================

                            _buildLogo(),


                            const SizedBox(
                              height:
                                  20,
                            ),


                            // =====================================
                            // BRAND
                            // =====================================

                            const Text(

                              'Family Finance',

                              style:
                                  TextStyle(

                                fontSize:
                                    36,

                                fontWeight:
                                    FontWeight
                                        .w900,

                                letterSpacing:
                                    -1.4,

                                color:
                                    AppTheme
                                        .ink,
                              ),
                            ),


                            const SizedBox(
                              height:
                                  8,
                            ),


                            Text(

                              'Sua vida financeira,\n'
                              'em um só lugar.',

                              textAlign:
                                  TextAlign.center,

                              style:
                                  TextStyle(

                                fontSize:
                                    16,

                                height:
                                    1.4,

                                fontWeight:
                                    FontWeight
                                        .w500,

                                color:
                                    AppTheme
                                        .inkSoft
                                        .withValues(
                                  alpha:
                                      0.92,
                                ),
                              ),
                            ),


                            SizedBox(
                              height:
                                  keyboardVisible
                                      ? 22
                                      : 34,
                            ),


                            // =====================================
                            // GLASS LOGIN
                            // =====================================

                            _buildGlassLoginCard(),


                            const SizedBox(
                              height:
                                  22,
                            ),


                            // =====================================
                            // SEGURANÇA
                            // =====================================

                            Row(

                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,

                              children: [

                                Icon(

                                  Icons
                                      .lock_outline_rounded,

                                  size:
                                      14,

                                  color:
                                      AppTheme
                                          .inkSoft
                                          .withValues(
                                    alpha:
                                        0.75,
                                  ),
                                ),


                                const SizedBox(
                                  width:
                                      6,
                                ),


                                Text(

                                  'Seus dados são protegidos',

                                  style:
                                      TextStyle(

                                    fontSize:
                                        12,

                                    fontWeight:
                                        FontWeight
                                            .w500,

                                    color:
                                        AppTheme
                                            .inkSoft
                                            .withValues(
                                      alpha:
                                          0.78,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // =========================================================
  // LOGO
  // =========================================================

  Widget _buildLogo() {

    return ClipRRect(

      borderRadius:
          BorderRadius.circular(
        28,
      ),

      child:
          BackdropFilter(

        filter:
            ImageFilter.blur(
          sigmaX:
              18,
          sigmaY:
              18,
        ),

        child:
            Container(

          width:
              86,

          height:
              86,

          decoration:
              BoxDecoration(

            color:
                Colors.white
                    .withValues(
              alpha:
                  0.60,
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
                    0.82,
              ),

              width:
                  1.1,
            ),

            boxShadow:
                AppTheme
                    .floatingShadow,
          ),

          child:
              Center(

            child:
                Container(

              width:
                  56,

              height:
                  56,

              decoration:
                  BoxDecoration(

                gradient:
                    AppTheme
                        .primaryGradient,

                borderRadius:
                    BorderRadius.circular(
                  19,
                ),

                boxShadow: [

                  BoxShadow(

                    color:
                        AppTheme.primary
                            .withValues(
                      alpha:
                          0.22,
                    ),

                    blurRadius:
                        20,

                    offset:
                        const Offset(
                      0,
                      8,
                    ),
                  ),
                ],
              ),

              child:
                  const Icon(

                Icons
                    .eco_rounded,

                color:
                    Colors.white,

                size:
                    30,
              ),
            ),
          ),
        ),
      ),
    );
  }


  // =========================================================
  // GLASS CARD
  // =========================================================

  Widget
      _buildGlassLoginCard() {

    return ClipRRect(

      borderRadius:
          BorderRadius.circular(
        30,
      ),

      child:
          BackdropFilter(

        filter:
            ImageFilter.blur(
          sigmaX:
              24,
          sigmaY:
              24,
        ),

        child:
            Container(

          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            22,
          ),

          decoration:
              AppTheme
                  .glassDecoration(
            radius:
                30,
            opacity:
                0.64,
          ),

          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,

            children: [

              // =============================================
              // HEADER DO CARD
              // =============================================

              const Text(

                'Bem-vindo',

                style:
                    TextStyle(

                  fontSize:
                      22,

                  fontWeight:
                      FontWeight
                          .w800,

                  letterSpacing:
                      -0.5,

                  color:
                      AppTheme
                          .ink,
                ),
              ),


              const SizedBox(
                height:
                    4,
              ),


              const Text(

                'Entre para acessar suas finanças.',

                style:
                    TextStyle(

                  fontSize:
                      13,

                  color:
                      AppTheme
                          .inkSoft,
                ),
              ),


              const SizedBox(
                height:
                    22,
              ),


              // =============================================
              // EMAIL
              // =============================================

              TextField(

                controller:
                    _emailController,

                enabled:
                    !_isLoading,

                keyboardType:
                    TextInputType
                        .emailAddress,

                textInputAction:
                    TextInputAction
                        .next,

                autocorrect:
                    false,

                enableSuggestions:
                    false,

                decoration:
                    const InputDecoration(

                  labelText:
                      'Email',

                  hintText:
                      'seu@email.com',

                  prefixIcon:
                      Icon(
                    Icons
                        .alternate_email_rounded,
                  ),
                ),
              ),


              const SizedBox(
                height:
                    14,
              ),


              // =============================================
              // SENHA
              // =============================================

              TextField(

                controller:
                    _passwordController,

                enabled:
                    !_isLoading,

                obscureText:
                    _obscurePassword,

                textInputAction:
                    TextInputAction
                        .done,

                onSubmitted:
                    (_) {

                  if (!_isLoading) {
                    _handleLogin();
                  }
                },

                decoration:
                    InputDecoration(

                  labelText:
                      'Senha',

                  hintText:
                      'Sua senha',

                  prefixIcon:
                      const Icon(
                    Icons
                        .lock_outline_rounded,
                  ),

                  suffixIcon:
                      IconButton(

                    tooltip:
                        _obscurePassword
                            ? 'Mostrar senha'
                            : 'Ocultar senha',

                    onPressed:
                        () {

                      setState(() {

                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },

                    icon:
                        AnimatedSwitcher(

                      duration:
                          const Duration(
                        milliseconds:
                            180,
                      ),

                      child:
                          Icon(

                        _obscurePassword
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,

                        key:
                            ValueKey(
                          _obscurePassword,
                        ),
                      ),
                    ),
                  ),
                ),
              ),


              // =============================================
              // ERRO
              // =============================================

              if (
                  _errorMessage !=
                  null
              ) ...[

                const SizedBox(
                  height:
                      14,
                ),


                Container(

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        13,
                    vertical:
                        11,
                  ),

                  decoration:
                      BoxDecoration(

                    color:
                        AppTheme.danger
                            .withValues(
                      alpha:
                          0.08,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    border:
                        Border.all(

                      color:
                          AppTheme.danger
                              .withValues(
                        alpha:
                            0.14,
                      ),
                    ),
                  ),

                  child:
                      Row(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      const Icon(

                        Icons
                            .error_outline_rounded,

                        size:
                            18,

                        color:
                            AppTheme
                                .danger,
                      ),


                      const SizedBox(
                        width:
                            9,
                      ),


                      Expanded(

                        child:
                            Text(

                          _errorMessage!,

                          style:
                              const TextStyle(

                            fontSize:
                                12.5,

                            height:
                                1.35,

                            color:
                                AppTheme
                                    .danger,

                            fontWeight:
                                FontWeight
                                    .w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],


              const SizedBox(
                height:
                    20,
              ),


              // =============================================
              // BOTÃO
              // =============================================

              _buildLoginButton(),


              const SizedBox(
                height:
                    16,
              ),


              // =============================================
              // CADASTRO
              // =============================================

              Row(

                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [

                  Text(

                    'Ainda não tem uma conta?',

                    style:
                        TextStyle(

                      fontSize:
                          13,

                      color:
                          AppTheme
                              .inkSoft
                              .withValues(
                        alpha:
                            0.90,
                      ),
                    ),
                  ),


                  TextButton(

                    onPressed:
                        _isLoading
                            ? null
                            : () {

                                Navigator.of(
                                  context,
                                ).push(

                                  MaterialPageRoute(

                                    builder:
                                        (_) =>
                                            const RegisterScreen(),
                                  ),
                                );
                              },

                    style:
                        TextButton
                            .styleFrom(

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            7,
                      ),
                    ),

                    child:
                        const Text(
                      'Criar conta',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  // =========================================================
  // BOTÃO LOGIN
  // =========================================================

  Widget
      _buildLoginButton() {

    return AnimatedOpacity(

      opacity:
          _isLoading
              ? 0.82
              : 1,

      duration:
          const Duration(
        milliseconds:
            180,
      ),

      child:
          Container(

        height:
            56,

        decoration:
            BoxDecoration(

          gradient:
              AppTheme
                  .primaryGradient,

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          boxShadow: [

            BoxShadow(

              color:
                  AppTheme.primary
                      .withValues(
                alpha:
                    0.22,
              ),

              blurRadius:
                  20,

              offset:
                  const Offset(
                0,
                9,
              ),
            ),
          ],
        ),

        child:
            Material(

          color:
              Colors.transparent,

          child:
              InkWell(

            onTap:
                _isLoading
                    ? null
                    : _handleLogin,

            borderRadius:
                BorderRadius.circular(
              18,
            ),

            child:
                Center(

              child:
                  AnimatedSwitcher(

                duration:
                    const Duration(
                  milliseconds:
                      180,
                ),

                child:
                    _isLoading

                        ? const SizedBox(

                            key:
                                ValueKey(
                              'loading',
                            ),

                            width:
                                22,

                            height:
                                22,

                            child:
                                CircularProgressIndicator(

                              strokeWidth:
                                  2.2,

                              color:
                                  Colors.white,
                            ),
                          )

                        : const Row(

                            key:
                                ValueKey(
                              'text',
                            ),

                            mainAxisSize:
                                MainAxisSize
                                    .min,

                            children: [

                              Text(

                                'Entrar',

                                style:
                                    TextStyle(

                                  color:
                                      Colors.white,

                                  fontSize:
                                      15,

                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),


                              SizedBox(
                                width:
                                    8,
                              ),


                              Icon(

                                Icons
                                    .arrow_forward_rounded,

                                color:
                                    Colors.white,

                                size:
                                    19,
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ===========================================================
// GLOW ORB
// ===========================================================

class _GlowOrb
    extends StatelessWidget {

  final double size;
  final Color color;


  const _GlowOrb({
    required this.size,
    required this.color,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    return ImageFiltered(

      imageFilter:
          ImageFilter.blur(
        sigmaX:
            55,
        sigmaY:
            55,
      ),

      child:
          Container(

        width:
            size,

        height:
            size,

        decoration:
            BoxDecoration(

          shape:
              BoxShape.circle,

          color:
              color.withValues(
            alpha:
                0.34,
          ),
        ),
      ),
    );
  }
}