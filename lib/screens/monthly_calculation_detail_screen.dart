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
  final _commitmentController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Map<String, dynamic>? _data;
  double _manualCommitment = 0;

  bool get _isCards =>
      widget.type == MonthlyCalculationType.creditCards;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commitmentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _financeService.getMonthlyBreakdown(month: widget.month),
        if (!_isCards)
          _financeService.getManualCommitment(month: widget.month),
      ]);

      if (!mounted) return;

      final data = results.first as Map<String, dynamic>;
      final manual = _isCards ? 0.0 : results[1] as double;

      setState(() {
        _data = data;
        _manualCommitment = manual;
        _commitmentController.text =
            manual == 0 ? '' : manual.toStringAsFixed(2).replaceAll('.', ',');
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

  Future<void> _saveManualCommitment() async {
    if (_isSaving) return;

    final normalized = _commitmentController.text
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final value = normalized.isEmpty ? 0.0 : double.tryParse(normalized);

    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor válido para o mês.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final saved = await _financeService.saveManualCommitment(
        month: widget.month,
        amount: value,
      );

      if (!mounted) return;

      setState(() {
        _manualCommitment = saved;
        _commitmentController.text =
            saved == 0 ? '' : saved.toStringAsFixed(2).replaceAll('.', ',');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valor do mês salvo.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> get _cardSection =>
      _map(_data?['credit_cards']);

  Map<String, dynamic> get _rawPix =>
      _map(_data?['raw_pix']);

  Map<String, dynamic> get _cashFlow =>
      _map(_data?['cash_flow']);

  List<Map<String, dynamic>> get _items =>
      _isCards
          ? _list(_cardSection['items'])
          : _list(_cashFlow['items']);

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get _cardTotal => _number(_cardSection['total']);
  double get _pixReceived => _number(_rawPix['received_total']);
  double get _pixSent => _number(_rawPix['sent_total']);
  double get _applications =>
      _number(_cashFlow['investment_applications']);
  double get _redemptions =>
      _number(_cashFlow['investment_redemptions']);

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
      : 'Movimentações do mês';

  IconData get _icon => _isCards
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

  String? _installmentLabel(Map<String, dynamic> item) {
    final current = item['installment_number'];
    final total = item['installment_total'];
    if (current == null || total == null) return null;
    return 'Parcela $current/$total';
  }

  String _classification(Map<String, dynamic> item) =>
      item['classification']?.toString().toUpperCase() ?? '';

  String _classificationLabel(Map<String, dynamic> item) {
    switch (_classification(item)) {
      case 'EXTERNAL_IN':
        return 'PIX recebido';
      case 'EXTERNAL_OUT':
        return 'PIX enviado';
      case 'INTERNAL_TRANSFER':
        return 'Transferência entre contas';
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

  bool _isPositiveMovement(Map<String, dynamic> item) {
    final classification = _classification(item);
    return classification == 'EXTERNAL_IN' ||
        classification == 'INVESTMENT_REDEMPTION';
  }

  bool _isNeutralMovement(Map<String, dynamic> item) {
    return _classification(item) == 'INTERNAL_TRANSFER';
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
            _isCards ? 'LANÇAMENTOS DA FATURA' : 'MOVIMENTAÇÕES PARA CONSULTA',
            style: TextStyle(
              color: AppTheme.inkSoft.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          if (!_isCards)
            const Text(
              'A lista abaixo não altera o cálculo automaticamente. Use-a para conferir o mês e informe no card acima quanto deve entrar como comprometido.',
              style: TextStyle(
                color: AppTheme.inkSoft,
                fontSize: 11.5,
                height: 1.35,
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
                              : 'Consulta das movimentações',
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
              if (_isCards) _buildCardSummary() else _buildManualSummary(),
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
        const SizedBox(height: 12),
        Text(
          'Ciclo do dia 5 deste mês até antes do dia 5 do mês seguinte.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildManualSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valor a considerar como comprometido',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Analise as movimentações abaixo e informe manualmente o valor que deve reduzir o disponível deste mês.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _commitmentController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  labelText: 'Comprometido no mês',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                  prefixText: 'R\$ ',
                  prefixStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.60),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 58,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveManualCommitment,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Valor salvo: ${_money(_manualCommitment)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill('PIX recebidos ${_money(_pixReceived)}'),
            _pill('PIX enviados ${_money(_pixSent)}'),
            _pill('Aplicações ${_money(_applications)}'),
            _pill('Resgates ${_money(_redemptions)}'),
          ],
        ),
      ],
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
          color: Colors.white.withValues(alpha: 0.74),
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
                : 'Nenhuma movimentação encontrada neste mês.',
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
    final positive = !_isCards && _isPositiveMovement(item);
    final neutral = !_isCards && _isNeutralMovement(item);
    final investmentName = item['investment_name']?.toString();

    return ValueListenableBuilder<bool>(
      valueListenable: PrivacyService.instance.valuesVisible,
      builder: (context, _, __) {
        final amountText = _isCards
            ? _money(amount)
            : '${positive ? '+' : neutral ? '' : '-'} ${_money(amount)}';

        final amountColor = _isCards || neutral
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
