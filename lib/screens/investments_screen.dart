import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/finance_service.dart';
import '../widgets/finance_ui.dart';

import 'add_investment_screen.dart';
import 'institution_investments_screen.dart';


class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({
    super.key,
  });

  @override
  State<InvestmentsScreen> createState() =>
      _InvestmentsScreenState();
}


class _InvestmentsScreenState
    extends State<InvestmentsScreen> {
  final _financeService = FinanceService();

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  List<dynamic> _investments = [];

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    try {
      final summary =
          await _financeService.getSummary();

      if (!mounted) return;

      setState(() {
        _investments =
            summary['payload']
                    ?['investments'] ??
                [];

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível carregar os investimentos.';
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
      await _loadInvestments();
    } catch (_) {
      await _loadInvestments();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openAddInvestment() async {
    final created =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const AddInvestmentScreen(),
      ),
    );

    if (created != true ||
        !mounted) {
      return;
    }

    await _loadInvestments();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Investimento adicionado.',
        ),
      ),
    );
  }

  double get _totalInvestments {
    double total = 0;

    for (final item in _investments) {
      total +=
          _getInvestmentValue(item);
    }

    return total;
  }

  int get _manualInvestmentsCount =>
      _investments
          .where(
            (item) =>
                item['source'] ==
                'MANUAL',
          )
          .length;

  int get _syncedInvestmentsCount =>
      _investments
          .where(
            (item) =>
                item['source'] ==
                'PLUGGY',
          )
          .length;

  List<InvestmentInstitution>
      get _institutions {
    final grouped =
        <String, InvestmentInstitution>{};

    for (final investment
        in _investments) {
      final institution =
          _getInstitutionName(
        investment,
      );

      final value =
          _getInvestmentValue(
        investment,
      );

      grouped.putIfAbsent(
        institution,
        () =>
            InvestmentInstitution(
          name: institution,
          total: 0,
          investments: [],
        ),
      );

      grouped[institution]!
          .total += value;

      grouped[institution]!
          .investments
          .add(investment);
    }

    final result =
        grouped.values.toList();

    result.sort(
      (a, b) =>
          b.total.compareTo(
        a.total,
      ),
    );

    return result;
  }

  double _getInvestmentValue(
    dynamic investment,
  ) {
    final value =
        investment['balance'] ??
            investment[
                'current_value'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _getInstitutionName(
    dynamic investment,
  ) {
    final candidates = [
      investment['institution_name'],
      investment[
          'resolved_institution'],
      investment['institution'],
      investment['institutionName'],
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
    InvestmentInstitution institution,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            InstitutionInvestmentsScreen(
          institutionName:
              institution.name,
          investments:
              institution.investments,
        ),
      ),
    );

    if (!mounted) return;

    await _loadInvestments();
  }

  @override
  Widget build(BuildContext context) {
    return FinancePage(
      title: 'Investimentos',
      isRefreshing: _isRefreshing,
      onRefreshButton: _refresh,
      onRefresh: _loadInvestments,
      actions: [
        FinanceIconButton(
          icon: Icons.add_rounded,
          tooltip:
              'Adicionar investimento',
          onTap:
              _openAddInvestment,
        ),
      ],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 220),
          Center(
            child:
                CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const FinanceEmptyState(
            icon:
                Icons.error_outline_rounded,
            title:
                'Não foi possível carregar',
            subtitle:
                'Verifique sua conexão e tente novamente.',
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
        FinanceHeroCard(
          label: 'Patrimônio investido',
          value: _totalInvestments,
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
                  Icons.pie_chart_rounded,
              text:
                  '${_investments.length} '
                  '${_investments.length == 1 ? 'ativo' : 'ativos'}',
            ),
            if (_manualInvestmentsCount >
                0)
              FinanceHeroInfo(
                icon:
                    Icons.edit_rounded,
                text:
                    '$_syncedInvestmentsCount automáticos • '
                    '$_manualInvestmentsCount manuais',
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
                Icons.show_chart_rounded,
            title:
                'Nenhum investimento',
            subtitle:
                'Conecte uma instituição ou adicione um investimento manualmente.',
          )
        else
          ..._institutions.map(
            (institution) {
              final percentage =
                  _totalInvestments <= 0
                      ? 0.0
                      : institution.total /
                          _totalInvestments;

              final manualCount =
                  institution.investments
                      .where(
                        (item) =>
                            item['source'] ==
                            'MANUAL',
                      )
                      .length;

              final count =
                  institution
                      .investments.length;

              String subtitle =
                  '$count '
                  '${count == 1 ? 'investimento' : 'investimentos'}';

              if (manualCount > 0) {
                subtitle +=
                    ' • $manualCount manual'
                    '${manualCount == 1 ? '' : 'is'}';
              }

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: FinanceListTile(
                  initials:
                      _initials(
                    institution.name,
                  ),
                  title:
                      institution.name,
                  subtitle:
                      subtitle,
                  value:
                      institution.total,
                  trailingText:
                      '${(percentage * 100).toStringAsFixed(1)}%',
                  progress:
                      percentage,
                  onTap: () =>
                      _openInstitution(
                    institution,
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 12),

        FinanceGlassCard(
          radius: 20,
          onTap:
              _openAddInvestment,
          child: const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color:
                      AppTheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Adicionar investimento manual',
                  style: TextStyle(
                    color:
                        AppTheme.primary,
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class InvestmentInstitution {
  final String name;

  double total;

  final List<dynamic> investments;

  InvestmentInstitution({
    required this.name,
    required this.total,
    required this.investments,
  });
}