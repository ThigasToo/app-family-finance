import 'package:flutter/material.dart';

import '../services/monthly_detail_loader.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ManualCardAdjustmentsSection extends StatefulWidget {
  final String month;
  final int refreshToken;
  final ValueChanged<double> onTotalChanged;

  const ManualCardAdjustmentsSection({
    super.key,
    required this.month,
    required this.refreshToken,
    required this.onTotalChanged,
  });

  @override
  State<ManualCardAdjustmentsSection> createState() =>
      _ManualCardAdjustmentsSectionState();
}

class _ManualCardAdjustmentsSectionState
    extends State<ManualCardAdjustmentsSection> {
  final _loader = MonthlyDetailLoader();

  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ManualCardAdjustmentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.month != widget.month) {
      _load();
    }
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _parseCurrency(String input) {
    var value = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (value.contains(',') && value.contains('.')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (value.contains(',')) {
      value = value.replaceAll(',', '.');
    }
    return double.tryParse(value);
  }

  Future<void> _load() async {
    try {
      final response = await _loader.fetchManualCardEntries(month: widget.month);
      final rawItems = response['items'];
      final items = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];
      final total = _number(response['total']);

      if (!mounted) return;
      setState(() {
        _items = items;
        _total = total;
        _loading = false;
      });
      widget.onTotalChanged(total);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final descriptionController = TextEditingController(
      text: item?['description']?.toString() ?? '',
    );
    final institutionController = TextEditingController(
      text: item?['institution']?.toString() ?? '',
    );
    final amountController = TextEditingController(
      text: item == null
          ? ''
          : _number(item['amount']).toStringAsFixed(2).replaceAll('.', ','),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'Adicionar ajuste manual' : 'Editar ajuste'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex.: Parcela não importada',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(
                  labelText: 'Instituição (opcional)',
                  hintText: 'Ex.: Nubank',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final description = descriptionController.text.trim();
              final amount = _parseCurrency(amountController.text);
              if (description.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe uma descrição e um valor válido.'),
                  ),
                );
                return;
              }

              try {
                if (item == null) {
                  await _loader.createManualCardEntry(
                    month: widget.month,
                    description: description,
                    amount: amount,
                    institution: institutionController.text.trim().isEmpty
                        ? null
                        : institutionController.text.trim(),
                  );
                } else {
                  await _loader.updateManualCardEntry(
                    entryId: (item['id'] as num).toInt(),
                    description: description,
                    amount: amount,
                    institution: institutionController.text.trim().isEmpty
                        ? null
                        : institutionController.text.trim(),
                  );
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    descriptionController.dispose();
    institutionController.dispose();
    amountController.dispose();

    if (saved == true) await _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir ajuste?'),
        content: Text(
          'O ajuste "${item['description'] ?? 'Manual'}" será removido deste mês.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _loader.deleteManualCardEntry(
        entryId: (item['id'] as num).toInt(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AJUSTES MANUAIS',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Use quando o banco não enviar toda a dívida do mês.',
                      style: TextStyle(
                        color: AppTheme.inkSoft,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_items.isEmpty)
            const Text(
              'Nenhum ajuste manual neste mês.',
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
            )
          else
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['description']?.toString() ?? 'Ajuste manual',
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((item['institution']?.toString() ?? '').isNotEmpty)
                            Text(
                              item['institution'].toString(),
                              style: const TextStyle(
                                color: AppTheme.inkSoft,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(_number(item['amount'])),
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(item);
                        if (value == 'delete') _delete(item);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (!_loading) ...[
            const Divider(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total manual',
                    style: TextStyle(
                      color: AppTheme.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatCurrency(_total),
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
