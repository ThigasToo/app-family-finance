String cardStorageKey(
  dynamic card,
) {
  final candidates = [
    card['id'],
    card['accountId'],
    card['account_id'],
    card['pluggy_id'],
  ];

  for (final value
      in candidates) {
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

  final institution =
      card['institution_name']
              ?.toString() ??
          card['resolved_institution']
              ?.toString() ??
          card['institution']
              ?.toString() ??
          '';

  final number =
      card['number']
          ?.toString() ??
      '';

  final name =
      card['marketingName']
              ?.toString() ??
          card['name']
              ?.toString() ??
          '';

  return '$institution|$number|$name';
}


String originalCardName(
  dynamic card,
) {
  final marketing =
      card['marketingName']
          ?.toString()
          .trim();

  if (marketing != null &&
      marketing.isNotEmpty) {
    return marketing;
  }

  final name =
      card['name']
          ?.toString()
          .trim();

  if (name != null &&
      name.isNotEmpty) {
    return name;
  }

  return 'Cartão';
}