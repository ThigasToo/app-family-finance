import 'package:flutter/material.dart';
import 'credit_card_transactions_screen.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CreditCardDetailScreen
    extends StatelessWidget {
  final Map<String, dynamic> card;

  const CreditCardDetailScreen({
    super.key,
    required this.card,
  });

  // =========================================================
  // HELPERS BÁSICOS
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

  double get _usedAmount {
    return _asDouble(
      card['balance'],
    );
  }

  double get _creditLimit {
    return _asDouble(
      _creditData?['creditLimit'],
    );
  }

  double get _availableLimit {
    return _asDouble(
      _creditData?[
          'availableCreditLimit'],
    );
  }

  double get _minimumPayment {
    return _asDouble(
      _creditData?[
          'minimumPayment'],
    );
  }

  double get _utilization {
    if (_creditLimit <= 0) {
      return 0;
    }

    return _usedAmount /
        _creditLimit;
  }

  String get _cardName {
    final marketingName =
        card['marketingName']
            ?.toString()
            .trim();

    if (marketingName != null &&
        marketingName.isNotEmpty) {
      return marketingName;
    }

    final name =
        card['name']
            ?.toString()
            .trim();

    if (name != null &&
        name.isNotEmpty) {
      return name;
    }

    return 'Cartão';
  }

  String get _institutionName {
    final candidates = [
      card['institution_name'],
      card['resolved_institution'],
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

  String get _brand {
    final value =
        _creditData?['brand']
            ?.toString()
            .trim();

    if (value == null ||
        value.isEmpty) {
      return '';
    }

    switch (
        value.toUpperCase()) {
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

    return lower[0].toUpperCase() +
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
        return value ?? 'Não informado';
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

  bool get _isFlexibleLimit {
    return _creditData?[
            'isLimitFlexible'] ==
        true;
  }

  List<dynamic> get _transactions {
    final raw =
        card['transactions'];

    if (raw is List) {
      return raw;
    }

    return [];
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
        title: const Text(
          'Cartão',
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
          _buildCardHeader(),

          const SizedBox(
            height: 20,
          ),

          _buildLimitCard(),

          const SizedBox(
            height: 16,
          ),

          _buildInvoiceCard(),

          const SizedBox(
            height: 28,
          ),

          _buildSectionTitle(
            'Informações do cartão',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildInformationCard(),

          const SizedBox(
            height: 28,
          ),

          _buildPurchasesPreview(
            context,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER DO CARTÃO
  // =========================================================

  Widget _buildCardHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        22,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  _institutionName,
                  style: TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.66,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),

              _buildStatusBadge(),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            _cardName,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.2,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            _brandAndLevel,
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.70,
              ),
              fontSize: 13,
            ),
          ),

          if (_cardNumber
              .isNotEmpty) ...[
            const SizedBox(
              height: 18,
            ),

            Text(
              _cardNumber,
              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: 0.72,
                ),
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white
            .withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        _status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // =========================================================
  // LIMITE
  // =========================================================

  Widget _buildLimitCard() {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Limite',
            style: TextStyle(
              fontSize: 15,
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
                    _buildMetric(
                  'Utilizado',
                  formatCurrency(
                    _usedAmount,
                  ),
                ),
              ),

              Expanded(
                child:
                    _buildMetric(
                  'Disponível',
                  formatCurrency(
                    _availableLimit,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            child:
                LinearProgressIndicator(
              value: _utilization
                  .clamp(
                    0.0,
                    1.0,
                  )
                  .toDouble(),
              minHeight: 7,
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
            height: 9,
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${(_utilization * 100).toStringAsFixed(1)}% utilizado',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors
                        .grey.shade500,
                  ),
                ),
              ),

              Text(
                'Limite ${formatCurrency(_creditLimit)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors
                      .grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
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
          height: 4,
        ),

        Text(
          value,
          style:
              const TextStyle(
            fontSize: 18,
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

  Widget _buildInvoiceCard() {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color: AppTheme
                      .primary
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons
                      .receipt_long_outlined,
                  color:
                      AppTheme.primary,
                  size: 20,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Text(
                  'Resumo da fatura',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          _buildInfoRow(
            'Valor em uso',
            formatCurrency(
              _usedAmount,
            ),
          ),

          _buildInfoRow(
            'Vencimento',
            _dueDate,
          ),

          _buildInfoRow(
            'Pagamento mínimo',
            formatCurrency(
              _minimumPayment,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFORMAÇÕES
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
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
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
          _buildInfoRow(
            'Instituição',
            _institutionName,
          ),

          _buildInfoRow(
            'Bandeira',
            _brand.isEmpty
                ? 'Não informado'
                : _brand,
          ),

          _buildInfoRow(
            'Categoria',
            _level.isEmpty
                ? 'Não informado'
                : _level,
          ),

          _buildInfoRow(
            'Final do cartão',
            _cardNumber.isEmpty
                ? 'Não informado'
                : _cardNumber,
          ),

          _buildInfoRow(
            'Status',
            _status,
          ),

          _buildInfoRow(
            'Limite flexível',
            _isFlexibleLimit
                ? 'Sim'
                : 'Não',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool showDivider = true,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 11,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom:
                    BorderSide(
                  color: Colors
                      .grey.shade100,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors
                    .grey.shade500,
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // COMPRAS - PREVIEW DO 4D
  // =========================================================

  Widget _buildPurchasesPreview(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Compras',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            Text(
              '${_transactions.length}',
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.grey.shade500,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        Material(
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CreditCardTransactionsScreen(
                    card:
                        Map<String, dynamic>.from(
                      card,
                    ),
                  ),
                ),
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
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(
                      color: AppTheme.primary
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .shopping_bag_outlined,
                      color:
                          AppTheme.primary,
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
                          'Ver compras do cartão',
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
                          _transactions.isEmpty
                              ? 'Nenhuma transação carregada'
                              : '${_transactions.length} movimentações disponíveis',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors
                                .grey
                                .shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons
                        .chevron_right_rounded,
                    color: Colors
                        .grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}