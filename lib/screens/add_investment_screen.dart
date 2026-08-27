import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../theme/app_theme.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({
    super.key,
  });

  @override
  State<AddInvestmentScreen> createState() =>
      _AddInvestmentScreenState();
}

class _AddInvestmentScreenState
    extends State<AddInvestmentScreen> {
  final _financeService = FinanceService();

  final _formKey =
      GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _institutionController =
      TextEditingController();

  final _valueController =
      TextEditingController();

  final _tickerController =
      TextEditingController();

  String _selectedType = 'CRYPTO';

  bool _isSaving = false;

  String? _errorMessage;

  // =========================================================
  // TIPOS
  // =========================================================

  final List<InvestmentTypeOption>
      _investmentTypes = [
    InvestmentTypeOption(
      value: 'CRYPTO',
      label: 'Criptomoeda',
      icon:
          Icons.currency_bitcoin_rounded,
    ),
    InvestmentTypeOption(
      value: 'ETF',
      label: 'ETF',
      icon:
          Icons.pie_chart_outline_rounded,
    ),
    InvestmentTypeOption(
      value: 'STOCK',
      label: 'Ação',
      icon:
          Icons.show_chart_rounded,
    ),
    InvestmentTypeOption(
      value: 'FIXED_INCOME',
      label: 'Renda fixa',
      icon:
          Icons.savings_outlined,
    ),
    InvestmentTypeOption(
      value: 'FUND',
      label: 'Fundo',
      icon:
          Icons.account_balance_outlined,
    ),
    InvestmentTypeOption(
      value: 'OTHER',
      label: 'Outro',
      icon:
          Icons.more_horiz_rounded,
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _valueController.dispose();
    _tickerController.dispose();

    super.dispose();
  }

  // =========================================================
  // SALVAR
  // =========================================================

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final value = _parseMoney(
        _valueController.text,
      );

      final ticker =
          _tickerController.text
                  .trim()
                  .isEmpty
              ? null
              : _tickerController.text
                  .trim()
                  .toUpperCase();

      await _financeService
          .createManualInvestment(
        name:
            _nameController.text.trim(),
        type: _selectedType,
        institution:
            _institutionController.text
                .trim(),
        currentValue: value,
        ticker: ticker,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Não foi possível adicionar o investimento.';
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
  // DINHEIRO
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

    return double.tryParse(
          normalized,
        ) ??
        0;
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
        title:
            const Text(
          'Novo investimento',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              32,
            ),
            children: [
              _buildIntro(),

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

              _buildValueExplanation(),

              if (_errorMessage !=
                  null) ...[
                const SizedBox(
                  height: 20,
                ),
                _buildError(),
              ],

              const SizedBox(
                height: 32,
              ),

              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INTRODUÇÃO
  // =========================================================

  Widget _buildIntro() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary
            .withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: AppTheme.primary
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons
                  .edit_note_rounded,
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
                  'Investimento manual',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Use esta opção para ativos que não aparecem nas instituições conectadas.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors
                        .grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TIPOS
  // =========================================================

  Widget _buildInvestmentTypes() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _investmentTypes.map(
        (option) {
          final selected =
              _selectedType ==
                  option.value;

          return InkWell(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            onTap: () {
              setState(() {
                _selectedType =
                    option.value;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 160,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration:
                  BoxDecoration(
                color: selected
                    ? AppTheme.primary
                    : Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(
                  16,
                ),
                border: Border.all(
                  color: selected
                      ? AppTheme
                          .primary
                      : Colors.grey
                          .shade200,
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                    color: selected
                        ? Colors.white
                        : AppTheme
                            .primary,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight
                              .w600,
                      color: selected
                          ? Colors.white
                          : Colors
                              .black87,
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

  // =========================================================
  // CAMPOS
  // =========================================================

  Widget _buildNameField() {
    return TextFormField(
      controller:
          _nameController,
      textCapitalization:
          TextCapitalization.words,
      decoration:
          const InputDecoration(
        labelText:
            'Nome do investimento',
        hintText:
            'Ex.: Bitcoin',
        prefixIcon: Icon(
          Icons
              .account_balance_wallet_outlined,
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

  Widget
      _buildInstitutionField() {
    return TextFormField(
      controller:
          _institutionController,
      textCapitalization:
          TextCapitalization.words,
      decoration:
          const InputDecoration(
        labelText: 'Instituição',
        hintText:
            'Ex.: Binance',
        prefixIcon: Icon(
          Icons
              .account_balance_outlined,
        ),
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Informe onde o investimento está';
        }

        return null;
      },
    );
  }

  Widget _buildTickerField() {
    return TextFormField(
      controller:
          _tickerController,
      textCapitalization:
          TextCapitalization
              .characters,
      decoration:
          const InputDecoration(
        labelText:
            'Ticker (opcional)',
        hintText:
            'Ex.: BTC ou IVVB11',
        prefixIcon: Icon(
          Icons.tag_rounded,
        ),
      ),
    );
  }

  Widget _buildValueField() {
    return TextFormField(
      controller:
          _valueController,
      keyboardType:
          const TextInputType
              .numberWithOptions(
        decimal: true,
      ),
      decoration:
          const InputDecoration(
        labelText:
            'Valor atual',
        hintText: '0,00',
        prefixText: 'R\$ ',
        prefixIcon: Icon(
          Icons
              .payments_outlined,
        ),
      ),
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Informe o valor atual';
        }

        final parsed =
            _parseMoney(value);

        if (parsed <= 0) {
          return 'Informe um valor maior que zero';
        }

        return null;
      },
    );
  }

  Widget
      _buildValueExplanation() {
    return Text(
      'Por enquanto, este é o valor que será usado no total da sua carteira. Você poderá atualizá-lo manualmente sempre que quiser.',
      style: TextStyle(
        fontSize: 12,
        height: 1.45,
        color:
            Colors.grey.shade500,
      ),
    );
  }

  // =========================================================
  // ERRO
  // =========================================================

  Widget _buildError() {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger
            .withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            color:
                AppTheme.danger,
            size: 19,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              _errorMessage!,
              style:
                  const TextStyle(
                color:
                    AppTheme.danger,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SALVAR
  // =========================================================

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed:
          _isSaving
              ? null
              : _saveInvestment,
      icon: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    Colors.white,
              ),
            )
          : const Icon(
              Icons
                  .check_rounded,
            ),
      label: Text(
        _isSaving
            ? 'Salvando...'
            : 'Adicionar investimento',
      ),
    );
  }

  // =========================================================
  // TÍTULO
  // =========================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight:
            FontWeight.w800,
      ),
    );
  }
}


// ===========================================================
// OPÇÃO DE TIPO
// ===========================================================

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