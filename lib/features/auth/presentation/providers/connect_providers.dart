// lib/features/auth/presentation/providers/connect_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/data/emby_connect_service.dart';

final embyConnectServiceProvider = Provider<EmbyConnectService>(
  (ref) => EmbyConnectService(),
);
