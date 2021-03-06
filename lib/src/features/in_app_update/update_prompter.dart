import 'dart:io';

import 'package:book_adapter/src/features/in_app_update/data/update_data.dart';
import 'package:book_adapter/src/features/in_app_update/update.dart';
import 'package:book_adapter/src/features/in_app_update/util/common.dart';
import 'package:book_adapter/src/features/in_app_update/util/http_utils.dart';
import 'package:book_adapter/src/features/in_app_update/util/toast_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_update_dialog/flutter_update_dialog.dart';

// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/update/update_prompter.dart

class UpdatePrompter {
  /// Version update information
  ///
  /// 版本更新信息
  final UpdateData updateData;

  final InstallCallback onInstall;

  final VoidCallback? onIgnore;
  final VoidCallback? onClose;
  final VoidCallback? onNoUpdate;
  UpdateDialog? _dialog;

  double _progress = 0.0;

  File? _apkFile;

  UpdatePrompter({
    required this.updateData,
    required this.onInstall,
    required this.onIgnore,
    required this.onClose,
    required this.onNoUpdate,
  });

  Future<void> show(BuildContext context) async {
    if (_dialog != null && _dialog!.isShowing()) {
      return;
    }

    if (!updateData.hasUpdate) {
      onNoUpdate?.call();
      return;
    }

    final String title = 'Upgrade to ${updateData.versionName}?';
    final String updateContent = getUpdateContent();
    if (Platform.isAndroid) {
      _apkFile = await CommonUtils.getApkFileByUpdateData(updateData);
    }

    if (_apkFile != null && _apkFile!.existsSync()) {
      // TODO: Fix lint
      // ignore: use_build_context_synchronously
      _dialog = UpdateDialog.showUpdate(
        context,
        title: title,
        updateContent: updateContent,
        updateButtonText: 'Install',
        ignoreButtonText: 'Cancel Install',
        extraHeight: 10,
        enableIgnore: updateData.isIgnorable,
        isForce: updateData.isForce,
        onUpdate: doInstall,
        onIgnore: onIgnore,
        onClose: onClose,
      );
    } else {
      // TODO: Fix lint
      // ignore: use_build_context_synchronously
      _dialog = UpdateDialog.showUpdate(
        context,
        title: title,
        updateContent: updateContent,
        updateButtonText: 'Download',
        ignoreButtonText: 'Ignore Update',
        extraHeight: 10,
        enableIgnore: updateData.isIgnorable,
        isForce: updateData.isForce,
        onUpdate: onUpdate,
        onIgnore: onIgnore,
        onClose: onClose,
      );
    }
  }

  String getUpdateContent() {
    final String targetSize =
        CommonUtils.getTargetSize(updateData.apkSize.toDouble());
    String updateContent = '';
    if (targetSize.isNotEmpty) {
      updateContent += 'New Version Size：$targetSize\n';
    }
    updateContent += updateData.updateContent;
    return updateContent;
  }

  Future<void> onUpdate() async {
    if (Platform.isIOS) {
      doInstall();
      return;
    }

    if (_apkFile == null) return;

    await HttpUtils.downloadFile(
      updateData.androidDownloadUrl,
      _apkFile!.path,
      onReceiveProgress: (int count, int total) {
        _progress = count.toDouble() / total;
        if (_progress <= 1.0001) {
          _dialog?.update(_progress);
        }
      },
    ).then((_) {
      doInstall();
    }).catchError((_) {
      ToastUtils.error('Download Failed!');
      _dialog?.dismiss();
    });
  }

  /// Install
  ///
  /// 安装
  void doInstall() {
    _dialog?.dismiss();
    onInstall.call(
        _apkFile != null ? _apkFile!.path : updateData.androidDownloadUrl);
  }
}
