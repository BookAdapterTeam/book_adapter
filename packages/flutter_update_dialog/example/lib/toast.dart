import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

const Duration defaultToastDuration = Duration(seconds: 2);
const Color defaultToastColor = Color(0xFF424242);

class ToastUtils {
  ToastUtils._internal();

  ///全局初始化Toast配置, child为MaterialApp
  static OKToast init(Widget child) {
    return OKToast(
      ///字体大小
      textStyle: const TextStyle(fontSize: 16, color: Colors.white),
      backgroundColor: defaultToastColor,
      radius: 10,
      dismissOtherOnShow: true,
      textPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: child,
      duration: defaultToastDuration,
    );
  }

  static void toast(String msg,
      {Duration duration = defaultToastDuration,
      Color color = defaultToastColor}) {
    showToast(msg, duration: duration, backgroundColor: color);
  }

  static void waring(String msg, {Duration duration = defaultToastDuration}) {
    showToast(msg, duration: duration, backgroundColor: Colors.yellow);
  }

  static void error(String msg, {Duration duration = defaultToastDuration}) {
    showToast(msg, duration: duration, backgroundColor: Colors.red);
  }

  static void success(String msg, {Duration duration = defaultToastDuration}) {
    showToast(msg, duration: duration, backgroundColor: Colors.lightGreen);
  }
}
