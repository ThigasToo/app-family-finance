import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

import 'account_transactions_screen.dart';

class InstitutionAccountsScreen
    extends StatelessWidget {
  final String institutionName;
  final List<dynamic> accounts;

  const InstitutionAccountsScreen({
    super.key,
    required this.institutionName,
    required this.accounts,
  });

  // =========================================================
  // TOTAL
  // =========================================================

  double get _totalBalance {
    double total = 0;

    for (final account in accounts) {
      total += _getAccountBalance(
        account,
      );
    }

    return total;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _getAccountBalance(
    dynamic account,
  ) {
    final balance =
        account['balance'];

    if (balance is num) {
      return balance.toDouble();
    }

    return double.tryParse(
          balance?.toString() ?? '',
        ) ??
        0;
  }

  String _getAccountName(
    dynamic account,
  ) {
    final marketingName =
        account['marketingName'];

    if (marketingName != null &&
        marketingName
            .toString()
            .trim()
            .isNotEmpty) {
      return _cleanAccountName(
        marketingName.toString(),
      );
    }

    final name =
        account['name'];

    if (name != null &&
        name
            .toString()
            .trim()
            .isNotEmpty) {
      return _cleanAccountName(
        name.toString(),
      );
    }

    return 'Conta';
  }

  String _cleanAccountName(
    String name,
  ) {
    var cleaned =
        name.trim();

    if (institutionName
            .toUpperCase() ==
        'PICPAY') {
      cleaned = cleaned
          .replaceAll(
            RegExp(
              r'PICPAY\s+INSTITUIÇÃO\s+DE\s+PAGAMENTO\s+S\.?A\.?',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(
            RegExp(
              r'PICPAY\s+INSTITUICAO\s+DE\s+PAGAMENTO\s+S/?A',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
    }

    cleaned = cleaned
        .replaceAll(
          RegExp(
            r'^\s*[-–—]\s*',
          ),
          '',
        )
        .trim();

    if (cleaned.startsWith('(') &&
        cleaned.endsWith(')')) {
      cleaned =
          cleaned.substring(
        1,
        cleaned.length - 1,
      );
    }

    if (cleaned.isEmpty) {
      return _friendlySubtype(
        '',
      );
    }

    return cleaned;
  }

  String _getAccountType(
    dynamic account,
  ) {
    return _friendlySubtype(
      account['subtype']
              ?.toString() ??
          '',
    );
  }

  String _friendlySubtype(
    String subtype,
  ) {
    switch (
        subtype.toUpperCase()) {
      case 'CHECKING_ACCOUNT':
        return 'Conta corrente';

      case 'SAVINGS_ACCOUNT':
        return 'Conta poupança';

      case 'PAYMENT_ACCOUNT':
        return 'Conta de pagamento';

      case 'PREPAID_ACCOUNT':
        return 'Conta pré-paga';

      case 'INVESTMENT_ACCOUNT':
        return 'Conta de investimento';

      default:
        return 'Conta bancária';
    }
  }

  String _getAccountNumber(
    dynamic account,
  ) {
    final number =
        account['number'];

    if (number == null ||
        number
            .toString()
            .trim()
            .isEmpty) {
      return '';
    }

    final value =
        number.toString().trim();

    if (value.length <= 5) {
      return '•••• $value';
    }

    return '•••• ${value.substring(value.length - 5)}';
  }

  double? _getClosingBalance(
    dynamic account,
  ) {
    final bankData =
        account['bankData'];

    if (bankData is! Map) {
      return null;
    }

    final value =
        bankData[
            'closingBalance'];

    if (value is num) {
      return value.toDouble();
    }

    return null;
  }

  double? _getAutomaticallyInvestedBalance(
    dynamic account,
  ) {
    final bankData =
        account['bankData'];

    if (bankData is! Map) {
      return null;
    }

    final value =
        bankData[
            'automaticallyInvestedBalance'];

    if (value is num) {
      return value.toDouble();
    }

    return null;
  }

  // =========================================================
  // ABRIR CONTA
  // =========================================================

  void _openAccount(
    BuildContext context,
    dynamic account,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AccountTransactionsScreen(
          account:
              Map<String, dynamic>.from(
            account,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final sortedAccounts =
        [...accounts];

    sortedAccounts.sort(
      (a, b) =>
          _getAccountBalance(b)
              .compareTo(
        _getAccountBalance(a),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          institutionName,
        ),
      ),
      body: ListView(
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

          if (sortedAccounts.isEmpty)
            _buildEmptyState()
          else
            ...sortedAccounts.map(
              (account) =>
                  _buildAccountCard(
                context,
                account,
              ),
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
            AppTheme.primary,
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
            'Saldo em $institutionName',
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.76,
              ),
              fontSize: 14,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            formatCurrency(
              _totalBalance,
            ),
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Text(
            '${accounts.length} '
            '${accounts.length == 1 ? 'conta' : 'contas'}',
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.7,
              ),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Suas contas',
            style:
                TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),

        Text(
          '${accounts.length}',
          style: TextStyle(
            color:
                Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _buildAccountCard(
    BuildContext context,
    dynamic account,
  ) {
    final balance =
        _getAccountBalance(
      account,
    );

    final accountNumber =
        _getAccountNumber(
      account,
    );

    final closingBalance =
        _getClosingBalance(
      account,
    );

    final investedBalance =
        _getAutomaticallyInvestedBalance(
      account,
    );

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
            _openAccount(
              context,
              account,
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
                    _buildAccountIcon(
                      account,
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAccountName(
                              account,
                            ),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            _getAccountType(
                              account,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey.shade500,
                            ),
                          ),

                          if (accountNumber
                              .isNotEmpty) ...[
                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              accountNumber,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors
                                    .grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(
                            balance,
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
                          'Saldo',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    Icon(
                      Icons
                          .chevron_right_rounded,
                      color: Colors
                          .grey.shade400,
                      size: 25,
                    ),
                  ],
                ),

                if ((closingBalance != null &&
                        closingBalance !=
                            balance) ||
                    (investedBalance != null &&
                        investedBalance >
                            0)) ...[
                  const SizedBox(
                    height: 16,
                  ),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary
                          .withValues(
                        alpha: 0.05,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (closingBalance != null &&
                            closingBalance !=
                                balance)
                          _buildMiniInfo(
                            'Saldo de fechamento',
                            formatCurrency(
                              closingBalance,
                            ),
                          ),

                        if (investedBalance != null &&
                            investedBalance >
                                0)
                          _buildMiniInfo(
                            'Aplicação automática',
                            formatCurrency(
                              investedBalance,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors
                    .grey.shade500,
              ),
            ),
          ),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountIcon(
    dynamic account,
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
      child: const Icon(
        Icons
            .account_balance_wallet_outlined,
        color:
            AppTheme.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding:
          const EdgeInsets.all(
        24,
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
      child:
          const Text(
        'Nenhuma conta encontrada nesta instituição.',
      ),
    );
  }
}