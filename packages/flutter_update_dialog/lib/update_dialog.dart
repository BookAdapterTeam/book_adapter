import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'number_progress.dart';

///版本更新加提示框
class UpdateDialog {
  bool _isShowing = false;
  final bool isForce;
  late BuildContext _context;
  late UpdateWidget _widget;
  final GlobalKey<_UpdateWidgetState> _keyUpdateWidget =
      GlobalKey<_UpdateWidgetState>(debugLabel: 'updateDialogGlobalKey');

  // ignore: sort_constructors_first
  UpdateDialog(
    BuildContext context, {
    double width = 0.0,
    required String title,
    required String updateContent,
    required VoidCallback onUpdate,
    double titleTextSize = 16.0,
    double contentTextSize = 14.0,
    double buttonTextSize = 14.0,
    double progress = -1.0,
    Color progressBackgroundColor = const Color(0xFFFFCDD2),
    Image? topImage,
    double extraHeight = 5.0,
    double radius = 4.0,
    Color themeColor = Colors.red,
    VoidCallback? onIgnore,
    this.isForce = false,
    String? updateButtonText,
    String? ignoreButtonText,
    VoidCallback? onClose,
  }) {
    _context = context;
    _widget = UpdateWidget(
      key: _keyUpdateWidget,
      width: width,
      title: title,
      updateContent: updateContent,
      onUpdate: onUpdate,
      titleTextSize: titleTextSize,
      contentTextSize: contentTextSize,
      buttonTextSize: buttonTextSize,
      progress: progress,
      topImage: topImage,
      extraHeight: extraHeight,
      radius: radius,
      themeColor: themeColor,
      progressBackgroundColor: progressBackgroundColor,
      onIgnore: () {
        dismiss();
        onIgnore?.call();
      },
      isForce: isForce,
      updateButtonText: updateButtonText ?? '更新',
      ignoreButtonText: ignoreButtonText ?? '忽略此版本',
      onClose: () {
        dismiss();
        onClose?.call();
      },
    );
  }

  /// 显示弹窗
  Future<bool> show() {
    try {
      if (isShowing()) {
        return Future<bool>.value(false);
      }
      showDialog<bool>(
          context: _context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () {
                if (!isForce) {
                  dismiss();
                }

                return Future<bool>.value(
                  false,
                );
              },
              child: _widget,
            );
          });
      _isShowing = true;
      return Future<bool>.value(true);
    } catch (err) {
      _isShowing = false;
      return Future<bool>.value(false);
    }
  }

  /// 隐藏弹窗
  Future<bool> dismiss() {
    try {
      if (_isShowing) {
        _isShowing = false;
        Navigator.pop(_context);
        return Future<bool>.value(true);
      } else {
        return Future<bool>.value(false);
      }
    } catch (err) {
      return Future<bool>.value(false);
    }
  }

  /// 是否显示
  bool isShowing() {
    return _isShowing;
  }

  /// 更新进度
  void update(double progress) {
    if (isShowing()) {
      _keyUpdateWidget.currentState?.update(progress);
    }
  }

  /// 显示版本更新提示框
  static UpdateDialog showUpdate(
    BuildContext context, {
    double width = 0.0,
    required String title,
    required String updateContent,
    required VoidCallback onUpdate,
    double titleTextSize = 16.0,
    double contentTextSize = 14.0,
    double buttonTextSize = 14.0,
    double progress = -1.0,
    Color progressBackgroundColor = const Color(0xFFFFCDD2),
    Image? topImage,
    double extraHeight = 5.0,
    double radius = 4.0,
    Color themeColor = Colors.red,
    bool enableIgnore = false,
    VoidCallback? onIgnore,
    VoidCallback? onClose,
    String? updateButtonText,
    String? ignoreButtonText,
    bool isForce = false,
  }) {
    final UpdateDialog dialog = UpdateDialog(
      context,
      width: width,
      title: title,
      updateContent: updateContent,
      onUpdate: onUpdate,
      titleTextSize: titleTextSize,
      contentTextSize: contentTextSize,
      buttonTextSize: buttonTextSize,
      progress: progress,
      topImage: topImage,
      extraHeight: extraHeight,
      radius: radius,
      themeColor: themeColor,
      progressBackgroundColor: progressBackgroundColor,
      isForce: isForce,
      updateButtonText: updateButtonText,
      ignoreButtonText: ignoreButtonText,
      onIgnore: onIgnore,
      onClose: onClose,
    );
    dialog.show();
    return dialog;
  }
}

// ignore: must_be_immutable
class UpdateWidget extends StatefulWidget {
  /// 对话框的宽度
  final double width;

  /// 升级标题
  final String title;

  /// 更新内容
  final String updateContent;

  /// 标题文字的大小
  final double titleTextSize;

  /// 更新文字内容的大小
  final double contentTextSize;

  /// 按钮文字的大小
  final double buttonTextSize;

  /// 顶部图片
  final Widget? topImage;

  /// 拓展高度(适配顶部图片高度不一致的情况）
  final double extraHeight;

  /// 边框圆角大小
  final double radius;

  /// 主题颜色
  final Color themeColor;

  /// 更新事件
  final VoidCallback onUpdate;

  /// 更新事件
  final VoidCallback? onIgnore;

  double progress;

  /// 进度条的背景颜色
  final Color progressBackgroundColor;

  /// 更新事件
  final VoidCallback? onClose;

  /// 是否是强制更新
  final bool isForce;

  /// 更新按钮内容
  final String updateButtonText;

  /// 忽略按钮内容
  final String ignoreButtonText;

  // ignore: sort_constructors_first
  UpdateWidget({
    Key? key,
    this.width = 0.0,
    required this.title,
    required this.updateContent,
    required this.onUpdate,
    this.titleTextSize = 16.0,
    this.contentTextSize = 14.0,
    this.buttonTextSize = 14.0,
    this.progress = -1.0,
    this.progressBackgroundColor = const Color(0xFFFFCDD2),
    this.topImage,
    this.extraHeight = 5.0,
    this.radius = 4.0,
    this.themeColor = Colors.red,
    this.onIgnore,
    this.isForce = false,
    this.updateButtonText = '更新',
    this.ignoreButtonText = '忽略此版本',
    this.onClose,
  }) : super(key: key);

  final _UpdateWidgetState _state = _UpdateWidgetState();

  void update(double progress) {
    _state.update(progress);
  }

  @override
  // ignore: no_logic_in_create_state
  State<UpdateWidget> createState() => _state;
}

class _UpdateWidgetState extends State<UpdateWidget> {
  void update(double progress) {
    if (!mounted) {
      return;
    }
    setState(() {
      widget.progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double dialogWidth =
        widget.width <= 0 ? getFitWidth(context) * 0.618 : widget.width;

    final Image image = Image.asset(
      'assets/update_bg_app_top.png',
      package: 'flutter_update_dialog',
      fit: BoxFit.fill,
    );

    return Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // ignore: hack
              // HACK: Wrap widgets with AnimatedSwitcher to get rid of gray line between them
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: dialogWidth,
                    child: widget.topImage ?? image,
                  ),
                ),
              ),
              // Dialog Body
              // Title
              Container(
                width: dialogWidth,
                color: Colors.white,
                padding: EdgeInsets.only(
                    top: widget.extraHeight, left: 16, right: 16),
                child: Text(
                  widget.title,
                  style: TextStyle(
                      fontSize: widget.titleTextSize, color: Colors.black),
                ),
              ),
              // Update Details
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    width: dialogWidth,
                    color: Colors.white,
                    padding: EdgeInsets.only(
                        top: widget.extraHeight, left: 16, right: 16),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: Text(
                          widget.updateContent,
                          style: TextStyle(
                              fontSize: widget.contentTextSize,
                              color: const Color(0xFF666666)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  width: dialogWidth,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(widget.radius),
                          bottomRight: Radius.circular(widget.radius)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Update Button and Progress
                      if (widget.progress < 0)
                        if (getScreenHeight(context) >= 400)
                          Column(children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: FractionallySizedBox(
                                widthFactor: 1,
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: MaterialStateProperty.all(
                                        TextStyle(
                                            fontSize: widget.buttonTextSize)),
                                    foregroundColor:
                                        MaterialStateProperty.all(Colors.white),
                                    shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5))),
                                    elevation: MaterialStateProperty.all(0),
                                    backgroundColor: MaterialStateProperty.all(
                                        widget.themeColor),
                                  ),
                                  onPressed: widget.onUpdate,
                                  child: Text(widget.updateButtonText),
                                ),
                              ),
                            ),
                            if (!widget.isForce && widget.onIgnore != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: FractionallySizedBox(
                                  widthFactor: 1,
                                  child: TextButton(
                                    style: ButtonStyle(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      textStyle: MaterialStateProperty.all(
                                          TextStyle(
                                              fontSize: widget.buttonTextSize)),
                                      foregroundColor:
                                          MaterialStateProperty.all(
                                              const Color(0xFF666666)),
                                      shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5))),
                                    ),
                                    onPressed: widget.onIgnore,
                                    child: Text(widget.ignoreButtonText),
                                  ),
                                ),
                              )
                            else
                              const SizedBox()
                          ])
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                if (!widget.isForce && widget.onIgnore != null)
                                  Flexible(
                                    child: TextButton(
                                      style: ButtonStyle(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        textStyle: MaterialStateProperty.all(
                                            TextStyle(
                                                fontSize:
                                                    widget.buttonTextSize)),
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                                const Color(0xFF666666)),
                                        shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5))),
                                      ),
                                      onPressed: widget.onIgnore,
                                      child: Text(widget.ignoreButtonText),
                                    ),
                                  ),
                                Flexible(
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      textStyle: MaterialStateProperty.all(
                                          TextStyle(
                                              fontSize: widget.buttonTextSize)),
                                      foregroundColor:
                                          MaterialStateProperty.all(
                                              Colors.white),
                                      shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5))),
                                      elevation: MaterialStateProperty.all(0),
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              widget.themeColor),
                                    ),
                                    onPressed: widget.onUpdate,
                                    child: Text(widget.updateButtonText),
                                  ),
                                ),
                              ],
                            ),
                          )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: NumberProgress(
                            value: widget.progress,
                            backgroundColor: widget.progressBackgroundColor,
                            valueColor: widget.themeColor,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        )
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),
              // Removed since it can cause RenderFlex overflow when screenheight is small
              // Close Button
              // if (!widget.isForce) ...<Widget>[
              //   const SizedBox(
              //       width: 1.5,
              //       height: 50,
              //       child: DecoratedBox(
              //           decoration: BoxDecoration(color: Colors.white))),
              //   Padding(
              //     padding: const EdgeInsets.only(bottom: 8.0),
              //     child: IconButton(
              //       iconSize: 30,
              //       constraints:
              //           const BoxConstraints(maxHeight: 30, maxWidth: 30),
              //       padding: EdgeInsets.zero,
              //       icon: Image.asset('assets/update_ic_close.png',
              //           package: 'flutter_update_dialog'),
              //       onPressed: widget.onClose,
              //     ),
              //   )
              // ] else
              //   const SizedBox()
            ],
          ),
        ));
  }

  double getFitWidth(BuildContext context) {
    return min(getScreenHeight(context), getScreenWidth(context));
  }

  double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
}
