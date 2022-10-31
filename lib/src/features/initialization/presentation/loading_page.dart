import 'package:flutter/material.dart';

import '../../../constants/constants.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              _LoadingMessageWidget(message: message),
            ],
          ),
        ),
      );
}

class _LoadingMessageWidget extends StatelessWidget {
  const _LoadingMessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        key: ValueKey(message),
        switchInCurve: Curves.easeInCubic,
        switchOutCurve: Curves.easeOutCubic,
        duration: kTransitionDuration,
        child: Text(message),
      );
}
