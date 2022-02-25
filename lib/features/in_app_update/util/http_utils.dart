import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'toast_utils.dart';

// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/utils/http.dart

/// Network request tools
///
/// 网络请求工具类
class HttpUtils {
  HttpUtils._internal();

  static late Dio sDio;

  static final _log = Logger();

  /// Global initialization
  ///
  /// 全局初始化
  static void init({
    String baseUrl = '',
    int timeout = 5000,
    Map<String, dynamic>? headers,
  }) {
    sDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        sendTimeout: timeout,
        receiveTimeout: timeout,
        headers: headers));
    // Add interceptor - 添加拦截器
    sDio.interceptors.add(InterceptorsWrapper(onRequest: (
      RequestOptions options,
      RequestInterceptorHandler handler,
    ) {
      _log.i('Before handling request');
      handler.next(options);
    }, onResponse: (Response response, handler) {
      _log.i('Before handling response');
      handler.next(response);
    }, onError: (DioError e, handler) {
      _log.i('Before handling error');
      handleError(e);
      handler.next(e);
    }));
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
  static Future get(String url, [Map<String, dynamic>? params]) async {
    Response response;
    if (params != null) {
      response = await sDio.get(url, queryParameters: params);
    } else {
      response = await sDio.get(url);
    }
    return response.data;
  }

  /// Post Request
  ///
  /// post 表单请求
  static Future post(String url, [Map<String, dynamic>? params]) async {
    final Response response = await sDio.post(url, queryParameters: params);
    return response.data;
  }

  /// Post Body Request
  ///
  /// post body请求
  static Future postJson<T>(String url, [Map<String, dynamic>? data]) async {
    final Response response = await sDio.post(url, data: data);
    return response.data;
  }

  /// Download File
  ///
  /// 下载文件
  static Future downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    final Response response = await sDio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      options: Options(sendTimeout: 25000, receiveTimeout: 25000),
    );
    return response;
  }
}
