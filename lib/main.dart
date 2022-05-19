import 'package:book_adapter/app.dart';
import 'package:book_adapter/src/features/in_app_update/update.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
