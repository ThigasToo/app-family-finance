import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CreditCardTransactionsScreen
    extends StatelessWidget {
  final Map<String, dynamic> card;

  const CreditCardTransactionsScreen({
    super.key,
    required this.card,
  });

  // =========================================================
  // TRANSAÇÕES
  // =========================================================

  List<Map<String, dynamic>>
      get _transactions {
    final raw =
        card['transactions'];

    if (raw is! List) {
      return [];
    }

    final result = raw
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();

    result.sort(
      (a, b) =>
          _transactionDate(b)
              .compareTo(
        _transactionDate(a),
      ),
    );

    return result;
  }

  Map<DateTime, List<Map<String, dynamic>>>
      get _groupedTransactions {
    final Map<
            DateTime,
            List<Map<String, dynamic>>>
        grouped = {};

    for (final transaction
        in _transactions) {
      final date =
          _transactionDate(
        transaction,
      );

      final key = DateTime(
        date.year,
        date.month,
        date.day,
      );

      grouped.putIfAbsent(
        key,
        () => [],
      );

      grouped[key]!.add(
        transaction,
      );
    }

    return grouped;
  }

  // =========================================================
  // DADOS DO CARTÃO
  // =========================================================

  String get _cardName {
    final value =
        card['name']
            ?.toString()
            .trim();

    if (value != null &&
        value.isNotEmpty) {
      return value;
    }

    return 'Cartão';
  }

  String get _institutionName {
    final candidates = [
      card['institution_name'],
      card['resolved_institution'],
      card['institution'],
    ];

    for (final candidate
        in candidates) {
      if (candidate != null &&
          candidate
              .toString()
              .trim()
              .isNotEmpty) {
        return candidate
            .toString()
            .trim();
      }
    }

    return 'Instituição';
  }

  String get _cardNumber {
    final value =
        card['number']
            ?.toString()
            .trim() ??
        '';

    if (value.isEmpty) {
      return '';
    }

    return '•••• ${value.length <= 4 ? value : value.substring(value.length - 4)}';
  }

  // =========================================================
  // TOTAIS
  // =========================================================

  double get _purchasesTotal {
    double total = 0;

    for (final transaction
        in _transactions) {
      if (_isPurchase(
        transaction,
      )) {
        total +=
            _transactionAmount(
          transaction,
        ).abs();
      }
    }

    return total;
  }

  int get _purchasesCount {
    return _transactions.where(
      _isPurchase,
    ).length;
  }

  // =========================================================
  // CLASSIFICAÇÃO
  // =========================================================

  bool _isPurchase(
    Map<String, dynamic> transaction,
  ) {
    final type =
        _normalize(
      transaction['type'],
    );

    final category =
        _normalize(
      transaction['category'],
    );

    final description =
        _normalize(
      transaction['description'],
    );

    final descriptionRaw =
        _normalize(
      transaction['descriptionRaw'],
    );

    final combined =
        '$type $category '
        '$description '
        '$descriptionRaw';

    // Pagamento de fatura não deve
    // aparecer como compra.
    if (
        combined.contains(
          'PAYMENT',
        ) ||
        combined.contains(
          'PAGAMENTO',
        ) ||
        combined.contains(
          'FATURA',
        )) {
      return false;
    }

    // Estornos também são separados.
    if (
        combined.contains(
          'REFUND',
        ) ||
        combined.contains(
          'ESTORNO',
        ) ||
        combined.contains(
          'REVERSAL',
        )) {
      return false;
    }

    return true;
  }

  String _transactionKind(
    Map<String, dynamic> transaction,
  ) {
    final combined =
        '${_normalize(transaction['type'])} '
        '${_normalize(transaction['category'])} '
        '${_normalize(transaction['description'])} '
        '${_normalize(transaction['descriptionRaw'])}';

    if (
        combined.contains(
          'REFUND',
        ) ||
        combined.contains(
          'ESTORNO',
        ) ||
        combined.contains(
          'REVERSAL',
        )) {
      return 'Estorno';
    }

    if (
        combined.contains(
          'PAYMENT',
        ) ||
        combined.contains(
          'PAGAMENTO',
        ) ||
        combined.contains(
          'FATURA',
        )) {
      return 'Pagamento de fatura';
    }

    return 'Compra';
  }

  // =========================================================
  // HELPERS DA TRANSAÇÃO
  // =========================================================

  String _normalize(
    dynamic value,
  ) {
    return value
        ?.toString()
        .trim()
        .toUpperCase() ??
        '';
  }

  DateTime _transactionDate(
    Map<String, dynamic> transaction,
  ) {
    final candidates = [
      transaction['date'],
      transaction['transactionDate'],
      transaction['createdAt'],
      transaction['updatedAt'],
    ];

    for (final candidate
        in candidates) {
      if (candidate == null) {
        continue;
      }

      try {
        return DateTime.parse(
          candidate.toString(),
        ).toLocal();
      } catch (_) {}
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  double _transactionAmount(
    Map<String, dynamic> transaction,
  ) {
    final candidates = [
      transaction['amount'],
      transaction['value'],
    ];

    for (final candidate
        in candidates) {
      if (candidate is num) {
        return candidate.toDouble();
      }

      if (candidate != null) {
        final parsed =
            double.tryParse(
          candidate.toString(),
        );

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return 0;
  }

  String _description(
    Map<String, dynamic> transaction,
  ) {
    final candidates = [
      transaction['description'],
      transaction['descriptionRaw'],
      transaction['merchant']
          ?['name'],
    ];

    for (final candidate
        in candidates) {
      if (candidate != null &&
          candidate
              .toString()
              .trim()
              .isNotEmpty) {
        return candidate
            .toString()
            .trim();
      }
    }

    return 'Transação';
  }

  String? _category(
    Map<String, dynamic> transaction,
  ) {
    final value =
        transaction['category']
            ?.toString()
            .trim();

    if (value == null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  String? _installmentText(
    Map<String, dynamic> transaction,
  ) {
    final creditCardMetadata =
        transaction[
            'creditCardMetadata'];

    if (creditCardMetadata is Map) {
      final installmentNumber =
          creditCardMetadata[
              'installmentNumber'];

      final totalInstallments =
          creditCardMetadata[
              'totalInstallments'];

      if (installmentNumber !=
              null &&
          totalInstallments !=
              null) {
        return '$installmentNumber/'
            '$totalInstallments';
      }
    }

    final installment =
        transaction[
            'installmentNumber'];

    final total =
        transaction[
            'totalInstallments'];

    if (installment != null &&
        total != null) {
      return '$installment/$total';
    }

    return null;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final grouped =
        _groupedTransactions;

    final dates =
        grouped.keys.toList()
          ..sort(
            (a, b) =>
                b.compareTo(a),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compras',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          36,
        ),
        children: [
          _buildHeader(),

          const SizedBox(
            height: 20,
          ),

          _buildSummary(),

          const SizedBox(
            height: 30,
          ),

          _buildSectionHeader(),

          const SizedBox(
            height: 12,
          ),

          if (_transactions.isEmpty)
            _buildEmptyState()
          else
            ...dates.map(
              (date) =>
                  _buildDayGroup(
                date,
                grouped[date]!,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color:
            const Color(
          0xFF315B78,
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _institutionName,
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.65,
              ),
              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            _cardName,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          if (_cardNumber
              .isNotEmpty) ...[
            const SizedBox(
              height: 5,
            ),

            Text(
              _cardNumber,
              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: 0.55,
                ),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // RESUMO
  // =========================================================

  Widget _buildSummary() {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
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
      child: Row(
        children: [
          Expanded(
            child: _buildMetric(
              'Compras',
              '$_purchasesCount',
            ),
          ),

          Container(
            width: 1,
            height: 38,
            color:
                Colors.grey.shade200,
          ),

          const SizedBox(
            width: 18,
          ),

          Expanded(
            child: _buildMetric(
              'Total',
              formatCurrency(
                _purchasesTotal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                Colors.grey.shade500,
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
            fontSize: 17,
            fontWeight:
                FontWeight.w800,
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
            'Movimentações',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),

        Text(
          '${_transactions.length}',
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
  // AGRUPAMENTO POR DIA
  // =========================================================

  Widget _buildDayGroup(
    DateTime date,
    List<Map<String, dynamic>>
        transactions,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(
              date,
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Column(
              children:
                  transactions
                      .asMap()
                      .entries
                      .map(
                (entry) {
                  return _buildTransaction(
                    entry.value,
                    showDivider:
                        entry.key !=
                            transactions.length -
                                1,
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LINHA DA TRANSAÇÃO
  // =========================================================

  Widget _buildTransaction(
    Map<String, dynamic> transaction, {
    required bool showDivider,
  }) {
    final kind =
        _transactionKind(
      transaction,
    );

    final amount =
        _transactionAmount(
      transaction,
    ).abs();

    final category =
        _category(
      transaction,
    );

    final installment =
        _installmentText(
      transaction,
    );

    final isRefund =
        kind == 'Estorno';

    final isPayment =
        kind ==
            'Pagamento de fatura';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom:
                    BorderSide(
                  color: Colors
                      .grey.shade100,
                ),
              )
            : null,
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
              color: AppTheme
                  .primary
                  .withValues(
                alpha: 0.07,
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              isRefund
                  ? Icons
                      .undo_rounded
                  : isPayment
                      ? Icons
                          .payments_outlined
                      : Icons
                          .shopping_bag_outlined,
              size: 19,
              color:
                  AppTheme.primary,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _description(
                    transaction,
                  ),
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildTag(
                      kind,
                    ),

                    if (category !=
                        null)
                      _buildTag(
                        category,
                      ),

                    if (installment !=
                        null)
                      _buildTag(
                        '$installment parcelas',
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Text(
            '${isRefund || isPayment ? '-' : ''}'
            '${formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
              color:
                  isRefund || isPayment
                      ? AppTheme.primary
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color:
            Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color:
              Colors.grey.shade600,
        ),
      ),
    );
  }

  // =========================================================
  // DATA
  // =========================================================

  String _formatDate(
    DateTime date,
  ) {
    final now =
        DateTime.now();

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today
            .difference(
          target,
        )
            .inDays;

    if (difference == 0) {
      return 'Hoje';
    }

    if (difference == 1) {
      return 'Ontem';
    }

    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  // =========================================================
  // EMPTY
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
          18,
        ),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.primary
                  .withValues(
                alpha: 0.08,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .shopping_bag_outlined,
              color:
                  AppTheme.primary,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Nenhuma compra encontrada',
            textAlign:
                TextAlign.center,
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
            'As movimentações disponibilizadas pela instituição aparecerão aqui.',
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
}