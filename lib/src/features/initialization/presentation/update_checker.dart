import 'package:book_adapter/src/constants/constants.dart';
import 'package:book_adapter/src/features/in_app_update/update.dart';
import 'package:flutter/material.dart';

class UpdateChecker extends StatefulWidget {
  const UpdateChecker({
    Key? key,
    required this.child,
    this.ignoreUpdate = false,
    required this.onIgnore,
    required this.onClose,
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onIgnore;
  final VoidCallback? onClose;
  final bool ignoreUpdate;

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.ignoreUpdate
        ? widget.child
        : FutureBuilder<void>(
            future: UpdateManager.checkUpdate(
              context: context,
              url: kUpdateUrl,
              onIgnore: widget.onIgnore,
              onClose: widget.onClose,
            ),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return widget.child;
            },
          );
  }
}