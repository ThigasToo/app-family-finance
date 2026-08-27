import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'connect_bank_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _financeService = FinanceService();

  AppUser? _user;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _refreshMessage;
  bool _refreshIsError = false;

  List<dynamic> _accounts = [];
  List<dynamic> _investments = [];
  String? _updatedAt;

  @override
  void initState() {
    super.initState();
    _loadUserAndSummary();
  }

  Future<void> _loadUserAndSummary() async {
    final user = await _authService.getCurrentUser();

    if (user == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    setState(() => _user = user);
    await _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _financeService.getSummary();
      setState(() {
        _accounts = summary['payload']?['accounts'] ?? [];
        _investments = summary['payload']?['investments'] ?? [];
        _updatedAt = summary['updated_at'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
      _refreshMessage = null;
    });

    try {
      await _financeService.refresh();
      await _loadSummary();
      setState(() {
        _refreshMessage = 'Atualizado com sucesso!';
        _refreshIsError = false;
      });
    } catch (e) {
      setState(() {
        _refreshMessage = e.toString().replaceFirst('Exception: ', '');
        _refreshIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _handleConnectAccount() async {
    final connected = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ConnectBankScreen()),
    );
    if (connected == true) {
      _loadSummary();
    }
  }

  double get _totalBalance {
    double total = 0;
    for (final acc in _accounts) {
      if (acc['type'] == 'BANK') {
        final balance = acc['balance'];
        if (balance is num) total += balance;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${_user?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Conectar conta',
            onPressed: _handleConnectAccount,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 8),
            _buildRefreshRow(),
            if (_refreshMessage != null) _buildRefreshFeedback(),
            const SizedBox(height: 24),
            _buildSectionHeader('Contas', _accounts.length),
            const SizedBox(height: 8),
            if (_accounts.isEmpty)
              _buildEmptyState('Nenhuma conta conectada ainda')
            else
              ..._accounts.map(_buildAccountCard),
            const SizedBox(height: 24),
            _buildSectionHeader('Investimentos', _investments.length),
            const SizedBox(height: 8),
            if (_investments.isEmpty)
              _buildEmptyState('Nenhum investimento encontrado')
            else
              ..._investments.map(_buildInvestmentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo total em contas',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(_totalBalance),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              formatUpdatedAt(_updatedAt),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: _isRefreshing ? null : _handleRefresh,
            icon: _isRefreshing
                ? const SizedBox(
                    height: 14, width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshFeedback() {
    final color = _refreshIsError ? AppTheme.danger : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_refreshIsError ? Icons.error_outline : Icons.check_circle_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_refreshMessage!, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Text(
      '$title ($count)',
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade500)),
    );
  }

  Widget _buildAccountCard(dynamic acc) {
    final isCredit = acc['type'] == 'CREDIT';
    final balance = acc['balance'];

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Icon(accountTypeIcon(acc['type']), color: AppTheme.primary),
        ),
        title: Text(acc['name'] ?? 'Conta', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(isCredit ? 'Fatura atual' : (acc['type'] ?? '')),
        trailing: Text(
          formatCurrency(balance),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isCredit ? AppTheme.danger : null,
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(dynamic inv) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.withValues(alpha: 0.15),
          child: const Icon(Icons.trending_up, color: Colors.amber),
        ),
        title: Text(inv['name'] ?? 'Investimento', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(inv['type'] ?? ''),
        trailing: Text(
          formatCurrency(inv['balance']),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}