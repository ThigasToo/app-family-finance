import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MonthlyPlanningScreen extends StatefulWidget {
  final double initialSalary;
  final double initialReceipts;
  final String monthName;

  const MonthlyPlanningScreen({
    super.key,
    required this.initialSalary,
    required this.initialReceipts,
    required this.monthName,
  });

  @override
  State<MonthlyPlanningScreen> createState() =>
      _MonthlyPlanningScreenState();
}

class _MonthlyPlanningScreenState
    extends State<MonthlyPlanningScreen> {
  late final TextEditingController _salaryController;
  late final TextEditingController _receiptsController;

  @override
  void initState() {
    super.initState();

    _salaryController = TextEditingController(
      text: widget.initialSalary == 0
          ? ''
          : _formatInputValue(widget.initialSalary),
    );

    _receiptsController = TextEditingController(
      text: widget.initialReceipts == 0
          ? ''
          : _formatInputValue(widget.initialReceipts),
    );
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _receiptsController.dispose();

    super.dispose();
  }

  double _parseMoneyInput(String value) {
    if (value.trim().isEmpty) {
      return 0;
    }

    String normalized = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '');

    if (normalized.contains(',')) {
      normalized = normalized
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }

  String _formatInputValue(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  void _save() {
    final salary = _parseMoneyInput(
      _salaryController.text,
    );

    final receipts = _parseMoneyInput(
      _receiptsController.text,
    );

    Navigator.of(context).pop({
      'salary': salary,
      'receipts': receipts,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planejamento mensal'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            32,
          ),
          children: [
            Text(
              'Planejamento de ${widget.monthName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Informe quanto você espera receber durante este mês.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 32),

            _buildSectionLabel(
              'Salário',
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _salaryController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Salário esperado',
                hintText: '0,00',
                prefixText: 'R\$ ',
                prefixIcon: Icon(
                  Icons.work_outline_rounded,
                ),
              ),
            ),

            const SizedBox(height: 28),

            _buildSectionLabel(
              'Outros recebimentos',
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _receiptsController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor esperado',
                hintText: '0,00',
                prefixText: 'R\$ ',
                prefixIcon: Icon(
                  Icons.add_card_outlined,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Ex.: bônus, reembolsos, renda extra ou algum valor que você já espera receber.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(
                Icons.check_rounded,
              ),
              label: const Text(
                'Salvar planejamento',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}