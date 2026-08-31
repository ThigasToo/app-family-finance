import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_ui.dart';


class AccountTransactionsScreen
    extends StatelessWidget {
  final Map<String, dynamic> account;

  const AccountTransactionsScreen({
    super.key,
    required this.account,
  });

  // =========================================================
  // CONTA
  // =========================================================

  String get _accountName {
    final marketingName =
        account['marketingName'];

    if (marketingName != null &&
        marketingName
            .toString()
            .trim()
            .isNotEmpty) {
      return marketingName
          .toString()
          .trim();
    }

    final name =
        account['name'];

    if (name != null &&
        name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    return 'Conta';
  }

  String get _institutionName {
    final candidates = [
      account['institution_name'],
      account['resolved_institution'],
      account['institution'],
      account['institutionName'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return 'Instituição';
  }

  String get _accountNumber {
    final value =
        account['number']
                ?.toString()
                .trim() ??
            '';

    if (value.isEmpty) {
      return '';
    }

    if (value.length <= 5) {
      return '•••• $value';
    }

    return '•••• ${value.substring(value.length - 5)}';
  }

  double get _accountBalance {
    return _asDouble(
      account['balance'],
    );
  }

  // =========================================================
  // TRANSAÇÕES
  // =========================================================

  List<Map<String, dynamic>>
      get _transactions {
    final raw =
        account['transactions'];

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
  // RESUMO MÊS
  // =========================================================

  double get _monthIncome {
    final now =
        DateTime.now();

    double total = 0;

    for (final transaction
        in _transactions) {
      final date =
          _transactionDate(
        transaction,
      );

      if (date.year != now.year ||
          date.month != now.month) {
        continue;
      }

      final amount =
          _transactionAmount(
        transaction,
      );

      if (amount > 0) {
        total += amount;
      }
    }

    return total;
  }

  double get _monthExpense {
    final now =
        DateTime.now();

    double total = 0;

    for (final transaction
        in _transactions) {
      final date =
          _transactionDate(
        transaction,
      );

      if (date.year != now.year ||
          date.month != now.month) {
        continue;
      }

      final amount =
          _transactionAmount(
        transaction,
      );

      if (amount < 0) {
        total += amount.abs();
      }
    }

    return total;
  }

  // =========================================================
  // HELPERS
  // =========================================================

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

  DateTime _transactionDate(
    Map<String, dynamic> transaction,
  ) {
    final candidates = [
      transaction['date'],
      transaction['transactionDate'],
      transaction['createdAt'],
      transaction['updatedAt'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }

      try {
        return DateTime.parse(
          candidate.toString(),
        ).toLocal();
      } catch (_) {}
    }

    return DateTime.fromMillisecondsSinceEpoch(
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

    for (final candidate in candidates) {
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

  String _transactionDescription(
    Map<String, dynamic> transaction,
  ) {
    final candidates = [
      transaction['merchant']?['name'],
      transaction['description'],
      transaction['descriptionRaw'],
      transaction['category'],
      transaction['type'],
    ];

    for (final candidate in candidates) {
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

    return 'Movimentação';
  }

  String? _transactionSubtitle(
    Map<String, dynamic> transaction,
  ) {
    final candidates = [
      transaction['category'],
      transaction['type'],
      transaction['paymentData']
          ?['payer']?['name'],
      transaction['paymentData']
          ?['receiver']?['name'],
    ];

    final description =
        _transactionDescription(
      transaction,
    );

    for (final candidate in candidates) {
      if (candidate != null &&
          candidate
              .toString()
              .trim()
              .isNotEmpty) {
        final value =
            candidate
                .toString()
                .trim();

        if (value != description) {
          return value;
        }
      }
    }

    return null;
  }

  IconData _transactionIcon(
    Map<String, dynamic> transaction,
  ) {
    final text =
        '${transaction['category'] ?? ''} '
                '${transaction['description'] ?? ''}'
            .toUpperCase();

    if (text.contains('PIX')) {
      return Icons.pix_rounded;
    }

    if (text.contains('FOOD') ||
        text.contains('RESTAUR') ||
        text.contains('ALIMENT')) {
      return Icons
          .restaurant_rounded;
    }

    if (text.contains('TRANSPORT') ||
        text.contains('UBER') ||
        text.contains('99')) {
      return Icons
          .directions_car_rounded;
    }

    if (text.contains('SHOP') ||
        text.contains('COMPRA')) {
      return Icons
          .shopping_bag_rounded;
    }

    if (_transactionAmount(
          transaction,
        ) >
        0) {
      return Icons
          .south_west_rounded;
    }

    return Icons
        .north_east_rounded;
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
      title: 'Movimentações',
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
                'Saldo atual',
            value:
                _accountBalance,
            details: [
              FinanceHeroInfo(
                icon:
                    Icons
                        .account_balance_rounded,
                text:
                    _institutionName,
              ),

              FinanceHeroInfo(
                icon:
                    Icons
                        .account_balance_wallet_rounded,
                text:
                    _accountName,
              ),

              if (_accountNumber
                  .isNotEmpty)
                FinanceHeroInfo(
                  icon:
                      Icons
                          .tag_rounded,
                  text:
                      _accountNumber,
                ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _summaryCard(
                  icon:
                      Icons
                          .south_west_rounded,
                  label:
                      'Entradas',
                  value:
                      _monthIncome,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    _summaryCard(
                  icon:
                      Icons
                          .north_east_rounded,
                  label:
                      'Saídas',
                  value:
                      _monthExpense,
                ),
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
                  'Nenhuma movimentação',
              subtitle:
                  'Não encontramos movimentações para esta conta.',
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

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required double value,
  }) {
    return FinanceGlassCard(
      radius: 20,
      child: Padding(
        padding:
            const EdgeInsets.all(
          15,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            FinanceIconBubble(
              icon: icon,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              label,
              style:
                  const TextStyle(
                color:
                    AppTheme.inkSoft,
                fontSize: 11,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              formatCurrency(value),
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    AppTheme.ink,
                fontSize: 15,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
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
                (entry) {
                  return _transactionRow(
                    entry.value,
                    showDivider:
                        entry.key !=
                            transactions
                                    .length -
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

  Widget _transactionRow(
    Map<String, dynamic> transaction, {
    required bool showDivider,
  }) {
    final amount =
        _transactionAmount(
      transaction,
    );

    final income =
        amount > 0;

    final subtitle =
        _transactionSubtitle(
      transaction,
    );

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
                _transactionIcon(
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
                  _transactionDescription(
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

                if (subtitle !=
                    null) ...[
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
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            '${income ? '+' : '-'}'
            '${formatCurrency(amount.abs())}',
            style: TextStyle(
              color:
                  income
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
          const Duration(
            days: 1,
          ),
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