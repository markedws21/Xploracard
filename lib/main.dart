import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xplora Card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const WebViewHomePage(),
    );
  }
}

class WebViewHomePage extends StatefulWidget {
  const WebViewHomePage({super.key});

  @override
  State<WebViewHomePage> createState() => _WebViewHomePageState();
}

class _WebViewHomePageState extends State<WebViewHomePage> {
  bool _isLoading = true;
  bool _hasConnection = true;
  bool _webError = false;
  late final WebViewController _controller;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final String _url = 'https://xploratarjetas.azurewebsites.net/';

  @override
  void initState() {
    super.initState();

    // Inicializar WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
              _webError = false;
            });
          },
          onWebResourceError: (_) {
            // Captura errores del WebView
            setState(() => _webError = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));

    // Escuchar cambios de conexión
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final connected = result != ConnectivityResult.none;

      if (connected && (!_hasConnection || _webError)) {
        // Si se reconecta o hubo error web, recargar
        _controller.loadRequest(Uri.parse(_url));
      }
      setState(() => _hasConnection = connected);
    });

    // Verificar conexión inicial
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _hasConnection = result.isNotEmpty && result.first != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshPage() async {
    if (_hasConnection) {
      await _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showError = !_hasConnection || _webError;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: showError
            ? _buildNoConnectionView()
            : Stack(
                children: [
                  RefreshIndicator(
                    color: Colors.deepPurple,
                    onRefresh: _refreshPage,
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
      ),
    );
  }

  Widget _buildNoConnectionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.grey, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Sin conexión a Internet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica tu conexión.\nLa página se recargará automáticamente cuando vuelvas a conectarte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
