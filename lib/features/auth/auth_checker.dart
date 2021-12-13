import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../controller/firebase_controller.dart';
import '../../data/constants.dart';
import '../widgets/async_value_widget.dart';
import 'login_view.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({Key? key, required this.child}) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreamAsyncValue = ref.watch(authStateChangesProvider);

    return Scaffold(
      body: AsyncValueWidget<User?>(
        value: userStreamAsyncValue,
        data: (data) => AnimatedSwitcher(
          switchInCurve: Curves.easeInCubic,
          switchOutCurve: Curves.easeOutCubic,
          duration: kTransitionDuration,
          child: data == null
          ? LoginView(key: const ValueKey('login'),)
          : child,  
        ),
      ),
    );
  }
}

