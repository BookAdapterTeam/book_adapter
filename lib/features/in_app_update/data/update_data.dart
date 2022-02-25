import 'dart:convert';

// From https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/update/entity/update_entity.dart

/// Version update information, used to display the version update pop-up window
/// 版本更新信息，用于显示版本更新弹窗
///
class UpdateData {
  //===========Can App Be Updated - 是否可以升级=============//

  /// Is there a new version
  ///
  /// 是否有新版本
  final bool hasUpdate;

  /// Mandatory installation: the app cannot be used without installation
  ///
  /// 是否强制安装：不安装无法使用app
  final bool isForce;

  /// Can this version be ignored
  ///
  /// 是否可忽略该版本
  bool get isIgnorable => !isForce;

  //===========Update information - 升级的信息=============//

  /// Version Number
  ///
  /// 版本号
  final int versionCode;

  /// Version Name
  ///
  /// 版本名称
  final String versionName;

  /// Update Content
  ///
  /// 更新内容
  final String updateContent;

  /// Android Download Link
  ///
  /// Android 下载地址
  final String androidDownloadUrl;

  /// Github Release Url
  final String githubReleaseUrl;

  /// APK Size [KB]
  ///
  /// apk的大小[KB]
  final int apkSize;

  /// The encrypted value of the apk file (here the default is the md5 value)
  ///
  /// apk文件的加密值（这里默认是md5值）
  final String apkMd5;

  UpdateData({
    required this.hasUpdate,
    this.isForce = false,
    required this.versionCode,
    required this.versionName,
    required this.updateContent,
    required this.androidDownloadUrl,
    required this.githubReleaseUrl,
    this.apkSize = 0,
    this.apkMd5 = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'hasUpdate': hasUpdate,
      'isForce': isForce,
      'versionCode': versionCode,
      'versionName': versionName,
      'updateContent': updateContent,
      'downloadUrl': androidDownloadUrl,
      'githubReleaseUrl': githubReleaseUrl,
      'apkSize': apkSize,
      'apkMd5': apkMd5,
    };
  }

  static UpdateData fromMap(Map<String, dynamic> map) {
    return UpdateData(
      hasUpdate: map['hasUpdate'],
      isForce: map['isForce'],
      versionCode: map['versionCode']?.toInt(),
      versionName: map['versionName'],
      updateContent: map['updateContent'],
      androidDownloadUrl: map['downloadUrl'],
      githubReleaseUrl: map['githubReleaseUrl'],
      apkSize: map['apkSize']?.toInt(),
      apkMd5: map['apkMd5'],
    );
  }

  String toJson() => json.encode(toMap());

  static UpdateData fromJson(String source) => fromMap(json.decode(source));

  @override
  String toString() {
    return 'UpdateEntity(hasUpdate: $hasUpdate, isForce: $isForce, '
        'versionCode: $versionCode, '
        'versionName: $versionName, updateContent: $updateContent, '
        'downloadUrl: $androidDownloadUrl, githubReleaseUrl: $githubReleaseUrl, '
        'apkSize: $apkSize, apkMd5: $apkMd5)';
  }
}
