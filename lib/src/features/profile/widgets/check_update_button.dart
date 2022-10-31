import 'package:flutter/material.dart';

import '../../../constants/constants.dart';
import '../../in_app_update/update.dart';
import '../../in_app_update/util/toast_utils.dart';

class CheckUpdateButton extends StatelessWidget {
  const CheckUpdateButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => TextButton.icon(
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
