import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../services/privacy_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';


enum MonthlyCalculationType {
  creditCards,
  pix,
}


class MonthlyCalculationDetailScreen
    extends StatefulWidget {
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
  State<MonthlyCalculationDetailScreen>
      createState() =>
          _MonthlyCalculationDetailScreenState();
}


class _MonthlyCalculationDetailScreenState
    extends State<MonthlyCalculationDetailScreen> {
  final _financeService = FinanceService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

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
      final data =
          await _financeService.getMonthlyBreakdown(
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
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> get _section {
    final key =
        widget.type == MonthlyCalculationType.creditCards
            ? 'credit_cards'
            : 'pix';

    final raw = _data?[key];

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  List<Map<String, dynamic>> get _items {
    final raw = _section['items'];

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get _total => _number(_section['total']);
  double get _pixSent => _number(_section['sent_total']);
  double get _pixReceived => _number(_section['received_total']);
  double get _pixNet => _number(_section['net']);

  int get _count {
    final value = _section['count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return _items.length;
  }

  String get _title =>
      widget.type == MonthlyCalculationType.creditCards
          ? 'Cartões do mês'
          : 'Movimentações PIX';

  String get _subtitle =>
      widget.type == MonthlyCalculationType.creditCards
          ? 'Ciclo do dia 5 deste mês até antes do dia 5 do mês seguinte'
          : 'Entradas e saídas PIX de todas as contas conectadas';

  IconData get _icon =>
      widget.type == MonthlyCalculationType.creditCards
          ? Icons.credit_card_rounded
          : Icons.pix_rounded;

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

  String? _installmentLabel(
    Map<String, dynamic> item,
  ) {
    final current = item['installment_number'];
    final total = item['installment_total'];

    if (current == null || total == null) {
      return null;
    }

    return 'Parcela $current/$total';
  }

  bool _isPixOut(Map<String, dynamic> item) =>
      item['direction']?.toString().toUpperCase() == 'OUT';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_title),
      ),
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 22),
          Text(
            widget.type == MonthlyCalculationType.creditCards
                ? 'LANÇAMENTOS DA FATURA'
                : 'MOVIMENTAÇÕES PIX',
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
      valueListenable:
          PrivacyService.instance.valuesVisible,
      builder: (context, _, __) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration:
              AppTheme.glassDarkDecoration(radius: 26),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _icon,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                          widget.type == MonthlyCalculationType.creditCards
                              ? 'Fatura calculada pelo ciclo'
                              : 'Fluxo PIX do mês',
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
              if (widget.type == MonthlyCalculationType.creditCards)
                _buildCardSummary()
              else
                _buildPixSummary(),
              const SizedBox(height: 14),
              Text(
                _subtitle,
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
          _money(_total),
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

  Widget _buildPixSummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPixMetric(
                label: 'Recebido',
                value: _pixReceived,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPixMetric(
                label: 'Enviado',
                value: _pixSent,
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Saldo líquido PIX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _money(_pixNet),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$_count movimentações PIX encontradas',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPixMetric({
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 28,
      ),
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
            widget.type == MonthlyCalculationType.creditCards
                ? 'Nenhum lançamento entrou nesta fatura.'
                : 'Nenhuma movimentação PIX encontrada neste mês.',
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

  Widget _buildItemCard(
    Map<String, dynamic> item,
  ) {
    final institution =
        item['institution']?.toString() ?? 'Instituição';
    final accountName =
        widget.type == MonthlyCalculationType.creditCards
            ? item['card_name']?.toString()
            : item['account_name']?.toString();
    final description =
        item['description']?.toString() ?? 'Lançamento';
    final installment = _installmentLabel(item);
    final pixOut = _isPixOut(item);
    final amount = _number(item['amount']);

    return ValueListenableBuilder<bool>(
      valueListenable:
          PrivacyService.instance.valuesVisible,
      builder: (context, _, __) {
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
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.type == MonthlyCalculationType.pix
                      ? (pixOut
                          ? Icons.north_east_rounded
                          : Icons.south_west_rounded)
                      : _icon,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                          widget.type == MonthlyCalculationType.pix
                              ? '${pixOut ? '-' : '+'} ${_money(amount)}'
                              : _money(amount),
                          style: TextStyle(
                            color: widget.type == MonthlyCalculationType.pix
                                ? (pixOut
                                    ? AppTheme.danger
                                    : AppTheme.success)
                                : AppTheme.ink,
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
                        if (widget.type == MonthlyCalculationType.pix)
                          pixOut ? 'Enviado' : 'Recebido',
                        if (widget.type == MonthlyCalculationType.pix &&
                            item['counterparty'] != null)
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
