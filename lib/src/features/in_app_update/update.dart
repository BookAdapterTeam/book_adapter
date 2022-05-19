import 'dart:convert';

import 'package:book_adapter/src/features/in_app_update/update_parser.dart';
import 'package:book_adapter/src/features/in_app_update/update_prompter.dart';
import 'package:book_adapter/src/features/in_app_update/util/common.dart';
import 'package:book_adapter/src/features/in_app_update/util/http_utils.dart';
import 'package:book_adapter/src/features/in_app_update/util/toast_utils.dart';
import 'package:flutter/material.dart';

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
    final VoidCallback? onIgnore,
    final VoidCallback? onClose,
    final VoidCallback? onNoUpdate,
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
        onInstall: (String filePath) async {
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
