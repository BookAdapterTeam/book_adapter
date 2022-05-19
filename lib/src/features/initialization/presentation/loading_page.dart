import 'package:book_adapter/src/constants/constants.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
}

class _LoadingMessageWidget extends StatelessWidget {
  const _LoadingMessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      key: ValueKey(message),
      switchInCurve: Curves.easeInCubic,
      switchOutCurve: Curves.easeOutCubic,
      duration: kTransitionDuration,
      child: Text(message),
    );
  }
}