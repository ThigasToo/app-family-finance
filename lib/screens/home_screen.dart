import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../services/privacy_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

import 'accounts_screen.dart';
import 'connect_bank_screen.dart';
import 'credit_cards_screen.dart';
import 'investments_screen.dart';
import 'login_screen.dart';
import 'monthly_calculation_detail_screen.dart';
import 'monthly_planning_screen.dart';
import 'profile_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _financeService = FinanceService();
  final _storage = const FlutterSecureStorage();

  AppUser? _user;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _valuesVisible = true;

  String? _refreshMessage;
  bool _refreshIsError = false;

  List<dynamic> _accounts = [];
  List<dynamic> _investments = [];

  Map<String, double> _monthlyCashFlowCommitment = {};
  Map<String, double> _cardCommitmentsByMonth = {};

  String? _updatedAt;

  double _expectedSalary = 0;
  double _expectedReceipts = 0;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  static const String _privacyStorageKey =
      'home_values_visible';


  @override
  void initState() {
    super.initState();
    _initializeHome();
  }


  Future<void> _initializeHome() async {
    await _loadPrivacyPreference();
    await _loadMonthlyPlanning();
    await _loadUserAndSummary();
  }


  Future<void> _loadPrivacyPreference() async {
    final saved = await _storage.read(
      key: _privacyStorageKey,
    );

    final visible =
        saved == null
            ? true
            : saved == 'true';

    PrivacyService.instance
        .valuesVisible.value = visible;

    if (!mounted) return;

    setState(() {
      _valuesVisible = visible;
    });
  }


  Future<void> _setValuesVisibility(
    bool value,
  ) async {
    if (!mounted) return;

    setState(() {
      _valuesVisible = value;
    });

    await PrivacyService.instance
        .setValuesVisible(value);
  }


  Future<void> _toggleValuesVisibility() async {
    await _setValuesVisibility(
      !_valuesVisible,
    );
  }


  String _money(
    double value,
  ) {
    if (!_valuesVisible) {
      return '••••••';
    }

    return formatCurrency(value);
  }


  Widget _animatedMoney({
    required double value,
    required TextStyle style,
    TextAlign? textAlign,
  }) {
    final text = _money(value);

    return AnimatedSwitcher(
      duration:
          const Duration(
        milliseconds: 180,
      ),
      child: Text(
        text,
        key: ValueKey(
          '${_valuesVisible}_$text',
        ),
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }


  Future<void> _loadUserAndSummary() async {
    final user =
        await _authService.getCurrentUser();

    if (user == null) {
      if (!mounted) return;

      Navigator.of(context)
          .pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _user = user;
    });

    await _loadSummary();
  }


  Map<String, double> _parseMonthlyMap(
    dynamic raw,
  ) {
    if (raw is! Map) {
      return {};
    }

    final result = <String, double>{};

    raw.forEach(
      (key, value) {
        final parsed =
            value is num
                ? value.toDouble()
                : double.tryParse(
                      value?.toString() ?? '',
                    ) ??
                    0;

        result[key.toString()] = parsed;
      },
    );

    return result;
  }


  Future<void> _loadSummary() async {
    try {
      final summary =
          await _financeService.getSummary();

      final payload =
          summary['payload'] ?? {};

      final cashFlowCommitment =
          _parseMonthlyMap(
        payload['pix_sent_by_month'],
      );

      final cardByMonth =
          _parseMonthlyMap(
        payload[
            'credit_card_commitments_by_month'],
      );

      if (!mounted) return;

      setState(() {
        _accounts =
            payload['accounts'] ?? [];

        _investments =
            payload['investments'] ?? [];

        _monthlyCashFlowCommitment =
            cashFlowCommitment;
        _cardCommitmentsByMonth =
            cardByMonth;

        _updatedAt =
            summary['updated_at'];

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }


  String get _monthStorageKey {
    final month =
        _selectedMonth.month
            .toString()
            .padLeft(2, '0');

    return '${_selectedMonth.year}_$month';
  }


  String get _selectedMonthKey {
    final month =
        _selectedMonth.month
            .toString()
            .padLeft(2, '0');

    return '${_selectedMonth.year}-$month';
  }


  String get _selectedMonthName {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return months[
        _selectedMonth.month - 1];
  }


  String get _selectedMonthLabel =>
      '$_selectedMonthName ${_selectedMonth.year}';


  Future<void> _previousMonth() async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });

    await _loadMonthlyPlanning();
  }


  Future<void> _nextMonth() async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });

    await _loadMonthlyPlanning();
  }


  Future<void> _loadMonthlyPlanning() async {
    final salary =
        await _storage.read(
      key:
          'expected_salary_$_monthStorageKey',
    );

    final receipts =
        await _storage.read(
      key:
          'expected_receipts_$_monthStorageKey',
    );

    if (!mounted) return;

    setState(() {
      _expectedSalary =
          double.tryParse(
                salary ?? '',
              ) ??
              0;

      _expectedReceipts =
          double.tryParse(
                receipts ?? '',
              ) ??
              0;
    });
  }


  Future<void> _saveMonthlyPlanning({
    required double salary,
    required double receipts,
  }) async {
    await _storage.write(
      key:
          'expected_salary_$_monthStorageKey',
      value: salary.toString(),
    );

    await _storage.write(
      key:
          'expected_receipts_$_monthStorageKey',
      value: receipts.toString(),
    );

    if (!mounted) return;

    setState(() {
      _expectedSalary = salary;
      _expectedReceipts = receipts;
    });
  }


  Future<void> _openMonthlyPlanning() async {
    final result =
        await Navigator.of(context)
            .push<Map<String, double>>(
      MaterialPageRoute(
        builder: (_) =>
            MonthlyPlanningScreen(
          initialSalary:
              _expectedSalary,
          initialReceipts:
              _expectedReceipts,
          monthName:
              '$_selectedMonthName '
              '${_selectedMonth.year}',
        ),
      ),
    );

    if (result == null ||
        !mounted) {
      return;
    }

    await _saveMonthlyPlanning(
      salary:
          result['salary'] ?? 0,
      receipts:
          result['receipts'] ?? 0,
    );
  }


  Future<void> _openMonthlyCalculation(
    MonthlyCalculationType type,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MonthlyCalculationDetailScreen(
          month: _selectedMonthKey,
          monthLabel: _selectedMonthLabel,
          type: type,
        ),
      ),
    );
  }


  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _refreshMessage = null;
    });

    try {
      await _financeService.refresh();
      await _loadSummary();

      if (!mounted) return;

      setState(() {
        _refreshMessage =
            'Dados atualizados';
        _refreshIsError = false;
      });

      Future.delayed(
        const Duration(seconds: 3),
        () {
          if (!mounted) return;

          setState(() {
            _refreshMessage = null;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _refreshMessage =
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );
        _refreshIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }


  Future<void> _handleConnectAccount() async {
    final connected =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const ConnectBankScreen(),
      ),
    );

    if (connected == true) {
      await _loadSummary();
    }
  }


  double get _totalAccountBalance {
    double total = 0;

    for (final account in _accounts) {
      if (account['type'] != 'BANK') {
        continue;
      }

      final balance = account['balance'];

      if (balance is num) {
        total += balance.toDouble();
      }
    }

    return total;
  }


  int get _bankAccountsCount =>
      _accounts
          .where(
            (account) =>
                account['type'] == 'BANK',
          )
          .length;


  double get _totalCreditCards {
    double total = 0;

    for (final account in _accounts) {
      if (account['type'] != 'CREDIT') {
        continue;
      }

      final balance = account['balance'];

      if (balance is num) {
        total += balance.toDouble();
      }
    }

    return total;
  }


  int get _creditCardsCount =>
      _accounts
          .where(
            (account) =>
                account['type'] == 'CREDIT',
          )
          .length;


  double get _totalInvestments {
    double total = 0;

    for (final investment
        in _investments) {
      final balance =
          investment['balance'];

      if (balance is num) {
        total += balance.toDouble();
      }
    }

    return total;
  }


  int get _investmentsCount =>
      _investments.length;


  double get _expectedIncome =>
      _expectedSalary +
      _expectedReceipts;


  double get _cardSelectedMonth =>
      _cardCommitmentsByMonth[
          _selectedMonthKey] ??
      0;


  double get _cashFlowSelectedMonth =>
      -(_monthlyCashFlowCommitment[_selectedMonthKey] ?? 0);


  double get _positiveCashFlowSelectedMonth =>
      _cashFlowSelectedMonth > 0
          ? _cashFlowSelectedMonth
          : 0;


  double get _negativeCashFlowSelectedMonth =>
      _cashFlowSelectedMonth < 0
          ? -_cashFlowSelectedMonth
          : 0;


  double get _receivableSelectedMonth =>
      _expectedIncome +
      _positiveCashFlowSelectedMonth;


  double get _committedSelectedMonth =>
      _cardSelectedMonth +
      _negativeCashFlowSelectedMonth;


  double get _availableSelectedMonth =>
      _expectedIncome +
      _cashFlowSelectedMonth -
      _cardSelectedMonth;


  String get _firstName {
    final name =
        _user?.name.trim();

    if (name == null ||
        name.isEmpty) {
      return '';
    }

    return name.split(' ').first;
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration:
              const BoxDecoration(
            gradient:
                AppTheme.backgroundGradient,
          ),
          child:
              const Center(
            child:
                CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    AppTheme.backgroundGradient,
              ),
            ),
          ),
          const Positioned(
            top: -120,
            right: -110,
            child: _HomeGlowOrb(
              size: 290,
              color: Color(
                0xFF9ED7CE,
              ),
            ),
          ),
          const Positioned(
            top: 310,
            left: -130,
            child: _HomeGlowOrb(
              size: 280,
              color: Color(
                0xFFB4CBE0,
              ),
            ),
          ),
          const Positioned(
            bottom: -120,
            right: -80,
            child: _HomeGlowOrb(
              size: 290,
              color: Color(
                0xFFC3E0D7,
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  36,
                ),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 26),
                  _buildAvailableMonthCard(),
                  const SizedBox(height: 14),
                  _buildSyncRow(),
                  if (_refreshMessage != null) ...[
                    const SizedBox(height: 10),
                    _buildRefreshFeedback(),
                  ],
                  const SizedBox(height: 16),
                  _buildExpectedIncomeCard(),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    'Seu dinheiro',
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialCard(
                    icon:
                        Icons.account_balance_wallet_rounded,
                    title:
                        'Saldo em contas',
                    value:
                        _totalAccountBalance,
                    subtitle:
                        _bankAccountsCount == 1
                            ? '1 conta conectada'
                            : '$_bankAccountsCount contas conectadas',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AccountsScreen(),
                        ),
                      );

                      if (mounted) {
                        await _loadSummary();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialCard(
                    icon:
                        Icons.show_chart_rounded,
                    title:
                        'Investimentos',
                    value:
                        _totalInvestments,
                    subtitle:
                        _investmentsCount == 1
                            ? '1 investimento'
                            : '$_investmentsCount investimentos',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const InvestmentsScreen(),
                        ),
                      );

                      if (mounted) {
                        await _loadSummary();
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    'Compromissos e fluxo do mês',
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialCard(
                    icon:
                        Icons.credit_card_rounded,
                    title:
                        'Cartões em $_selectedMonthName',
                    value:
                        _cardSelectedMonth,
                    subtitle:
                        'Calculado automaticamente pelas compras e parcelas',
                    automatic: true,
                    onTap: () {
                      _openMonthlyCalculation(
                        MonthlyCalculationType.creditCards,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialCard(
                    icon:
                        Icons.swap_vert_circle_rounded,
                    title:
                        'Fluxo de caixa em $_selectedMonthName',
                    value:
                        _cashFlowSelectedMonth,
                    subtitle:
                        'Entradas, saídas e aplicações ou resgates de investimentos',
                    automatic: true,
                    onTap: () {
                      _openMonthlyCalculation(
                        MonthlyCalculationType.pix,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialCard(
                    icon:
                        Icons.credit_card_rounded,
                    title:
                        'Dívida atual dos cartões',
                    value:
                        _totalCreditCards,
                    subtitle:
                        _creditCardsCount == 1
                            ? '1 cartão conectado'
                            : '$_creditCardsCount cartões conectados',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const CreditCardsScreen(),
                        ),
                      );

                      if (mounted) {
                        await _loadSummary();
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildConnectAccountButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $_firstName',
                style:
                    const TextStyle(
                  color:
                      AppTheme.inkSoft,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Sua vida financeira',
                style:
                    TextStyle(
                  color: AppTheme.ink,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        _buildHeaderAction(
          icon:
              _valuesVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
          tooltip:
              _valuesVisible
                  ? 'Ocultar valores'
                  : 'Mostrar valores',
          onTap:
              _toggleValuesVisibility,
        ),
        const SizedBox(width: 8),
        _buildHeaderAction(
          icon:
              Icons.person_outline_rounded,
          tooltip: 'Perfil',
          onTap: () async {
            if (_user == null) return;

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ProfileScreen(
                  user: _user!,
                  accounts: _accounts,
                  valuesVisible:
                      _valuesVisible,
                  onValuesVisibilityChanged:
                      _setValuesVisibility,
                  onConnectionChanged:
                      _loadSummary,
                ),
              ),
            );

            if (mounted) {
              await _loadSummary();
            }
          },
        ),
      ],
    );
  }


  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required Future<void> Function() onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),
          child: Material(
            color:
                Colors.white.withValues(
              alpha: 0.58,
            ),
            child: InkWell(
              onTap: () {
                onTap();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  border:
                      Border.all(
                    color:
                        Colors.white.withValues(
                      alpha: 0.76,
                    ),
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAvailableMonthCard() {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            22,
          ),
          decoration:
              BoxDecoration(
            gradient:
                AppTheme.premiumGradient,
            borderRadius:
                BorderRadius.circular(30),
            border: Border.all(
              color:
                  Colors.white.withValues(
                alpha: 0.16,
              ),
            ),
            boxShadow:
                AppTheme.floatingShadow,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildMonthArrow(
                    icon:
                        Icons.chevron_left_rounded,
                    onTap:
                        _previousMonth,
                  ),
                  Expanded(
                    child: Text(
                      '$_selectedMonthName '
                      '${_selectedMonth.year}',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white.withValues(
                          alpha: 0.85,
                        ),
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildMonthArrow(
                    icon:
                        Icons.chevron_right_rounded,
                    onTap: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Disponível no mês',
                style: TextStyle(
                  color:
                      Colors.white.withValues(
                    alpha: 0.68,
                  ),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              _animatedMoney(
                value:
                    _availableSelectedMonth,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 33,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(19),
                  border: Border.all(
                    color:
                        Colors.white.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          _buildAvailableDetail(
                        label: 'A receber',
                        value:
                            _receivableSelectedMonth,
                      ),
                    ),
                    Container(
                      height: 38,
                      width: 1,
                      color:
                          Colors.white.withValues(
                        alpha: 0.15,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child:
                          _buildAvailableDetail(
                        label: 'Comprometido',
                        value:
                            _committedSelectedMonth,
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


  Widget _buildMonthArrow({
    required IconData icon,
    required Future<void> Function() onTap,
  }) {
    return Material(
      color:
          Colors.white.withValues(
        alpha: 0.08,
      ),
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius:
            BorderRadius.circular(12),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            color:
                Colors.white.withValues(
              alpha: 0.85,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAvailableDetail({
    required String label,
    required double value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                Colors.white.withValues(
              alpha: 0.60,
            ),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 5),
        _animatedMoney(
          value: value,
          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }


  Widget _buildSyncRow() {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.white.withValues(
              alpha: 0.48,
            ),
            borderRadius:
                BorderRadius.circular(30),
            border: Border.all(
              color:
                  Colors.white.withValues(
                alpha: 0.70,
              ),
            ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration:
                    const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                formatUpdatedAt(_updatedAt),
                style:
                    const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.inkSoft,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Material(
          color:
              Colors.white.withValues(
            alpha: 0.50,
          ),
          borderRadius:
              BorderRadius.circular(14),
          child: InkWell(
            onTap:
                _isRefreshing
                    ? null
                    : _handleRefresh,
            borderRadius:
                BorderRadius.circular(14),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child:
                    _isRefreshing
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color:
                                AppTheme.primary,
                          ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildExpectedIncomeCard() {
    return _GlassSurface(
      radius: 23,
      onTap: _openMonthlyPlanning,
      child: Padding(
        padding:
            const EdgeInsets.all(17),
        child: Row(
          children: [
            _buildIconBubble(
              icon:
                  Icons.payments_rounded,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Salário esperado + recebimentos',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedMonthName,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.inkSoft,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _animatedMoney(
                    value:
                        _expectedIncome,
                    style:
                        const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _valuesVisible
                        ? 'Salário ${formatCurrency(_expectedSalary)}  •  Outros ${formatCurrency(_expectedReceipts)}'
                        : 'Salário ••••••  •  Outros ••••••',
                    style:
                        const TextStyle(
                      color:
                          AppTheme.inkSoft,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.primary.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child:
                  const Icon(
                Icons.edit_rounded,
                size: 17,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFinancialCard({
    required IconData icon,
    required String title,
    required double value,
    required String subtitle,
    required VoidCallback onTap,
    bool automatic = false,
  }) {
    return _GlassSurface(
      radius: 23,
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),
        child: Row(
          children: [
            _buildIconBubble(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style:
                              const TextStyle(
                            color:
                                AppTheme.inkSoft,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      if (automatic) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                AppTheme.success.withValues(
                              alpha: 0.09,
                            ),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child:
                              const Text(
                            'AUTO',
                            style: TextStyle(
                              color:
                                  AppTheme.success,
                              fontSize: 8.5,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  _animatedMoney(
                    value: value,
                    style:
                        const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          AppTheme.inkSoft.withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.primary.withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child:
                  const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildIconBubble({
    required IconData icon,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration:
          BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(
              alpha: 0.13,
            ),
            AppTheme.primaryLight.withValues(
              alpha: 0.07,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.75,
          ),
        ),
      ),
      child: Icon(
        icon,
        color: AppTheme.primary,
        size: 22,
      ),
    );
  }


  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 3),
      child: Text(
        title.toUpperCase(),
        style:
            const TextStyle(
          color: AppTheme.inkSoft,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }


  Widget _buildRefreshFeedback() {
    final color =
        _refreshIsError
            ? AppTheme.danger
            : AppTheme.success;

    return _GlassSurface(
      radius: 15,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        child: Row(
          children: [
            Icon(
              _refreshIsError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _refreshMessage!,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildConnectAccountButton() {
    return _GlassSurface(
      radius: 20,
      onTap: _handleConnectAccount,
      child: const Padding(
        padding:
            EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 15,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: AppTheme.primary,
              size: 21,
            ),
            SizedBox(width: 8),
            Text(
              'Conectar instituição',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _GlassSurface
    extends StatelessWidget {
  final Widget child;
  final double radius;
  final VoidCallback? onTap;

  const _GlassSurface({
    required this.child,
    this.radius = 22,
    this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color:
              Colors.white.withValues(
            alpha: 0.62,
          ),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(radius),
                border: Border.all(
                  color:
                      Colors.white.withValues(
                    alpha: 0.76,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(
                      alpha: 0.025,
                    ),
                    blurRadius: 22,
                    offset:
                        const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}


class _HomeGlowOrb
    extends StatelessWidget {
  final double size;
  final Color color;

  const _HomeGlowOrb({
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
        sigmaX: 60,
        sigmaY: 60,
      ),
      child: Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(
          shape: BoxShape.circle,
          color:
              color.withValues(
            alpha: 0.26,
          ),
        ),
      ),
    );
  }
}
