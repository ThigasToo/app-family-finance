import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_ui.dart';


class EditInvestmentScreen
    extends StatefulWidget {
  final Map<String, dynamic> investment;

  const EditInvestmentScreen({
    super.key,
    required this.investment,
  });

  @override
  State<EditInvestmentScreen>
      createState() =>
          _EditInvestmentScreenState();
}


class _EditInvestmentScreenState
    extends State<EditInvestmentScreen> {
  final _financeService =
      FinanceService();

  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _nameController;

  late final TextEditingController
      _institutionController;

  late final TextEditingController
      _valueController;

  late final TextEditingController
      _tickerController;

  late String _selectedType;

  bool _isSaving =
      false;

  bool _isDeleting =
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
  void initState() {
    super.initState();

    final investment =
        widget.investment;

    _nameController =
        TextEditingController(
      text:
          investment['name']
                  ?.toString() ??
              '',
    );

    _institutionController =
        TextEditingController(
      text:
          investment[
                      'institution_name']
                  ?.toString() ??
              investment['institution']
                  ?.toString() ??
              '',
    );

    _tickerController =
        TextEditingController(
      text:
          investment['ticker']
                  ?.toString() ??
              '',
    );

    final currentValue =
        investment['current_value'] ??
            investment['balance'] ??
            0;

    _valueController =
        TextEditingController(
      text:
          _formatInputValue(
        _asDouble(
          currentValue,
        ),
      ),
    );

    _selectedType =
        investment['type']
                ?.toString()
                .toUpperCase() ??
            'OTHER';

    final knownTypes =
        _investmentTypes
            .map(
              (item) =>
                  item.value,
            )
            .toSet();

    if (!knownTypes.contains(
      _selectedType,
    )) {
      _selectedType =
          'OTHER';
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
  // VALOR
  // =========================================================

  double get _currentValue {
    return _parseMoney(
      _valueController.text,
    );
  }

  // =========================================================
  // SALVAR
  // =========================================================

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final manualId =
        widget.investment['manual_id'];

    if (manualId is! int) {
      setState(() {
        _errorMessage =
            'Não foi possível identificar este investimento manual.';
      });

      return;
    }

    FocusScope.of(context)
        .unfocus();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _financeService
          .updateManualInvestment(
        id: manualId,
        data: {
          'name':
              _nameController.text
                  .trim(),
          'type':
              _selectedType,
          'institution':
              _institutionController
                  .text
                  .trim(),
          'current_value':
              _parseMoney(
            _valueController.text,
          ),
          'ticker':
              _tickerController.text
                      .trim()
                      .isEmpty
                  ? null
                  : _tickerController
                      .text
                      .trim()
                      .toUpperCase(),
        },
      );

      if (!mounted) return;

      Navigator.of(context)
          .pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Não foi possível atualizar o investimento.';
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
  // EXCLUIR
  // =========================================================

  Future<void>
      _confirmDelete() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title:
              const Text(
            'Excluir investimento?',
          ),
          content: Text(
            'O investimento '
            '"${_nameController.text.trim()}" '
            'será removido da sua carteira.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
                  TextButton.styleFrom(
                foregroundColor:
                    AppTheme.danger,
              ),
              child:
                  const Text(
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
    final manualId =
        widget.investment['manual_id'];

    if (manualId is! int) {
      setState(() {
        _errorMessage =
            'Não foi possível identificar este investimento manual.';
      });

      return;
    }

    setState(() {
      _isDeleting =
          true;

      _errorMessage =
          null;
    });

    try {
      await _financeService
          .deleteManualInvestment(
        manualId,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        InvestmentEditResult.deleted,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Não foi possível excluir o investimento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting =
              false;
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

  String _formatInputValue(
    double value,
  ) {
    return value
        .toStringAsFixed(2)
        .replaceAll(
          '.',
          ',',
        );
  }

  IconData get _currentTypeIcon {
    for (final option
        in _investmentTypes) {
      if (option.value ==
          _selectedType) {
        return option.icon;
      }
    }

    return Icons
        .trending_up_rounded;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final busy =
        _isSaving ||
        _isDeleting;

    return FinancePage(
      title:
          'Editar investimento',
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
            _buildHero(),

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
                      'Atualize este valor sempre que quiser ajustar sua carteira manualmente.',
                      style:
                          TextStyle(
                        color:
                            AppTheme
                                .inkSoft,
                        fontSize:
                            11.5,
                        height:
                            1.45,
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

            _buildSaveButton(
              busy,
            ),

            const SizedBox(
              height: 13,
            ),

            _buildDeleteButton(
              busy,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HERO
  // =========================================================

  Widget _buildHero() {
    return Container(
      width:
          double.infinity,
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
        border:
            Border.all(
          color:
              Colors.white
                  .withValues(
            alpha:
                0.15,
          ),
        ),
        boxShadow:
            AppTheme
                .floatingShadow,
      ),
      child: Row(
        children: [
          Container(
            width:
                49,
            height:
                49,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha:
                    0.10,
              ),
              borderRadius:
                  BorderRadius
                      .circular(
                16,
              ),
            ),
            child:
                Icon(
              _currentTypeIcon,
              color:
                  Colors.white,
              size:
                  23,
            ),
          ),

          const SizedBox(
            width:
                14,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  _nameController
                          .text
                          .trim()
                          .isEmpty
                      ? 'Investimento manual'
                      : _nameController
                          .text
                          .trim(),
                  maxLines:
                      2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        15.5,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Text(
                  'Valor atual',
                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha:
                          0.58,
                    ),
                    fontSize:
                        10.5,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  formatCurrency(
                    _currentValue,
                  ),
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  9,
              vertical:
                  5,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha:
                    0.10,
              ),
              borderRadius:
                  BorderRadius
                      .circular(
                20,
              ),
            ),
            child:
                const Text(
              'MANUAL',
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    9,
                fontWeight:
                    FontWeight
                        .w800,
                letterSpacing:
                    0.5,
              ),
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
      spacing:
          9,
      runSpacing:
          9,
      children:
          _investmentTypes.map(
        (option) {
          final selected =
              option.value ==
                  _selectedType;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedType =
                    option.value;
              });
            },
            borderRadius:
                BorderRadius.circular(
              17,
            ),
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds:
                    180,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    13,
                vertical:
                    11,
              ),
              decoration:
                  BoxDecoration(
                color:
                    selected
                        ? AppTheme
                            .primary
                        : Colors.white
                            .withValues(
                          alpha:
                              0.60,
                        ),
                borderRadius:
                    BorderRadius
                        .circular(
                  17,
                ),
                border:
                    Border.all(
                  color:
                      selected
                          ? AppTheme
                              .primary
                          : Colors.white
                              .withValues(
                            alpha:
                                0.78,
                          ),
                ),
              ),
              child:
                  Row(
                mainAxisSize:
                    MainAxisSize
                        .min,
                children: [
                  Icon(
                    option.icon,
                    size:
                        17,
                    color:
                        selected
                            ? Colors
                                .white
                            : AppTheme
                                .primary,
                  ),

                  const SizedBox(
                    width:
                        7,
                  ),

                  Text(
                    option.label,
                    style:
                        TextStyle(
                      color:
                          selected
                              ? Colors
                                  .white
                              : AppTheme
                                  .ink,
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight
                              .w600,
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
        prefixIcon:
            Icon(
          Icons
              .account_balance_wallet_rounded,
        ),
      ),
      validator:
          (value) {
        if (value == null ||
            value
                .trim()
                .isEmpty) {
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
      decoration:
          const InputDecoration(
        labelText:
            'Instituição',
        prefixIcon:
            Icon(
          Icons
              .account_balance_rounded,
        ),
      ),
      validator:
          (value) {
        if (value == null ||
            value
                .trim()
                .isEmpty) {
          return 'Informe a instituição';
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
        decimal:
            true,
      ),
      decoration:
          const InputDecoration(
        labelText:
            'Valor atual',
        prefixText:
            'R\$ ',
        prefixIcon:
            Icon(
          Icons.payments_rounded,
        ),
      ),
      validator:
          (value) {
        if (value == null ||
            value
                .trim()
                .isEmpty) {
          return 'Informe o valor atual';
        }

        if (_parseMoney(
              value,
            ) <=
            0) {
          return 'Informe um valor maior que zero';
        }

        return null;
      },
    );
  }

  // =========================================================
  // ERRO
  // =========================================================

  Widget _buildError() {
    return FinanceGlassCard(
      radius:
          17,
      child:
          Padding(
        padding:
            const EdgeInsets
                .all(
          13,
        ),
        child:
            Row(
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color:
                  AppTheme.danger,
              size:
                  19,
            ),

            const SizedBox(
              width:
                  9,
            ),

            Expanded(
              child:
                  Text(
                _errorMessage!,
                style:
                    const TextStyle(
                  color:
                      AppTheme
                          .danger,
                  fontSize:
                      12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOTÕES
  // =========================================================

  Widget _buildSaveButton(
    bool busy,
  ) {
    return Container(
      height:
          55,
      decoration:
          BoxDecoration(
        gradient:
            AppTheme
                .primaryGradient,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child:
          Material(
        color:
            Colors.transparent,
        child:
            InkWell(
          onTap:
              busy
                  ? null
                  : _save,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          child:
              Center(
            child:
                _isSaving
                    ? const SizedBox(
                        width:
                            21,
                        height:
                            21,
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.white,
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .check_rounded,
                            color:
                                Colors.white,
                          ),
                          SizedBox(
                            width:
                                8,
                          ),
                          Text(
                            'Salvar alterações',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
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

  Widget _buildDeleteButton(
    bool busy,
  ) {
    return FinanceGlassCard(
      radius:
          18,
      onTap:
          busy
              ? null
              : _confirmDelete,
      child:
          SizedBox(
        height:
            52,
        child:
            Center(
          child:
              _isDeleting
                  ? const SizedBox(
                      width:
                          19,
                      height:
                          19,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                        color:
                            AppTheme
                                .danger,
                      ),
                    )
                  : const Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .delete_outline_rounded,
                          color:
                              AppTheme
                                  .danger,
                          size:
                              19,
                        ),
                        SizedBox(
                          width:
                              8,
                        ),
                        Text(
                          'Excluir investimento',
                          style:
                              TextStyle(
                            color:
                                AppTheme
                                    .danger,
                            fontSize:
                                13.5,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
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


enum InvestmentEditResult {
  deleted,
}