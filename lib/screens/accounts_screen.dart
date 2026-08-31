import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../widgets/finance_ui.dart';
import '../widgets/privacy_finance_ui.dart';

import 'institution_accounts_screen.dart';


class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
  });

  @override
  State<AccountsScreen> createState() =>
      _AccountsScreenState();
}


class _AccountsScreenState extends State<AccountsScreen> {
  final _financeService = FinanceService();

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final summary =
          await _financeService.getSummary();

      final allAccounts =
          summary['payload']?['accounts'] ?? [];

      final bankAccounts =
          List<dynamic>.from(allAccounts)
              .where(
                (account) =>
                    account['type']
                        ?.toString()
                        .toUpperCase() ==
                    'BANK',
              )
              .toList();

      if (!mounted) return;

      setState(() {
        _accounts = bankAccounts;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível carregar suas contas.';
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _financeService.refresh();
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

  double get _totalBalance {
    double total = 0;

    for (final account in _accounts) {
      total += _getAccountBalance(account);
    }

    return total;
  }

  List<AccountInstitution> get _institutions {
    final grouped =
        <String, AccountInstitution>{};

    for (final account in _accounts) {
      final institution =
          _getInstitutionName(account);

      final balance =
          _getAccountBalance(account);

      grouped.putIfAbsent(
        institution,
        () => AccountInstitution(
          name: institution,
          totalBalance: 0,
          accounts: [],
        ),
      );

      grouped[institution]!
          .totalBalance += balance;

      grouped[institution]!
          .accounts
          .add(account);
    }

    final result =
        grouped.values.toList();

    result.sort(
      (a, b) =>
          b.totalBalance.compareTo(
        a.totalBalance,
      ),
    );

    return result;
  }

  double _getAccountBalance(
    dynamic account,
  ) {
    final value = account['balance'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _getInstitutionName(
    dynamic account,
  ) {
    final candidates = [
      account['institution_name'],
      account['resolved_institution'],
      account['institution'],
      account['institutionName'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return 'Outros';
  }

  String _initials(
    String name,
  ) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length >= 2 ? 2 : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  Future<void> _openInstitution(
    AccountInstitution institution,
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

    await _loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return FinancePage(
      title: 'Contas',
      isRefreshing: _isRefreshing,
      onRefreshButton: _refresh,
      onRefresh: _loadAccounts,
      actions: const [
        PrivacyEyeButton(),
      ],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const FinancePageSkeleton();
    }

    if (_errorMessage != null) {
      return ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          FinanceEmptyState(
            icon:
                Icons.error_outline_rounded,
            title:
                'Não foi possível carregar',
            subtitle:
                'Verifique sua conexão e tente atualizar novamente.',
          ),
        ],
      );
    }

    return ListView(
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
        PrivacyFinanceHeroCard(
          label: 'Saldo disponível',
          value: _totalBalance,
          details: [
            FinanceHeroInfo(
              icon:
                  Icons.account_balance_rounded,
              text:
                  '${_institutions.length} '
                  '${_institutions.length == 1 ? 'instituição' : 'instituições'}',
            ),
            FinanceHeroInfo(
              icon:
                  Icons.account_balance_wallet_rounded,
              text:
                  '${_accounts.length} '
                  '${_accounts.length == 1 ? 'conta' : 'contas'}',
            ),
          ],
        ),

        const SizedBox(height: 30),

        FinanceSectionHeader(
          title: 'Por instituição',
          trailing:
              '${_institutions.length}',
        ),

        const SizedBox(height: 12),

        if (_institutions.isEmpty)
          const FinanceEmptyState(
            icon:
                Icons.account_balance_wallet_outlined,
            title:
                'Nenhuma conta encontrada',
            subtitle:
                'Conecte uma instituição para visualizar suas contas.',
          )
        else
          ..._institutions.map(
            (institution) {
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
                child: PrivacyFinanceListTile(
                  institutionName:
                      institution.name,
                  title:
                      institution.name,
                  subtitle:
                      '${institution.accounts.length} '
                      '${institution.accounts.length == 1 ? 'conta' : 'contas'}',
                  value:
                      institution.totalBalance,
                  trailingText:
                      _totalBalance > 0
                          ? '${(percentage * 100).toStringAsFixed(1)}%'
                          : null,
                  progress:
                      _totalBalance > 0
                          ? percentage
                          : null,
                  onTap: () =>
                      _openInstitution(
                    institution,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}


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