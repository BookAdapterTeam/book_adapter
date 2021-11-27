import 'dart:convert';

import 'package:book_adapter/features/in_app_update/update_parser.dart';
import 'package:book_adapter/features/in_app_update/update_prompter.dart';
import 'package:book_adapter/features/in_app_update/util/common.dart';
import 'package:book_adapter/features/in_app_update/util/http_utils.dart';
import 'package:book_adapter/features/in_app_update/util/toast_utils.dart';
import 'package:flutter/material.dart';

// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/update/update.dart

/// Version Update Manager
///
/// 版本更新管理
class UpdateManager {
  /// Global initialization
  ///
  /// 全局初始化
  static init({
    String baseUrl = '',
    int timeout = 5000,
    Map<String, dynamic>? headers,
  }) {
    HttpUtils.init(baseUrl: baseUrl, timeout: timeout, headers: headers);
  }

  static void checkUpdate(BuildContext context, String url) {
    HttpUtils.get(url).then((response) {
      UpdateParser.parseJson(json.encode(response)).then(
        (data) {
          if (data == null) return;

          UpdatePrompter(
            updateData: data,
            onInstall: (String filePath) {
              CommonUtils.installAPP(
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
