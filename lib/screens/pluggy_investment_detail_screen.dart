import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PluggyInvestmentDetailScreen
    extends StatelessWidget {
  final Map<String, dynamic> investment;

  const PluggyInvestmentDetailScreen({
    super.key,
    required this.investment,
  });

  // =========================================================
  // VALORES PRINCIPAIS
  // =========================================================

  double get _currentValue {
    return _asDouble(
      investment['balance'] ??
          investment['current_value'],
    );
  }

  double? get _originalValue {
    final value =
        investment['amountOriginal'];

    if (value == null) {
      return null;
    }

    return _asDouble(value);
  }

  double? get _profitValue {
    final amountProfit =
        investment['amountProfit'];

    if (amountProfit != null) {
      return _asDouble(
        amountProfit,
      );
    }

    final original =
        _originalValue;

    if (original != null) {
      return _currentValue -
          original;
    }

    return null;
  }

  double? get _profitPercentage {
    final original =
        _originalValue;

    if (original == null ||
        original == 0) {
      return null;
    }

    return (
      (_currentValue / original) - 1
    ) * 100;
  }

  // =========================================================
  // IDENTIFICAÇÃO
  // =========================================================

  String get _name {
    final value =
        investment['name'];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'Investimento';
    }

    return value
        .toString()
        .trim();
  }

  String get _type {
    final subtype =
        investment['subtype'];

    if (subtype != null &&
        subtype.toString().trim().isNotEmpty) {
      return _friendlyType(
        subtype.toString(),
      );
    }

    return _friendlyType(
      investment['type']
              ?.toString() ??
          'Investimento',
    );
  }

  String get _institution {
    final candidates = [
      investment[
          'institution_name'],
      investment[
          'resolved_institution'],
      investment['issuer'],
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

    return 'Instituição';
  }

  // =========================================================
  // TAXA CONTRATADA
  // =========================================================

  String? get _contractedRate {
    final rawRate =
        investment['rate'];

    final rawRateType =
        investment['rateType'];

    final rawFixedRate =
        investment['fixedAnnualRate'];

    final bool hasRate =
        rawRate != null;

    final bool hasRateType =
        rawRateType != null &&
        rawRateType
            .toString()
            .trim()
            .isNotEmpty;

    final bool hasFixedRate =
        rawFixedRate != null;

    final rate = hasRate
        ? _asDouble(rawRate)
        : null;

    final fixedRate =
        hasFixedRate
            ? _asDouble(rawFixedRate)
            : null;

    final rateType =
        hasRateType
            ? rawRateType
                .toString()
                .trim()
                .toUpperCase()
            : null;

    // =====================================================
    // INDEXADO + TAXA FIXA
    //
    // Ex:
    // 100% IPCA + 6,50% a.a.
    // =====================================================

    if (rate != null &&
        rateType != null &&
        fixedRate != null) {
      // Se for 100% do indexador,
      // visualmente fica mais natural:
      //
      // IPCA + 6,50% a.a.
      //
      // em vez de:
      //
      // 100% do IPCA + 6,50% a.a.

      if (rate == 100) {
        return '$rateType + '
            '${_cleanNumber(fixedRate)}% a.a.';
      }

      return '${_cleanNumber(rate)}% do '
          '$rateType + '
          '${_cleanNumber(fixedRate)}% a.a.';
    }

    // =====================================================
    // INDEXADO
    //
    // Ex:
    // 102% do CDI
    // =====================================================

    if (rate != null &&
        rateType != null) {
      return '${_cleanNumber(rate)}% do $rateType';
    }

    // =====================================================
    // PREFIXADO
    //
    // Ex:
    // 16,76% a.a.
    // =====================================================

    if (fixedRate != null) {
      return '${_cleanNumber(fixedRate)}% a.a.';
    }

    // =====================================================
    // TAXA SEM INDEXADOR
    // =====================================================

    if (rate != null) {
      return '${_cleanNumber(rate)}%';
    }

    return null;
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
          'Detalhes do investimento',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            36,
          ),
          children: [
            _buildHeader(),

            const SizedBox(
              height: 20,
            ),

            _buildValueCard(),

            // =================================================
            // RENTABILIDADE / TAXA CONTRATADA
            // =================================================

            if (_hasRateInfo) ...[
              const SizedBox(
                height: 30,
              ),

              _buildSectionTitle(
                'Rentabilidade',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildRateCard(),
            ],

            const SizedBox(
              height: 30,
            ),

            _buildSectionTitle(
              'Informações do investimento',
            ),

            const SizedBox(
              height: 12,
            ),

            _buildInformationCard(),

            if (_hasDates) ...[
              const SizedBox(
                height: 30,
              ),

              _buildSectionTitle(
                'Datas',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildDatesCard(),
            ],

            if (_hasTaxes) ...[
              const SizedBox(
                height: 30,
              ),

              _buildSectionTitle(
                'Impostos e resgate',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildTaxesCard(),
            ],

            const SizedBox(
              height: 28,
            ),

            _buildSyncNotice(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildInvestmentIcon(),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _name,
                style:
                    const TextStyle(
                  fontSize: 19,
                  height: 1.25,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                '$_type • $_institution',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors
                      .grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CARD PRINCIPAL
  // =========================================================

  Widget _buildValueCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        color:
            AppTheme.primary,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Valor atual',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white
                  .withValues(
                alpha: 0.7,
              ),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            formatCurrency(
              _currentValue,
            ),
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),

          if (_originalValue !=
              null) ...[
            const SizedBox(
              height: 22,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      _buildValueDetail(
                    'Aplicado',
                    formatCurrency(
                      _originalValue!,
                    ),
                  ),
                ),

                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white
                      .withValues(
                    alpha: 0.2,
                  ),
                ),

                const SizedBox(
                  width: 18,
                ),

                Expanded(
                  child:
                      _buildValueDetail(
                    'Resultado',
                    _formatProfit(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValueDetail(
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
            color: Colors.white
                .withValues(
              alpha: 0.62,
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

  String _formatProfit() {
    final profit =
        _profitValue;

    final percentage =
        _profitPercentage;

    if (profit == null) {
      return '-';
    }

    final money =
        formatCurrency(profit);

    if (percentage == null) {
      return money;
    }

    final prefix =
        percentage >= 0
            ? '+'
            : '';

    return '$money '
        '($prefix${percentage.toStringAsFixed(2).replaceAll('.', ',')}%)';
  }

  // =========================================================
  // RENTABILIDADE
  // =========================================================

  bool get _hasRateInfo {
    return _contractedRate != null ||
        investment[
                'annualRate'] !=
            null ||
        investment[
                'lastMonthRate'] !=
            null ||
        investment[
                'lastTwelveMonthsRate'] !=
            null;
  }

  Widget _buildRateCard() {
    final rows =
        <Widget>[];

    // =====================================================
    // TAXA CONTRATADA
    // =====================================================

    if (_contractedRate != null) {
      rows.add(
        _buildInfoRow(
          'Taxa contratada',
          _contractedRate!,
          highlight: true,
        ),
      );
    }

    // =====================================================
    // RENTABILIDADES INFORMADAS PELA PLUGGY
    // =====================================================

    if (investment[
            'annualRate'] !=
        null) {
      rows.add(
        _buildInfoRow(
          'Rentabilidade anual',
          _formatPercent(
            investment[
                'annualRate'],
          ),
        ),
      );
    }

    if (investment[
            'lastMonthRate'] !=
        null) {
      rows.add(
        _buildInfoRow(
          'Último mês',
          _formatPercent(
            investment[
                'lastMonthRate'],
          ),
        ),
      );
    }

    if (investment[
            'lastTwelveMonthsRate'] !=
        null) {
      rows.add(
        _buildInfoRow(
          'Últimos 12 meses',
          _formatPercent(
            investment[
                'lastTwelveMonthsRate'],
          ),
        ),
      );
    }

    return _buildWhiteCard(
      children: rows,
    );
  }

  // =========================================================
  // INFORMAÇÕES
  // =========================================================

  Widget _buildInformationCard() {
    final rows =
        <Widget>[];

    void add(
      String label,
      dynamic value,
    ) {
      if (value == null ||
          value
              .toString()
              .trim()
              .isEmpty) {
        return;
      }

      rows.add(
        _buildInfoRow(
          label,
          value.toString(),
        ),
      );
    }

    add(
      'Tipo',
      _type,
    );

    add(
      'Instituição',
      _institution,
    );

    add(
      'Emissor',
      investment['issuer'],
    );

    add(
      'CNPJ do emissor',
      investment['issuerCNPJ'],
    );

    add(
      'Código',
      investment['code'],
    );

    add(
      'ISIN',
      investment['isin'],
    );

    final quantity =
        investment['quantity'];

    if (quantity != null) {
      rows.add(
        _buildInfoRow(
          'Quantidade',
          _formatNumber(
            quantity,
          ),
        ),
      );
    }

    final unitValue =
        investment['value'];

    if (unitValue != null) {
      rows.add(
        _buildInfoRow(
          'Valor unitário',
          formatCurrency(
            _asDouble(
              unitValue,
            ),
          ),
        ),
      );
    }

    add(
      'Moeda',
      investment[
          'currencyCode'],
    );

    final taxExempt =
        investment['taxExempt'];

    if (taxExempt != null) {
      rows.add(
        _buildInfoRow(
          'Isento de IR',
          taxExempt == true
              ? 'Sim'
              : 'Não',
        ),
      );
    }

    final status =
        investment['status'];

    if (status != null) {
      rows.add(
        _buildInfoRow(
          'Status',
          _friendlyStatus(
            status.toString(),
          ),
        ),
      );
    }

    return _buildWhiteCard(
      children: rows,
    );
  }

  // =========================================================
  // DATAS
  // =========================================================

  bool get _hasDates {
    return investment[
                'purchaseDate'] !=
            null ||
        investment[
                'issueDate'] !=
            null ||
        investment[
                'dueDate'] !=
            null ||
        investment[
                'gracePeriodDate'] !=
            null;
  }

  Widget _buildDatesCard() {
    final rows =
        <Widget>[];

    void addDate(
      String label,
      dynamic value,
    ) {
      if (value == null) {
        return;
      }

      rows.add(
        _buildInfoRow(
          label,
          _formatDate(value),
        ),
      );
    }

    addDate(
      'Data da aplicação',
      investment[
          'purchaseDate'],
    );

    addDate(
      'Data de emissão',
      investment[
          'issueDate'],
    );

    addDate(
      'Carência',
      investment[
          'gracePeriodDate'],
    );

    addDate(
      'Vencimento',
      investment[
          'dueDate'],
    );

    return _buildWhiteCard(
      children: rows,
    );
  }

  // =========================================================
  // IMPOSTOS
  // =========================================================

  bool get _hasTaxes {
    return investment['taxes'] !=
            null ||
        investment['taxes2'] !=
            null ||
        investment[
                'amountWithdrawal'] !=
            null;
  }

  Widget _buildTaxesCard() {
    final rows =
        <Widget>[];

    if (investment[
            'taxes'] !=
        null) {
      rows.add(
        _buildInfoRow(
          'Impostos',
          formatCurrency(
            _asDouble(
              investment[
                  'taxes'],
            ),
          ),
        ),
      );
    }

    if (investment[
            'taxes2'] !=
        null) {
      rows.add(
        _buildInfoRow(
          'Outros impostos',
          formatCurrency(
            _asDouble(
              investment[
                  'taxes2'],
            ),
          ),
        ),
      );
    }

    if (investment[
            'amountWithdrawal'] !=
        null) {
      rows.add(
        _buildInfoRow(
          'Valor líquido para resgate',
          formatCurrency(
            _asDouble(
              investment[
                  'amountWithdrawal'],
            ),
          ),
        ),
      );
    }

    return _buildWhiteCard(
      children: rows,
    );
  }

  // =========================================================
  // AVISO DE SINCRONIZAÇÃO
  // =========================================================

  Widget _buildSyncNotice() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary
            .withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sync_rounded,
            size: 19,
            color:
                AppTheme.primary,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              'As informações deste investimento são sincronizadas automaticamente pela instituição conectada.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors
                    .grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // COMPONENTES
  // =========================================================

  Widget _buildWhiteCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 15,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlight
                    ? Colors
                        .grey.shade700
                    : Colors
                        .grey.shade500,
                fontSize: 13,
                fontWeight: highlight
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                fontSize: highlight
                    ? 15
                    : 13,
                fontWeight: highlight
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: highlight
                    ? AppTheme.primary
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style:
          const TextStyle(
        fontSize: 17,
        fontWeight:
            FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildInvestmentIcon() {
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
      width: 52,
      height: 52,
      decoration:
          BoxDecoration(
        color: AppTheme.primary
            .withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Icon(
        icon,
        color:
            AppTheme.primary,
        size: 24,
      ),
    );
  }

  // =========================================================
  // FORMATAÇÃO
  // =========================================================

  double _asDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  String _cleanNumber(
    double value,
  ) {
    if (value ==
        value.truncateToDouble()) {
      return value
          .toInt()
          .toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  String _formatNumber(
    dynamic value,
  ) {
    final number =
        _asDouble(value);

    if (number ==
        number.truncateToDouble()) {
      return number
          .toInt()
          .toString();
    }

    return number
        .toStringAsFixed(8)
        .replaceFirst(
          RegExp(r'0+$'),
          '',
        )
        .replaceFirst(
          RegExp(r'\.$'),
          '',
        );
  }

  String _formatPercent(
    dynamic value,
  ) {
    final number =
        _asDouble(value);

    final prefix =
        number > 0
            ? '+'
            : '';

    return '$prefix'
        '${number.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  String _formatDate(
    dynamic value,
  ) {
    try {
      final date =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      final day = date.day
          .toString()
          .padLeft(2, '0');

      final month = date.month
          .toString()
          .padLeft(2, '0');

      return '$day/$month/${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _friendlyStatus(
    String status,
  ) {
    switch (
        status.toUpperCase()) {
      case 'ACTIVE':
        return 'Ativo';

      case 'PENDING':
        return 'Pendente';

      case 'CLOSED':
        return 'Encerrado';

      case 'MATURED':
        return 'Vencido';

      default:
        return status;
    }
  }

  String _friendlyType(
    String value,
  ) {
    switch (
        value.toUpperCase()) {
      case 'CDB':
        return 'CDB';

      case 'LCI':
        return 'LCI';

      case 'LCA':
        return 'LCA';

      case 'FIXED_INCOME':
        return 'Renda fixa';

      case 'ETF':
        return 'ETF';

      case 'STOCK':
        return 'Ação';

      case 'CRYPTO':
        return 'Criptomoeda';

      case 'FUND':
      case 'INVESTMENT_FUND':
        return 'Fundo';

      default:
        return value
            .replaceAll(
              '_',
              ' ',
            )
            .toLowerCase()
            .split(' ')
            .map(
              (word) =>
                  word.isEmpty
                      ? ''
                      : word[0]
                              .toUpperCase() +
                          word.substring(
                            1,
                          ),
            )
            .join(' ');
    }
  }
}