import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_ui.dart';


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

  Map<DateTime,
          List<Map<String, dynamic>>>
      get _groupedTransactions {
    final grouped =
        <DateTime,
            List<Map<String, dynamic>>>{};

    for (final transaction
        in _transactions) {
      final date =
          _transactionDate(
        transaction,
      );

      final key =
          DateTime(
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
  // CARTÃO
  // =========================================================

  String get _cardName {
    final marketing =
        card['marketingName']
            ?.toString()
            .trim();

    if (marketing != null &&
        marketing.isNotEmpty) {
      return marketing;
    }

    final value =
        card['name']
            ?.toString()
            .trim();

    return value?.isNotEmpty ==
            true
        ? value!
        : 'Cartão';
  }

  String get _institutionName {
    final candidates = [
      card['institution_name'],
      card[
          'resolved_institution'],
      card['institution'],
      card['institutionName'],
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

    final last =
        value.length <= 4
            ? value
            : value.substring(
                value.length - 4,
              );

    return '•••• $last';
  }

  // =========================================================
  // TOTAL
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

  int get _purchasesCount =>
      _transactions
          .where(
            _isPurchase,
          )
          .length;

  // =========================================================
  // CLASSIFICAÇÃO
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

  bool _isPurchase(
    Map<String, dynamic> transaction,
  ) {
    final combined =
        '${_normalize(transaction['type'])} '
        '${_normalize(transaction['category'])} '
        '${_normalize(transaction['description'])} '
        '${_normalize(transaction['descriptionRaw'])}';

    if (combined.contains(
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

    if (combined.contains(
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

    if (combined.contains(
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

    if (combined.contains(
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
  // HELPERS
  // =========================================================

  DateTime _transactionDate(
    Map<String, dynamic> transaction,
  ) {
    final candidates = [
      transaction['date'],
      transaction[
          'transactionDate'],
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
      transaction['merchant']
          ?['name'],
      transaction['description'],
      transaction[
          'descriptionRaw'],
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

    return value?.isNotEmpty ==
            true
        ? value
        : null;
  }

  String? _installmentText(
    Map<String, dynamic> transaction,
  ) {
    final metadata =
        transaction[
            'creditCardMetadata'];

    if (metadata is Map) {
      final current =
          metadata[
              'installmentNumber'];

      final total =
          metadata[
              'totalInstallments'];

      if (current != null &&
          total != null) {
        return '$current/$total';
      }
    }

    final current =
        transaction[
            'installmentNumber'];

    final total =
        transaction[
            'totalInstallments'];

    if (current != null &&
        total != null) {
      return '$current/$total';
    }

    return null;
  }

  IconData _categoryIcon(
    Map<String, dynamic> transaction,
  ) {
    final value =
        '${_category(transaction) ?? ''} '
                '${_description(transaction)}'
            .toUpperCase();

    if (value.contains('FOOD') ||
        value.contains('RESTAUR') ||
        value.contains('ALIMENT')) {
      return Icons
          .restaurant_rounded;
    }

    if (value.contains('TRANSPORT') ||
        value.contains('UBER')) {
      return Icons
          .directions_car_rounded;
    }

    if (value.contains('STREAM') ||
        value.contains('NETFLIX') ||
        value.contains('SPOTIFY')) {
      return Icons
          .subscriptions_rounded;
    }

    if (value.contains('MARKET') ||
        value.contains('MERCADO')) {
      return Icons
          .shopping_cart_rounded;
    }

    return Icons
        .shopping_bag_rounded;
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

    return FinancePage(
      title: 'Compras',
      child: ListView(
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
          FinanceHeroCard(
            label:
                'Total das compras',
            value:
                _purchasesTotal,
            details: [
              FinanceHeroInfo(
                icon:
                    Icons
                        .credit_card_rounded,
                text:
                    _cardName,
              ),
              FinanceHeroInfo(
                icon:
                    Icons
                        .account_balance_rounded,
                text:
                    _institutionName,
              ),
              if (_cardNumber
                  .isNotEmpty)
                FinanceHeroInfo(
                  icon:
                      Icons.tag_rounded,
                  text:
                      _cardNumber,
                ),
              FinanceHeroInfo(
                icon:
                    Icons
                        .shopping_bag_rounded,
                text:
                    '$_purchasesCount compras',
              ),
            ],
          ),

          const SizedBox(
            height: 30,
          ),

          FinanceSectionHeader(
            title:
                'Movimentações',
            trailing:
                '${_transactions.length}',
          ),

          const SizedBox(
            height: 14,
          ),

          if (_transactions.isEmpty)
            const FinanceEmptyState(
              icon:
                  Icons
                      .receipt_long_outlined,
              title:
                  'Nenhuma compra encontrada',
              subtitle:
                  'As movimentações deste cartão aparecerão aqui.',
            )
          else
            ...dates.map(
              (date) =>
                  _dayGroup(
                date,
                grouped[date]!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayGroup(
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
          Padding(
            padding:
                const EdgeInsets.only(
              left: 3,
              bottom: 8,
            ),
            child: Text(
              _formatDate(date),
              style:
                  const TextStyle(
                color:
                    AppTheme.inkSoft,
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          FinanceGlassCard(
            radius: 20,
            child: Column(
              children:
                  transactions
                      .asMap()
                      .entries
                      .map(
                (entry) =>
                    _transactionRow(
                  entry.value,
                  showDivider:
                      entry.key !=
                          transactions
                                  .length -
                              1,
                ),
              )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionRow(
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

    String subtitle =
        category ?? kind;

    if (installment != null) {
      subtitle +=
          ' • Parcela $installment';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        border:
            showDivider
                ? Border(
                    bottom:
                        BorderSide(
                      color:
                          AppTheme.line
                              .withValues(
                        alpha:
                            0.65,
                      ),
                    ),
                  )
                : null,
      ),
      child: Row(
        children: [
          FinanceIconBubble(
            icon:
                isPayment
                    ? Icons
                        .payments_rounded
                    : isRefund
                        ? Icons
                            .undo_rounded
                        : _categoryIcon(
                            transaction,
                          ),
          ),

          const SizedBox(
            width: 13,
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
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.ink,
                    fontSize: 13.5,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppTheme
                            .inkSoft,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            '${isRefund ? '+' : ''}'
            '${formatCurrency(amount)}',
            style: TextStyle(
              color:
                  isRefund
                      ? AppTheme
                          .success
                      : AppTheme.ink,
              fontSize: 13.5,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

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

    final value =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (value == today) {
      return 'HOJE';
    }

    if (value ==
        today.subtract(
          const Duration(days: 1),
        )) {
      return 'ONTEM';
    }

    const months = [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}