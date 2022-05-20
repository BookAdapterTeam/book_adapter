import 'package:appwrite_test/env/env.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:oxidized/oxidized.dart';

Client client = Client()
    .setEndpoint(
        'https://api.bookadapter.com/v1') // Make sure your endpoint is accessible
    .setProject('6246775298d4e3bab05a') // Your project ID
    .setKey(Env.key);

Users users = Users(client);
Storage storage = Storage(client);

Future<Result<User, Exception>> signUp(
  String email,
  String password,
  String userId,
) async {
  return Result.asyncOf(
    () => users.create(userId: userId, email: email, password: password),
  );
}

Future<Result<Bucket, Exception>> createBucket({
  required String bucketId,
  required String name,
  required String permission,
  List<dynamic>? read,
  List<dynamic>? write,
  bool? enabled,
  int? maximumFileSize,
  List<dynamic>? allowedFileExtensions,
  bool? encryption,
  bool? antivirus,
}) async {
  return Result.asyncOf(
    () => storage.createBucket(
      bucketId: bucketId,
      name: name,
      permission: permission,
      read: read,
      write: write,
      enabled: enabled,
      maximumFileSize: maximumFileSize,
      allowedFileExtensions: allowedFileExtensions,
      encryption: encryption,
      antivirus: antivirus,
    ),
  );
}

Future<Result<File, Exception>> uploadFile({
  required String path,
  required String bucketId,
  required String fileId,
  List<dynamic>? read,
  List<dynamic>? write,
  dynamic Function(UploadProgress)? onProgress,
}) async {
  final InputFile file = InputFile(path: path);
  return Result.asyncOf(
    () => storage.createFile(
      bucketId: bucketId,
      fileId: fileId,
      file: file,
      read: read,
      write: write,
      onProgress: onProgress,
    ),
  );
}

Future<Result<BucketList, Exception>> listBuckets() async {
  return Result.asyncOf(() => storage.listBuckets());
}
