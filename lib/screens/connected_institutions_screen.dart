import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/finance_ui.dart';

import 'connect_bank_screen.dart';
import 'institution_accounts_screen.dart';


class ConnectedInstitutionsScreen
    extends StatelessWidget {
  final List<dynamic> accounts;

  final Future<void> Function()?
      onConnectionChanged;


  const ConnectedInstitutionsScreen({
    super.key,
    required this.accounts,
    this.onConnectionChanged,
  });


  // =========================================================
  // NOME DA INSTITUIÇÃO
  // =========================================================

  String _institutionName(
    dynamic account,
  ) {
    final candidates = [
      account['institution_name'],
      account['resolved_institution'],
      account['institution'],
      account['institutionName'],
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

    return 'Instituição';
  }


  // =========================================================
  // AGRUPAMENTO
  // =========================================================

  Map<String, List<dynamic>>
      get _groupedInstitutions {
    final grouped =
        <String, List<dynamic>>{};

    for (final account in accounts) {
      // Queremos instituições bancárias/reais
      // aqui, não agrupamentos manuais.
      final name =
          _institutionName(
        account,
      );

      grouped.putIfAbsent(
        name,
        () => [],
      );

      grouped[name]!.add(
        account,
      );
    }

    return grouped;
  }


  // =========================================================
  // CONECTAR
  // =========================================================

  Future<void> _connect(
    BuildContext context,
  ) async {
    final connected =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const ConnectBankScreen(),
      ),
    );

    if (connected != true) {
      return;
    }

    if (onConnectionChanged != null) {
      await onConnectionChanged!();
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop(
      true,
    );
  }


  // =========================================================
  // ABRIR INSTITUIÇÃO
  // =========================================================

  void _openInstitution(
    BuildContext context,
    String name,
    List<dynamic> institutionAccounts,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            InstitutionAccountsScreen(
          institutionName:
              name,
          accounts:
              institutionAccounts,
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
    final grouped =
        _groupedInstitutions;

    final institutions =
        grouped.keys.toList()
          ..sort(
            (a, b) =>
                a
                    .toLowerCase()
                    .compareTo(
                      b.toLowerCase(),
                    ),
          );


    return FinancePage(
      title:
          'Instituições conectadas',
      child:
          ListView(
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
          _buildHero(
            institutions.length,
          ),

          const SizedBox(
            height: 28,
          ),

          const FinanceSectionHeader(
            title:
                'Suas instituições',
          ),

          const SizedBox(
            height: 12,
          ),

          if (institutions.isEmpty)
            const FinanceEmptyState(
              icon:
                  Icons
                      .account_balance_outlined,
              title:
                  'Nenhuma instituição conectada',
              subtitle:
                  'Conecte um banco para começar a acompanhar suas finanças.',
            )
          else
            ...institutions.map(
              (institution) {
                final institutionAccounts =
                    grouped[
                        institution] ??
                    [];

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child:
                      _buildInstitutionCard(
                    context,
                    institution,
                    institutionAccounts,
                  ),
                );
              },
            ),

          const SizedBox(
            height: 10,
          ),

          SizedBox(
            width:
                double.infinity,
            height:
                52,
            child:
                FilledButton.icon(
              onPressed:
                  () =>
                      _connect(
                context,
              ),
              icon:
                  const Icon(
                Icons.add_rounded,
              ),
              label:
                  const Text(
                'Conectar nova instituição',
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // HERO
  // =========================================================

  Widget _buildHero(
    int count,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          BoxDecoration(
        gradient:
            AppTheme.premiumGradient,
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        boxShadow:
            AppTheme.floatingShadow,
      ),
      child:
          Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                19,
              ),
              border:
                  Border.all(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.14,
                ),
              ),
            ),
            child:
                const Icon(
              Icons
                  .account_balance_rounded,
              color:
                  Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conexões financeiras',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  count == 0
                      ? 'Nenhuma instituição conectada'
                      : '$count ${count == 1 ? 'instituição conectada' : 'instituições conectadas'}',
                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.68,
                    ),
                    fontSize:
                        11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // CARD
  // =========================================================

  Widget _buildInstitutionCard(
    BuildContext context,
    String institution,
    List<dynamic> institutionAccounts,
  ) {
    final count =
        institutionAccounts.length;

    return FinanceGlassCard(
      radius: 23,
      onTap: () =>
          _openInstitution(
        context,
        institution,
        institutionAccounts,
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child:
            Row(
          children: [
            InstitutionLogo(
              institutionName:
                  institution,
              size:
                  50,
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    institution,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.ink,
                      fontSize:
                          14.5,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    '$count ${count == 1 ? 'conta encontrada' : 'contas encontradas'}',
                    style:
                        const TextStyle(
                      color:
                          AppTheme.inkSoft,
                      fontSize:
                          10.5,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration:
                            const BoxDecoration(
                          color:
                              AppTheme.success,
                          shape:
                              BoxShape.circle,
                        ),
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      const Text(
                        'Conectada',
                        style:
                            TextStyle(
                          color:
                              AppTheme.success,
                          fontSize:
                              10,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            const Icon(
              Icons
                  .chevron_right_rounded,
              color:
                  AppTheme.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}