import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/finance_ui.dart';


class AddInvestmentScreen
    extends StatefulWidget {
  const AddInvestmentScreen({
    super.key,
  });

  @override
  State<AddInvestmentScreen>
      createState() =>
          _AddInvestmentScreenState();
}


class _AddInvestmentScreenState
    extends State<AddInvestmentScreen> {
  final _financeService =
      FinanceService();

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

  String _selectedType =
      'CRYPTO';

  bool _isSaving =
      false;

  String? _errorMessage;

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
          Icons.pie_chart_rounded,
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
          Icons.savings_rounded,
    ),
    InvestmentTypeOption(
      value: 'FUND',
      label: 'Fundo',
      icon:
          Icons.account_balance_rounded,
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

  Future<void>
      _saveInvestment() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    FocusScope.of(context)
        .unfocus();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final value =
          _parseMoney(
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
            _nameController.text
                .trim(),
        type:
            _selectedType,
        institution:
            _institutionController.text
                .trim(),
        currentValue:
            value,
        ticker:
            ticker,
      );

      if (!mounted) return;

      Navigator.of(context)
          .pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Não foi possível adicionar o investimento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving =
              false;
        });
      }
    }
  }

  // =========================================================
  // PARSER
  // =========================================================

  double _parseMoney(
    String value,
  ) {
    var normalized =
        value
            .replaceAll(
              'R\$',
              '',
            )
            .replaceAll(
              ' ',
              '',
            );

    if (normalized.contains(',')) {
      normalized =
          normalized
              .replaceAll(
                '.',
                '',
              )
              .replaceAll(
                ',',
                '.',
              );
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
    return FinancePage(
      title: 'Novo investimento',
      child: Form(
        key: _formKey,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            36,
          ),
          children: [
            _buildIntro(),

            const SizedBox(
              height: 28,
            ),

            const FinanceSectionHeader(
              title:
                  'Tipo de investimento',
            ),

            const SizedBox(
              height: 12,
            ),

            _buildInvestmentTypes(),

            const SizedBox(
              height: 28,
            ),

            const FinanceSectionHeader(
              title: 'Informações',
            ),

            const SizedBox(
              height: 12,
            ),

            FinanceGlassCard(
              radius: 23,
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  children: [
                    _buildNameField(),

                    const SizedBox(
                      height: 13,
                    ),

                    _buildInstitutionField(),

                    const SizedBox(
                      height: 13,
                    ),

                    _buildTickerField(),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            const FinanceSectionHeader(
              title: 'Valor atual',
            ),

            const SizedBox(
              height: 12,
            ),

            FinanceGlassCard(
              radius: 23,
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _buildValueField(),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Esse valor será utilizado no total da sua carteira. Você poderá atualizá-lo manualmente sempre que quiser.',
                      style:
                          TextStyle(
                        color:
                            AppTheme
                                .inkSoft,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage !=
                null) ...[
              const SizedBox(
                height: 18,
              ),
              _buildError(),
            ],

            const SizedBox(
              height: 28,
            ),

            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // INTRO
  // =========================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        gradient:
            AppTheme.premiumGradient,
        borderRadius:
            BorderRadius.circular(
          26,
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
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.11,
              ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child:
                const Icon(
              Icons.add_chart_rounded,
              color: Colors.white,
              size: 23,
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
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Adicione ativos que não aparecem nas suas instituições conectadas.',
                  style: TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.68,
                    ),
                    fontSize: 11.5,
                    height: 1.4,
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
      spacing: 9,
      runSpacing: 9,
      children:
          _investmentTypes.map(
        (option) {
          final selected =
              _selectedType ==
                  option.value;

          return InkWell(
            borderRadius:
                BorderRadius.circular(
              17,
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
                milliseconds: 180,
              ),
              curve:
                  Curves.easeOut,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              decoration:
                  BoxDecoration(
                color:
                    selected
                        ? AppTheme.primary
                        : Colors.white
                            .withValues(
                          alpha: 0.60,
                        ),
                borderRadius:
                    BorderRadius.circular(
                  17,
                ),
                border: Border.all(
                  color:
                      selected
                          ? AppTheme.primary
                          : Colors.white
                              .withValues(
                            alpha:
                                0.78,
                          ),
                ),
                boxShadow:
                    selected
                        ? [
                            BoxShadow(
                              color:
                                  AppTheme
                                      .primary
                                      .withValues(
                                alpha:
                                    0.14,
                              ),
                              blurRadius:
                                  15,
                              offset:
                                  const Offset(
                                0,
                                6,
                              ),
                            ),
                          ]
                        : null,
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 17,
                    color:
                        selected
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
                      color:
                          selected
                              ? Colors.white
                              : AppTheme.ink,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
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
      textInputAction:
          TextInputAction.next,
      decoration:
          const InputDecoration(
        labelText:
            'Nome do investimento',
        hintText:
            'Ex.: Bitcoin',
        prefixIcon:
            Icon(
          Icons
              .account_balance_wallet_rounded,
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
      controller:
          _institutionController,
      textCapitalization:
          TextCapitalization.words,
      textInputAction:
          TextInputAction.next,
      decoration:
          const InputDecoration(
        labelText:
            'Instituição',
        hintText:
            'Ex.: Binance',
        prefixIcon:
            Icon(
          Icons
              .account_balance_rounded,
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
          TextCapitalization.characters,
      textInputAction:
          TextInputAction.next,
      decoration:
          const InputDecoration(
        labelText:
            'Ticker (opcional)',
        hintText:
            'Ex.: BTC ou IVVB11',
        prefixIcon:
            Icon(
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
      textInputAction:
          TextInputAction.done,
      onFieldSubmitted:
          (_) {
        if (!_isSaving) {
          _saveInvestment();
        }
      },
      decoration:
          const InputDecoration(
        labelText:
            'Valor atual',
        hintText:
            '0,00',
        prefixText:
            'R\$ ',
        prefixIcon:
            Icon(
          Icons.payments_rounded,
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

  // =========================================================
  // ERRO / SALVAR
  // =========================================================

  Widget _buildError() {
    return FinanceGlassCard(
      radius: 17,
      child: Padding(
        padding:
            const EdgeInsets.all(
          13,
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
              width: 9,
            ),

            Expanded(
              child: Text(
                _errorMessage!,
                style:
                    const TextStyle(
                  color:
                      AppTheme.danger,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 55,
      decoration:
          BoxDecoration(
        gradient:
            AppTheme.primaryGradient,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.primary
                    .withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap:
              _isSaving
                  ? null
                  : _saveInvestment,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          child: Center(
            child:
                _isSaving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .add_rounded,
                            color:
                                Colors.white,
                            size: 19,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Adicionar investimento',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
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