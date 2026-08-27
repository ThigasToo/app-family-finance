import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ConnectBankScreen extends StatefulWidget {
  const ConnectBankScreen({super.key});

  @override
  State<ConnectBankScreen> createState() => _ConnectBankScreenState();
}

class _ConnectBankScreenState extends State<ConnectBankScreen> {
  final _authService = AuthService();
  late final WebViewController _controller;

  bool _isLoadingToken = true;
  bool _isRegisteringItem = false;
  bool _itemProcessed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  Future<void> _setupWebView() async {
    try {
      print('🔵 Buscando connect token...');
      final token = await _authService.getToken();
      print('🔵 Token JWT obtido: ${token != null}');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pluggy/connect-token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('🔵 Status da resposta: ${response.statusCode}');
      print('🔵 Corpo: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Não foi possível gerar o token de conexão');
      }

      final connectToken = jsonDecode(response.body)['connect_token'];

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (message) => _handlePluggyResult(message.message),
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (_itemProcessed) return;
              final uri = Uri.tryParse(url);
              final itemId = uri?.queryParameters['itemId'];
              if (itemId != null && itemId.isNotEmpty) {
                _itemProcessed = true;
                _handlePluggyResult(jsonEncode({
                  'status': 'success',
                  'item': {'id': itemId},
                }));
              }
            },
          ),
        )
        ..loadHtmlString(_buildHtml(connectToken), baseUrl: 'https://localhost/');

      setState(() => _isLoadingToken = false);
    } catch (e) {
      setState(() {
        _isLoadingToken = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _buildHtml(String connectToken) {
  return '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="UTF-8">
    <script>
      window.open = function(url) {
        window.location.href = url;
        return null;
      };
    </script>
    <script src="https://cdn.pluggy.ai/pluggy-connect/v2.8.2/pluggy-connect.js"></script>
  </head>
  <body>
    <script>
      const pluggyConnect = new PluggyConnect({
        connectToken: "$connectToken",
        includeSandbox: false,
        onSuccess: (itemData) => {
          FlutterChannel.postMessage(JSON.stringify({ status: "success", item: itemData.item }));
        },
        onError: (error) => {
          FlutterChannel.postMessage(JSON.stringify({ status: "error", message: error.message }));
        },
      });
      pluggyConnect.init();
    </script>
  </body>
  </html>
  ''';
}

  Future<void> _handlePluggyResult(String rawMessage) async {
    final data = jsonDecode(rawMessage);

    if (data['status'] == 'error') {
      setState(() => _errorMessage = data['message']);
      return;
    }

    final itemId = data['item']['id'];
    setState(() => _isRegisteringItem = true);

    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pluggy/items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'item_id': itemId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true); // volta avisando sucesso
      } else {
        setState(() => _errorMessage = 'Conta conectada, mas houve erro ao registrar no app');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isRegisteringItem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar conta')),
      body: _isLoadingToken
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isRegisteringItem)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
    );
  }
}