import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String formatCurrency(num? value) {
  if (value == null) return '—';
  return _currencyFormat.format(value);
}

String formatUpdatedAt(String? isoDate) {
  if (isoDate == null) return 'Ainda não atualizado';
  try {
    final date = DateTime.parse(isoDate).toLocal();
    final formatter = DateFormat('dd/MM/yyyy \'às\' HH:mm');
    return 'Atualizado em ${formatter.format(date)}';
  } catch (_) {
    return 'Atualizado recentemente';
  }
}

IconData accountTypeIcon(String? type) {
  switch (type) {
    case 'BANK':
      return Icons.account_balance;
    case 'CREDIT':
      return Icons.credit_card;
    default:
      return Icons.savings;
  }
}