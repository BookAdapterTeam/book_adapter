import 'data/update_data.dart';
import 'data/update_info.dart';
import 'util/common.dart';

// From: https://github.com/xuexiangjys/flutter_app_update_example/blob/master/lib/update/entity/update_info.dart

/// The default method of version update
///
/// 版本更新默认的方法
class UpdateParser {
  /// Parser
  ///
  /// 解析器
  static Future<UpdateData?> parseJson(String json) async {
    final UpdateInfo updateInfo = UpdateInfo.fromJson(json);
    if (updateInfo.code != 0) {
      return null;
    }

    // Perform a second check
    // 进行二次校验
    bool hasUpdate = updateInfo.updateStatus != noNewVersion;
    if (hasUpdate) {
      final String versionCode = await CommonUtils.getVersionCode();
      // The latest version returned by the server is less than or
      // equal to the current version, no need to update.
      // 服务器返回的最新版本小于等于现在的版本，不需要更新
      if (updateInfo.versionCode <= int.parse(versionCode)) {
        hasUpdate = false;
      }
    }

    return UpdateData(
      hasUpdate: hasUpdate,
      isForce: updateInfo.updateStatus == haveNewVersionForcedUpload,
      versionCode: updateInfo.versionCode,
      versionName: updateInfo.versionName,
      updateContent: updateInfo.modifyContent,
      androidDownloadUrl: updateInfo.androidDownloadUrl,
      githubReleaseUrl: updateInfo.githubReleaseUrl,
      apkSize: updateInfo.apkSize,
      apkMd5: updateInfo.apkMd5,
    );
  }
}
