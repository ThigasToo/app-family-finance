import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_ui.dart';

import 'credit_card_transactions_screen.dart';


class CreditCardDetailScreen
    extends StatelessWidget {
  final Map<String, dynamic> card;

  const CreditCardDetailScreen({
    super.key,
    required this.card,
  });

  // =========================================================
  // HELPERS
  // =========================================================

  Map<String, dynamic>?
      get _creditData {
    final raw =
        card['creditData'];

    if (raw is Map) {
      return Map<String, dynamic>.from(
        raw,
      );
    }

    return null;
  }

  double _asDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double get _usedAmount =>
      _asDouble(
        card['balance'],
      );

  double get _creditLimit =>
      _asDouble(
        _creditData?[
            'creditLimit'],
      );

  double get _availableLimit =>
      _asDouble(
        _creditData?[
            'availableCreditLimit'],
      );

  double get _minimumPayment =>
      _asDouble(
        _creditData?[
            'minimumPayment'],
      );

  double get _utilization {
    if (_creditLimit <= 0) {
      return 0;
    }

    return _usedAmount /
        _creditLimit;
  }

  String get _cardName {
    final marketing =
        card['marketingName']
            ?.toString()
            .trim();

    if (marketing != null &&
        marketing.isNotEmpty) {
      return marketing;
    }

    final name =
        card['name']
            ?.toString()
            .trim();

    return name?.isNotEmpty ==
            true
        ? name!
        : 'Cartão';
  }

  String get _institutionName {
    final candidates = [
      card['institution_name'],
      card[
          'resolved_institution'],
      card['institution'],
      card['institutionName'],
    ];

    for (final candidate
        in candidates) {
      if (candidate != null &&
          candidate
              .toString()
              .trim()
              .isNotEmpty) {
        return candidate
            .toString()
            .trim();
      }
    }

    return 'Instituição';
  }

  String get _cardNumber {
    final value =
        card['number']
                ?.toString()
                .trim() ??
            '';

    if (value.isEmpty) {
      return '';
    }

    final last =
        value.length <= 4
            ? value
            : value.substring(
                value.length - 4,
              );

    return '•••• $last';
  }

  String get _brand {
    final value =
        _creditData?['brand']
            ?.toString()
            .trim();

    if (value == null ||
        value.isEmpty) {
      return '';
    }

    switch (value.toUpperCase()) {
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
        return value;
    }
  }

  String get _level {
    final value =
        _creditData?['level']
            ?.toString()
            .trim();

    if (value == null ||
        value.isEmpty) {
      return '';
    }

    final lower =
        value.toLowerCase();

    return lower[0]
            .toUpperCase() +
        lower.substring(1);
  }

  String get _brandAndLevel {
    if (_brand.isNotEmpty &&
        _level.isNotEmpty) {
      return '$_brand • $_level';
    }

    if (_brand.isNotEmpty) {
      return _brand;
    }

    if (_level.isNotEmpty) {
      return _level;
    }

    return 'Cartão de crédito';
  }

  String get _status {
    final value =
        _creditData?['status']
            ?.toString()
            .trim()
            .toUpperCase();

    switch (value) {
      case 'ACTIVE':
        return 'Ativo';
      case 'BLOCKED':
        return 'Bloqueado';
      case 'CANCELLED':
        return 'Cancelado';
      default:
        return value ??
            'Não informado';
    }
  }

  String get _dueDate {
    final raw =
        _creditData?[
            'balanceDueDate'];

    if (raw == null ||
        raw.toString().isEmpty) {
      return 'Não informado';
    }

    try {
      final date =
          DateTime.parse(
        raw.toString(),
      );

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  bool get _isFlexibleLimit =>
      _creditData?[
          'isLimitFlexible'] ==
      true;

  List<dynamic>
      get _transactions {
    final raw =
        card['transactions'];

    return raw is List
        ? raw
        : [];
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return FinancePage(
      title: 'Cartão',
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
          _creditCardVisual(),

          const SizedBox(
            height: 16,
          ),

          _limitCard(),

          const SizedBox(
            height: 14,
          ),

          _invoiceCard(),

          const SizedBox(
            height: 28,
          ),

          const FinanceSectionHeader(
            title:
                'Informações',
          ),

          const SizedBox(
            height: 12,
          ),

          _informationCard(),

          const SizedBox(
            height: 28,
          ),

          FinanceSectionHeader(
            title:
                'Movimentações',
            trailing:
                '${_transactions.length}',
          ),

          const SizedBox(
            height: 12,
          ),

          _transactionsButton(
            context,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CARTÃO VISUAL
  // =========================================================

  Widget _creditCardVisual() {
    return AspectRatio(
      aspectRatio: 1.62,
      child: Container(
        padding:
            const EdgeInsets.all(
          22,
        ),
        decoration:
            BoxDecoration(
          gradient:
              AppTheme
                  .premiumGradient,
          borderRadius:
              BorderRadius.circular(
            28,
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
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _institutionName,
                    style:
                        TextStyle(
                      color:
                          Colors.white
                              .withValues(
                        alpha:
                            0.70,
                      ),
                      fontSize:
                          12.5,
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white
                            .withValues(
                      alpha:
                          0.11,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child: Text(
                    _status,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          10,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            const Icon(
              Icons
                  .contactless_rounded,
              color:
                  Colors.white70,
              size: 28,
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              _cardName,
              maxLines: 1,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              _brandAndLevel,
              style:
                  TextStyle(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.66,
                ),
                fontSize: 11.5,
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _cardNumber,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      letterSpacing:
                          1.2,
                      fontSize:
                          14,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ),
                Text(
                  _brand
                      .toUpperCase(),
                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha:
                          0.82,
                    ),
                    fontSize: 12,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LIMITE
  // =========================================================

  Widget _limitCard() {
    return FinanceGlassCard(
      radius: 23,
      child: Padding(
        padding:
            const EdgeInsets.all(
          17,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Limite',
              style:
                  TextStyle(
                color:
                    AppTheme.ink,
                fontSize: 14.5,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      _metric(
                    'Utilizado',
                    _usedAmount,
                  ),
                ),

                Expanded(
                  child:
                      _metric(
                    'Disponível',
                    _availableLimit,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 17,
            ),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              child:
                  LinearProgressIndicator(
                value:
                    _utilization.clamp(
                  0.0,
                  1.0,
                ),
                minHeight: 5,
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

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '${(_utilization * 100).toStringAsFixed(1)}% utilizado',
                    style:
                        const TextStyle(
                      color:
                          AppTheme
                              .inkSoft,
                      fontSize:
                          10.5,
                    ),
                  ),
                ),
                Text(
                  'Limite ${formatCurrency(_creditLimit)}',
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
          ],
        ),
      ),
    );
  }

  Widget _metric(
    String label,
    double value,
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
          height: 5,
        ),
        Text(
          formatCurrency(value),
          style:
              const TextStyle(
            color:
                AppTheme.ink,
            fontSize: 16,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FATURA
  // =========================================================

  Widget _invoiceCard() {
    return FinanceGlassCard(
      radius: 23,
      child: Padding(
        padding:
            const EdgeInsets.all(
          17,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const FinanceIconBubble(
                  icon:
                      Icons
                          .receipt_long_rounded,
                ),
                const SizedBox(
                  width: 13,
                ),
                const Expanded(
                  child: Text(
                    'Resumo da fatura',
                    style:
                        TextStyle(
                      color:
                          AppTheme.ink,
                      fontSize: 14,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 17,
            ),

            _infoRow(
              'Valor em uso',
              formatCurrency(
                _usedAmount,
              ),
            ),

            _infoRow(
              'Vencimento',
              _dueDate,
            ),

            _infoRow(
              'Pagamento mínimo',
              formatCurrency(
                _minimumPayment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _informationCard() {
    return FinanceGlassCard(
      radius: 23,
      child: Padding(
        padding:
            const EdgeInsets.all(
          17,
        ),
        child: Column(
          children: [
            _infoRow(
              'Instituição',
              _institutionName,
            ),
            _infoRow(
              'Bandeira',
              _brand.isEmpty
                  ? 'Não informado'
                  : _brand,
            ),
            _infoRow(
              'Categoria',
              _level.isEmpty
                  ? 'Não informado'
                  : _level,
            ),
            _infoRow(
              'Status',
              _status,
            ),
            _infoRow(
              'Limite flexível',
              _isFlexibleLimit
                  ? 'Sim'
                  : 'Não',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
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
                fontSize: 11.5,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color:
                    AppTheme.ink,
                fontSize: 11.5,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionsButton(
    BuildContext context,
  ) {
    return FinanceGlassCard(
      radius: 22,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CreditCardTransactionsScreen(
              card: card,
            ),
          ),
        );
      },
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Row(
          children: [
            const FinanceIconBubble(
              icon:
                  Icons
                      .receipt_long_rounded,
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
                    'Ver todas as compras',
                    style:
                        TextStyle(
                      color:
                          AppTheme.ink,
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
                    '${_transactions.length} movimentações',
                    style:
                        const TextStyle(
                      color:
                          AppTheme
                              .inkSoft,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons
                  .chevron_right_rounded,
              color:
                  AppTheme.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}