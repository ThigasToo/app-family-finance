import 'package:flutter/material.dart';
import 'credit_card_detail_screen.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

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
      total += _getCardBalance(
        card,
      );
    }

    return total;
  }

  double get _totalLimit {
    double total = 0;

    for (final card in cards) {
      final limit =
          _getCreditLimit(card);

      if (limit != null) {
        total += limit;
      }
    }

    return total;
  }

  double get _totalAvailable {
    double total = 0;

    for (final card in cards) {
      final available =
          _getAvailableLimit(card);

      if (available != null) {
        total += available;
      }
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

    if (value != null) {
      return double.tryParse(
        value.toString(),
      );
    }

    return null;
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

    if (value != null) {
      return double.tryParse(
        value.toString(),
      );
    }

    return null;
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

    switch (
        brand.toUpperCase()) {
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

    if (value != null) {
      return double.tryParse(
        value.toString(),
      );
    }

    return null;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          institutionName,
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

          if (sortedCards.isEmpty)
            _buildEmptyState()
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
  // RESUMO
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
            const Color(
          0xFF315B78,
        ),
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
            'Total utilizado em $institutionName',
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
              _totalUsed,
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
            height: 22,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildSummaryDetail(
                  label:
                      'Limite total',
                  value:
                      formatCurrency(
                    _totalLimit,
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 38,
                color: Colors.white
                    .withValues(
                  alpha: 0.18,
                ),
              ),

              const SizedBox(
                width: 18,
              ),

              Expanded(
                child:
                    _buildSummaryDetail(
                  label:
                      'Disponível',
                  value:
                      formatCurrency(
                    _totalAvailable,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: [
              const Icon(
                Icons.credit_card_rounded,
                size: 16,
                color: Colors.white70,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                '${cards.length} '
                '${cards.length == 1 ? 'cartão' : 'cartões'}',
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.68,
                  ),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetail({
    required String label,
    required String value,
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
              alpha: 0.58,
            ),
            fontSize: 11,
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
            color: Colors.white,
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
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
            'Seus cartões',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),

        Text(
          '${cards.length}',
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

    final minimumPayment =
        _getMinimumPayment(
      card,
    );

    final dueDate =
        _getDueDate(
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
        bottom: 14,
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
          _openCard(
            context,
            card,
          );
        },
          child: Container(
            padding:
                const EdgeInsets.all(
              18,
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
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildCardIcon(),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCardName(
                              card,
                            ),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            _getCardSubtitle(
                              card,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey.shade500,
                            ),
                          ),

                          if (_getCardNumber(
                            card,
                          ).isNotEmpty) ...[
                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              _getCardNumber(
                                card,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors
                                    .grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
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

                const SizedBox(
                  height: 20,
                ),

                Text(
                  'Em uso',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade500,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  formatCurrency(
                    used,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                if (limit != null &&
                    limit > 0) ...[
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
                      value: utilization
                          .clamp(
                            0.0,
                            1.0,
                          )
                          .toDouble(),
                      minHeight: 6,
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

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildInfo(
                          'Limite',
                          formatCurrency(
                            limit,
                          ),
                        ),
                      ),

                      if (available != null)
                        Expanded(
                          child:
                              _buildInfo(
                            'Disponível',
                            formatCurrency(
                              available,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                if (dueDate != null ||
                    minimumPayment !=
                        null ||
                    status.isNotEmpty) ...[
                  const SizedBox(
                    height: 16,
                  ),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors
                          .grey.shade50,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (dueDate != null)
                          _buildMiniInfo(
                            'Vencimento',
                            dueDate,
                          ),

                        if (minimumPayment !=
                            null)
                          _buildMiniInfo(
                            'Pagamento mínimo',
                            formatCurrency(
                              minimumPayment,
                            ),
                          ),

                        if (status.isNotEmpty)
                          _buildMiniInfo(
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
      ),
    );
  }

  Widget _buildCardIcon() {
    return Container(
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
      child: const Icon(
        Icons.credit_card_rounded,
        color:
            AppTheme.primary,
        size: 22,
      ),
    );
  }

  Widget _buildInfo(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                Colors.grey.shade500,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          value,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors
                    .grey.shade500,
              ),
            ),
          ),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TEMPORÁRIO - 4C
  // =========================================================

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
  // EMPTY
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
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
        'Nenhum cartão encontrado nesta instituição.',
      ),
    );
  }
}