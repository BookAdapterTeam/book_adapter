import 'package:book_adapter/app.dart';
import 'package:book_adapter/features/in_app_update/update.dart';
import 'package:book_adapter/features/in_app_update/util/http_utils.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  await init();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpUtils.init();
  UpdateManager.init();
}
