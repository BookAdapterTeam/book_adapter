import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'src/app.dart';
import 'src/features/in_app_update/update.dart';

void main() async {
  await init();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  UpdateManager.init(
    updateCheckTimeout: 60 * 1000, // 1 minute
    downloadTimeout: 60 * 1000, // 1 minute
  );
}
