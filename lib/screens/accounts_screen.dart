import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

import 'institution_accounts_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
  });

  @override
  State<AccountsScreen> createState() =>
      _AccountsScreenState();
}

class _AccountsScreenState
    extends State<AccountsScreen> {
  final _financeService =
      FinanceService();

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();

    _loadAccounts();
  }

  // =========================================================
  // CARREGAMENTO
  // =========================================================

  Future<void> _loadAccounts() async {
    try {
      final summary =
          await _financeService
              .getSummary();

      final allAccounts =
          summary['payload']
                  ?['accounts'] ??
              [];

      final bankAccounts =
          List<dynamic>.from(
        allAccounts,
      ).where(
        (account) =>
            account['type']
                ?.toString()
                .toUpperCase() ==
            'BANK',
      ).toList();

      if (!mounted) return;

      setState(() {
        _accounts = bankAccounts;

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage =
            'Não foi possível carregar suas contas.';
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _financeService
          .refresh();

      await _loadAccounts();
    } catch (_) {
      await _loadAccounts();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // =========================================================
  // TOTAL
  // =========================================================

  double get _totalBalance {
    double total = 0;

    for (final account
        in _accounts) {
      total += _getAccountBalance(
        account,
      );
    }

    return total;
  }

  // =========================================================
  // AGRUPAMENTO
  // =========================================================

  List<AccountInstitution>
      get _institutions {
    final Map<
            String,
            AccountInstitution>
        grouped = {};

    for (final account
        in _accounts) {
      final institutionName =
          _getInstitutionName(
        account,
      );

      final balance =
          _getAccountBalance(
        account,
      );

      if (!grouped.containsKey(
        institutionName,
      )) {
        grouped[
            institutionName] =
            AccountInstitution(
          name: institutionName,
          totalBalance: 0,
          accounts: [],
        );
      }

      grouped[
              institutionName]!
          .totalBalance +=
          balance;

      grouped[
              institutionName]!
          .accounts
          .add(account);
    }

    final institutions =
        grouped.values.toList();

    institutions.sort(
      (a, b) =>
          b.totalBalance
              .compareTo(
        a.totalBalance,
      ),
    );

    return institutions;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _getAccountBalance(
    dynamic account,
  ) {
    final balance =
        account['balance'];

    if (balance is num) {
      return balance.toDouble();
    }

    return double.tryParse(
          balance?.toString() ??
              '',
        ) ??
        0;
  }

  String _getInstitutionName(
    dynamic account,
  ) {
    final candidates = [
      account[
          'institution_name'],
      account[
          'resolved_institution'],
      account['institution'],
      account[
          'institutionName'],
    ];

    for (final value
        in candidates) {
      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }

    return 'Outros';
  }

  // =========================================================
  // ABRIR INSTITUIÇÃO
  // =========================================================

  Future<void>
      _openInstitution(
    AccountInstitution
        institution,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            InstitutionAccountsScreen(
          institutionName:
              institution.name,
          accounts:
              institution.accounts,
        ),
      ),
    );

    if (!mounted) return;

    // Ao retornar, buscamos o summary
    // novamente para manter os valores
    // sincronizados.
    await _loadAccounts();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Contas',
        ),
        actions: [
          IconButton(
            tooltip:
                'Atualizar',
            onPressed:
                _isRefreshing
                    ? null
                    : _refresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons
                        .refresh_rounded,
                  ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh:
          _loadAccounts,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32,
        ),
        children: [
          _buildSummaryCard(),

          const SizedBox(
            height: 30,
          ),

          _buildSectionHeader(),

          const SizedBox(
            height: 12,
          ),

          if (_institutions.isEmpty)
            _buildEmptyState()
          else
            ..._institutions.map(
              _buildInstitutionCard,
            ),
        ],
      ),
    );
  }

  // =========================================================
  // CARD PRINCIPAL
  // =========================================================

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme.primary,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo disponível',
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.76,
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
              _totalBalance,
            ),
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Row(
            children: [
              _buildSummaryInfo(
                icon: Icons
                    .account_balance_outlined,
                label:
                    '${_institutions.length} '
                    '${_institutions.length == 1 ? 'instituição' : 'instituições'}',
              ),

              const SizedBox(
                width: 18,
              ),

              _buildSummaryInfo(
                icon: Icons
                    .account_balance_wallet_outlined,
                label:
                    '${_accounts.length} '
                    '${_accounts.length == 1 ? 'conta' : 'contas'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryInfo({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white
              .withValues(
            alpha: 0.72,
          ),
        ),

        const SizedBox(
          width: 6,
        ),

        Text(
          label,
          style: TextStyle(
            color: Colors.white
                .withValues(
              alpha: 0.72,
            ),
            fontSize: 12,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CABEÇALHO
  // =========================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Por instituição',
            style:
                TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),

        Text(
          '${_institutions.length}',
          style: TextStyle(
            fontSize: 13,
            color: Colors
                .grey.shade500,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INSTITUIÇÃO
  // =========================================================

  Widget _buildInstitutionCard(
    AccountInstitution
        institution,
  ) {
    final percentage =
        _totalBalance == 0
            ? 0.0
            : institution
                    .totalBalance /
                _totalBalance;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          onTap: () {
            _openInstitution(
              institution,
            );
          },
          child: Container(
            padding:
                const EdgeInsets.all(
              18,
            ),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: Colors
                    .grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildInstitutionIcon(
                      institution.name,
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
                            institution.name,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            '${institution.accounts.length} '
                            '${institution.accounts.length == 1 ? 'conta' : 'contas'}',
                            style:
                                TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey
                                  .shade500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .end,
                      children: [
                        Text(
                          formatCurrency(
                            institution
                                .totalBalance,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        if (_totalBalance >
                            0)
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style:
                                TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey
                                  .shade500,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Icon(
                      Icons
                          .chevron_right_rounded,
                      size: 26,
                      color: Colors
                          .grey.shade400,
                    ),
                  ],
                ),

                if (_totalBalance >
                    0) ...[
                  const SizedBox(
                    height: 16,
                  ),

                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                    child:
                        LinearProgressIndicator(
                      value: percentage
                          .clamp(
                            0.0,
                            1.0,
                          )
                          .toDouble(),
                      minHeight: 5,
                      backgroundColor:
                          AppTheme.primary
                              .withValues(
                        alpha: 0.08,
                      ),
                      valueColor:
                          const AlwaysStoppedAnimation<
                              Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ÍCONE
  // =========================================================

  Widget _buildInstitutionIcon(
    String institution,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration:
          BoxDecoration(
        color: AppTheme.primary
            .withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),
      child: Center(
        child: Text(
          _institutionInitials(
            institution,
          ),
          style:
              const TextStyle(
            color:
                AppTheme.primary,
            fontSize: 14,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _institutionInitials(
    String name,
  ) {
    final words = name
        .trim()
        .split(
          RegExp(r'\s+'),
        )
        .where(
          (word) =>
              word.isNotEmpty,
        )
        .toList();

    if (words.isEmpty) {
      return '?';
    }

    if (words.length == 1) {
      final word =
          words.first;

      if (word.length == 1) {
        return word
            .toUpperCase();
      }

      return word
          .substring(
            0,
            word.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return (
      words.first[0] +
          words.last[0]
    ).toUpperCase();
  }

  // =========================================================
  // EMPTY / ERROR
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration:
                BoxDecoration(
              color: AppTheme.primary
                  .withValues(
                alpha: 0.08,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .account_balance_wallet_outlined,
              color:
                  AppTheme.primary,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Nenhuma conta encontrada',
            style:
                TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'As contas bancárias das instituições conectadas aparecerão aqui.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors
                  .grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 42,
              color:
                  AppTheme.danger,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              _errorMessage!,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  _loadAccounts,
              child:
                  const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ===========================================================
// AGRUPAMENTO
// ===========================================================

class AccountInstitution {
  final String name;

  double totalBalance;

  final List<dynamic> accounts;

  AccountInstitution({
    required this.name,
    required this.totalBalance,
    required this.accounts,
  });
}