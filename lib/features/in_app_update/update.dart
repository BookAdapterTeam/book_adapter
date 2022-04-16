import 'dart:convert';

import 'package:flutter/material.dart';

import 'update_parser.dart';
import 'update_prompter.dart';
import 'util/common.dart';
import 'util/http_utils.dart';
import 'util/toast_utils.dart';

// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/update/update.dart

/// Version Update Manager
///
/// 版本更新管理
class UpdateManager {
  /// Global initialization
  ///
  /// 全局初始化
  static void init({
    String baseUrl = '',
    int updateCheckTimeout = 5000,
    int downloadTimeout = 5000,
    Map<String, dynamic>? headers,
  }) {
    HttpUtils.init(
      baseUrl: baseUrl,
      updateCheckTimeout: updateCheckTimeout,
      downloadTimeout: downloadTimeout,
      headers: headers,
    );
  }

  static Future<void> checkUpdate(
    BuildContext context,
    String url,
    final VoidCallback? onIgnore,
    final VoidCallback? onClose,
  ) async {
    await HttpUtils.get<Map<String, dynamic>>(url).then((response) {
      UpdateParser.parseJson(json.encode(response)).then(
        (data) {
          if (data == null) return;

          UpdatePrompter(
            updateData: data,
            onIgnore: onIgnore,
            onClose: onClose,
            onInstall: (String filePath) async {
              await CommonUtils.installAPP(
                filePath: filePath,
                githubReleaseUrl: data.githubReleaseUrl,
              );
            },
          ).show(context);
        },
      );
    }).catchError((onError) {
      ToastUtils.error(onError.toString());
    });
  }
}

typedef InstallCallback = Function(String filePath);
