import 'package:flutter/material.dart';

import '../services/card_alias_service.dart';
import '../utils/card_utils.dart';


class CardName extends StatefulWidget {
  final dynamic card;
  final TextStyle? style;

  final int maxLines;

  const CardName({
    super.key,
    required this.card,
    this.style,
    this.maxLines = 2,
  });

  @override
  State<CardName> createState() =>
      _CardNameState();
}


class _CardNameState
    extends State<CardName> {
  final _service =
      CardAliasService();

  String? _alias;


  @override
  void initState() {
    super.initState();

    _load();
  }


  Future<void> _load() async {
    final alias =
        await _service.getAlias(
      cardStorageKey(
        widget.card,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _alias =
          alias;
    });
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      _alias ??
          originalCardName(
            widget.card,
          ),
      maxLines:
          widget.maxLines,
      overflow:
          TextOverflow.ellipsis,
      style:
          widget.style,
    );
  }
}