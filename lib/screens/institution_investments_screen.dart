import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

import 'edit_investment_screen.dart';
import 'pluggy_investment_detail_screen.dart';

class InstitutionInvestmentsScreen
    extends StatefulWidget {
  final String institutionName;
  final List<dynamic> investments;

  const InstitutionInvestmentsScreen({
    super.key,
    required this.institutionName,
    required this.investments,
  });

  @override
  State<InstitutionInvestmentsScreen>
      createState() =>
          _InstitutionInvestmentsScreenState();
}

class _InstitutionInvestmentsScreenState
    extends State<InstitutionInvestmentsScreen> {
  late List<dynamic> _investments;

  @override
  void initState() {
    super.initState();

    _investments =
        List<dynamic>.from(
      widget.investments,
    );
  }

  // =========================================================
  // TOTAL
  // =========================================================

  double get _totalValue {
    double total = 0;

    for (final investment
        in _investments) {
      total += _getInvestmentValue(
        investment,
      );
    }

    return total;
  }

  int get _manualCount {
    return _investments
        .where(
          (investment) =>
              investment['source'] ==
              'MANUAL',
        )
        .length;
  }

  int get _syncedCount {
    return _investments
        .where(
          (investment) =>
              investment['source'] ==
              'PLUGGY',
        )
        .length;
  }

  // =========================================================
  // HELPERS
  // =========================================================

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

  String _getInvestmentName(
    dynamic investment,
  ) {
    final name =
        investment['name'];

    if (name == null ||
        name
            .toString()
            .trim()
            .isEmpty) {
      return 'Investimento';
    }

    return name
        .toString()
        .trim();
  }

  String _getInvestmentType(
    dynamic investment,
  ) {
    final subtype =
        investment['subtype'];

    if (subtype != null &&
        subtype
            .toString()
            .trim()
            .isNotEmpty) {
      return _friendlyType(
        subtype.toString(),
      );
    }

    final type =
        investment['type'];

    if (type != null &&
        type
            .toString()
            .trim()
            .isNotEmpty) {
      return _friendlyType(
        type.toString(),
      );
    }

    return 'Investimento';
  }

  String _friendlyType(
    String value,
  ) {
    switch (
        value.toUpperCase()) {
      case 'CRYPTO':
        return 'Criptomoeda';

      case 'ETF':
        return 'ETF';

      case 'STOCK':
        return 'Ação';

      case 'FIXED_INCOME':
        return 'Renda fixa';

      case 'CDB':
        return 'CDB';

      case 'LCI':
        return 'LCI';

      case 'LCA':
        return 'LCA';

      case 'TREASURY':
        return 'Tesouro';

      case 'FUND':
      case 'INVESTMENT_FUND':
        return 'Fundo';

      case 'OTHER':
        return 'Outro';

      default:
        return value
            .replaceAll(
              '_',
              ' ',
            )
            .toLowerCase()
            .split(' ')
            .map(
              (word) {
                if (word.isEmpty) {
                  return '';
                }

                return word[0]
                        .toUpperCase() +
                    word.substring(1);
              },
            )
            .join(' ');
    }
  }

  String? _getTicker(
    dynamic investment,
  ) {
    final ticker =
        investment['ticker'] ??
            investment['code'];

    if (ticker == null ||
        ticker
            .toString()
            .trim()
            .isEmpty) {
      return null;
    }

    return ticker
        .toString()
        .trim()
        .toUpperCase();
  }

  // =========================================================
  // ABRIR INVESTIMENTO
  // =========================================================

  Future<void> _openInvestment(
    dynamic investment,
  ) async {
    final isManual =
        investment['source'] ==
            'MANUAL';

    // =====================================================
    // INVESTIMENTO PLUGGY
    // =====================================================

    if (!isManual) {
      await Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder: (_) =>
              PluggyInvestmentDetailScreen(
            investment:
                Map<String, dynamic>.from(
              investment,
            ),
          ),
        ),
      );

      return;
    }

    // =====================================================
    // INVESTIMENTO MANUAL
    // =====================================================

    final result =
        await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (_) =>
            EditInvestmentScreen(
          investment:
              Map<String, dynamic>.from(
            investment,
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (result ==
        InvestmentEditResult.deleted) {
      setState(() {
        _investments.removeWhere(
          (item) =>
              item['manual_id'] ==
              investment[
                  'manual_id'],
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Investimento excluído.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (result == true) {
      if (Navigator.of(
        context,
      ).canPop()) {
        Navigator.of(
          context,
        ).pop(true);
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
    final sortedInvestments =
        [..._investments];

    sortedInvestments.sort(
      (a, b) =>
          _getInvestmentValue(b)
              .compareTo(
        _getInvestmentValue(a),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.institutionName,
        ),
      ),
      body: ListView(
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

          if (sortedInvestments
              .isEmpty)
            _buildEmptyState()
          else
            ...sortedInvestments.map(
              (investment) =>
                  _buildInvestmentCard(
                investment,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
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
            'Investido em ${widget.institutionName}',
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
              _totalValue,
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
              Icon(
                Icons
                    .pie_chart_outline_rounded,
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
                '${_investments.length} '
                '${_investments.length == 1 ? 'ativo' : 'ativos'}',
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.72,
                  ),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          if (_manualCount > 0 &&
              _syncedCount > 0) ...[
            const SizedBox(
              height: 8,
            ),

            Text(
              '$_syncedCount sincronizados • $_manualCount manuais',
              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: 0.58,
                ),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // SECTION
  // =========================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Seus investimentos',
            style:
                TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),

        Text(
          '${_investments.length}',
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
  // CARD
  // =========================================================

  Widget _buildInvestmentCard(
    dynamic investment,
  ) {
    final value =
        _getInvestmentValue(
      investment,
    );

    final percentage =
        _totalValue <= 0
            ? 0.0
            : value /
                _totalValue;

    final isManual =
        investment['source'] ==
            'MANUAL';

    final ticker =
        _getTicker(
      investment,
    );

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
            _openInvestment(
              investment,
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
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _buildInvestmentIcon(
                      investment,
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
                            _getInvestmentName(
                              investment,
                            ),
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 14,
                              height: 1.25,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _getInvestmentType(
                                    investment,
                                  ),
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .grey
                                        .shade500,
                                  ),
                                ),
                              ),

                              if (ticker !=
                                  null) ...[
                                const SizedBox(
                                  width: 7,
                                ),

                                Text(
                                  '• $ticker',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .grey
                                        .shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (isManual) ...[
                            const SizedBox(
                              height: 7,
                            ),

                            _buildManualBadge(),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .end,
                      children: [
                        Text(
                          formatCurrency(
                            value,
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
                      width: 3,
                    ),

                    Icon(
                      isManual
                          ? Icons
                              .edit_outlined
                          : Icons
                              .chevron_right_rounded,
                      size: isManual
                          ? 20
                          : 25,
                      color: Colors
                          .grey.shade400,
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
                    minHeight: 4,
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

  Widget _buildManualBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary
            .withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),
      child:
          const Text(
        'Manual',
        style: TextStyle(
          color:
              AppTheme.primary,
          fontSize: 10,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // =========================================================
  // ICON
  // =========================================================

  Widget _buildInvestmentIcon(
    dynamic investment,
  ) {
    final type =
        (
          investment['type'] ??
              investment['subtype'] ??
              ''
        )
            .toString()
            .toUpperCase();

    IconData icon;

    if (type.contains(
      'CRYPTO',
    )) {
      icon =
          Icons.currency_bitcoin_rounded;
    } else if (type.contains(
      'ETF',
    )) {
      icon =
          Icons.pie_chart_outline_rounded;
    } else if (type.contains(
      'STOCK',
    )) {
      icon =
          Icons.show_chart_rounded;
    } else if (type.contains(
          'FIXED',
        ) ||
        type.contains(
          'CDB',
        ) ||
        type.contains(
          'LCI',
        ) ||
        type.contains(
          'LCA',
        )) {
      icon =
          Icons.savings_outlined;
    } else if (type.contains(
      'FUND',
    )) {
      icon =
          Icons.account_balance_outlined;
    } else {
      icon =
          Icons.trending_up_rounded;
    }

    return Container(
      width: 46,
      height: 46,
      decoration:
          BoxDecoration(
        color: AppTheme.primary
            .withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Icon(
        icon,
        size: 22,
        color:
            AppTheme.primary,
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child:
          const Text(
        'Nenhum investimento nesta instituição.',
      ),
    );
  }
}