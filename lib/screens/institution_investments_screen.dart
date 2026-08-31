import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_ui.dart';

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
    extends State<
        InstitutionInvestmentsScreen> {
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
  // TOTAIS
  // =========================================================

  double get _totalValue {
    double total = 0;

    for (final investment
        in _investments) {
      total +=
          _getInvestmentValue(
        investment,
      );
    }

    return total;
  }

  int get _manualCount =>
      _investments
          .where(
            (investment) =>
                investment[
                    'source'] ==
                'MANUAL',
          )
          .length;

  int get _syncedCount =>
      _investments
          .where(
            (investment) =>
                investment[
                    'source'] ==
                'PLUGGY',
          )
          .length;

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

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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
    switch (value.toUpperCase()) {
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

  IconData _investmentIcon(
    dynamic investment,
  ) {
    final type =
        '${investment['type'] ?? ''} '
                '${investment['subtype'] ?? ''}'
            .toUpperCase();

    if (type.contains('CRYPTO')) {
      return Icons
          .currency_bitcoin_rounded;
    }

    if (type.contains('FIXED') ||
        type.contains('CDB') ||
        type.contains('LCI') ||
        type.contains('LCA')) {
      return Icons
          .account_balance_rounded;
    }

    if (type.contains('ETF') ||
        type.contains('STOCK')) {
      return Icons
          .show_chart_rounded;
    }

    return Icons
        .trending_up_rounded;
  }

  // =========================================================
  // ABRIR
  // =========================================================

  Future<void> _openInvestment(
    dynamic investment,
  ) async {
    final isManual =
        investment['source'] ==
            'MANUAL';

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
        ),
      );

      return;
    }

    if (result == true) {
      if (Navigator.of(context)
          .canPop()) {
        Navigator.of(context).pop(
          true,
        );
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

    return FinancePage(
      title:
          widget.institutionName,
      child: ListView(
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
            label:
                'Investido em ${widget.institutionName}',
            value:
                _totalValue,
            details: [
              FinanceHeroInfo(
                icon:
                    Icons
                        .pie_chart_rounded,
                text:
                    '${_investments.length} '
                    '${_investments.length == 1 ? 'ativo' : 'ativos'}',
              ),

              if (_syncedCount > 0)
                FinanceHeroInfo(
                  icon:
                      Icons
                          .sync_rounded,
                  text:
                      '$_syncedCount sincronizado'
                      '${_syncedCount == 1 ? '' : 's'}',
                ),

              if (_manualCount > 0)
                FinanceHeroInfo(
                  icon:
                      Icons
                          .edit_rounded,
                  text:
                      '$_manualCount manual'
                      '${_manualCount == 1 ? '' : 'is'}',
                ),
            ],
          ),

          const SizedBox(
            height: 30,
          ),

          FinanceSectionHeader(
            title:
                'Seus investimentos',
            trailing:
                '${_investments.length}',
          ),

          const SizedBox(
            height: 12,
          ),

          if (sortedInvestments
              .isEmpty)
            const FinanceEmptyState(
              icon:
                  Icons
                      .show_chart_rounded,
              title:
                  'Nenhum investimento',
              subtitle:
                  'Não há investimentos disponíveis nesta instituição.',
            )
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
            : value / _totalValue;

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
      child: FinanceGlassCard(
        radius: 23,
        onTap: () {
          _openInvestment(
            investment,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(
            17,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  FinanceIconBubble(
                    icon:
                        _investmentIcon(
                      investment,
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
                            color:
                                AppTheme.ink,
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

                        Text(
                          ticker != null
                              ? '${_getInvestmentType(investment)} • $ticker'
                              : _getInvestmentType(
                                  investment,
                                ),
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme
                                    .inkSoft,
                            fontSize: 11.5,
                          ),
                        ),

                        if (isManual) ...[
                          const SizedBox(
                            height: 7,
                          ),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  8,
                              vertical:
                                  4,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppTheme
                                      .primary
                                      .withValues(
                                alpha:
                                    0.08,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                8,
                              ),
                            ),
                            child:
                                const Text(
                              'Manual',
                              style:
                                  TextStyle(
                                color:
                                    AppTheme
                                        .primary,
                                fontSize:
                                    9.5,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(
                          value,
                        ),
                        style:
                            const TextStyle(
                          color:
                              AppTheme.ink,
                          fontSize: 15.5,
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
                            const TextStyle(
                          color:
                              AppTheme
                                  .inkSoft,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Icon(
                    isManual
                        ? Icons
                            .edit_rounded
                        : Icons
                            .chevron_right_rounded,
                    color:
                        AppTheme.inkSoft,
                    size:
                        isManual
                            ? 18
                            : 24,
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                child:
                    LinearProgressIndicator(
                  value:
                      percentage.clamp(
                    0.0,
                    1.0,
                  ),
                  minHeight: 4.5,
                  backgroundColor:
                      AppTheme.primary
                          .withValues(
                    alpha: 0.07,
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
    );
  }
}