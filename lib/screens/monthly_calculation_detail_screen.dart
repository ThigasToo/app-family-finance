import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../services/privacy_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';


enum MonthlyCalculationType {
  creditCards,
  pix,
}


class MonthlyCalculationDetailScreen extends StatefulWidget {
  final String month;
  final String monthLabel;
  final MonthlyCalculationType type;

  const MonthlyCalculationDetailScreen({
    super.key,
    required this.month,
    required this.monthLabel,
    required this.type,
  });

  @override
  State<MonthlyCalculationDetailScreen> createState() =>
      _MonthlyCalculationDetailScreenState();
}


class _MonthlyCalculationDetailScreenState
    extends State<MonthlyCalculationDetailScreen> {
  final _financeService = FinanceService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  bool get _isCards =>
      widget.type == MonthlyCalculationType.creditCards;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final data = await _financeService.getMonthlyBreakdown(
        month: widget.month,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Map<String, dynamic> get _cardSection =>
      _map(_data?['credit_cards']);

  Map<String, dynamic> get _cashFlow =>
      _map(_data?['cash_flow'] ?? _data?['pix']);

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get _items =>
      _list(_isCards ? _cardSection['items'] : _cashFlow['items']);

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get _cardTotal => _number(_cardSection['total']);
  double get _externalIn => _number(_cashFlow['external_in']);
  double get _externalOut => _number(_cashFlow['external_out']);
  double get _applications =>
      _number(_cashFlow['investment_applications']);
  double get _redemptions =>
      _number(_cashFlow['investment_redemptions']);
  double get _internalTransfers =>
      _number(_cashFlow['internal_transfers']);
  double get _cashIn => _externalIn + _redemptions;
  double get _cashOut => _externalOut + _applications;
  double get _cashNet => _number(_cashFlow['net']);

  int get _count {
    final value = _isCards
        ? _cardSection['count']
        : _cashFlow['count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return _items.length;
  }

  String get _title => _isCards
      ? 'Cartões do mês'
      : 'Fluxo de caixa';

  IconData get _icon => _isCards
      ? Icons.credit_card_rounded
      : Icons.swap_vert_circle_rounded;

  String _money(double value) {
    return PrivacyService.instance.valuesVisible.value
        ? formatCurrency(value)
        : '••••••';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Data não informada';
    try {
      final date = DateTime.parse(value.toString());
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String? _installmentLabel(Map<String, dynamic> item) {
    final current = item['installment_number'];
    final total = item['installment_total'];
    if (current == null || total == null) return null;
    return 'Parcela $current/$total';
  }

  String _classification(Map<String, dynamic> item) =>
      item['classification']?.toString().toUpperCase() ?? '';

  bool _isInternal(Map<String, dynamic> item) =>
      _classification(item) == 'INTERNAL_TRANSFER';

  bool _isPositiveImpact(Map<String, dynamic> item) =>
      _number(item['impact']) > 0;

  String _classificationLabel(Map<String, dynamic> item) {
    switch (_classification(item)) {
      case 'EXTERNAL_IN':
        return 'Entrada externa';
      case 'EXTERNAL_OUT':
        return 'Saída externa';
      case 'INTERNAL_TRANSFER':
        return 'Transferência própria • neutra';
      case 'INVESTMENT_APPLICATION':
        return 'Aplicação em investimento';
      case 'INVESTMENT_REDEMPTION':
        return 'Resgate de investimento';
      default:
        return item['direction']?.toString().toUpperCase() == 'OUT'
            ? 'Saída'
            : 'Entrada';
    }
  }

  IconData _flowIcon(Map<String, dynamic> item) {
    switch (_classification(item)) {
      case 'INVESTMENT_APPLICATION':
        return Icons.trending_up_rounded;
      case 'INVESTMENT_REDEMPTION':
        return Icons.savings_outlined;
      case 'INTERNAL_TRANSFER':
        return Icons.sync_alt_rounded;
      case 'EXTERNAL_OUT':
        return Icons.north_east_rounded;
      default:
        return Icons.south_west_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          top: false,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: AppTheme.danger,
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 22),
          Text(
            _isCards ? 'LANÇAMENTOS DA FATURA' : 'MOVIMENTAÇÕES DO CAIXA',
            style: TextStyle(
              color: AppTheme.inkSoft.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            _buildEmptyState()
          else
            ..._items.map(_buildItemCard),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: PrivacyService.instance.valuesVisible,
      builder: (context, _, __) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDarkDecoration(radius: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_icon, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.monthLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isCards
                              ? 'Fatura calculada pelo ciclo'
                              : 'Caixa disponível do mês',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (_isCards) _buildCardSummary() else _buildCashFlowSummary(),
              const SizedBox(height: 14),
              Text(
                _isCards
                    ? 'Ciclo do dia 5 deste mês até antes do dia 5 do mês seguinte.'
                    : 'Transferências entre suas próprias contas são neutras. Aplicações reduzem o caixa disponível e resgates aumentam.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _money(_cardTotal),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 31,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '$_count ${_count == 1 ? 'lançamento' : 'lançamentos'} na fatura',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowSummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metric(
                label: 'Entradas no caixa',
                value: _cashIn,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metric(
                label: 'Saídas do caixa',
                value: _cashOut,
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Fluxo líquido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _money(_cashNet),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill('Aplicações ${_money(_applications)}'),
            _pill('Resgates ${_money(_redemptions)}'),
            if (_internalTransfers > 0)
              _pill('Transf. internas ${_money(_internalTransfers)}'),
          ],
        ),
      ],
    );
  }

  Widget _metric({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.white.withValues(alpha: 0.78),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _money(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: AppTheme.glassDecoration(radius: 22),
      child: Column(
        children: [
          Icon(
            _icon,
            size: 34,
            color: AppTheme.inkSoft.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 10),
          Text(
            _isCards
                ? 'Nenhum lançamento entrou nesta fatura.'
                : 'Nenhuma movimentação de caixa encontrada neste mês.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final institution =
        item['institution']?.toString() ?? 'Instituição';
    final accountName = _isCards
        ? item['card_name']?.toString()
        : item['account_name']?.toString();
    final description =
        item['description']?.toString() ?? 'Lançamento';
    final installment = _installmentLabel(item);
    final amount = _number(item['amount']);
    final impact = _number(item['impact']);
    final internal = !_isCards && _isInternal(item);
    final positive = !_isCards && _isPositiveImpact(item);
    final investmentName = item['investment_name']?.toString();

    return ValueListenableBuilder<bool>(
      valueListenable: PrivacyService.instance.valuesVisible,
      builder: (context, _, __) {
        final amountText = _isCards
            ? _money(amount)
            : internal
                ? _money(amount)
                : '${positive ? '+' : '-'} ${_money(impact.abs())}';

        final amountColor = _isCards || internal
            ? AppTheme.ink
            : positive
                ? AppTheme.success
                : AppTheme.danger;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration(
            radius: 20,
            opacity: 0.72,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isCards ? _icon : _flowIcon(item),
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          amountText,
                          style: TextStyle(
                            color: amountColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        institution,
                        if (accountName != null &&
                            accountName.trim().isNotEmpty)
                          accountName,
                        if (investmentName != null &&
                            investmentName.trim().isNotEmpty)
                          investmentName,
                      ].join(' • '),
                      style: const TextStyle(
                        color: AppTheme.inkSoft,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _formatDate(item['date']),
                        if (installment != null) installment,
                        if (!_isCards) _classificationLabel(item),
                        if (!_isCards && item['counterparty'] != null)
                          item['counterparty'].toString(),
                      ].join(' • '),
                      style: TextStyle(
                        color: AppTheme.inkSoft.withValues(alpha: 0.82),
                        fontSize: 10.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
