import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  double get _total {
    final value = _section['total'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  int get _count {
    final value = _section['count'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return _items.length;
  }

  String get _title =>
      widget.type == MonthlyCalculationType.creditCards
          ? 'Cartões do mês'
          : 'PIX enviados';

  String get _subtitle =>
      widget.type == MonthlyCalculationType.creditCards
          ? 'Compras e parcelas consideradas no cálculo automático'
          : 'Movimentações PIX consideradas no cálculo automático';

  IconData get _icon =>
      widget.type == MonthlyCalculationType.creditCards
          ? Icons.credit_card_rounded
          : Icons.pix_rounded;

  String _money(double value) {
    return PrivacyService.instance.valuesVisible.value
        ? formatCurrency(value)
        : '••••••';
  }

  double _itemAmount(Map<String, dynamic> item) {
    final value = item['amount'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Data não informada';

    try {
      final date = DateTime.parse(value.toString());
      return DateFormat('dd/MM/yyyy', 'pt_BR')
          .format(date);
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
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
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
            'LANÇAMENTOS CONSIDERADOS',
            style: TextStyle(
              color: AppTheme.inkSoft.withValues(
                alpha: 0.9,
              ),
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
              AppTheme.glassDarkDecoration(
            radius: 26,
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
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.10,
                      ),
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
                            color: Colors.white.withValues(
                              alpha: 0.70,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Calculado automaticamente',
                          style: TextStyle(
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
                '$_count ${_count == 1 ? 'lançamento considerado' : 'lançamentos considerados'}',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.72,
                  ),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.62,
                  ),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 28,
      ),
      decoration: AppTheme.glassDecoration(
        radius: 22,
      ),
      child: Column(
        children: [
          Icon(
            _icon,
            size: 34,
            color: AppTheme.inkSoft.withValues(
              alpha: 0.55,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nenhum lançamento entrou neste cálculo.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
    final installment =
        _installmentLabel(item);

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
                  color: AppTheme.primary.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  _icon,
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
                          _money(_itemAmount(item)),
                          style: const TextStyle(
                            color: AppTheme.ink,
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
                        if (installment != null)
                          installment,
                        if (widget.type ==
                                MonthlyCalculationType.pix &&
                            item['counterparty'] != null)
                          item['counterparty'].toString(),
                      ].join(' • '),
                      style: TextStyle(
                        color: AppTheme.inkSoft.withValues(
                          alpha: 0.82,
                        ),
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