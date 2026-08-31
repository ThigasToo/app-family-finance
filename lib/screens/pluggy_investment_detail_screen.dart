import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_ui.dart';


class PluggyInvestmentDetailScreen
    extends StatelessWidget {
  final Map<String, dynamic> investment;

  const PluggyInvestmentDetailScreen({
    super.key,
    required this.investment,
  });

  // =========================================================
  // VALORES
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
    final profit =
        investment['amountProfit'];

    if (profit != null) {
      return _asDouble(profit);
    }

    final original =
        _originalValue;

    if (original == null) {
      return null;
    }

    return _currentValue - original;
  }

  double? get _profitPercentage {
    final original =
        _originalValue;

    if (original == null ||
        original == 0) {
      return null;
    }

    return ((_currentValue / original) - 1) *
        100;
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

    return value.toString().trim();
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
      investment['institution_name'],
      investment['resolved_institution'],
      investment['issuer'],
      investment['institution'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return 'Instituição';
  }

  IconData get _investmentIcon {
    final type =
        '${investment['type'] ?? ''} '
                '${investment['subtype'] ?? ''}'
            .toUpperCase();

    if (type.contains('CRYPTO')) {
      return Icons.currency_bitcoin_rounded;
    }

    if (type.contains('ETF')) {
      return Icons.pie_chart_rounded;
    }

    if (type.contains('STOCK')) {
      return Icons.show_chart_rounded;
    }

    if (type.contains('FIXED') ||
        type.contains('CDB') ||
        type.contains('LCI') ||
        type.contains('LCA')) {
      return Icons.savings_rounded;
    }

    if (type.contains('FUND')) {
      return Icons.account_balance_rounded;
    }

    return Icons.trending_up_rounded;
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

    final rate =
        rawRate != null
            ? _asDouble(rawRate)
            : null;

    final fixedRate =
        rawFixedRate != null
            ? _asDouble(rawFixedRate)
            : null;

    final rateType =
        rawRateType != null &&
                rawRateType
                    .toString()
                    .trim()
                    .isNotEmpty
            ? rawRateType
                .toString()
                .trim()
                .toUpperCase()
            : null;

    if (rate != null &&
        rateType != null &&
        fixedRate != null) {
      if (rate == 100) {
        return '$rateType + '
            '${_cleanNumber(fixedRate)}% a.a.';
      }

      return '${_cleanNumber(rate)}% do '
          '$rateType + '
          '${_cleanNumber(fixedRate)}% a.a.';
    }

    if (rate != null &&
        rateType != null) {
      return '${_cleanNumber(rate)}% do $rateType';
    }

    if (fixedRate != null) {
      return '${_cleanNumber(fixedRate)}% a.a.';
    }

    if (rate != null) {
      return '${_cleanNumber(rate)}%';
    }

    return null;
  }

  bool get _hasRateInfo {
    return _contractedRate != null ||
        investment['annualRate'] != null ||
        investment['lastMonthRate'] != null ||
        investment[
                'lastTwelveMonthsRate'] !=
            null;
  }

  bool get _hasDates {
    return investment['purchaseDate'] != null ||
        investment['issueDate'] != null ||
        investment['dueDate'] != null ||
        investment['gracePeriodDate'] !=
            null;
  }

  bool get _hasTaxes {
    return investment['taxes'] != null ||
        investment['taxes2'] != null ||
        investment['amountWithdrawal'] !=
            null;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return FinancePage(
      title: 'Investimento',
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
          _buildIdentity(),

          const SizedBox(
            height: 16,
          ),

          _buildValueHero(),

          if (_hasRateInfo) ...[
            const SizedBox(
              height: 30,
            ),

            const FinanceSectionHeader(
              title: 'Rentabilidade',
            ),

            const SizedBox(
              height: 12,
            ),

            _buildRateCard(),
          ],

          const SizedBox(
            height: 30,
          ),

          const FinanceSectionHeader(
            title: 'Informações do investimento',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildInformationCard(),

          if (_hasDates) ...[
            const SizedBox(
              height: 30,
            ),

            const FinanceSectionHeader(
              title: 'Datas',
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

            const FinanceSectionHeader(
              title: 'Impostos e resgate',
            ),

            const SizedBox(
              height: 12,
            ),

            _buildTaxesCard(),
          ],

          const SizedBox(
            height: 24,
          ),

          _buildSyncNotice(),
        ],
      ),
    );
  }

  // =========================================================
  // IDENTIDADE
  // =========================================================

  Widget _buildIdentity() {
    return FinanceGlassCard(
      radius: 23,
      child: Padding(
        padding:
            const EdgeInsets.all(
          17,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            FinanceIconBubble(
              icon: _investmentIcon,
            ),

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
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    _type,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.inkSoft,
                      fontSize: 11.5,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    _institution,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          AppTheme.inkSoft
                              .withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.primary
                        .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child:
                  const Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_rounded,
                    color:
                        AppTheme.primary,
                    size: 13,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Text(
                    'Sincronizado',
                    style: TextStyle(
                      color:
                          AppTheme.primary,
                      fontSize: 9.5,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HERO
  // =========================================================

  Widget _buildValueHero() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        23,
      ),
      decoration:
          BoxDecoration(
        gradient:
            AppTheme.premiumGradient,
        borderRadius:
            BorderRadius.circular(
          29,
        ),
        border: Border.all(
          color:
              Colors.white.withValues(
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
            'Valor atual',
            style: TextStyle(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.65,
              ),
              fontSize: 12.5,
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
              fontSize: 32,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),

          if (_originalValue != null) ...[
            const SizedBox(
              height: 22,
            ),

            Container(
              padding:
                  const EdgeInsets.all(
                14,
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
                border: Border.all(
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
                        _heroMetric(
                      'Aplicado',
                      formatCurrency(
                        _originalValue!,
                      ),
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 38,
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
                        _heroMetric(
                      'Resultado',
                      _formatProfit(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroMetric(
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
            color:
                Colors.white
                    .withValues(
              alpha: 0.56,
            ),
            fontSize: 10.5,
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
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
      return '—';
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
        '($prefix'
        '${percentage.toStringAsFixed(2).replaceAll('.', ',')}%)';
  }

  // =========================================================
  // RENTABILIDADE
  // =========================================================

  Widget _buildRateCard() {
    final rows =
        <Widget>[];

    if (_contractedRate != null) {
      rows.add(
        _infoRow(
          'Taxa contratada',
          _contractedRate!,
          highlight: true,
        ),
      );
    }

    if (investment['annualRate'] != null) {
      rows.add(
        _infoRow(
          'Rentabilidade anual',
          _formatPercent(
            investment['annualRate'],
          ),
        ),
      );
    }

    if (investment['lastMonthRate'] !=
        null) {
      rows.add(
        _infoRow(
          'Último mês',
          _formatPercent(
            investment['lastMonthRate'],
          ),
        ),
      );
    }

    if (investment[
            'lastTwelveMonthsRate'] !=
        null) {
      rows.add(
        _infoRow(
          'Últimos 12 meses',
          _formatPercent(
            investment[
                'lastTwelveMonthsRate'],
          ),
        ),
      );
    }

    return _glassRows(
      rows,
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
          value.toString().trim().isEmpty) {
        return;
      }

      rows.add(
        _infoRow(
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

    if (investment['quantity'] != null) {
      rows.add(
        _infoRow(
          'Quantidade',
          _formatNumber(
            investment['quantity'],
          ),
        ),
      );
    }

    if (investment['value'] != null) {
      rows.add(
        _infoRow(
          'Valor unitário',
          formatCurrency(
            _asDouble(
              investment['value'],
            ),
          ),
        ),
      );
    }

    add(
      'Moeda',
      investment['currencyCode'],
    );

    if (investment['taxExempt'] != null) {
      rows.add(
        _infoRow(
          'Isento de IR',
          investment['taxExempt'] == true
              ? 'Sim'
              : 'Não',
        ),
      );
    }

    if (investment['status'] != null) {
      rows.add(
        _infoRow(
          'Status',
          _friendlyStatus(
            investment['status']
                .toString(),
          ),
        ),
      );
    }

    return _glassRows(
      rows,
    );
  }

  // =========================================================
  // DATAS
  // =========================================================

  Widget _buildDatesCard() {
    final rows =
        <Widget>[];

    void add(
      String label,
      dynamic value,
    ) {
      if (value == null) {
        return;
      }

      rows.add(
        _infoRow(
          label,
          _formatDate(value),
        ),
      );
    }

    add(
      'Data da aplicação',
      investment['purchaseDate'],
    );

    add(
      'Data de emissão',
      investment['issueDate'],
    );

    add(
      'Carência',
      investment['gracePeriodDate'],
    );

    add(
      'Vencimento',
      investment['dueDate'],
    );

    return _glassRows(
      rows,
    );
  }

  // =========================================================
  // IMPOSTOS
  // =========================================================

  Widget _buildTaxesCard() {
    final rows =
        <Widget>[];

    if (investment['taxes'] != null) {
      rows.add(
        _infoRow(
          'Impostos',
          formatCurrency(
            _asDouble(
              investment['taxes'],
            ),
          ),
        ),
      );
    }

    if (investment['taxes2'] != null) {
      rows.add(
        _infoRow(
          'Outros impostos',
          formatCurrency(
            _asDouble(
              investment['taxes2'],
            ),
          ),
        ),
      );
    }

    if (investment['amountWithdrawal'] !=
        null) {
      rows.add(
        _infoRow(
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

    return _glassRows(
      rows,
    );
  }

  // =========================================================
  // COMPONENTES
  // =========================================================

  Widget _glassRows(
    List<Widget> rows,
  ) {
    return FinanceGlassCard(
      radius: 23,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 3,
        ),
        child: Column(
          children: rows,
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        border:
            Border(
          bottom:
              BorderSide(
            color:
                AppTheme.line
                    .withValues(
              alpha: 0.6,
            ),
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
                color:
                    highlight
                        ? AppTheme.ink
                        : AppTheme.inkSoft,
                fontSize: 11.5,
                fontWeight:
                    highlight
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
                color:
                    highlight
                        ? AppTheme.primary
                        : AppTheme.ink,
                fontSize:
                    highlight
                        ? 13.5
                        : 11.5,
                fontWeight:
                    highlight
                        ? FontWeight.w800
                        : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncNotice() {
    return FinanceGlassCard(
      radius: 18,
      child: Padding(
        padding:
            const EdgeInsets.all(
          15,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const FinanceIconBubble(
              icon: Icons.sync_rounded,
            ),

            const SizedBox(
              width: 12,
            ),

            const Expanded(
              child: Text(
                'As informações deste investimento são sincronizadas automaticamente pela instituição conectada.',
                style: TextStyle(
                  color:
                      AppTheme.inkSoft,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
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
          value?.toString() ?? '',
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
        .replaceAll(
          '.',
          ',',
        );
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

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _friendlyStatus(
    String status,
  ) {
    switch (status.toUpperCase()) {
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
    switch (value.toUpperCase()) {
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
                          word.substring(1),
            )
            .join(' ');
    }
  }
}