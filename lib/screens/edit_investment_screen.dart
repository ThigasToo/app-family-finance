import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../theme/app_theme.dart';

class EditInvestmentScreen extends StatefulWidget {
  final Map<String, dynamic> investment;

  const EditInvestmentScreen({
    super.key,
    required this.investment,
  });

  @override
  State<EditInvestmentScreen> createState() =>
      _EditInvestmentScreenState();
}

class _EditInvestmentScreenState
    extends State<EditInvestmentScreen> {
  final _financeService = FinanceService();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _institutionController;
  late final TextEditingController _valueController;
  late final TextEditingController _tickerController;

  late String _selectedType;

  bool _isSaving = false;
  bool _isDeleting = false;

  String? _errorMessage;

  final List<InvestmentTypeOption> _investmentTypes = [
    InvestmentTypeOption(
      value: 'CRYPTO',
      label: 'Criptomoeda',
      icon: Icons.currency_bitcoin_rounded,
    ),
    InvestmentTypeOption(
      value: 'ETF',
      label: 'ETF',
      icon: Icons.pie_chart_outline_rounded,
    ),
    InvestmentTypeOption(
      value: 'STOCK',
      label: 'Ação',
      icon: Icons.show_chart_rounded,
    ),
    InvestmentTypeOption(
      value: 'FIXED_INCOME',
      label: 'Renda fixa',
      icon: Icons.savings_outlined,
    ),
    InvestmentTypeOption(
      value: 'FUND',
      label: 'Fundo',
      icon: Icons.account_balance_outlined,
    ),
    InvestmentTypeOption(
      value: 'OTHER',
      label: 'Outro',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    final investment = widget.investment;

    _nameController = TextEditingController(
      text: investment['name']?.toString() ?? '',
    );

    _institutionController = TextEditingController(
      text: investment['institution_name']?.toString() ??
          investment['institution']?.toString() ??
          '',
    );

    _tickerController = TextEditingController(
      text: investment['ticker']?.toString() ?? '',
    );

    final currentValue =
        investment['current_value'] ??
            investment['balance'] ??
            0;

    _valueController = TextEditingController(
      text: _formatInputValue(
        _asDouble(currentValue),
      ),
    );

    _selectedType =
        investment['type']?.toString().toUpperCase() ??
            'OTHER';

    final knownTypes = _investmentTypes
        .map((e) => e.value)
        .toSet();

    if (!knownTypes.contains(_selectedType)) {
      _selectedType = 'OTHER';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _valueController.dispose();
    _tickerController.dispose();

    super.dispose();
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final manualId = widget.investment['manual_id'];

    if (manualId is! int) {
      setState(() {
        _errorMessage =
            'Não foi possível identificar este investimento manual.';
      });

      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _financeService.updateManualInvestment(
        id: manualId,
        data: {
          'name': _nameController.text.trim(),
          'type': _selectedType,
          'institution': _institutionController.text.trim(),
          'current_value': _parseMoney(
            _valueController.text,
          ),
          'ticker': _tickerController.text.trim().isEmpty
              ? null
              : _tickerController.text.trim().toUpperCase(),
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Não foi possível atualizar o investimento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Excluir investimento?',
          ),
          content: Text(
            'O investimento "${_nameController.text.trim()}" será removido da sua carteira.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.danger,
              ),
              child: const Text(
                'Excluir',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _delete();
  }

  Future<void> _delete() async {
    final manualId = widget.investment['manual_id'];

    if (manualId is! int) {
      setState(() {
        _errorMessage =
            'Não foi possível identificar este investimento manual.';
      });

      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _financeService.deleteManualInvestment(
        manualId,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        InvestmentEditResult.deleted,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Não foi possível excluir o investimento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _parseMoney(
    String value,
  ) {
    var normalized = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '');

    if (normalized.contains(',')) {
      normalized = normalized
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }

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

  String _formatInputValue(
    double value,
  ) {
    return value
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final busy =
        _isSaving || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar investimento',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              32,
            ),
            children: [
              _buildManualNotice(),

              const SizedBox(
                height: 28,
              ),

              _buildSectionTitle(
                'Tipo de investimento',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildInvestmentTypes(),

              const SizedBox(
                height: 30,
              ),

              _buildSectionTitle(
                'Informações',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildNameField(),

              const SizedBox(
                height: 14,
              ),

              _buildInstitutionField(),

              const SizedBox(
                height: 14,
              ),

              _buildTickerField(),

              const SizedBox(
                height: 30,
              ),

              _buildSectionTitle(
                'Valor atual',
              ),

              const SizedBox(
                height: 12,
              ),

              _buildValueField(),

              const SizedBox(
                height: 10,
              ),

              Text(
                'Atualize este valor sempre que quiser ajustar sua carteira manualmente.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: Colors.grey.shade500,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(
                  height: 20,
                ),
                _buildError(),
              ],

              const SizedBox(
                height: 32,
              ),

              ElevatedButton.icon(
                onPressed: busy
                    ? null
                    : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_rounded,
                      ),
                label: Text(
                  _isSaving
                      ? 'Salvando...'
                      : 'Salvar alterações',
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : _confirmDelete,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline_rounded,
                      ),
                label: Text(
                  _isDeleting
                      ? 'Excluindo...'
                      : 'Excluir investimento',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  minimumSize: const Size.fromHeight(
                    52,
                  ),
                  side: BorderSide(
                    color: AppTheme.danger.withValues(
                      alpha: 0.35,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // WIDGETS
  // =========================================================

  Widget _buildManualNotice() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.edit_outlined,
            color: AppTheme.primary,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              'Este ativo foi cadastrado manualmente. Você pode alterar seus dados e valor atual.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentTypes() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _investmentTypes.map(
        (option) {
          final selected =
              option.value == _selectedType;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedType =
                    option.value;
              });
            },
            borderRadius: BorderRadius.circular(
              16,
            ),
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 160,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color: selected
                      ? AppTheme.primary
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                    color: selected
                        ? Colors.white
                        : AppTheme.primary,
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nome do investimento',
        prefixIcon: Icon(
          Icons.account_balance_wallet_outlined,
        ),
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Informe o nome do investimento';
        }

        return null;
      },
    );
  }

  Widget _buildInstitutionField() {
    return TextFormField(
      controller: _institutionController,
      decoration: const InputDecoration(
        labelText: 'Instituição',
        prefixIcon: Icon(
          Icons.account_balance_outlined,
        ),
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Informe a instituição';
        }

        return null;
      },
    );
  }

  Widget _buildTickerField() {
    return TextFormField(
      controller: _tickerController,
      textCapitalization:
          TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Ticker (opcional)',
        prefixIcon: Icon(
          Icons.tag_rounded,
        ),
      ),
    );
  }

  Widget _buildValueField() {
    return TextFormField(
      controller: _valueController,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: const InputDecoration(
        labelText: 'Valor atual',
        prefixText: 'R\$ ',
        prefixIcon: Icon(
          Icons.payments_outlined,
        ),
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Informe o valor atual';
        }

        if (_parseMoney(value) <= 0) {
          return 'Informe um valor maior que zero';
        }

        return null;
      },
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 19,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.danger,
                fontSize: 13,
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class InvestmentTypeOption {
  final String value;
  final String label;
  final IconData icon;

  InvestmentTypeOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

enum InvestmentEditResult {
  deleted,
}