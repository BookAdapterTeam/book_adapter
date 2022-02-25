import 'dart:convert';
// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/update/entity/update_info.dart

/// 0: No Version Update
///
/// 0:无版本更新
const int noNewVersion = 0;

/// 1: There is a version update, no mandatory upgrade is required
///
/// 1:有版本更新，不需要强制升级
const int haveNewVersion = 1;

/// 2: There is a version update, a mandatory upgrade is required
///
/// 2:有版本更新，需要强制升级
const int haveNewVersionForcedUpload = 2;

/// The format of the result returned by the default network request
///
/// 默认网络请求返回的结果格式
class UpdateInfo {
  /// Request return code
  ///
  /// 请求返回码
  final int code;

  /// Request error message
  ///
  /// 请求错误信息
  final String msg;

  /// Updated status
  ///
  /// 更新的状态
  final int updateStatus;

  /// The latest version number [according to the version number to
  /// determine whether you need to upgrade]
  ///
  /// 最新版本号[根据版本号来判别是否需要升级]
  final int versionCode;

  /// The name of the latest APP version [version name for display]
  ///
  /// 最新APP版本的名称[用于展示的版本名]
  final String versionName;

  /// App Update Time
  ///
  /// APP更新时间
  final String uploadTime;

  /// App Changelog
  ///
  /// APP变更的内容
  final String modifyContent;

  /// Android Download Link
  ///
  /// 下载地址
  final String androidDownloadUrl;

  /// Github Release Link
  final String githubReleaseUrl;

  /// APK MD5 Value
  ///
  /// Apk MD5值
  final String apkMd5;

  /// Apk Size [KB]
  ///
  /// Apk大小【单位：KB】
  final int apkSize;

  UpdateInfo({
    required this.code,
    required this.msg,
    required this.updateStatus,
    required this.versionCode,
    required this.versionName,
    required this.uploadTime,
    required this.modifyContent,
    required this.androidDownloadUrl,
    required this.githubReleaseUrl,
    required this.apkMd5,
    required this.apkSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'Code': code,
      'Msg': msg,
      'UpdateStatus': updateStatus,
      'VersionCode': versionCode,
      'VersionName': versionName,
      'UploadTime': uploadTime,
      'ModifyContent': modifyContent,
      'DownloadUrl': androidDownloadUrl,
      'GithubReleaseUrl': githubReleaseUrl,
      'ApkMd5': apkMd5,
      'ApkSize': apkSize,
    };
  }

  static UpdateInfo fromMap(Map<String, dynamic> map) {
    return UpdateInfo(
      code: map['Code']?.toInt(),
      msg: map['Msg'],
      updateStatus: map['UpdateStatus']?.toInt(),
      versionCode: map['VersionCode']?.toInt(),
      versionName: map['VersionName'],
      uploadTime: map['UploadTime'],
      modifyContent: map['ModifyContent'],
      androidDownloadUrl: map['DownloadUrl'],
      githubReleaseUrl: map['GithubReleaseUrl'],
      apkMd5: map['ApkMd5'],
      apkSize: map['ApkSize']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  static UpdateInfo fromJson(String source) => fromMap(json.decode(source));

  @override
  String toString() {
    return 'UpdateInfo(Code: $code, Msg: $msg, UpdateStatus: $updateStatus, '
        'VersionCode: $versionCode, VersionName: $versionName, '
        'UploadTime: $uploadTime, ModifyContent: $modifyContent, '
        'DownloadUrl: $androidDownloadUrl, GithubReleaseUrl: $githubReleaseUrl, '
        'ApkMd5: $apkMd5, ApkSize: $apkSize)';
  }
}
