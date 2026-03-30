// lib/features/auth/presentation/server_connect_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';

class ServerConnectScreen extends ConsumerStatefulWidget {
  const ServerConnectScreen({super.key});

  @override
  ConsumerState<ServerConnectScreen> createState() =>
      _ServerConnectScreenState();
}

class _ServerConnectScreenState extends ConsumerState<ServerConnectScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool get _isHttpUrl {
    final text = _urlController.text.trim().toLowerCase();
    return text.startsWith('http://');
  }

  String _normalizeUrl(String input) {
    var url = input.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<void> _connect() async {
    setState(() => _errorMessage = null);

    if (_urlController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a server URL');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final url = _normalizeUrl(_urlController.text);

    setState(() => _isConnecting = true);

    try {
      final apiClient = ref.read(embyApiClientProvider);
      apiClient.updateBaseUrl(url);

      final repo = ref.read(authRepositoryProvider);
      final serverInfo = await repo.validateServer(url);

      if (!mounted) return;

      ref.read(serverInfoProvider.notifier).state = serverInfo;

      final storage = ref.read(secureStorageServiceProvider);
      await storage.saveServerUrl(url);

      if (!mounted) return;

      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not connect to server: $e';
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AltEmby',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to your Emby server',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://emby.example.com:8096',
                      prefixIcon: const Icon(Icons.dns),
                      border: const OutlineInputBorder(),
                      errorText: _errorMessage,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _connect(),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_isHttpUrl) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'You are not using HTTPS. Your connection is not secure.',
                            style: TextStyle(color: Colors.orange[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isConnecting ? null : _connect,
                      child: _isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
