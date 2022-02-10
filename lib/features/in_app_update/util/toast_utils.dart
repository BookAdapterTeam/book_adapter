import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import '../../../data/constants.dart';

const defaultToastColor = Color(0xFF424242);

// From https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/utils/toast.dart

class ToastUtils {
  ToastUtils._internal();

  /// Initialize Toast configuration globally, child is MaterialApp
  ///
  /// 全局初始化Toast配置, child为MaterialApp
  static Widget init({required Widget child}) {
    return OKToast(
      /// Front Size
      ///
      /// 字体大小
      textStyle: const TextStyle(fontSize: 16, color: Colors.white),
      backgroundColor: defaultToastColor,
      radius: 10,
      dismissOtherOnShow: true,
      textPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: child,
      duration: kSnackBarDuration,
    );
  }

  static void toast(
    String msg, {
    Duration duration = kSnackBarDuration,
    Color color = defaultToastColor,
  }) {
    showToast(
      msg,
      duration: duration,
      backgroundColor: color,
      position: ToastPosition.bottom,
    );
  }

  static void warning(
    String msg, {
    Duration duration = kSnackBarDuration,
  }) {
    showToast(
      msg,
      duration: duration,
      backgroundColor: Colors.yellow,
      position: ToastPosition.bottom,
    );
  }

  static void error(
    String msg, {
    Duration duration = kSnackBarDuration,
  }) {
    showToast(
      msg,
      duration: duration,
      backgroundColor: Colors.red,
      position: ToastPosition.bottom,
    );
  }

  static void success(
    String msg, {
    Duration duration = kSnackBarDuration,
  }) {
    showToast(
      msg,
      duration: duration,
      backgroundColor: Colors.lightGreen,
      position: ToastPosition.bottom,
    );
  }
}
