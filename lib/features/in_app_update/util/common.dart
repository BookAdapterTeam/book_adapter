import 'dart:io';

import 'package:app_installer/app_installer.dart';
import 'package:book_adapter/features/in_app_update/data/update_data.dart';
import 'package:logger/logger.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/utils/common.dart

class CommonUtils {
  CommonUtils._internal();

  static final _log = Logger();

  static String getTargetSize(double kbSize) {
    if (kbSize <= 0) {
      return '';
    } else if (kbSize < 1024) {
      return '${kbSize.toStringAsFixed(1)}KB';
    } else if (kbSize < 1048576) {
      return '${(kbSize / 1024).toStringAsFixed(1)}MB';
    } else {
      return '${(kbSize / 1048576).toStringAsFixed(1)}GB';
    }
  }

  /// Get Download Cache Path
  ///
  /// 获取下载缓存路径
  static Future<String> getDownloadDirPath() async {
    final Directory directory = Platform.isAndroid
        ? await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Obtain the apk installation file according to the update information
  ///
  /// 根据更新信息获取apk安装文件
  static Future<File> getApkFileByUpdateData(
    UpdateData updateData,
  ) async {
    final String appName = getApkNameByDownloadUrl(updateData.downloadUrl);
    final String dirPath = await getDownloadDirPath();
    return File('$dirPath/${updateData.versionName}/$appName');
  }

  /// Obtain the file name from download url
  ///
  /// 根据下载地址获取文件名
  static String getApkNameByDownloadUrl(String downloadUrl) {
    if (downloadUrl.isEmpty) {
      return 'temp_${currentTimeMillis()}.apk';
    } else {
      String appName = downloadUrl.substring(downloadUrl.lastIndexOf('/') + 1);
      if (!appName.endsWith('.apk')) {
        appName = 'temp_${currentTimeMillis()}.apk';
      }
      return appName;
    }
  }

  static int currentTimeMillis() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Get application package information
  ///
  /// 获取应用包信息
  static Future<PackageInfo> getPackageInfo() {
    return PackageInfo.fromPlatform();
  }

  /// Get the application version number
  ///
  /// 获取应用版本号
  static Future<String> getVersionCode() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

  /// Get application package name
  ///
  /// 获取应用包名
  static Future<String> getPackageName() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.packageName;
  }

  /// Installs APK on android, goes to app store on iOS
  ///
  /// 安装apk
  static void installAPP(String uri) async {
    if (Platform.isAndroid) {
      // Install android apk

      // 需要先允许读取存储权限才可以
      // You need to allow read storage permissions first
      final storageStatus = await Permission.storage.request();
      if (storageStatus == PermissionStatus.granted) {
        // ignore: unawaited_futures
        try {
          await AppInstaller.installApk(uri);
          _log.i('App Update Installed');
        } catch (e, st) {
          _log.e(e.toString(), e, st);
        }
      } else {
        _log.i('Permission request fail!');
      }
    } else {
      // Goes to iOS store app url
      // await AppInstaller.goStore('', uri);
      await launch('https://github.com/BookAdapterTeam/book_adapter/releases');
    }
  }
}
