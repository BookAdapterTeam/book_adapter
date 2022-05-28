import 'package:appwrite_admin/env/env.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:oxidized/oxidized.dart';

Client client = Client()
    .setEndpoint(
        'https://api.bookadapter.com/v1') // Make sure your endpoint is accessible
    .setProject('bookAdapter') // Your project ID
    .setKey(Env.key);

Users users = Users(client);
Storage storage = Storage(client);

Future<Result<User, Exception>> signUp(
  String email,
  String password,
  String userId,
) {
  return Result.asyncOf(
    () => users.create(userId: userId, email: email, password: password),
  );
}

Future<Result<Bucket, Exception>> createBucket({
  required String bucketId,
  required String name,
  required String permission,
  int? maximumFileSize,
  bool? encryption,
  bool? antivirus,
}) {
  return Result.asyncOf(
    () => storage.createBucket(
      bucketId: bucketId,
      name: name,
      permission: permission,
      maximumFileSize: maximumFileSize,
      encryption: encryption,
      antivirus: antivirus,
    ),
  );
}

Future<Result<File, Exception>> uploadFile({
  required String path,
  required String bucketId,
  required String fileId,
  void Function(UploadProgress)? onProgress,
}) {
  final InputFile file = InputFile(path: path);
  return Result.asyncOf(
    () => storage.createFile(
      bucketId: bucketId,
      fileId: fileId,
      file: file,
      onProgress: onProgress,
    ),
  );
}

Future<Result<BucketList, Exception>> listBuckets() {
  return Result.asyncOf(() => storage.listBuckets());
}

Future<Result<User, Exception>> setUserName(String userId, String name) async {
  return Result.asyncOf(() => users.updateName(userId: userId, name: name));
}

Future<Result<UserList, Exception>> listUsers() {
  return Result.asyncOf(() => users.list());
}
