import 'package:book_adapter/src/data/constants.dart';
import 'package:book_adapter/src/features/in_app_update/update.dart';
import 'package:book_adapter/src/features/in_app_update/util/toast_utils.dart';
import 'package:flutter/material.dart';

class CheckUpdateButton extends StatelessWidget {
  const CheckUpdateButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.refresh_outlined),
      label: Text(
        'Check for Updates...',
        style: Theme.of(context).textTheme.button?.copyWith(
              color: ButtonTheme.of(context).colorScheme?.primary,
            ),
      ),
      onPressed: () {
        UpdateManager.checkUpdate(
          context: context,
          url: kUpdateUrl,
          onNoUpdate: () {
            ToastUtils.toast('There are currently no updates available');
          },
        );
      },
    );
  }
}
