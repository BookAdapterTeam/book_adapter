import 'package:appwrite_test/appwrite_test.dart' as lib;
import 'package:dart_appwrite/models.dart';
import 'package:dcli/dcli.dart';

const String kExitString = 'Exit';
const String kCreateAccountString = 'Create Account';
const String kListUsersString = 'List Users';
const String kUpdateUserNameString = 'Update User Name';
const String kUploadFileString = 'Upload File';
const String kListBucketsString = 'List Buckets';
const String kCreateBucketString = 'Create Bucket';

Future<void> main(List<String> arguments) async {
  String choice = 'Exit';
  do {
    print(orange('\nAppwrite Admin Console'));
    choice = menu(
      prompt: 'Select an option: ',
      options: [
        kExitString,
        kCreateAccountString,
        kListUsersString,
        kUpdateUserNameString,
        kUploadFileString,
        kListBucketsString,
        kCreateBucketString,
      ],
    );

    switch (choice) {
      case kExitString:
        break;
      case kCreateAccountString:
        print(green('\nCreate an Account\n'));
        final email = ask('Email: ', validator: Ask.email);
        final password = ask('Password: ', hidden: true);
        final username = ask('User Name: ', required: false);
        final userId = ask('User ID: ', defaultValue: 'unique()');
        final result = await lib.signUp(email, password, userId);
        final message = result.whenAsync(
          ok: (user) async {
            String message = green('User created: ${user.email}');
            final res = await lib.setUserName(user.$id, username);
            if (res.isErr()) {
              message += red('\nCould not set name of user');
            }

            return message;
          },
          err: (e) async => red('Exception: $e'),
        );

        print(message);
        break;
      case kListUsersString:
        print(green('\nUsers\n'));
        final result = await lib.listUsers();
        final message = result.when(
          ok: (UserList users) => users.users
              .map((u) =>
                  'Email: ${u.email}\n  Name: ${u.name}\n  ID: ${u.$id}\n')
              .toList()
              .join('\n'),
          err: (Exception e) => red('Exception: $e'),
        );
        print(message);
        break;
      case kUpdateUserNameString:
        print(green('\nUpdate User Name\n'));
        final userId = ask('User ID: ', required: true);
        final name = ask('New Name: ', required: true);
        final result = await lib.setUserName(userId, name);
        final message = result.when(
          ok: (User user) => green('User name updated: ${user.name}'),
          err: (Exception e) => red('Exception: $e'),
        );
        print(message);
        break;
      case kUploadFileString:
        print(green('\nUpload a File\n'));
        final path = ask('Full File Path: ');
        final bucketId = ask('Bucket Id: ');
        final fileId = ask('File Id: ', defaultValue: 'unique()');
        final result = await lib.uploadFile(
          fileId: fileId,
          path: path,
          bucketId: bucketId,
          onProgress: (progress) {
            print(yellow('Uploading: ${progress.progress}%'));
          },
        );
        final message = result.when(
          ok: (file) => green('File uploaded: ${file.name}'),
          err: (e) => red('Exception: $e'),
        );
        print(message);
        break;
      case kListBucketsString:
        print(green('\nBuckets\n'));
        final result = await lib.listBuckets();
        final message = result.when(
          ok: (BucketList buckets) => buckets.buckets
              .map((e) => 'Name: ${e.name}\n  ID: ${e.$id}\n')
              .toList()
              .join('\n'),
          err: (Exception e) => red('Exception: $e'),
        );
        print(message);

        break;
      case kCreateBucketString:
        print(green('\nCreate a Bucket\n'));
        final name = ask('Bucket Name: ');
        final bucketId = ask(
          'Bucket Id: ',
          defaultValue: 'unique()',
        );
        final String maximumFileSize = ask(
          'Bucket Maximum File Size (Bytes)',
          validator: Ask.integer,
          defaultValue: '30000000',
        );
        final encryption = confirm(
          'Enable Bucket Encryption: ',
          defaultValue: true,
        );
        final antivirus = confirm(
          'Enable Bucket Antivirus: ',
          defaultValue: true,
        );
        final result = await lib.createBucket(
          bucketId: bucketId,
          name: name,
          permission: 'file',
          maximumFileSize: int.tryParse(maximumFileSize),
          encryption: encryption,
          antivirus: antivirus,
        );

        final message = result.when(
          ok: (bucket) => green('Bucket created: ${bucket.name}'),
          err: (e) => red('Exception: $e'),
        );
        print(message);
        break;
      default:
        print(red('$choice Choice Not implemented yet'));
    }
  } while (choice != kExitString);

  print(green('Exited!'));
}
