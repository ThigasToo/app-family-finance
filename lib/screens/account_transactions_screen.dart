import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

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
        marketingName.toString().trim().isNotEmpty) {
      return marketingName
          .toString()
          .trim();
    }

    final name = account['name'];

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
        account['number']?.toString().trim() ?? '';

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

    final result =
        raw
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
          _transactionDate(b).compareTo(
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
  // VALORES DO MÊS
  // =========================================================

  double get _monthIncome {
    final now = DateTime.now();

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
    final now = DateTime.now();

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
        final parsed = double.tryParse(
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
      transaction['description'],
      transaction['descriptionRaw'],
      transaction['merchant']?['name'],
      transaction['category'],
      transaction['type'],
    ];

    for (final candidate in candidates) {
      if (candidate != null &&
          candidate.toString().trim().isNotEmpty) {
        return candidate.toString().trim();
      }
    }

    return 'Movimentação';
  }

  String? _transactionSubtitle(
    Map<String, dynamic> transaction,
  ) {
    final candidates = [
      transaction['type'],
      transaction['category'],
      transaction['paymentData']?['payer']?['name'],
      transaction['paymentData']?['receiver']?['name'],
    ];

    for (final candidate in candidates) {
      if (candidate != null &&
          candidate.toString().trim().isNotEmpty) {
        final value =
            candidate.toString().trim();

        if (value !=
            _transactionDescription(
              transaction,
            )) {
          return value;
        }
      }
    }

    return null;
  }

  bool _isIncome(
    Map<String, dynamic> transaction,
  ) {
    return _transactionAmount(
          transaction,
        ) >
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
          'Movimentações',
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
          _buildAccountHeader(),

          const SizedBox(
            height: 20,
          ),

          _buildMonthSummary(),

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

  Widget _buildAccountHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary,
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
                alpha: 0.72,
              ),
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            _accountName,
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

          if (_accountNumber
              .isNotEmpty) ...[
            const SizedBox(
              height: 5,
            ),

            Text(
              _accountNumber,
              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: 0.55,
                ),
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(
            height: 22,
          ),

          Text(
            'Saldo atual',
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.62,
              ),
              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            formatCurrency(
              _accountBalance,
            ),
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RESUMO DO MÊS
  // =========================================================

  Widget _buildMonthSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            icon:
                Icons.arrow_downward_rounded,
            label: 'Entradas',
            value:
                formatCurrency(
              _monthIncome,
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: _buildSummaryItem(
            icon:
                Icons.arrow_upward_rounded,
            label: 'Saídas',
            value:
                formatCurrency(
              _monthExpense,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color:
                AppTheme.primary,
          ),

          const SizedBox(
            height: 10,
          ),

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
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TÍTULO
  // =========================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Movimentações',
            style:
                TextStyle(
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
            _formatGroupDate(
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
                  final index =
                      entry.key;

                  final transaction =
                      entry.value;

                  return _buildTransactionRow(
                    transaction,
                    showDivider:
                        index !=
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

  Widget _buildTransactionRow(
    Map<String, dynamic> transaction, {
    required bool showDivider,
  }) {
    final amount =
        _transactionAmount(
      transaction,
    );

    final income =
        _isIncome(
      transaction,
    );

    final subtitle =
        _transactionSubtitle(
      transaction,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: Colors
                      .grey.shade100,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary
                  .withValues(
                alpha: 0.07,
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              income
                  ? Icons
                      .south_west_rounded
                  : Icons
                      .north_east_rounded,
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
                  _transactionDescription(
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

                if (subtitle !=
                    null) ...[
                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors
                          .grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Text(
            '${income ? '+' : '-'}'
            '${formatCurrency(amount.abs())}',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
              color: income
                  ? AppTheme.primary
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DATAS
  // =========================================================

  String _formatGroupDate(
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
                  .receipt_long_outlined,
              color:
                  AppTheme.primary,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Nenhuma movimentação encontrada',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Quando a instituição disponibilizar transações para esta conta, elas aparecerão aqui.',
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