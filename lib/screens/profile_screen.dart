
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../widgets/finance_ui.dart';
import 'connected_institutions_screen.dart';
import 'connect_bank_screen.dart';
import 'login_screen.dart';


class ProfileScreen extends StatefulWidget {
  final AppUser user;

  final List<dynamic> accounts;

  final bool valuesVisible;

  final Future<void> Function(bool value)
      onValuesVisibilityChanged;

  final Future<void> Function()?
      onConnectionChanged;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.accounts,
    required this.valuesVisible,
    required this.onValuesVisibilityChanged,
    this.onConnectionChanged,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}


class _ProfileScreenState
    extends State<ProfileScreen> {
  final _authService =
      AuthService();

  final _biometricService =
      BiometricService();

  late bool _valuesVisible;

  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  String _biometricLabel =
      'Biometria';


  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _valuesVisible =
        widget.valuesVisible;

    _loadBiometricStatus();
  }


  // =========================================================
  // BIOMETRIA
  // =========================================================

  Future<void>
      _loadBiometricStatus() async {
    final available =
        await _biometricService
            .isAvailable();

    final enabled =
        await _biometricService
            .isEnabled();

    final biometrics =
        await _biometricService
            .getAvailableBiometrics();

    String label =
        'Biometria';

    if (biometrics.contains(
      BiometricType.face,
    )) {
      label =
          'Reconhecimento facial';
    } else if (biometrics.contains(
      BiometricType.fingerprint,
    )) {
      label =
          'Impressão digital';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricAvailable =
          available;

      _biometricEnabled =
          enabled && available;

      _biometricLabel =
          label;
    });
  }


  Future<void>
      _toggleBiometric(
    bool value,
  ) async {
    if (!_biometricAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Este aparelho não possui biometria disponível ou cadastrada.',
          ),
        ),
      );

      return;
    }

    if (value) {
      final authenticated =
          await _biometricService
              .authenticate(
        reason:
            'Confirme sua identidade para ativar a biometria',
      );

      if (!authenticated) {
        return;
      }
    }

    await _biometricService
        .setEnabled(
      value,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricEnabled =
          value;
    });
  }


  // =========================================================
  // PERFIL
  // =========================================================

  String get _initials {
    final parts =
        widget.user.name
            .trim()
            .split(
          RegExp(r'\s+'),
        )
            .where(
          (part) =>
              part.isNotEmpty,
        )
            .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      final first =
          parts.first;

      return first
          .substring(
            0,
            first.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}'
            '${parts.last[0]}'
        .toUpperCase();
  }


  // =========================================================
  // INSTITUIÇÕES
  // =========================================================

  List<String>
      get _institutions {
    final institutions =
        <String>{};

    for (final account
        in widget.accounts) {
      final candidates = [
        account[
            'institution_name'],
        account[
            'resolved_institution'],
        account[
            'institution'],
        account[
            'institutionName'],
      ];

      for (final candidate
          in candidates) {
        if (candidate != null &&
            candidate
                .toString()
                .trim()
                .isNotEmpty) {
          institutions.add(
            candidate
                .toString()
                .trim(),
          );

          break;
        }
      }
    }

    final result =
        institutions.toList();

    result.sort(
      (a, b) =>
          a
              .toLowerCase()
              .compareTo(
                b.toLowerCase(),
              ),
    );

    return result;
  }


  // =========================================================
  // VISIBILIDADE DOS VALORES
  // =========================================================

  Future<void>
      _changeValuesVisibility(
    bool value,
  ) async {
    setState(() {
      _valuesVisible =
          value;
    });

    await widget
        .onValuesVisibilityChanged(
      value,
    );
  }


  // =========================================================
  // CONECTAR INSTITUIÇÃO
  // =========================================================

  Future<void>
      _connectInstitution() async {
    final connected =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const ConnectBankScreen(),
      ),
    );

    if (connected != true) {
      return;
    }

    if (widget.onConnectionChanged !=
        null) {
      await widget
          .onConnectionChanged!();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Instituição conectada com sucesso.',
        ),
      ),
    );
  }


  // =========================================================
  // INSTITUIÇÕES CONECTADAS
  // =========================================================

  Future<void>
    _openConnectedInstitutions() async {
  final changed =
      await Navigator.of(context)
          .push<bool>(
    MaterialPageRoute(
      builder: (_) =>
          ConnectedInstitutionsScreen(
        accounts:
            widget.accounts,
        onConnectionChanged:
            widget.onConnectionChanged,
      ),
    ),
  );

  if (changed == true &&
      widget.onConnectionChanged !=
          null) {
    await widget
        .onConnectionChanged!();
  }
}


  // =========================================================
  // COMO FUNCIONA
  // =========================================================

  void _showHowItWorks() {
    showDialog(
      context:
          context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Como funciona',
          ),
          content:
              const Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _HelpRow(
                number: '1',
                title:
                    'Conecte suas instituições',
                text:
                    'O Family Finance reúne suas contas, cartões e investimentos conectados.',
              ),

              SizedBox(
                height: 18,
              ),

              _HelpRow(
                number: '2',
                title:
                    'Planeje o mês',
                text:
                    'Informe salário, recebimentos, PIX e a parcela dos cartões que deseja considerar em cada mês.',
              ),

              SizedBox(
                height: 18,
              ),

              _HelpRow(
                number: '3',
                title:
                    'Acompanhe sua vida financeira',
                text:
                    'A Home mostra quanto você espera receber, quanto já está comprometido e quanto ficará disponível.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Entendi',
              ),
            ),
          ],
        );
      },
    );
  }


  // =========================================================
  // PRIVACIDADE
  // =========================================================

  void _showPrivacy() {
    showDialog(
      context:
          context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Privacidade e dados',
          ),
          content:
              const Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _PrivacyRow(
                icon:
                    Icons
                        .lock_outline_rounded,
                title:
                    'Acesso protegido',
                text:
                    'O acesso às suas informações exige autenticação no Family Finance.',
              ),

              SizedBox(
                height: 18,
              ),

              _PrivacyRow(
                icon:
                    Icons
                        .fingerprint_rounded,
                title:
                    'Proteção biométrica',
                text:
                    'Quando ativada, a biometria adiciona uma camada de proteção ao abrir o aplicativo.',
              ),

              SizedBox(
                height: 18,
              ),

              _PrivacyRow(
                icon:
                    Icons
                        .visibility_off_outlined,
                title:
                    'Valores ocultáveis',
                text:
                    'Você pode esconder os valores financeiros da tela sempre que precisar.',
              ),

              SizedBox(
                height: 18,
              ),

              _PrivacyRow(
                icon:
                    Icons.key_rounded,
                title:
                    'Sessão protegida',
                text:
                    'O token da sessão é armazenado no armazenamento seguro do dispositivo.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Fechar',
              ),
            ),
          ],
        );
      },
    );
  }


  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void>
      _confirmLogout() async {
    final confirmed =
        await showDialog<bool>(
      context:
          context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Sair do Family Finance?',
          ),
          content:
              const Text(
            'Você precisará entrar novamente para acessar suas informações.',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),

            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  TextButton.styleFrom(
                foregroundColor:
                    AppTheme.danger,
              ),
              child:
                  const Text(
                'Sair',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _authService.logout();

    if (!mounted) return;

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) =>
          false,
    );
  }


  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return FinancePage(
      title:
          'Perfil',
      child:
          ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          36,
        ),
        children: [
          _buildProfileHero(),

          const SizedBox(
            height: 30,
          ),

          const FinanceSectionHeader(
            title:
                'Segurança',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildSecurityCard(),

          const SizedBox(
            height: 30,
          ),

          const FinanceSectionHeader(
            title:
                'Conexões',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildConnectionsCard(),

          const SizedBox(
            height: 30,
          ),

          const FinanceSectionHeader(
            title:
                'Ajuda',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildHelpCard(),

          const SizedBox(
            height: 30,
          ),

          const FinanceSectionHeader(
            title:
                'Conta',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildAccountCard(),
        ],
      ),
    );
  }


  // =========================================================
  // HERO
  // =========================================================

  Widget _buildProfileHero() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          BoxDecoration(
        gradient:
            AppTheme.premiumGradient,
        borderRadius:
            BorderRadius.circular(
          29,
        ),
        border:
            Border.all(
          color:
              Colors.white
                  .withValues(
            alpha: 0.15,
          ),
        ),
        boxShadow:
            AppTheme.floatingShadow,
      ),
      child:
          Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
              border:
                  Border.all(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.16,
                ),
              ),
            ),
            child:
                Center(
              child:
                  Text(
                _initials,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      21,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      0.4,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing:
                        -0.3,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  widget.user.email,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.68,
                    ),
                    fontSize:
                        11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // SEGURANÇA
  // =========================================================

  Widget _buildSecurityCard() {
    return FinanceGlassCard(
      radius: 23,
      child:
          Column(
        children: [
          _SettingsTile(
            icon:
                Icons.fingerprint_rounded,
            title:
                _biometricLabel,
            subtitle:
                !_biometricAvailable
                    ? 'Não disponível neste aparelho'
                    : _biometricEnabled
                        ? 'Proteção ativada'
                        : 'Proteja a abertura do app',
            trailing:
                Switch(
              value:
                  _biometricEnabled,
              activeTrackColor:
                  AppTheme.primary,
              onChanged:
                  _biometricAvailable
                      ? _toggleBiometric
                      : null,
            ),
          ),

          const _SettingsDivider(),

          _SettingsTile(
            icon:
                _valuesVisible
                    ? Icons
                        .visibility_outlined
                    : Icons
                        .visibility_off_outlined,
            title:
                'Mostrar valores',
            subtitle:
                _valuesVisible
                    ? 'Os valores estão visíveis'
                    : 'Os valores estão ocultos',
            trailing:
                Switch(
              value:
                  _valuesVisible,
              activeTrackColor:
                  AppTheme.primary,
              onChanged:
                  _changeValuesVisibility,
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // CONEXÕES
  // =========================================================

  Widget _buildConnectionsCard() {
    return FinanceGlassCard(
      radius: 23,
      child:
          Column(
        children: [
          _SettingsTile(
            icon:
                Icons
                    .account_balance_rounded,
            title:
                'Instituições conectadas',
            subtitle:
                _institutions.isEmpty
                    ? 'Nenhuma instituição'
                    : '${_institutions.length} '
                        '${_institutions.length == 1 ? 'instituição' : 'instituições'}',
            onTap:
                _openConnectedInstitutions,
            trailing:
                const Icon(
              Icons
                  .chevron_right_rounded,
              color:
                  AppTheme.inkSoft,
            ),
          ),

          const _SettingsDivider(),

          _SettingsTile(
            icon:
                Icons.add_rounded,
            title:
                'Conectar nova instituição',
            subtitle:
                'Adicionar banco ou conta',
            onTap:
                _connectInstitution,
            trailing:
                const Icon(
              Icons
                  .chevron_right_rounded,
              color:
                  AppTheme.inkSoft,
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // AJUDA
  // =========================================================

  Widget _buildHelpCard() {
    return FinanceGlassCard(
      radius: 23,
      child:
          Column(
        children: [
          _SettingsTile(
            icon:
                Icons
                    .help_outline_rounded,
            title:
                'Como funciona',
            subtitle:
                'Entenda os principais recursos',
            onTap:
                _showHowItWorks,
            trailing:
                const Icon(
              Icons
                  .chevron_right_rounded,
              color:
                  AppTheme.inkSoft,
            ),
          ),

          const _SettingsDivider(),

          _SettingsTile(
            icon:
                Icons.shield_outlined,
            title:
                'Privacidade e dados',
            subtitle:
                'Como suas informações são protegidas',
            onTap:
                _showPrivacy,
            trailing:
                const Icon(
              Icons
                  .chevron_right_rounded,
              color:
                  AppTheme.inkSoft,
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // CONTA
  // =========================================================

  Widget _buildAccountCard() {
    return FinanceGlassCard(
      radius: 23,
      child:
          _SettingsTile(
        icon:
            Icons.logout_rounded,
        iconColor:
            AppTheme.danger,
        title:
            'Sair',
        titleColor:
            AppTheme.danger,
        subtitle:
            'Encerrar sessão neste aparelho',
        onTap:
            _confirmLogout,
      ),
    );
  }
}


// ===========================================================
// SETTINGS TILE
// ===========================================================

class _SettingsTile
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String? subtitle;

  final Widget? trailing;

  final VoidCallback? onTap;

  final Color? iconColor;

  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child:
              Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      (iconColor ??
                              AppTheme.primary)
                          .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  size: 20,
                  color:
                      iconColor ??
                          AppTheme.primary,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          TextStyle(
                        color:
                            titleColor ??
                                AppTheme.ink,
                        fontSize:
                            13.5,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    if (subtitle !=
                        null) ...[
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        subtitle!,
                        style:
                            const TextStyle(
                          color:
                              AppTheme.inkSoft,
                          fontSize:
                              10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (trailing !=
                  null) ...[
                const SizedBox(
                  width: 10,
                ),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// ===========================================================
// DIVIDER
// ===========================================================

class _SettingsDivider
    extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 70,
      ),
      child:
          Divider(
        height: 1,
        color:
            AppTheme.line
                .withValues(
          alpha: 0.65,
        ),
      ),
    );
  }
}


// ===========================================================
// HELP ROW
// ===========================================================

class _HelpRow
    extends StatelessWidget {
  final String number;

  final String title;

  final String text;

  const _HelpRow({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration:
              const BoxDecoration(
            color:
                AppTheme.primary,
            shape:
                BoxShape.circle,
          ),
          child:
              Center(
            child:
                Text(
              number,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      AppTheme.ink,
                  fontSize:
                      13.5,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                text,
                style:
                    const TextStyle(
                  color:
                      AppTheme.inkSoft,
                  fontSize:
                      11.5,
                  height:
                      1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ===========================================================
// PRIVACY ROW
// ===========================================================

class _PrivacyRow
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String text;

  const _PrivacyRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(
            color:
                AppTheme.primary
                    .withValues(
              alpha: 0.08,
            ),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child:
              Icon(
            icon,
            size: 18,
            color:
                AppTheme.primary,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      AppTheme.ink,
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                text,
                style:
                    const TextStyle(
                  color:
                      AppTheme.inkSoft,
                  fontSize:
                      11,
                  height:
                      1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}