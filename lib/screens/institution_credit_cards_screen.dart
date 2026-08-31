import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_ui.dart';

import 'credit_card_detail_screen.dart';


class InstitutionCreditCardsScreen
    extends StatelessWidget {
  final String institutionName;
  final List<dynamic> cards;

  const InstitutionCreditCardsScreen({
    super.key,
    required this.institutionName,
    required this.cards,
  });

  // =========================================================
  // TOTAIS
  // =========================================================

  double get _totalUsed {
    double total = 0;

    for (final card in cards) {
      total +=
          _getCardBalance(
        card,
      );
    }

    return total;
  }

  double get _totalLimit {
    double total = 0;

    for (final card in cards) {
      total +=
          _getCreditLimit(card) ??
              0;
    }

    return total;
  }

  double get _totalAvailable {
    double total = 0;

    for (final card in cards) {
      total +=
          _getAvailableLimit(
                card,
              ) ??
              0;
    }

    return total;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _getCardBalance(
    dynamic card,
  ) {
    final value =
        card['balance'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  Map<String, dynamic>?
      _getCreditData(
    dynamic card,
  ) {
    final value =
        card['creditData'];

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return null;
  }

  double? _getCreditLimit(
    dynamic card,
  ) {
    final value =
        _getCreditData(card)
            ?['creditLimit'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  double? _getAvailableLimit(
    dynamic card,
  ) {
    final value =
        _getCreditData(card)
            ?['availableCreditLimit'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  String _getCardName(
    dynamic card,
  ) {
    final marketingName =
        card['marketingName'];

    if (marketingName != null &&
        marketingName
            .toString()
            .trim()
            .isNotEmpty) {
      return marketingName
          .toString()
          .trim();
    }

    final name =
        card['name'];

    if (name != null &&
        name
            .toString()
            .trim()
            .isNotEmpty) {
      return name
          .toString()
          .trim();
    }

    return 'Cartão';
  }

  String _getCardNumber(
    dynamic card,
  ) {
    final number =
        card['number']
            ?.toString()
            .trim() ??
        '';

    if (number.isEmpty) {
      return '';
    }

    if (number.length <= 4) {
      return '•••• $number';
    }

    return '•••• ${number.substring(number.length - 4)}';
  }

  String _getBrand(
    dynamic card,
  ) {
    final brand =
        _getCreditData(card)
            ?['brand']
            ?.toString()
            .trim();

    if (brand == null ||
        brand.isEmpty) {
      return '';
    }

    switch (brand.toUpperCase()) {
      case 'MASTERCARD':
        return 'Mastercard';

      case 'VISA':
        return 'Visa';

      case 'ELO':
        return 'Elo';

      case 'AMEX':
      case 'AMERICAN_EXPRESS':
        return 'American Express';

      default:
        return brand;
    }
  }

  String _getLevel(
    dynamic card,
  ) {
    final level =
        _getCreditData(card)
            ?['level']
            ?.toString()
            .trim();

    if (level == null ||
        level.isEmpty) {
      return '';
    }

    final lower =
        level.toLowerCase();

    return lower[0].toUpperCase() +
        lower.substring(1);
  }

  String _getCardSubtitle(
    dynamic card,
  ) {
    final brand =
        _getBrand(card);

    final level =
        _getLevel(card);

    if (brand.isNotEmpty &&
        level.isNotEmpty) {
      return '$brand • $level';
    }

    if (brand.isNotEmpty) {
      return brand;
    }

    if (level.isNotEmpty) {
      return level;
    }

    return 'Cartão de crédito';
  }

  String? _getDueDate(
    dynamic card,
  ) {
    final raw =
        _getCreditData(card)
            ?['balanceDueDate'];

    if (raw == null ||
        raw.toString().trim().isEmpty) {
      return null;
    }

    try {
      final date =
          DateTime.parse(
        raw.toString(),
      );

      final day =
          date.day
              .toString()
              .padLeft(
                2,
                '0',
              );

      final month =
          date.month
              .toString()
              .padLeft(
                2,
                '0',
              );

      return '$day/$month/${date.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  double? _getMinimumPayment(
    dynamic card,
  ) {
    final value =
        _getCreditData(card)
            ?['minimumPayment'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  String _getStatus(
    dynamic card,
  ) {
    final status =
        _getCreditData(card)
            ?['status']
            ?.toString()
            .trim()
            .toUpperCase();

    switch (status) {
      case 'ACTIVE':
        return 'Ativo';

      case 'BLOCKED':
        return 'Bloqueado';

      case 'CANCELLED':
        return 'Cancelado';

      default:
        return status ?? '';
    }
  }

  void _openCard(
    BuildContext context,
    dynamic card,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CreditCardDetailScreen(
          card:
              Map<String, dynamic>.from(
            card,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final sortedCards =
        [...cards];

    sortedCards.sort(
      (a, b) =>
          _getCardBalance(b)
              .compareTo(
        _getCardBalance(a),
      ),
    );

    return FinancePage(
      title: institutionName,
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
          _buildHero(),

          const SizedBox(
            height: 30,
          ),

          FinanceSectionHeader(
            title: 'Seus cartões',
            trailing:
                '${cards.length}',
          ),

          const SizedBox(
            height: 12,
          ),

          if (sortedCards.isEmpty)
            const FinanceEmptyState(
              icon:
                  Icons
                      .credit_card_rounded,
              title:
                  'Nenhum cartão encontrado',
              subtitle:
                  'Não há cartões disponíveis nesta instituição.',
            )
          else
            ...sortedCards.map(
              (card) =>
                  _buildCard(
                context,
                card,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // HERO
  // =========================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        23,
      ),
      decoration: BoxDecoration(
        gradient:
            AppTheme.premiumGradient,
        borderRadius:
            BorderRadius.circular(
          29,
        ),
        border: Border.all(
          color:
              Colors.white
                  .withValues(
            alpha: 0.15,
          ),
        ),
        boxShadow:
            AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Total utilizado em $institutionName',
            style: TextStyle(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.68,
              ),
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            formatCurrency(
              _totalUsed,
            ),
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 32,
              fontWeight:
                  FontWeight.w800,
              letterSpacing:
                  -0.9,
            ),
          ),

          const SizedBox(
            height: 21,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              15,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border:
                  Border.all(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.09,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _heroDetail(
                    'Limite total',
                    _totalLimit,
                  ),
                ),

                Container(
                  height: 38,
                  width: 1,
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.14,
                  ),
                ),

                const SizedBox(
                  width: 16,
                ),

                Expanded(
                  child:
                      _heroDetail(
                    'Disponível',
                    _totalAvailable,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          FinanceHeroInfo(
            icon:
                Icons
                    .credit_card_rounded,
            text:
                '${cards.length} '
                '${cards.length == 1 ? 'cartão' : 'cartões'}',
          ),
        ],
      ),
    );
  }

  Widget _heroDetail(
    String label,
    double value,
  ) {
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
              alpha: 0.58,
            ),
            fontSize: 10.5,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          formatCurrency(value),
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _buildCard(
    BuildContext context,
    dynamic card,
  ) {
    final used =
        _getCardBalance(
      card,
    );

    final limit =
        _getCreditLimit(
      card,
    );

    final available =
        _getAvailableLimit(
      card,
    );

    final dueDate =
        _getDueDate(
      card,
    );

    final minimumPayment =
        _getMinimumPayment(
      card,
    );

    final status =
        _getStatus(
      card,
    );

    final utilization =
        limit == null ||
                limit <= 0
            ? 0.0
            : used / limit;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: FinanceGlassCard(
        radius: 23,
        onTap: () {
          _openCard(
            context,
            card,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(
            17,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FinanceIconBubble(
                    icon:
                        Icons
                            .credit_card_rounded,
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
                          _getCardName(
                            card,
                          ),
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme.ink,
                            fontSize: 14.5,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          _getCardSubtitle(
                            card,
                          ),
                          style:
                              const TextStyle(
                            color:
                                AppTheme
                                    .inkSoft,
                            fontSize: 11.5,
                          ),
                        ),

                        if (_getCardNumber(
                              card,
                            )
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            _getCardNumber(
                              card,
                            ),
                            style: TextStyle(
                              color:
                                  AppTheme
                                      .inkSoft
                                      .withValues(
                                alpha:
                                    0.65,
                              ),
                              fontSize:
                                  10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        AppTheme.inkSoft,
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        _cardMetric(
                      'Em uso',
                      formatCurrency(
                        used,
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        _cardMetric(
                      'Disponível',
                      available != null
                          ? formatCurrency(
                              available,
                            )
                          : '—',
                    ),
                  ),
                ],
              ),

              if (limit != null &&
                  limit > 0) ...[
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
                        utilization.clamp(
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

              if (dueDate != null ||
                  minimumPayment != null ||
                  status.isNotEmpty) ...[
                const SizedBox(
                  height: 15,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppTheme.primary
                            .withValues(
                      alpha: 0.045,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (dueDate != null)
                        _detailRow(
                          'Vencimento',
                          dueDate,
                        ),

                      if (minimumPayment !=
                          null)
                        _detailRow(
                          'Pagamento mínimo',
                          formatCurrency(
                            minimumPayment,
                          ),
                        ),

                      if (status.isNotEmpty)
                        _detailRow(
                          'Status',
                          status,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardMetric(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                AppTheme.inkSoft,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color:
                AppTheme.ink,
            fontSize: 13.5,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    AppTheme.inkSoft,
                fontSize: 10.5,
              ),
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(
              color:
                  AppTheme.ink,
              fontSize: 10.5,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}