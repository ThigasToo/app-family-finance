import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/finance_ui.dart';
import '../widgets/privacy_finance_ui.dart';

import 'institution_credit_cards_screen.dart';


class CreditCardsScreen
    extends StatefulWidget {
  const CreditCardsScreen({
    super.key,
  });

  @override
  State<CreditCardsScreen> createState() =>
      _CreditCardsScreenState();
}


class _CreditCardsScreenState
    extends State<CreditCardsScreen> {
  final _financeService = FinanceService();

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  List<dynamic> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final summary =
          await _financeService
              .getSummary();

      final allAccounts =
          summary['payload']
                  ?['accounts'] ??
              [];

      final cards =
          List<dynamic>.from(
        allAccounts,
      ).where(
        (account) =>
            account['type']
                ?.toString()
                .toUpperCase() ==
            'CREDIT',
      ).toList();

      if (!mounted) return;

      setState(() {
        _cards = cards;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Não foi possível carregar seus cartões.';
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _financeService.refresh();
      await _loadCards();
    } catch (_) {
      await _loadCards();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  double get _totalInvoice {
    double total = 0;

    for (final card in _cards) {
      total +=
          _getCardBalance(card);
    }

    return total;
  }

  double get _totalCreditLimit {
    double total = 0;

    for (final card in _cards) {
      final value =
          _getCreditLimit(card);

      if (value != null) {
        total += value;
      }
    }

    return total;
  }

  double get _totalAvailableLimit {
    double total = 0;

    for (final card in _cards) {
      final value =
          _getAvailableLimit(card);

      if (value != null) {
        total += value;
      }
    }

    return total;
  }

  List<CardInstitution>
      get _institutions {
    final grouped =
        <String, CardInstitution>{};

    for (final card in _cards) {
      final institution =
          _getInstitutionName(
        card,
      );

      grouped.putIfAbsent(
        institution,
        () => CardInstitution(
          name: institution,
          invoiceTotal: 0,
          creditLimit: 0,
          availableLimit: 0,
          cards: [],
        ),
      );

      grouped[institution]!
          .invoiceTotal +=
          _getCardBalance(card);

      grouped[institution]!
          .creditLimit +=
          _getCreditLimit(card) ??
              0;

      grouped[institution]!
          .availableLimit +=
          _getAvailableLimit(card) ??
              0;

      grouped[institution]!
          .cards
          .add(card);
    }

    final result =
        grouped.values.toList();

    result.sort(
      (a, b) =>
          b.invoiceTotal.compareTo(
        a.invoiceTotal,
      ),
    );

    return result;
  }

  double _getCardBalance(
    dynamic card,
  ) {
    final value =
        card['balance'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  Map<String, dynamic>?
      _getCreditData(
    dynamic card,
  ) {
    final value =
        card['creditData'];

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return null;
  }

  double? _getCreditLimit(
    dynamic card,
  ) {
    final value =
        _getCreditData(card)
            ?['creditLimit'];

    if (value is num) {
      return value.toDouble();
    }

    if (value != null) {
      return double.tryParse(
        value.toString(),
      );
    }

    return null;
  }

  double? _getAvailableLimit(
    dynamic card,
  ) {
    final value =
        _getCreditData(card)
            ?['availableCreditLimit'];

    if (value is num) {
      return value.toDouble();
    }

    if (value != null) {
      return double.tryParse(
        value.toString(),
      );
    }

    return null;
  }

  String _getInstitutionName(
    dynamic card,
  ) {
    final candidates = [
      card['institution_name'],
      card['resolved_institution'],
      card['institution'],
      card['institutionName'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return 'Outros';
  }

  Future<void> _openInstitution(
    CardInstitution institution,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            InstitutionCreditCardsScreen(
          institutionName:
              institution.name,
          cards:
              institution.cards,
        ),
      ),
    );

    if (!mounted) return;

    await _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return FinancePage(
      title: 'Cartões',
      isRefreshing: _isRefreshing,
      onRefreshButton: _refresh,
      onRefresh: _loadCards,
      actions: const [
        PrivacyEyeButton(),
      ],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const FinancePageSkeleton();
    }

    if (_errorMessage != null) {
      return ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const FinanceEmptyState(
            icon:
                Icons.error_outline_rounded,
            title:
                'Não foi possível carregar',
            subtitle:
                'Verifique sua conexão e tente novamente.',
          ),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        36,
      ),
      children: [
        _buildCreditHero(),

        const SizedBox(height: 30),

        FinanceSectionHeader(
          title: 'Por instituição',
          trailing:
              '${_institutions.length}',
        ),

        const SizedBox(height: 12),

        if (_institutions.isEmpty)
          const FinanceEmptyState(
            icon:
                Icons.credit_card_rounded,
            title:
                'Nenhum cartão encontrado',
            subtitle:
                'Conecte uma instituição para visualizar seus cartões.',
          )
        else
          ..._institutions.map(
            (institution) {
              final utilization =
                  institution.creditLimit <=
                          0
                      ? 0.0
                      : institution
                              .invoiceTotal /
                          institution
                              .creditLimit;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: PrivacyFinanceListTile(
                  institutionName:
                      institution.name,
                  title:
                      institution.name,
                  subtitle:
                      '${institution.cards.length} '
                      '${institution.cards.length == 1 ? 'cartão' : 'cartões'}',
                  value:
                      institution.invoiceTotal,
                  trailingText:
                      institution.creditLimit >
                              0
                          ? '${(utilization * 100).toStringAsFixed(0)}% utilizado'
                          : null,
                  progress:
                      institution.creditLimit >
                              0
                          ? utilization
                          : null,
                  onTap: () =>
                      _openInstitution(
                    institution,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCreditHero() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient:
            AppTheme.premiumGradient,
        borderRadius:
            BorderRadius.circular(29),
        border: Border.all(
          color:
              Colors.white
                  .withValues(
            alpha: 0.15,
          ),
        ),
        boxShadow:
            AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Total em cartões',
            style: TextStyle(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.68,
              ),
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(height: 7),

          PrivacyMoney(
            value:
                _totalInvoice,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 32,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),

          const SizedBox(height: 21),

          Container(
            padding:
                const EdgeInsets.all(
              15,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border:
                  Border.all(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.09,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _heroValue(
                    label:
                        'Limite total',
                    value:
                        _totalCreditLimit,
                  ),
                ),

                Container(
                  height: 38,
                  width: 1,
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.14,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child:
                      _heroValue(
                    label:
                        'Disponível',
                    value:
                        _totalAvailableLimit,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              FinanceHeroInfo(
                icon:
                    Icons.account_balance_rounded,
                text:
                    '${_institutions.length} '
                    '${_institutions.length == 1 ? 'instituição' : 'instituições'}',
              ),
              FinanceHeroInfo(
                icon:
                    Icons.credit_card_rounded,
                text:
                    '${_cards.length} '
                    '${_cards.length == 1 ? 'cartão' : 'cartões'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroValue({
    required String label,
    required double value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                Colors.white
                    .withValues(
              alpha: 0.58,
            ),
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 5),

        PrivacyMoney(
          value:
              value,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }
}


class CardInstitution {
  final String name;

  double invoiceTotal;
  double creditLimit;
  double availableLimit;

  final List<dynamic> cards;

  CardInstitution({
    required this.name,
    required this.invoiceTotal,
    required this.creditLimit,
    required this.availableLimit,
    required this.cards,
  });
}