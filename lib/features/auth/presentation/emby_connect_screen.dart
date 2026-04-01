// lib/features/auth/presentation/emby_connect_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/core/error/app_exceptions.dart';
import 'package:altemby/core/utils/device_utils.dart';
import 'package:altemby/features/auth/data/emby_connect_service.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/auth/presentation/providers/connect_providers.dart';

class EmbyConnectScreen extends ConsumerStatefulWidget {
  const EmbyConnectScreen({super.key});

  @override
  ConsumerState<EmbyConnectScreen> createState() => _EmbyConnectScreenState();
}

class _EmbyConnectScreenState extends ConsumerState<EmbyConnectScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  // After authentication
  ConnectUser? _connectUser;
  List<ConnectServer>? _servers;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _error = null);
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email or username');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final service = ref.read(embyConnectServiceProvider);
      final user = await service.authenticate(
        nameOrEmail: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final servers = await service.getServers(
        connectUserId: user.id,
        connectAccessToken: user.accessToken,
      );

      if (!mounted) return;

      if (servers.isEmpty) {
        setState(() {
          _error = 'No servers linked to this Emby Connect account.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _connectUser = user;
        _servers = servers;
        _isLoading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.userMessage;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Sign in failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToServer(ConnectServer server) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(embyConnectServiceProvider);
      final deviceUtils = ref.read(deviceUtilsProvider);
      final deviceId = await deviceUtils.getOrCreateDeviceId();

      // Try local URL first, then remote
      ConnectExchangeResult? exchange;
      String? serverUrl;

      for (final url
          in [server.localUrl, server.remoteUrl].whereType<String>()) {
        try {
          exchange = await service.exchangeToken(
            serverUrl: url,
            connectUserId: _connectUser!.id,
            accessKey: server.accessKey,
            deviceId: deviceId,
            deviceName: DeviceUtils.getDeviceName(),
          );
          serverUrl = url;
          break;
        } catch (_) {
          continue;
        }
      }

      if (exchange == null || serverUrl == null) {
        throw const NetworkException('Could not reach any server address',
            userMessage: 'Could not connect to this server.');
      }

      // Build a UserSession from the exchange result
      final session = UserSession(
        userId: exchange.localUserId,
        userName: _connectUser!.name,
        accessToken: exchange.accessToken,
        serverId: server.systemId,
        serverUrl: serverUrl,
      );

      // Set up the API client and save
      final apiClient = ref.read(embyApiClientProvider);
      apiClient.updateBaseUrl(serverUrl);
      apiClient.authInterceptor.token = exchange.accessToken;

      final storage = ref.read(secureStorageServiceProvider);
      await storage.saveSession(session);
      await storage.addSavedSession(session);
      await storage.saveServerUrl(serverUrl);

      if (!mounted) return;

      // Authenticate via the notifier so the router redirects
      ref.read(authNotifierProvider.notifier).switchToSession(session);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.userMessage;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to connect to server.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emby Connect')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _servers != null ? _buildServerPicker() : _buildLoginForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.cloud_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'Sign in with Emby Connect',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Use your Emby Connect account to find your servers automatically.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email or Username',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _signIn(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            style:
                TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _signIn,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign In'),
        ),
      ],
    );
  }

  Widget _buildServerPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select a Server',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which server to connect to:',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        ..._servers!.map(
          (server) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.dns),
              title: Text(server.name),
              subtitle: Text(server.remoteUrl ?? server.localUrl ?? ''),
              trailing: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isLoading ? null : () => _connectToServer(server),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() {
            _servers = null;
            _connectUser = null;
            _error = null;
          }),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}
