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

  static Future<void> checkUpdate({
    required BuildContext context,
    required String url,
    VoidCallback? onIgnore,
    VoidCallback? onClose,
    VoidCallback? onNoUpdate,
  }) async {
    try {
      final response = await HttpUtils.get<Map<String, dynamic>>(url);

      final data = await UpdateParser.parseJson(json.encode(response));
      if (data == null) return;

      // TODO: Fix lint
      // ignore: use_build_context_synchronously
      await UpdatePrompter(
        updateData: data,
        onIgnore: onIgnore,
        onClose: onClose,
        onNoUpdate: onNoUpdate,
        onInstall: (filePath) async {
          await CommonUtils.installAPP(
            filePath: filePath,
            githubReleaseUrl: data.githubReleaseUrl,
          );
        },
      ).show(context);
    } catch (e) {
      ToastUtils.error(e.toString());
    }
  }
}

typedef InstallCallback = Function(String filePath);
