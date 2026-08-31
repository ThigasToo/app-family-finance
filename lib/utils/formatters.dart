import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

String formatCurrency(num? value) {
  if (value == null) return '—';

  return _currencyFormat.format(value);
}


// ===========================================================
// DATA/HORA
// ===========================================================

String formatUpdatedAt(String? isoDate) {
  if (isoDate == null ||
      isoDate.trim().isEmpty) {
    return 'Ainda não atualizado';
  }

  try {
    final parsed =
        DateTime.parse(
      isoDate,
    );

    /*
     * O backend está trabalhando com timestamps UTC.
     *
     * São Paulo:
     * UTC - 3
     *
     * Não dependemos aqui do timezone configurado
     * no aparelho/runtime.
     */
    final utcDate =
        parsed.isUtc
            ? parsed
            : parsed.toUtc();

    final saoPaulo =
        utcDate.subtract(
      const Duration(
        hours: 3,
      ),
    );

    final formatter =
        DateFormat(
      "dd/MM/yyyy 'às' HH:mm",
      'pt_BR',
    );

    return 'Atualizado em '
        '${formatter.format(saoPaulo)}';
  } catch (_) {
    return 'Atualizado recentemente';
  }
}


IconData accountTypeIcon(
  String? type,
) {
  switch (type) {
    case 'BANK':
      return Icons.account_balance;

    case 'CREDIT':
      return Icons.credit_card;

    default:
      return Icons.savings;
  }
}