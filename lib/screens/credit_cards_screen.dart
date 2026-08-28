import 'package:flutter/material.dart';

import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

import 'institution_credit_cards_screen.dart';

class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({
    super.key,
  });

  @override
  State<CreditCardsScreen> createState() =>
      _CreditCardsScreenState();
}

class _CreditCardsScreenState
    extends State<CreditCardsScreen> {
  final _financeService =
      FinanceService();

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  List<dynamic> _cards = [];

  @override
  void initState() {
    super.initState();

    _loadCards();
  }

  // =========================================================
  // CARREGAMENTO
  // =========================================================

  Future<void> _loadCards() async {
    try {
      final summary =
          await _financeService.getSummary();

      final allAccounts =
          summary['payload']?['accounts'] ??
              [];

      final creditCards =
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
        _cards = creditCards;

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage =
            'Não foi possível carregar seus cartões.';
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) {
      return;
    }

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

  // =========================================================
  // TOTAIS
  // =========================================================

  double get _totalInvoice {
    double total = 0;

    for (final card in _cards) {
      total += _getCardBalance(
        card,
      );
    }

    return total;
  }

  double get _totalCreditLimit {
    double total = 0;

    for (final card in _cards) {
      final limit =
          _getCreditLimit(card);

      if (limit != null) {
        total += limit;
      }
    }

    return total;
  }

  double get _totalAvailableLimit {
    double total = 0;

    for (final card in _cards) {
      final available =
          _getAvailableLimit(card);

      if (available != null) {
        total += available;
      }
    }

    return total;
  }

  // =========================================================
  // AGRUPAMENTO
  // =========================================================

  List<CardInstitution>
      get _institutions {
    final Map<
            String,
            CardInstitution>
        grouped = {};

    for (final card in _cards) {
      final institution =
          _getInstitutionName(
        card,
      );

      final balance =
          _getCardBalance(
        card,
      );

      final limit =
          _getCreditLimit(
        card,
      );

      final available =
          _getAvailableLimit(
        card,
      );

      if (!grouped.containsKey(
        institution,
      )) {
        grouped[institution] =
            CardInstitution(
          name: institution,
          invoiceTotal: 0,
          creditLimit: 0,
          availableLimit: 0,
          cards: [],
        );
      }

      grouped[institution]!
          .invoiceTotal +=
          balance;

      if (limit != null) {
        grouped[institution]!
            .creditLimit +=
            limit;
      }

      if (available != null) {
        grouped[institution]!
            .availableLimit +=
            available;
      }

      grouped[institution]!
          .cards
          .add(card);
    }

    final institutions =
        grouped.values.toList();

    institutions.sort(
      (a, b) =>
          b.invoiceTotal.compareTo(
        a.invoiceTotal,
      ),
    );

    return institutions;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _getCardBalance(
    dynamic card,
  ) {
    final balance =
        card['balance'];

    if (balance is num) {
      return balance.toDouble();
    }

    return double.tryParse(
          balance?.toString() ?? '',
        ) ??
        0;
  }

  Map<String, dynamic>?
      _getCreditData(
    dynamic card,
  ) {
    final creditData =
        card['creditData'];

    if (creditData is Map) {
      return Map<String, dynamic>.from(
        creditData,
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
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }

    return 'Outros';
  }

  // =========================================================
  // ABRIR INSTITUIÇÃO
  // =========================================================

  Future<void>
      _openInstitution(
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cartões',
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed:
                _isRefreshing
                    ? null
                    : _refresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                  ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh:
          _loadCards,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32,
        ),
        children: [
          _buildSummaryCard(),

          const SizedBox(
            height: 30,
          ),

          _buildSectionHeader(),

          const SizedBox(
            height: 12,
          ),

          if (_institutions.isEmpty)
            _buildEmptyState()
          else
            ..._institutions.map(
              _buildInstitutionCard,
            ),
        ],
      ),
    );
  }

  // =========================================================
  // RESUMO
  // =========================================================

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        color:
            const Color(
          0xFF315B78,
        ),
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Total em cartões',
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.76,
              ),
              fontSize: 14,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            formatCurrency(
              _totalInvoice,
            ),
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildSummaryDetail(
                  label:
                      'Limite total',
                  value:
                      formatCurrency(
                    _totalCreditLimit,
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 38,
                color: Colors.white
                    .withValues(
                  alpha: 0.18,
                ),
              ),

              const SizedBox(
                width: 18,
              ),

              Expanded(
                child:
                    _buildSummaryDetail(
                  label:
                      'Disponível',
                  value:
                      formatCurrency(
                    _totalAvailableLimit,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: [
              Icon(
                Icons
                    .account_balance_outlined,
                size: 15,
                color: Colors.white
                    .withValues(
                  alpha: 0.62,
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                '${_institutions.length} '
                '${_institutions.length == 1 ? 'instituição' : 'instituições'}',
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.62,
                  ),
                  fontSize: 11,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Icon(
                Icons
                    .credit_card_rounded,
                size: 15,
                color: Colors.white
                    .withValues(
                  alpha: 0.62,
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                '${_cards.length} '
                '${_cards.length == 1 ? 'cartão' : 'cartões'}',
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.62,
                  ),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetail({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white
                .withValues(
              alpha: 0.58,
            ),
            fontSize: 11,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SEÇÃO
  // =========================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Por instituição',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),

        Text(
          '${_institutions.length}',
          style: TextStyle(
            fontSize: 13,
            color:
                Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INSTITUIÇÃO
  // =========================================================

  Widget _buildInstitutionCard(
    CardInstitution institution,
  ) {
    final utilization =
        institution.creditLimit <= 0
            ? 0.0
            : institution.invoiceTotal /
                institution.creditLimit;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          onTap: () {
            _openInstitution(
              institution,
            );
          },
          child: Container(
            padding:
                const EdgeInsets.all(
              18,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildInstitutionIcon(
                      institution.name,
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
                          Text(
                            institution.name,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            '${institution.cards.length} '
                            '${institution.cards.length == 1 ? 'cartão' : 'cartões'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(
                            institution
                                .invoiceTotal,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'em uso',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Icon(
                      Icons
                          .chevron_right_rounded,
                      size: 25,
                      color: Colors
                          .grey.shade400,
                    ),
                  ],
                ),

                if (institution
                        .creditLimit >
                    0) ...[
                  const SizedBox(
                    height: 16,
                  ),

                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                    child:
                        LinearProgressIndicator(
                      value: utilization
                          .clamp(
                            0.0,
                            1.0,
                          )
                          .toDouble(),
                      minHeight: 5,
                      backgroundColor:
                          AppTheme.primary
                              .withValues(
                        alpha: 0.08,
                      ),
                      valueColor:
                          const AlwaysStoppedAnimation<
                              Color>(
                        AppTheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${(utilization * 100).toStringAsFixed(1)}% do limite utilizado',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey.shade500,
                          ),
                        ),
                      ),

                      Text(
                        '${formatCurrency(institution.availableLimit)} disponível',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors
                              .grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionIcon(
    String institution,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primary
            .withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),
      child: Center(
        child: Text(
          _institutionInitials(
            institution,
          ),
          style: const TextStyle(
            color:
                AppTheme.primary,
            fontSize: 14,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _institutionInitials(
    String name,
  ) {
    final words = name
        .trim()
        .split(
          RegExp(r'\s+'),
        )
        .where(
          (word) =>
              word.isNotEmpty,
        )
        .toList();

    if (words.isEmpty) {
      return '?';
    }

    if (words.length == 1) {
      final word =
          words.first;

      return word
          .substring(
            0,
            word.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return (
      words.first[0] +
          words.last[0]
    ).toUpperCase();
  }

  // =========================================================
  // EMPTY / ERROR
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary
                  .withValues(
                alpha: 0.08,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color:
                  AppTheme.primary,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Nenhum cartão encontrado',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Os cartões das instituições conectadas aparecerão aqui.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color:
                  Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 42,
              color:
                  AppTheme.danger,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              _errorMessage!,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  _loadCards,
              child: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ===========================================================
// AGRUPAMENTO
// ===========================================================

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