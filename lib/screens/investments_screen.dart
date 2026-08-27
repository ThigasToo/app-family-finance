import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

import 'add_investment_screen.dart';
import 'institution_investments_screen.dart';


class InvestmentsScreen
    extends StatefulWidget {
  const InvestmentsScreen({
    super.key,
  });

  @override
  State<InvestmentsScreen>
      createState() =>
          _InvestmentsScreenState();
}


class _InvestmentsScreenState
    extends State<InvestmentsScreen> {
  final _financeService =
      FinanceService();

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  List<dynamic> _investments = [];

  @override
  void initState() {
    super.initState();

    _loadInvestments();
  }

  // =========================================================
  // CARREGAMENTO
  // =========================================================

  Future<void>
      _loadInvestments() async {
    try {
      final summary =
          await _financeService
              .getSummary();

      if (!mounted) return;

      setState(() {
        _investments =
            summary['payload']
                    ?['investments'] ??
                [];

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage =
            'Não foi possível carregar os investimentos.';
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

  // =========================================================
  // ADICIONAR
  // =========================================================

  Future<void>
      _openAddInvestment() async {
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
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // TOTAL
  // =========================================================

  double get _totalInvestments {
    double total = 0;

    for (final investment
        in _investments) {
      final balance =
          investment['balance'] ??
              investment[
                  'current_value'];

      if (balance is num) {
        total +=
            balance.toDouble();
      }
    }

    return total;
  }

  int get _manualInvestmentsCount {
    return _investments
        .where(
          (investment) =>
              investment['source'] ==
              'MANUAL',
        )
        .length;
  }

  int get _syncedInvestmentsCount {
    return _investments
        .where(
          (investment) =>
              investment['source'] ==
              'PLUGGY',
        )
        .length;
  }

  // =========================================================
  // AGRUPAMENTO
  // =========================================================

  List<InvestmentInstitution>
      get _institutions {
    final Map<
            String,
            InvestmentInstitution>
        grouped = {};

    for (final investment
        in _investments) {
      final institutionName =
          _getInstitutionName(
        investment,
      );

      final value =
          _getInvestmentValue(
        investment,
      );

      if (!grouped.containsKey(
        institutionName,
      )) {
        grouped[institutionName] =
            InvestmentInstitution(
          name: institutionName,
          total: 0,
          investments: [],
        );
      }

      grouped[institutionName]!
          .total += value;

      grouped[institutionName]!
          .investments
          .add(investment);
    }

    final institutions =
        grouped.values.toList();

    institutions.sort(
      (a, b) =>
          b.total.compareTo(
        a.total,
      ),
    );

    return institutions;
  }

  String _getInstitutionName(
    dynamic investment,
  ) {
    final candidates = [
      investment[
          'institution_name'],
      investment[
          'resolved_institution'],
      investment['institution'],
      investment[
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

    return 0;
  }

  // =========================================================
  // ABRIR INSTITUIÇÃO
  // =========================================================

  Future<void>
      _openInstitution(
    InvestmentInstitution
        institution,
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
          'Investimentos',
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
          _loadInvestments,
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

          const SizedBox(
            height: 24,
          ),

          _buildAddInvestmentButton(),
        ],
      ),
    );
  }

  // =========================================================
  // RESUMO
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
            'Total investido',
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
              _totalInvestments,
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
                    '${_institutions.length} ${_institutions.length == 1 ? 'instituição' : 'instituições'}',
              ),

              const SizedBox(
                width: 18,
              ),

              _buildSummaryInfo(
                icon: Icons
                    .pie_chart_outline_rounded,
                label:
                    '${_investments.length} ${_investments.length == 1 ? 'ativo' : 'ativos'}',
              ),
            ],
          ),

          if (_manualInvestmentsCount >
              0) ...[
            const SizedBox(
              height: 10,
            ),

            Text(
              '$_syncedInvestmentsCount sincronizados • '
              '$_manualInvestmentsCount manuais',
              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: 0.62,
                ),
                fontSize: 11,
              ),
            ),
          ],
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
  // SEÇÃO
  // =========================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Por instituição',
            style: TextStyle(
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
            color:
                Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INSTITUIÇÃO
  // =========================================================

  Widget _buildInstitutionCard(
    InvestmentInstitution
        institution,
  ) {
    final percentage =
        _totalInvestments <= 0
            ? 0.0
            : institution.total /
                _totalInvestments;

    final manualCount =
        institution.investments
            .where(
              (investment) =>
                  investment[
                      'source'] ==
                  'MANUAL',
            )
            .length;

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
                            institution
                                .name,
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
                            _institutionSubtitle(
                              institution,
                              manualCount,
                            ),
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
                                .total,
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
                      color: Colors
                          .grey.shade400,
                      size: 26,
                    ),
                  ],
                ),

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
                    ),
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
            ),
          ),
        ),
      ),
    );
  }

  String _institutionSubtitle(
    InvestmentInstitution
        institution,
    int manualCount,
  ) {
    final count =
        institution
            .investments.length;

    final base =
        '$count ${count == 1 ? 'investimento' : 'investimentos'}';

    if (manualCount == 0) {
      return base;
    }

    if (manualCount == count) {
      return '$base • Manual';
    }

    return '$base • $manualCount manual${manualCount == 1 ? '' : 'is'}';
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
          .substring(0, 2)
          .toUpperCase();
    }

    return (
      words.first[0] +
          words.last[0]
    ).toUpperCase();
  }

  // =========================================================
  // ADICIONAR
  // =========================================================

  Widget _buildAddInvestmentButton() {
    return OutlinedButton.icon(
      onPressed:
          _openAddInvestment,
      icon: const Icon(
        Icons.add_rounded,
      ),
      label: const Text(
        'Adicionar investimento',
      ),
      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            AppTheme.primary,
        minimumSize:
            const Size.fromHeight(
          54,
        ),
        side: BorderSide(
          color: AppTheme.primary
              .withValues(
            alpha: 0.28,
          ),
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY
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
                  .trending_up_rounded,
              color:
                  AppTheme.primary,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Nenhum investimento encontrado',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Conecte uma instituição ou adicione um investimento manualmente.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color:
                  Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERRO
  // =========================================================

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
                  _loadInvestments,
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

class InvestmentInstitution {
  final String name;

  double total;

  final List<dynamic>
      investments;

  InvestmentInstitution({
    required this.name,
    required this.total,
    required this.investments,
  });
}