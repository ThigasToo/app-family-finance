import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/finance_ui.dart';

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
  // TOTAIS
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
    var cleaned = name.trim();

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
      cleaned = cleaned.substring(
        1,
        cleaned.length - 1,
      );
    }

    if (cleaned.isEmpty) {
      return 'Conta bancária';
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
    switch (subtype.toUpperCase()) {
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

  double?
      _getAutomaticallyInvestedBalance(
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

  IconData _accountIcon(
    dynamic account,
  ) {
    final subtype =
        account['subtype']
            ?.toString()
            .toUpperCase();

    switch (subtype) {
      case 'SAVINGS_ACCOUNT':
        return Icons.savings_rounded;

      case 'INVESTMENT_ACCOUNT':
        return Icons.trending_up_rounded;

      case 'PREPAID_ACCOUNT':
        return Icons.wallet_rounded;

      default:
        return Icons
            .account_balance_wallet_rounded;
    }
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

    return FinancePage(
      title: institutionName,
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
                'Saldo em $institutionName',
            value:
                _totalBalance,
            details: [
              FinanceHeroInfo(
                icon:
                    Icons
                        .account_balance_wallet_rounded,
                text:
                    '${accounts.length} '
                    '${accounts.length == 1 ? 'conta' : 'contas'}',
              ),
            ],
          ),

          const SizedBox(
            height: 30,
          ),

          FinanceSectionHeader(
            title: 'Suas contas',
            trailing:
                '${accounts.length}',
          ),

          const SizedBox(
            height: 12,
          ),

          if (sortedAccounts.isEmpty)
            const FinanceEmptyState(
              icon:
                  Icons
                      .account_balance_wallet_outlined,
              title:
                  'Nenhuma conta encontrada',
              subtitle:
                  'Não há contas disponíveis nesta instituição.',
            )
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
      child: FinanceGlassCard(
        radius: 23,
        onTap: () {
          _openAccount(
            context,
            account,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(
            17,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  FinanceIconBubble(
                    icon:
                        _accountIcon(
                      account,
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
                        Text(
                          _getAccountName(
                            account,
                          ),
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AppTheme.ink,
                            fontSize: 14.5,
                            height: 1.25,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          _getAccountType(
                            account,
                          ),
                          style:
                              const TextStyle(
                            color:
                                AppTheme
                                    .inkSoft,
                            fontSize: 11.5,
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
                              color:
                                  AppTheme
                                      .inkSoft
                                      .withValues(
                                alpha:
                                    0.65,
                              ),
                              fontSize:
                                  10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 10,
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
                          color:
                              AppTheme.ink,
                          fontSize: 15.5,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      const Text(
                        'Saldo',
                        style:
                            TextStyle(
                          color:
                              AppTheme
                                  .inkSoft,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        AppTheme.inkSoft,
                    size: 24,
                  ),
                ],
              ),

              if ((closingBalance !=
                          null &&
                      closingBalance !=
                          balance) ||
                  (investedBalance !=
                          null &&
                      investedBalance >
                          0)) ...[
                const SizedBox(
                  height: 15,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppTheme.primary
                            .withValues(
                      alpha: 0.05,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (closingBalance !=
                              null &&
                          closingBalance !=
                              balance)
                        _miniInfo(
                          'Saldo de fechamento',
                          formatCurrency(
                            closingBalance,
                          ),
                        ),

                      if (investedBalance !=
                              null &&
                          investedBalance >
                              0)
                        _miniInfo(
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
    );
  }

  Widget _miniInfo(
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
              style:
                  const TextStyle(
                color:
                    AppTheme.inkSoft,
                fontSize: 10.5,
              ),
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(
              color:
                  AppTheme.ink,
              fontSize: 10.5,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}