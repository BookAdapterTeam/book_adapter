import 'package:book_adapter/app.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  await init();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
}
