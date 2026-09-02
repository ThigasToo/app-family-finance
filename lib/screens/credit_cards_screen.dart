import 'package:flutter/material.dart';

import '../services/card_notes_service.dart';
import '../services/finance_service.dart';
import '../services/planning_scope_service.dart';
import '../theme/app_theme.dart';
import '../widgets/finance_ui.dart';
import '../widgets/privacy_finance_ui.dart';

import 'institution_credit_cards_screen.dart';


class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({super.key});

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}


class _CreditCardsScreenState extends State<CreditCardsScreen> {
  final _financeService = FinanceService();
  final _planningScopeService = PlanningScopeService();
  final _cardNotesService = CardNotesService();
  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSavingNotes = false;

  String? _errorMessage;
  int? _activeUserId;
  List<dynamic> _cards = [];

  @override
  void initState() {
    super.initState();
    _initializeCards();
    _loadNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeCards() async {
    _activeUserId = await _planningScopeService.getActiveUserId();

    if (_activeUserId != null) {
      final cachedSummary = await _financeService.getCachedSummary(
        userId: _activeUserId!,
      );

      if (cachedSummary != null) {
        _applySummary(cachedSummary);
      }
    }

    // Stale-while-revalidate: se havia snapshot, os cartões já aparecem acima.
    // A rede continua buscando os dados atuais e atualiza a tela ao concluir.
    await _loadCards();
  }

  Future<void> _loadNotes() async {
    final notes = await _cardNotesService.load();
    if (!mounted) return;
    _notesController.text = notes;
  }

  Future<void> _saveNotes() async {
    if (_isSavingNotes) return;

    setState(() => _isSavingNotes = true);

    try {
      await _cardNotesService.save(_notesController.text);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Observações dos cartões salvas.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingNotes = false);
      }
    }
  }

  void _applySummary(Map<String, dynamic> summary) {
    final allAccounts = summary['payload']?['accounts'] ?? [];

    final cards = List<dynamic>.from(allAccounts)
        .where(
          (account) =>
              account['type']?.toString().toUpperCase() == 'CREDIT',
        )
        .toList();

    if (!mounted) return;

    setState(() {
      _cards = cards;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadCards() async {
    try {
      final summary = await _financeService.getSummary(
        snapshotUserId: _activeUserId,
      );

      _applySummary(summary);
    } catch (_) {
      if (!mounted) return;

      // Se o snapshot já carregou cartões, uma falha de rede não deve apagar
      // a tela nem trocar dados úteis por um estado de erro.
      if (_cards.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar seus cartões.';
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await _financeService.refresh();
      await _loadCards();
    } catch (_) {
      await _loadCards();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  double get _totalInvoice {
    double total = 0;
    for (final card in _cards) {
      total += _getCardBalance(card);
    }
    return total;
  }

  double get _totalCreditLimit {
    double total = 0;
    for (final card in _cards) {
      final value = _getCreditLimit(card);
      if (value != null) total += value;
    }
    return total;
  }

  double get _totalAvailableLimit {
    double total = 0;
    for (final card in _cards) {
      final value = _getAvailableLimit(card);
      if (value != null) total += value;
    }
    return total;
  }

  List<CardInstitution> get _institutions {
    final grouped = <String, CardInstitution>{};

    for (final card in _cards) {
      final institution = _getInstitutionName(card);

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

      grouped[institution]!.invoiceTotal += _getCardBalance(card);
      grouped[institution]!.creditLimit += _getCreditLimit(card) ?? 0;
      grouped[institution]!.availableLimit += _getAvailableLimit(card) ?? 0;
      grouped[institution]!.cards.add(card);
    }

    final result = grouped.values.toList();
    result.sort((a, b) => b.invoiceTotal.compareTo(a.invoiceTotal));
    return result;
  }

  double _getCardBalance(dynamic card) {
    final value = card['balance'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic>? _getCreditData(dynamic card) {
    final value = card['creditData'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  double? _getCreditLimit(dynamic card) {
    final value = _getCreditData(card)?['creditLimit'];
    if (value is num) return value.toDouble();
    if (value != null) return double.tryParse(value.toString());
    return null;
  }

  double? _getAvailableLimit(dynamic card) {
    final value = _getCreditData(card)?['availableCreditLimit'];
    if (value is num) return value.toDouble();
    if (value != null) return double.tryParse(value.toString());
    return null;
  }

  String _getInstitutionName(dynamic card) {
    final candidates = [
      card['institution_name'],
      card['resolved_institution'],
      card['institution'],
      card['institutionName'],
    ];

    for (final value in candidates) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return 'Outros';
  }

  Future<void> _openInstitution(CardInstitution institution) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstitutionCreditCardsScreen(
          institutionName: institution.name,
          cards: institution.cards,
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
      actions: const [PrivacyEyeButton()],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const FinancePageSkeleton();
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 80),
          FinanceEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Não foi possível carregar',
            subtitle: 'Verifique sua conexão e tente novamente.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        _buildCreditHero(),
        const SizedBox(height: 14),
        _buildNotesCard(),
        const SizedBox(height: 30),
        FinanceSectionHeader(
          title: 'Por instituição',
          trailing: '${_institutions.length}',
        ),
        const SizedBox(height: 12),
        if (_institutions.isEmpty)
          const FinanceEmptyState(
            icon: Icons.credit_card_rounded,
            title: 'Nenhum cartão encontrado',
            subtitle: 'Conecte uma instituição para visualizar seus cartões.',
          )
        else
          ..._institutions.map((institution) {
            final utilization = institution.creditLimit <= 0
                ? 0.0
                : institution.invoiceTotal / institution.creditLimit;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PrivacyFinanceListTile(
                institutionName: institution.name,
                title: institution.name,
                subtitle:
                    '${institution.cards.length} ${institution.cards.length == 1 ? 'cartão' : 'cartões'}',
                value: institution.invoiceTotal,
                trailingText: institution.creditLimit > 0
                    ? '${(utilization * 100).toStringAsFixed(0)}% utilizado'
                    : null,
                progress: institution.creditLimit > 0 ? utilization : null,
                onTap: () => _openInstitution(institution),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildNotesCard() {
    return FinanceGlassCard(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FinanceIconBubble(icon: Icons.event_note_rounded),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observações',
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Anote vencimentos ou lembretes dos cartões.',
                        style: TextStyle(
                          color: AppTheme.inkSoft,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ex.: Nubank vence dia 3 • C6 dia 5 • PicPay dia 5',
                filled: true,
                fillColor: AppTheme.primary.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSavingNotes ? null : _saveNotes,
                icon: _isSavingNotes
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(_isSavingNotes ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: AppTheme.premiumGradient,
        borderRadius: BorderRadius.circular(29),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total em cartões',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          PrivacyMoney(
            value: _totalInvoice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 21),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _heroValue(
                    label: 'Limite total',
                    value: _totalCreditLimit,
                  ),
                ),
                Container(
                  height: 38,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _heroValue(
                    label: 'Disponível',
                    value: _totalAvailableLimit,
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
                icon: Icons.account_balance_rounded,
                text:
                    '${_institutions.length} ${_institutions.length == 1 ? 'instituição' : 'instituições'}',
              ),
              FinanceHeroInfo(
                icon: Icons.credit_card_rounded,
                text: '${_cards.length} ${_cards.length == 1 ? 'cartão' : 'cartões'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroValue({required String label, required double value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 5),
        PrivacyMoney(
          value: value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
