import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'accounts_screen.dart';
import 'investments_screen.dart';
import 'connect_bank_screen.dart';
import 'login_screen.dart';
import 'monthly_planning_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final _authService = AuthService();

  final _financeService =
      FinanceService();

  final _storage =
      const FlutterSecureStorage();

  AppUser? _user;

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _refreshMessage;
  bool _refreshIsError = false;

  List<dynamic> _accounts = [];
  List<dynamic> _investments = [];

  String? _updatedAt;

  double _expectedSalary = 0;
  double _expectedReceipts = 0;

  @override
  void initState() {
    super.initState();

    _initializeHome();
  }

  // =========================================================
  // INICIALIZAÇÃO
  // =========================================================

  Future<void> _initializeHome() async {
    await _loadMonthlyPlanning();

    await _loadUserAndSummary();
  }

  Future<void>
      _loadUserAndSummary() async {
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

    setState(() {
      _user = user;
    });

    await _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary =
          await _financeService.getSummary();

      if (!mounted) return;

      setState(() {
        _accounts =
            summary['payload']
                    ?['accounts'] ??
                [];

        _investments =
            summary['payload']
                    ?['investments'] ??
                [];

        _updatedAt =
            summary['updated_at'];

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // PLANEJAMENTO MENSAL
  // =========================================================

  String get _monthStorageKey {
    final now = DateTime.now();

    final month = now.month
        .toString()
        .padLeft(2, '0');

    return '${now.year}_$month';
  }

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

  Future<void>
      _openMonthlyPlanning() async {
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
              _currentMonthName,
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

  // =========================================================
  // ATUALIZAÇÃO
  // =========================================================

  Future<void>
      _handleRefresh() async {
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
            'Atualizado com sucesso!';

        _refreshIsError = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _refreshMessage = e
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

  // =========================================================
  // LOGIN / CONEXÃO
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
  // CONTAS
  // =========================================================

  double get _totalAccountBalance {
    double total = 0;

    for (final account
        in _accounts) {
      if (account['type'] ==
          'BANK') {
        final balance =
            account['balance'];

        if (balance is num) {
          total +=
              balance.toDouble();
        }
      }
    }

    return total;
  }

  int get _bankAccountsCount {
    return _accounts
        .where(
          (account) =>
              account['type'] ==
              'BANK',
        )
        .length;
  }

  // =========================================================
  // CARTÕES
  // =========================================================

  double get _totalCreditCards {
    double total = 0;

    for (final account
        in _accounts) {
      if (account['type'] ==
          'CREDIT') {
        final balance =
            account['balance'];

        if (balance is num) {
          total +=
              balance.toDouble();
        }
      }
    }

    return total;
  }

  int get _creditCardsCount {
    return _accounts
        .where(
          (account) =>
              account['type'] ==
              'CREDIT',
        )
        .length;
  }

  // =========================================================
  // INVESTIMENTOS
  // =========================================================

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

  // =========================================================
  // PLANEJAMENTO DO MÊS
  // =========================================================

  double get _expectedIncome {
    return _expectedSalary +
        _expectedReceipts;
  }

  /// Será substituído pelos PIX
  /// efetivamente enviados no mês.
  double get _pixSentThisMonth {
    return 0;
  }

  double get _committedThisMonth {
    return _totalCreditCards +
        _pixSentThisMonth;
  }

  double get _availableThisMonth {
    return _expectedIncome -
        _committedThisMonth;
  }

  // =========================================================
  // DATA / USUÁRIO
  // =========================================================

  String get _currentMonthName {
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
        DateTime.now().month - 1];
  }

  String get _firstName {
    final name =
        _user?.name.trim();

    if (name == null ||
        name.isEmpty) {
      return '';
    }

    return name.split(' ').first;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              32,
            ),
            children: [
              _buildHeader(),

              const SizedBox(
                height: 28,
              ),

              _buildAvailableMonthCard(),

              const SizedBox(
                height: 16,
              ),

              _buildUpdateRow(),

              if (_refreshMessage !=
                  null) ...[
                const SizedBox(
                  height: 8,
                ),
                _buildRefreshFeedback(),
              ],

              const SizedBox(
                height: 16,
              ),

              _buildExpectedIncomeCard(),

              const SizedBox(
                height: 32,
              ),

              _buildSectionTitle(
                'Seu dinheiro',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildFinancialCard(
                icon: Icons
                    .account_balance_wallet_outlined,
                title:
                    'Saldo em contas',
                value:
                    _totalAccountBalance,
                subtitle:
                    _bankAccountsCount ==
                            1
                        ? '1 conta conectada'
                        : '$_bankAccountsCount contas conectadas',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AccountsScreen(),
                    ),
                  );

                  if (!mounted) return;

                  await _loadSummary();
                },
              ),

              const SizedBox(
                height: 12,
              ),

              _buildFinancialCard(
                icon: Icons
                    .trending_up_rounded,
                title: 'Investimentos',
                value:
                    _totalInvestments,
                subtitle:
                    _investmentsCount ==
                            1
                        ? '1 investimento'
                        : '$_investmentsCount investimentos',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const InvestmentsScreen(),
                    ),
                  );

                  if (!mounted) return;

                  await _loadSummary();
                },
              ),

              const SizedBox(
                height: 32,
              ),

              _buildSectionTitle(
                'Compromissos',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildFinancialCard(
                icon:
                    Icons.credit_card_rounded,
                title: 'Cartões',
                value:
                    _totalCreditCards,
                subtitle:
                    _creditCardsCount ==
                            1
                        ? '1 cartão'
                        : '$_creditCardsCount cartões',
                valueColor:
                    AppTheme.danger,
                onTap: () {
                  _showComingSoon(
                    'Cartões',
                  );
                },
              ),

              const SizedBox(
                height: 32,
              ),

              _buildConnectAccountButton(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $_firstName',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors
                      .grey.shade600,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              const Text(
                'Sua vida financeira',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.1,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed:
              _showAccountMenu,
          icon: const Icon(
            Icons
                .account_circle_outlined,
          ),
          iconSize: 28,
          tooltip: 'Perfil',
        ),
      ],
    );
  }

  // =========================================================
  // DISPONÍVEL NO MÊS
  // =========================================================

  Widget
      _buildAvailableMonthCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            const Color(0xFF315B78),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Disponível neste mês de $_currentMonthName',
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.78,
              ),
              fontSize: 14,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            formatCurrency(
              _availableThisMonth,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildAvailableDetail(
                  label: 'A receber',
                  value:
                      _expectedIncome,
                ),
              ),

              Container(
                width: 1,
                height: 40,
                color: Colors.white
                    .withValues(
                  alpha: 0.20,
                ),
              ),

              const SizedBox(
                width: 20,
              ),

              Expanded(
                child:
                    _buildAvailableDetail(
                  label: 'Comprometido',
                  value:
                      _committedThisMonth,
                ),
              ),
            ],
          ),
        ],
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
            color: Colors.white
                .withValues(
              alpha: 0.65,
            ),
            fontSize: 12,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          formatCurrency(value),
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SALÁRIO + RECEBIMENTOS
  // =========================================================

  Widget
      _buildExpectedIncomeCard() {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap:
            _openMonthlyPlanning,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
                  Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary
                      .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons
                      .payments_outlined,
                  color:
                      AppTheme.primary,
                  size: 21,
                ),
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
                    const Text(
                      'Salário esperado + Recebimentos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      formatCurrency(
                        _expectedIncome,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Salário ${formatCurrency(_expectedSalary)}'
                      '  •  Outros ${formatCurrency(_expectedReceipts)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors
                            .grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Icon(
                Icons.edit_outlined,
                color:
                    Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CARDS
  // =========================================================

  Widget _buildFinancialCard({
    required IconData icon,
    required String title,
    required double value,
    required String subtitle,
    required VoidCallback onTap,
    Color? valueColor,
  }) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color:
                  Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary
                      .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      AppTheme.primary,
                  size: 23,
                ),
              ),

              const SizedBox(
                width: 16,
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
                        fontSize: 14,
                        color: Colors
                            .grey.shade700,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      formatCurrency(
                        value,
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .w800,
                        letterSpacing:
                            -0.3,
                        color:
                            valueColor,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    Colors.grey.shade400,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TÍTULO
  // =========================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight:
            FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  // =========================================================
  // ATUALIZAÇÃO
  // =========================================================

  Widget _buildUpdateRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            formatUpdatedAt(
              _updatedAt,
            ),
            style: TextStyle(
              color:
                  Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ),

        TextButton.icon(
          onPressed: _isRefreshing
              ? null
              : _handleRefresh,
          icon: _isRefreshing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons
                      .refresh_rounded,
                  size: 18,
                ),
          label:
              const Text('Atualizar'),
        ),
      ],
    );
  }

  Widget
      _buildRefreshFeedback() {
    final color =
        _refreshIsError
            ? AppTheme.danger
            : AppTheme.primary;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _refreshIsError
                ? Icons.error_outline
                : Icons
                    .check_circle_outline,
            color: color,
            size: 18,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              _refreshMessage!,
              style: TextStyle(
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CONECTAR INSTITUIÇÃO
  // =========================================================

  Widget
      _buildConnectAccountButton() {
    return OutlinedButton.icon(
      onPressed:
          _handleConnectAccount,
      icon: const Icon(
        Icons.add_rounded,
        size: 20,
      ),
      label: const Text(
        'Conectar instituição',
      ),
      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            AppTheme.primary,
        minimumSize:
            const Size.fromHeight(
          52,
        ),
        side: BorderSide(
          color: AppTheme.primary
              .withValues(
            alpha: 0.25,
          ),
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PERFIL
  // =========================================================

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      const Icon(
                    Icons
                        .link_rounded,
                  ),
                  title: const Text(
                    'Conectar instituição',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _handleConnectAccount();
                  },
                ),

                ListTile(
                  leading:
                      const Icon(
                    Icons
                        .logout_rounded,
                  ),
                  title:
                      const Text(
                    'Sair',
                  ),
                  textColor:
                      AppTheme.danger,
                  iconColor:
                      AppTheme.danger,
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _handleLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // TEMPORÁRIO
  // =========================================================

  void _showComingSoon(
    String section,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$section será a próxima tela que vamos construir.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}