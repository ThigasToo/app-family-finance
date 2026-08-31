import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'profile_screen.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

import 'accounts_screen.dart';
import 'investments_screen.dart';
import 'credit_cards_screen.dart';
import 'connect_bank_screen.dart';
import 'login_screen.dart';
import 'monthly_planning_screen.dart';


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

  final _storage =
      const FlutterSecureStorage();

  // =========================================================
  // ESTADO
  // =========================================================

  AppUser? _user;

  bool _isLoading = true;
  bool _isRefreshing = false;

  bool _valuesVisible = true;

  String? _refreshMessage;
  bool _refreshIsError = false;

  List<dynamic> _accounts = [];
  List<dynamic> _investments = [];

  String? _updatedAt;

  // =========================================================
  // PLANEJAMENTO
  // =========================================================

  double _expectedSalary = 0;
  double _expectedReceipts = 0;

  double _manualPixSelectedMonth = 0;

  Map<String, double>
      _manualCardAllocations = {};

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  static const String
      _cardAllocationsStorageKey =
      'manual_card_allocations';

  static const String
      _privacyStorageKey =
      'home_values_visible';

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _initializeHome();
  }

  Future<void> _initializeHome() async {
    await _loadPrivacyPreference();
    await _loadMonthlyPlanning();
    await _loadCardAllocations();
    await _loadManualPix();
    await _loadUserAndSummary();
  }

  // =========================================================
  // PRIVACIDADE
  // =========================================================

  Future<void>
      _loadPrivacyPreference() async {
    final saved = await _storage.read(
      key: _privacyStorageKey,
    );

    if (!mounted) return;

    setState(() {
      _valuesVisible =
          saved == null
              ? true
              : saved == 'true';
    });
  }

  Future<void>
      _toggleValuesVisibility() async {
    final newValue =
        !_valuesVisible;

    setState(() {
      _valuesVisible = newValue;
    });

    await _storage.write(
      key: _privacyStorageKey,
      value: newValue.toString(),
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
    final text =
        _money(value);

    return AnimatedSwitcher(
      duration:
          const Duration(
        milliseconds: 180,
      ),
      transitionBuilder: (
        child,
        animation,
      ) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Text(
        text,
        key: ValueKey(
          '${_valuesVisible}_$text',
        ),
        textAlign: textAlign,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  // =========================================================
  // USER
  // =========================================================

  Future<void>
      _loadUserAndSummary() async {
    final user =
        await _authService
            .getCurrentUser();

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

    setState(() {
      _user = user;
    });

    await _loadSummary();
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Future<void>
      _loadSummary() async {
    try {
      final summary =
          await _financeService
              .getSummary();

      final payload =
          summary['payload'] ?? {};

      if (!mounted) return;

      setState(() {
        _accounts =
            payload['accounts'] ??
                [];

        _investments =
            payload[
                    'investments'] ??
                [];

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

  // =========================================================
  // MÊS
  // =========================================================

  String get _monthStorageKey {
    final month =
        _selectedMonth.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '${_selectedMonth.year}_$month';
  }

  String get _selectedMonthKey {
    final month =
        _selectedMonth.month
            .toString()
            .padLeft(
              2,
              '0',
            );

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

  // =========================================================
  // SALÁRIO
  // =========================================================

  Future<void>
      _loadMonthlyPlanning() async {
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

  Future<void>
      _saveMonthlyPlanning({
    required double salary,
    required double receipts,
  }) async {
    await _storage.write(
      key:
          'expected_salary_$_monthStorageKey',
      value:
          salary.toString(),
    );

    await _storage.write(
      key:
          'expected_receipts_$_monthStorageKey',
      value:
          receipts.toString(),
    );

    if (!mounted) return;

    setState(() {
      _expectedSalary =
          salary;

      _expectedReceipts =
          receipts;
    });
  }

  Future<void>
      _openMonthlyPlanning() async {
    final result =
        await Navigator.of(context)
            .push<
                Map<String, double>>(
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
          result['receipts'] ??
              0,
    );
  }

  // =========================================================
  // CARTÕES MANUAIS
  // =========================================================

  Future<void>
      _loadCardAllocations() async {
    final raw =
        await _storage.read(
      key:
          _cardAllocationsStorageKey,
    );

    if (raw == null ||
        raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! Map) {
        return;
      }

      final allocations =
          <String, double>{};

      decoded.forEach(
        (key, value) {
          final parsed =
              value is num
                  ? value
                      .toDouble()
                  : double.tryParse(
                        value.toString(),
                      ) ??
                      0;

          allocations[
                  key.toString()] =
              parsed;
        },
      );

      if (!mounted) return;

      setState(() {
        _manualCardAllocations =
            allocations;
      });
    } catch (_) {}
  }

  Future<void>
      _saveCardAllocations() async {
    await _storage.write(
      key:
          _cardAllocationsStorageKey,
      value:
          jsonEncode(
        _manualCardAllocations,
      ),
    );
  }

  Future<void>
      _editCardAllocation() async {
    final current =
        _cardAllocatedSelectedMonth;

    final controller =
        TextEditingController(
      text:
          current > 0
              ? current
                  .toStringAsFixed(
                    2,
                  )
                  .replaceAll(
                    '.',
                    ',',
                  )
              : '',
    );

    final result =
        await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Cartão em '
            '$_selectedMonthName '
            '${_selectedMonth.year}',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                'Dívida total dos cartões',
                style: TextStyle(
                  color:
                      AppTheme.inkSoft,
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                _money(
                  _totalCreditCards,
                ),
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'Já alocado: '
                '${_money(_totalCardAllocated)}',
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                'Ainda não alocado: '
                '${_money(_unallocatedCardDebt)}',
              ),
              const SizedBox(
                height: 22,
              ),
              TextField(
                controller:
                    controller,
                autofocus: true,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'Valor para este mês',
                  prefixText:
                      'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                final parsed =
                    _parseMoney(
                  controller.text,
                );

                Navigator.pop(
                  context,
                  parsed,
                );
              },
              child:
                  const Text(
                'Salvar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null ||
        !mounted) {
      return;
    }

    final currentAllocation =
        _cardAllocatedSelectedMonth;

    final availableForThisMonth =
        _unallocatedCardDebt +
            currentAllocation;

    if (result >
        availableForThisMonth +
            0.01) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'O valor excede o '
            'disponível para alocação: '
            '${_money(availableForThisMonth)}',
          ),
        ),
      );

      return;
    }

    setState(() {
      if (result <= 0) {
        _manualCardAllocations
            .remove(
          _selectedMonthKey,
        );
      } else {
        _manualCardAllocations[
                _selectedMonthKey] =
            result;
      }
    });

    await _saveCardAllocations();
  }

  // =========================================================
  // PIX MANUAL
  // =========================================================

  String get _manualPixStorageKey {
    return 'manual_pix_$_monthStorageKey';
  }

  Future<void>
      _loadManualPix() async {
    final raw =
        await _storage.read(
      key:
          _manualPixStorageKey,
    );

    if (!mounted) return;

    setState(() {
      _manualPixSelectedMonth =
          double.tryParse(
                raw ?? '',
              ) ??
              0;
    });
  }

  Future<void> _saveManualPix(
    double value,
  ) async {
    await _storage.write(
      key:
          _manualPixStorageKey,
      value:
          value.toString(),
    );

    if (!mounted) return;

    setState(() {
      _manualPixSelectedMonth =
          value;
    });
  }

  Future<void>
      _editManualPix() async {
    final controller =
        TextEditingController(
      text:
          _manualPixSelectedMonth >
                  0
              ? _manualPixSelectedMonth
                  .toStringAsFixed(
                    2,
                  )
                  .replaceAll(
                    '.',
                    ',',
                  )
              : '',
    );

    final result =
        await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'PIX em '
            '$_selectedMonthName '
            '${_selectedMonth.year}',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Text(
                'Informe o total de PIX '
                'enviados que deseja '
                'considerar neste mês.',
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller:
                    controller,
                autofocus: true,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'PIX enviados no mês',
                  prefixText:
                      'R\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _parseMoney(
                    controller.text,
                  ),
                );
              },
              child:
                  const Text(
                'Salvar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null ||
        !mounted) {
      return;
    }

    await _saveManualPix(
      result,
    );
  }

  double _parseMoney(
    String raw,
  ) {
    var text =
        raw
            .trim()
            .replaceAll(
              'R\$',
              '',
            )
            .replaceAll(
              ' ',
              '',
            );

    if (text.contains(',') &&
        text.contains('.')) {
      text = text
          .replaceAll(
            '.',
            '',
          )
          .replaceAll(
            ',',
            '.',
          );
    } else if (text.contains(',')) {
      text =
          text.replaceAll(
        ',',
        '.',
      );
    }

    return double.tryParse(
          text,
        ) ??
        0;
  }

  // =========================================================
  // NAVEGAÇÃO DE MESES
  // =========================================================

  Future<void>
      _previousMonth() async {
    setState(() {
      _selectedMonth =
          DateTime(
        _selectedMonth.year,
        _selectedMonth.month -
            1,
      );
    });

    await _loadMonthlyPlanning();
    await _loadManualPix();
  }

  Future<void>
      _nextMonth() async {
    setState(() {
      _selectedMonth =
          DateTime(
        _selectedMonth.year,
        _selectedMonth.month +
            1,
      );
    });

    await _loadMonthlyPlanning();
    await _loadManualPix();
  }

  // =========================================================
  // ATUALIZAR
  // =========================================================

  Future<void>
      _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
      _refreshMessage = null;
    });

    try {
      await _financeService
          .refresh();

      await _loadSummary();

      if (!mounted) return;

      setState(() {
        _refreshMessage =
            'Dados atualizados';
        _refreshIsError =
            false;
      });

      Future.delayed(
        const Duration(
          seconds: 3,
        ),
        () {
          if (!mounted) return;

          setState(() {
            _refreshMessage =
                null;
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

        _refreshIsError =
            true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing =
              false;
        });
      }
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void>
      _handleLogout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.of(context)
        .pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
    );
  }

  // =========================================================
  // CONEXÃO
  // =========================================================

  Future<void>
      _handleConnectAccount() async {
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

  // =========================================================
  // TOTAIS
  // =========================================================

  double get _totalAccountBalance {
    double total = 0;

    for (final account
        in _accounts) {
      if (account['type'] !=
          'BANK') {
        continue;
      }

      final balance =
          account['balance'];

      if (balance is num) {
        total +=
            balance.toDouble();
      }
    }

    return total;
  }

  int get _bankAccountsCount =>
      _accounts
          .where(
            (account) =>
                account['type'] ==
                'BANK',
          )
          .length;

  double get _totalCreditCards {
    double total = 0;

    for (final account
        in _accounts) {
      if (account['type'] !=
          'CREDIT') {
        continue;
      }

      final balance =
          account['balance'];

      if (balance is num) {
        total +=
            balance.toDouble();
      }
    }

    return total;
  }

  int get _creditCardsCount =>
      _accounts
          .where(
            (account) =>
                account['type'] ==
                'CREDIT',
          )
          .length;

  double get
      _cardAllocatedSelectedMonth {
    return _manualCardAllocations[
            _selectedMonthKey] ??
        0;
  }

  double get _totalCardAllocated {
    return _manualCardAllocations
        .values
        .fold(
          0.0,
          (
            total,
            value,
          ) =>
              total + value,
        );
  }

  double get _unallocatedCardDebt {
    final remaining =
        _totalCreditCards -
            _totalCardAllocated;

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }

  double get _totalInvestments {
    double total = 0;

    for (final investment
        in _investments) {
      final balance =
          investment['balance'];

      if (balance is num) {
        total +=
            balance.toDouble();
      }
    }

    return total;
  }

  int get _investmentsCount =>
      _investments.length;

  double get _expectedIncome =>
      _expectedSalary +
      _expectedReceipts;

  double get
      _committedSelectedMonth =>
          _cardAllocatedSelectedMonth +
          _manualPixSelectedMonth;

  double get
      _availableSelectedMonth =>
          _expectedIncome -
          _committedSelectedMonth;

  String get _firstName {
    final name =
        _user?.name.trim();

    if (name == null ||
        name.isEmpty) {
      return '';
    }

    return name
        .split(' ')
        .first;
  }

  // =========================================================
  // BUILD
  // =========================================================

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
                AppTheme
                    .backgroundGradient,
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
                    AppTheme
                        .backgroundGradient,
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
            child:
                RefreshIndicator(
              onRefresh:
                  _loadSummary,
              child:
                  ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  20,
                  18,
                  20,
                  36,
                ),
                children: [
                  _buildHeader(),

                  const SizedBox(
                    height: 26,
                  ),

                  _buildAvailableMonthCard(),

                  const SizedBox(
                    height: 14,
                  ),

                  _buildSyncRow(),

                  if (_refreshMessage !=
                      null) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    _buildRefreshFeedback(),
                  ],

                  const SizedBox(
                    height: 16,
                  ),

                  _buildExpectedIncomeCard(),

                  const SizedBox(
                    height: 30,
                  ),

                  _buildSectionTitle(
                    'Seu dinheiro',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildFinancialCard(
                    icon:
                        Icons
                            .account_balance_wallet_rounded,
                    title:
                        'Saldo em contas',
                    value:
                        _totalAccountBalance,
                    subtitle:
                        _bankAccountsCount ==
                                1
                            ? '1 conta conectada'
                            : '$_bankAccountsCount contas conectadas',
                    onTap:
                        () async {
                      await Navigator.of(
                        context,
                      ).push(
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

                  const SizedBox(
                    height: 12,
                  ),

                  _buildFinancialCard(
                    icon:
                        Icons
                            .show_chart_rounded,
                    title:
                        'Investimentos',
                    value:
                        _totalInvestments,
                    subtitle:
                        _investmentsCount ==
                                1
                            ? '1 investimento'
                            : '$_investmentsCount investimentos',
                    onTap:
                        () async {
                      await Navigator.of(
                        context,
                      ).push(
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

                  const SizedBox(
                    height: 30,
                  ),

                  _buildSectionTitle(
                    'Compromissos',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildFinancialCard(
                    icon:
                        Icons
                            .credit_card_rounded,
                    title:
                        'Cartões',
                    value:
                        _totalCreditCards,
                    subtitle:
                        _creditCardsCount ==
                                1
                            ? '1 cartão conectado'
                            : '$_creditCardsCount cartões conectados',
                    onTap:
                        () async {
                      await Navigator.of(
                        context,
                      ).push(
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

                  const SizedBox(
                    height: 12,
                  ),

                  _buildFinancialCard(
                    icon:
                        Icons
                            .calendar_month_rounded,
                    title:
                        'Cartão em $_selectedMonthName',
                    value:
                        _cardAllocatedSelectedMonth,
                    subtitle:
                        _valuesVisible
                            ? 'Restam ${formatCurrency(_unallocatedCardDebt)} para alocar'
                            : 'Restam •••••• para alocar',
                    onTap:
                        _editCardAllocation,
                    editable: true,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildFinancialCard(
                    icon:
                        Icons
                            .pix_rounded,
                    title:
                        'PIX em $_selectedMonthName',
                    value:
                        _manualPixSelectedMonth,
                    subtitle:
                        'Toque para informar o total do mês',
                    onTap:
                        _editManualPix,
                    editable: true,
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  _buildConnectAccountButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

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
              style: const TextStyle(
                color: AppTheme.inkSoft,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            const Text(
              'Sua vida financeira',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ],
        ),
      ),

      _buildHeaderAction(
        icon:
            Icons.person_outline_rounded,
        tooltip:
            'Perfil',
        onTap: () async {
          if (_user == null) {
            return;
          }

          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ProfileScreen(
                user: _user!,
                accounts: _accounts,
                valuesVisible:
                    _valuesVisible,

                onValuesVisibilityChanged:
                    (value) async {
                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _valuesVisible =
                        value;
                  });

                  await _storage.write(
                    key:
                        _privacyStorageKey,
                    value:
                        value.toString(),
                  );
                },

                onConnectionChanged:
                    () async {
                  await _loadSummary();
                },
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
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),
          child: Material(
            color:
                Colors.white
                    .withValues(
              alpha: 0.58,
            ),
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  border:
                      Border.all(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.76,
                    ),
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child:
                    AnimatedSwitcher(
                  duration:
                      const Duration(
                    milliseconds:
                        180,
                  ),
                  child: Icon(
                    icon,
                    key:
                        ValueKey(icon),
                    size: 21,
                    color:
                        AppTheme.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CARD PRINCIPAL
  // =========================================================

  Widget
      _buildAvailableMonthCard() {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        30,
      ),
      child: BackdropFilter(
        filter:
            ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding:
              const EdgeInsets
                  .fromLTRB(
            22,
            18,
            22,
            22,
          ),
          decoration:
              BoxDecoration(
            gradient:
                AppTheme
                    .premiumGradient,
            borderRadius:
                BorderRadius.circular(
              30,
            ),
            border:
                Border.all(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.16,
              ),
            ),
            boxShadow:
                AppTheme
                    .floatingShadow,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                children: [
                  _buildMonthArrow(
                    icon:
                        Icons
                            .chevron_left_rounded,
                    onTap:
                        _previousMonth,
                  ),

                  Expanded(
                    child: Text(
                      '$_selectedMonthName '
                      '${_selectedMonth.year}',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            Colors.white
                                .withValues(
                          alpha:
                              0.85,
                        ),
                        fontSize:
                            14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  _buildMonthArrow(
                    icon:
                        Icons
                            .chevron_right_rounded,
                    onTap:
                        _nextMonth,
                  ),
                ],
              ),

              const SizedBox(
                height: 22,
              ),

              Text(
                'Disponível no mês',
                style: TextStyle(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.68,
                  ),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              _animatedMoney(
                value:
                    _availableSelectedMonth,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 33,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      -1,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    19,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          _buildAvailableDetail(
                        label:
                            'A receber',
                        value:
                            _expectedIncome,
                      ),
                    ),

                    Container(
                      height: 38,
                      width: 1,
                      color:
                          Colors.white
                              .withValues(
                        alpha: 0.15,
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child:
                          _buildAvailableDetail(
                        label:
                            'Comprometido',
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
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          Colors.white
              .withValues(
        alpha: 0.08,
      ),
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            color:
                Colors.white
                    .withValues(
              alpha: 0.85,
            ),
          ),
        ),
      ),
    );
  }

  Widget
      _buildAvailableDetail({
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
                Colors.white
                    .withValues(
              alpha: 0.60,
            ),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        _animatedMoney(
          value: value,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 14.5,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SYNC
  // =========================================================

  Widget _buildSyncRow() {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.white
                    .withValues(
              alpha: 0.48,
            ),
            borderRadius:
                BorderRadius.circular(
              30,
            ),
            border:
                Border.all(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.70,
              ),
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
                  shape:
                      BoxShape.circle,
                  color:
                      AppTheme.success,
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              Text(
                formatUpdatedAt(
                  _updatedAt,
                ),
                style: TextStyle(
                  fontSize: 11.5,
                  color:
                      AppTheme.inkSoft,
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
              Colors.white
                  .withValues(
            alpha: 0.50,
          ),
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          child: InkWell(
            onTap:
                _isRefreshing
                    ? null
                    : _handleRefresh,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
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
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .refresh_rounded,
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

  // =========================================================
  // SALÁRIO
  // =========================================================

  Widget
      _buildExpectedIncomeCard() {
    return _GlassSurface(
      radius: 23,
      onTap:
          _openMonthlyPlanning,
      child: Padding(
        padding:
            const EdgeInsets.all(
          17,
        ),
        child: Row(
          children: [
            _buildIconBubble(
              icon:
                  Icons
                      .payments_rounded,
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'Salário esperado + recebimentos',
                    style:
                        const TextStyle(
                      color:
                          AppTheme.ink,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    _selectedMonthName,
                    style: TextStyle(
                      color:
                          AppTheme.inkSoft,
                      fontSize: 11.5,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  _animatedMoney(
                    value:
                        _expectedIncome,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.ink,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    _valuesVisible
                        ? 'Salário ${formatCurrency(_expectedSalary)}  •  Outros ${formatCurrency(_expectedReceipts)}'
                        : 'Salário ••••••  •  Outros ••••••',
                    style: TextStyle(
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
                    AppTheme.primary
                        .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  const Icon(
                Icons.account_balance_wallet_rounded,
                size: 17,
                color:
                    AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FINANCIAL CARD
  // =========================================================

  Widget _buildFinancialCard({
    required IconData icon,
    required String title,
    required double value,
    required String subtitle,
    required VoidCallback onTap,
    bool editable = false,
  }) {
    return _GlassSurface(
      radius: 23,
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 17,
          vertical: 16,
        ),
        child: Row(
          children: [
            _buildIconBubble(
              icon: icon,
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          AppTheme.inkSoft,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  _animatedMoney(
                    value: value,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.ink,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing:
                          -0.4,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style: TextStyle(
                      color:
                          AppTheme.inkSoft
                              .withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.primary
                        .withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                editable
                    ? Icons
                        .edit_rounded
                    : Icons
                        .chevron_right_rounded,
                color:
                    AppTheme.primary,
                size:
                    editable
                        ? 17
                        : 22,
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
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            AppTheme.primary
                .withValues(
              alpha: 0.13,
            ),
            AppTheme.primaryLight
                .withValues(
              alpha: 0.07,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              Colors.white
                  .withValues(
            alpha: 0.75,
          ),
        ),
      ),
      child: Icon(
        icon,
        color:
            AppTheme.primary,
        size: 22,
      ),
    );
  }

  // =========================================================
  // SECTION
  // =========================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 3,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color:
              AppTheme.inkSoft,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Widget
      _buildRefreshFeedback() {
    final color =
        _refreshIsError
            ? AppTheme.danger
            : AppTheme.success;

    return _GlassSurface(
      radius: 15,
      child: Padding(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        child: Row(
          children: [
            Icon(
              _refreshIsError
                  ? Icons
                      .error_outline_rounded
                  : Icons
                      .check_circle_outline_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(
              width: 8,
            ),
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

  // =========================================================
  // CONECTAR
  // =========================================================

  Widget
      _buildConnectAccountButton() {
    return _GlassSurface(
      radius: 20,
      onTap:
          _handleConnectAccount,
      child: Padding(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 17,
          vertical: 15,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              color:
                  AppTheme.primary,
              size: 21,
            ),
            const SizedBox(
              width: 8,
            ),
            const Text(
              'Conectar instituição',
              style: TextStyle(
                color:
                    AppTheme.primary,
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


// ===========================================================
// GLASS SURFACE
// ===========================================================

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
          BorderRadius.circular(
        radius,
      ),
      child: BackdropFilter(
        filter:
            ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color:
              Colors.white
                  .withValues(
            alpha: 0.62,
          ),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  radius,
                ),
                border:
                    Border.all(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.76,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withValues(
                      alpha:
                          0.025,
                    ),
                    blurRadius: 22,
                    offset:
                        const Offset(
                      0,
                      8,
                    ),
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


// ===========================================================
// BACKGROUND GLOW
// ===========================================================

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
          shape:
              BoxShape.circle,
          color:
              color.withValues(
            alpha: 0.26,
          ),
        ),
      ),
    );
  }
}