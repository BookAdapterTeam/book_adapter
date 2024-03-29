import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_update_dialog/flutter_update_dialog.dart';

import 'data/update_data.dart';
import 'update.dart';
import 'util/common.dart';
import 'util/http_utils.dart';
import 'util/toast_utils.dart';

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

    final title = 'Upgrade to ${updateData.versionName}?';
    final updateContent = getUpdateContent();
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
    final targetSize = CommonUtils.getTargetSize(updateData.apkSize.toDouble());
    var updateContent = '';
    if (targetSize.isNotEmpty) {
      updateContent += 'New Version Size: $targetSize\n';
    }

    return updateContent + updateData.updateContent;
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
      onReceiveProgress: (count, total) {
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
    onInstall.call(_apkFile != null ? _apkFile!.path : updateData.androidDownloadUrl);
  }
}
