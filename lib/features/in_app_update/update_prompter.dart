import 'dart:io';

import 'package:book_adapter/features/in_app_update/util/common.dart';
import 'package:book_adapter/features/in_app_update/util/http_utils.dart';
import 'package:book_adapter/features/in_app_update/util/toast_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_update_dialog/flutter_update_dialog.dart';

import 'data/update_data.dart';
import 'update.dart';

// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/update/update_prompter.dart

class UpdatePrompter {
  /// Version update information
  ///
  /// 版本更新信息
  final UpdateData updateData;

  final InstallCallback onInstall;

  UpdateDialog? _dialog;

  double _progress = 0.0;

  File? _apkFile;

  UpdatePrompter({required this.updateData, required this.onInstall});

  void show(BuildContext context) async {
    if (_dialog != null && _dialog!.isShowing()) {
      return;
    }

    if (updateData.hasUpdate == false) return;
    
    final String title = 'Upgrade to ${updateData.versionName}?';
    final String updateContent = getUpdateContent();
    if (Platform.isAndroid) {
      _apkFile = await CommonUtils.getApkFileByUpdateData(updateData);
    }


    if (_apkFile != null && _apkFile!.existsSync()) {
      _dialog = UpdateDialog.showUpdate(
        context,
        title: title,
        updateContent: updateContent,
        updateButtonText: 'Install',
        extraHeight: 10,
        enableIgnore: updateData.isIgnorable,
        isForce: updateData.isForce,
        onUpdate: doInstall,
      );
    } else {
      _dialog = UpdateDialog.showUpdate(
        context,
        title: title,
        updateContent: updateContent,
        extraHeight: 10,
        enableIgnore: updateData.isIgnorable,
        isForce: updateData.isForce,
        onUpdate: onUpdate,
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

  void onUpdate() {
    if (Platform.isIOS) {
      doInstall();
      return;
    }

    if (_apkFile == null) return;

    HttpUtils.downloadFile(
      updateData.downloadUrl,
      _apkFile!.path,
      onReceiveProgress: (int count, int total) {
        _progress = count.toDouble() / total;
        if (_progress <= 1.0001) {
          _dialog?.update(_progress);
        }
      },
    ).then((value) {
      doInstall();
    }).catchError((value) {
      ToastUtils.success('Download Failed!');
      _dialog?.dismiss();
    });
  }

  /// Install
  ///
  /// 安装
  void doInstall() {
    _dialog?.dismiss();
    onInstall.call(_apkFile != null ? _apkFile!.path : updateData.downloadUrl);
  }
}
