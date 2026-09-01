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
  late DateTimeRange _cardRange;

  bool get _isCards =>
      widget.type == MonthlyCalculationType.creditCards;

  @override
  void initState() {
    super.initState();
    _cardRange = _fullMonthRange();
    _load();
  }

  @override
  void dispose() {
    _commitmentController.dispose();
    super.dispose();
  }

  DateTimeRange _fullMonthRange() {
    final parts = widget.month.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTimeRange(
      start: DateTime(year, month, 1),
      end: DateTime(year, month + 1, 0),
    );
  }

  DateTime _parseApiDate(dynamic value, DateTime fallback) {
    if (value == null) return fallback;
    return DateTime.tryParse(value.toString()) ?? fallback;
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      if (_isCards) {
        final period = await _financeService.getCardPeriod(
          month: widget.month,
        );
        final full = _fullMonthRange();
        final range = DateTimeRange(
          start: _parseApiDate(period['date_from'], full.start),
          end: _parseApiDate(period['date_to'], full.end),
        );

        final data = await _financeService.getMonthlyBreakdown(
          month: widget.month,
          dateFrom: range.start,
          dateTo: range.end,
        );

        if (!mounted) return;
        setState(() {
          _cardRange = range;
          _data = data;
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait([
        _financeService.getMonthlyBreakdown(month: widget.month),
        _financeService.getManualCommitment(month: widget.month),
      ]);

      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      final manual = results[1] as double;

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

  Future<void> _selectCardRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      initialDateRange: _cardRange,
      helpText: 'Filtrar lançamentos dos cartões',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );

    if (selected == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _financeService.saveCardPeriod(
        month: widget.month,
        dateFrom: selected.start,
        dateTo: selected.end,
      );
      if (!mounted) return;
      setState(() => _cardRange = selected);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _resetCardRange() async {
    setState(() => _isLoading = true);
    try {
      await _financeService.resetCardPeriod(month: widget.month);
      if (!mounted) return;
      setState(() => _cardRange = _fullMonthRange());
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  double? _parseCurrencyInput(String input) {
    var value = input.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (value.contains(',') && value.contains('.')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (value.contains(',')) {
      value = value.replaceAll(',', '.');
    }

    return value.isEmpty ? 0.0 : double.tryParse(value);
  }

  Future<void> _saveManualCommitment() async {
    if (_isSaving) return;

    final value = _parseCurrencyInput(_commitmentController.text);
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
        const SnackBar(content: Text('Valor do mês salvo.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  List<Map<String, dynamic>> get _items => _isCards
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
    final value = _isCards ? _cardSection['count'] : _cashFlow['count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return _items.length;
  }

  String get _title =>
      _isCards ? 'Cartões do mês' : 'Movimentações do mês';

  IconData get _icon =>
      _isCards ? Icons.credit_card_rounded : Icons.pix_rounded;

  String _money(double value) {
    return PrivacyService.instance.valuesVisible.value
        ? formatCurrency(value)
        : '••••••';
  }

  String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Data não informada';
    final parsed = DateTime.tryParse(value.toString());
    return parsed == null ? value.toString() : _shortDate(parsed);
  }

  bool get _isFullMonthRange {
    final full = _fullMonthRange();
    return DateUtils.isSameDay(_cardRange.start, full.start) &&
        DateUtils.isSameDay(_cardRange.end, full.end);
  }

  String get _cardRangeLabel =>
      '${_shortDate(_cardRange.start)} — ${_shortDate(_cardRange.end)}';

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

  bool _isNeutralMovement(Map<String, dynamic> item) =>
      _classification(item) == 'INTERNAL_TRANSFER';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(top: false, child: _buildBody()),
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
                style: const TextStyle(color: AppTheme.inkSoft),
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
          if (_isCards) ...[
            const SizedBox(height: 14),
            _buildCardDateFilter(),
          ],
          const SizedBox(height: 22),
          Text(
            _isCards
                ? 'LANÇAMENTOS NO PERÍODO'
                : 'MOVIMENTAÇÕES PARA CONSULTA',
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

  Widget _buildCardDateFilter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration(radius: 20),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: _selectCardRange,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Período dos lançamentos',
                      style: TextStyle(color: AppTheme.inkSoft, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _cardRangeLabel,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_isFullMonthRange)
            TextButton(
              onPressed: _resetCardRange,
              child: const Text('Mês inteiro'),
            )
          else
            IconButton(
              onPressed: _selectCardRange,
              icon: const Icon(Icons.tune_rounded),
              color: AppTheme.primary,
              tooltip: 'Alterar período',
            ),
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
                              ? 'Compras no período selecionado'
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
          '$_count ${_count == 1 ? 'lançamento' : 'lançamentos'} entre ${_shortDate(_cardRange.start)} e ${_shortDate(_cardRange.end)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12.5,
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
        const SizedBox(height: 16),
        TextField(
          controller: _commitmentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveManualCommitment(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: '0,00',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
            ),
            prefixText: 'R\$ ',
            prefixStyle: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white, width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveManualCommitment,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryDark,
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_isSaving ? 'Salvando...' : 'Salvar valor do mês'),
          ),
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
            size: 32,
            color: AppTheme.primary.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 10),
          Text(
            _isCards
                ? 'Nenhum lançamento encontrado neste período.'
                : 'Nenhuma movimentação encontrada neste mês.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.inkSoft,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final institution = item['institution']?.toString() ?? 'Instituição';
    final accountName = _isCards
        ? item['card_name']?.toString()
        : item['account_name']?.toString();
    final description = item['description']?.toString() ?? 'Lançamento';
    final installment = _installmentLabel(item);
    final amount = _number(item['amount']);
    final positive = !_isCards && _isPositiveMovement(item);
    final neutral = !_isCards && _isNeutralMovement(item);
    final investmentName = item['investment_name']?.toString();

    final amountText = _isCards
        ? _money(amount)
        : neutral
            ? _money(amount)
            : '${positive ? '+' : '-'} ${_money(amount)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isCards ? Icons.credit_card_rounded : _flowIcon(item),
              color: AppTheme.primary,
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amountText,
                      style: TextStyle(
                        color: neutral
                            ? AppTheme.ink
                            : positive
                                ? AppTheme.success
                                : _isCards
                                    ? AppTheme.ink
                                    : AppTheme.danger,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  [
                    institution,
                    if (accountName != null && accountName.trim().isNotEmpty)
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
                const SizedBox(height: 6),
                Text(
                  [
                    _formatDate(item['date']),
                    if (_isCards && installment != null) installment,
                    if (!_isCards) _classificationLabel(item),
                  ].join(' • '),
                  style: TextStyle(
                    color: AppTheme.inkSoft.withValues(alpha: 0.80),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
