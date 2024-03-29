import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'toast_utils.dart';

// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/utils/http.dart

/// Network request tools
///
/// 网络请求工具类
class HttpUtils {
  HttpUtils._internal();

  static late final Dio sDio;

  static final _log = Logger();
  static late final int downloadTimeout;

  /// Global initialization
  ///
  /// 全局初始化
  static void init({
    String baseUrl = '',
    int updateCheckTimeout = 5000,
    int downloadTimeout = 5000,
    Map<String, dynamic>? headers,
  }) {
    HttpUtils.downloadTimeout = downloadTimeout;
    sDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: updateCheckTimeout,
        sendTimeout: updateCheckTimeout,
        receiveTimeout: updateCheckTimeout,
        headers: headers,
      ),
    );
    // Add interceptor - 添加拦截器
    sDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          options,
          handler,
        ) {
          _log.i('Before handling request');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log.i('Before handling response');
          handler.next(response);
        },
        onError: (e, handler) {
          _log.i('Before handling error');
          handleError(e);
          handler.next(e);
        },
      ),
    );
  }

  /// Error processing
  ///
  /// error统一处理
  static void handleError(DioError e) {
    switch (e.type) {
      case DioErrorType.connectTimeout:
        showError('Connection Timed Out');
        break;
      case DioErrorType.sendTimeout:
        showError('Request Timed Out');
        break;
      case DioErrorType.receiveTimeout:
        showError('Response Timed Out');
        break;
      case DioErrorType.response:
        showError('Incorrect Status');
        break;
      case DioErrorType.cancel:
        showError('Request Canceled');
        break;
      default:
        showError('Unknown Dio Error');
        break;
    }
  }

  static void showError(String error) {
    _log.e(error);
    ToastUtils.error(error);
  }

  /// Get Request
  ///
  /// get请求
  static Future<T?> get<T>(String url, [Map<String, dynamic>? params]) async {
    Response<T> response;
    if (params != null) {
      response = await sDio.get<T>(url, queryParameters: params);
    } else {
      response = await sDio.get<T>(url);
    }
    return response.data;
  }

  /// Download File
  ///
  /// 下载文件
  static Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await sDio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      options: Options(
        sendTimeout: downloadTimeout,
        receiveTimeout: downloadTimeout,
      ),
    );
    return response;
  }
}
