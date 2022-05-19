import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:book_adapter/src/data/app_exception.dart';
import 'package:book_adapter/src/constants/constants.dart';
import 'package:book_adapter/src/data/failure.dart';
import 'package:book_adapter/src/data/file_hash.dart';
import 'package:book_adapter/src/service/isolate_service.dart';
import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

final storageServiceInitProvider = FutureProvider<void>((ref) async {
  await ref.watch(storageServiceProvider).init();
});

/// Provider to easily get access to the [FirebaseService] functions
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// A utility class to handle all Firebase calls
class StorageService {
  StorageService();

  late final io.Directory appDir;

  late final io.Directory appBookAdaptDirectory;

  final _log = Logger();

  Box<Map<String, dynamic>>? _uploadQueueBox;

  Box<Map<String, dynamic>>? get uploadQueueBox => _uploadQueueBox;

  /// 'isDocumentUploaded'
  static const kIsDocumentUploadedKey = 'isDocumentUploaded';

  /// 'isFileUploaded'
  static const kIsFileUploaded = 'isFileUploaded';

  /// 'fileHashKey'
  static const kFileHashKey = 'fileHashKey';

  /// Initilize the class
  ///
  /// Throws a `MissingPlatformDirectoryException`
  /// if the system is unable to provide the directory.
  Future<void> init() async {
    try {
      appDir = await _getAppDirectory();
      appBookAdaptDirectory = io.Directory('${appDir.path}/BookAdapt');
      await appBookAdaptDirectory.create();
      await Hive.initFlutter('BookAdapterData');
      Hive.registerAdapter(FileHashAdapter());
    } on Exception catch (e, st) {
      _log.e(e.toString(), e, st);
      rethrow;
    }
  }

  Future<void> initQueueBox(String userId) async {
    _uploadQueueBox = await Hive.openBox('$userId-$kUploadQueueBox');
  }

  /// Retrieve the books in the upload queue
  /// and return as a list of [FileHash] objects
  List<FileHash> get uploadQueueFileHashList {
    if (_uploadQueueBox == null) {
      throw AppException('_uploadQueueBox not initialized');
    }

    return _uploadQueueBox!.values.map(FileHash.fromMap).toList();
  }

  /// Get a [FileHash] object from the upload queue box by the filepath
  FileHash? getUploadQueueItem(String filepath) {
    if (_uploadQueueBox == null) {
      throw AppException('_uploadQueueBox not initialized');
    }

    final itemMap = _uploadQueueBox!.get(filepath);
    if (itemMap == null) return null;

    return FileHash.fromMap(itemMap);
  }

  /// Adds a file to the upload queue box with `filepath` as the key
  Future<void> boxAddToUploadQueue(
    String filepath, {
    required FileHash fileHash,
    bool isDocumentUploaded = false,
    bool isFileUploaded = false,
  }) async {
    if (_uploadQueueBox == null) {
      throw AppException('_uploadQueueBox not initialized');
    }

    await _uploadQueueBox!.put(filepath, {
      kFileHashKey: fileHash,
      kIsDocumentUploadedKey: isDocumentUploaded,
      kIsFileUploaded: isFileUploaded,
    });
  }

  Future<void> boxSetDocumentUploadedInUploadQueue(
    String filepath,
  ) async {
    final fileHash = getUploadQueueItem(filepath);
    if (fileHash == null) return;

    await boxAddToUploadQueue(
      filepath,
      fileHash: fileHash,
      isDocumentUploaded: true,
    );
  }

  Future<void> boxSetFileUploadedInUploadQueue(
    String filepath,
  ) async {
    final fileHash = getUploadQueueItem(filepath);
    if (fileHash == null) return;

    await boxAddToUploadQueue(
      filepath,
      fileHash: fileHash,
      isFileUploaded: true,
    );
  }

  /// Removes a file to the upload queue box
  Future<void> boxRemoveFromUploadQueue(String filepath) async {
    if (_uploadQueueBox == null) {
      throw AppException('_uploadQueueBox not initialized');
    }

    return _uploadQueueBox!.delete(filepath);
  }

  String getAppFilePath(String filepath) =>
      '${appBookAdaptDirectory.path}/$filepath';

  String getPathFromFilename({
    required String userId,
    required String filename,
  }) =>
      '${appBookAdaptDirectory.path}/$userId/$filename';

  /// Method to create a directory for the user when they login
  Future<io.Directory> createUserDirectory(String userId) async {
    try {
      return await io.Directory('${appBookAdaptDirectory.path}/$userId')
          .create();
    } on Exception catch (e, st) {
      _log.e(e.toString(), e, st);
      rethrow;
    }
  }

  /// Utility method to get the directory for the app to store documents
  static Future<io.Directory> _getAppDirectory() async {
    io.Directory dir;
    if (io.Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()) ??
          await getApplicationSupportDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    // Any OS
    // getApplicationDocumentsDirectory();

    // Use for cover images
    // getApplicationSupportDirectory();

    // No android support
    // getLibraryDirectory();

    // Android only
    // getExternalStorageDirectory();
    // TODO: Use below to ask user preffered location. Books will be moved.
    // getExternalStorageDirectories(type: StorageDirectory.documents);
    // getExternalCacheDirectories();

    return dir;
  }

  /// Selects a directory and returns its absolute path.
  ///
  /// On Android, this requires to be running on SDK 21 or above
  /// Returns `null` if folder path couldn't be resolved.
  ///
  /// `dialogTitle` can be set to display a custom title on desktop platforms.
  /// It will be ignored on Web & IO.
  ///
  /// Note: Some Android paths are protected, hence can't be accessed and will return `/` instead.
  Future<Either<Failure, String>> pickDirectory({String? dialogTitle}) async {
    final String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);

    if (selectedDirectory == null) {
      return Left(Failure(
          'User canceled the directory picker or Android SDK not 21 or above'));
    }

    return Right(selectedDirectory);
  }

  /// Check if files exist on device on app start,
  /// then check for a book if it exists before opening it
  ///
  /// Returns a list of the filenames
  List<io.FileSystemEntity> listFiles({
    required String userId,
    bool recursive = false,
    bool followLinks = true,
  }) {
    try {
      final userDirectory =
          io.Directory('${appBookAdaptDirectory.path}/$userId');
      final files = userDirectory.listSync(
        recursive: recursive,
        followLinks: followLinks,
      );
      return files;
    } on Exception catch (e, st) {
      _log.e(e.toString(), e, st);
      throw AppException(e.toString());
    }
  }

  /// Deletes a given File
  ///
  /// Returns a list of the filenames
  Future<io.FileSystemEntity> deleteFile(String filepath) async {
    try {
      final file = io.File(filepath);
      return await file.delete();
    } on Exception catch (e, st) {
      _log.e(e.toString(), e, st);
      rethrow;
    }
  }

  /// Retrieves the file(s) from the underlying platform
  ///
  /// Default `type` set to [FileType.any] with `allowMultiple` set to `false`.
  /// Optionally, `allowedExtensions` may be provided (e.g. `[pdf, svg, jpg]`.).
  ///
  /// If `withData` is set, picked files will have its byte
  /// data immediately available on memory as `Uint8List`
  /// which can be useful if you are picking it for server
  /// upload or similar. However, have in mind that
  /// enabling this on IO (iOS & Android) may result in
  /// out of memory issues if you allow multiple picks or
  /// pick huge files. Use `withReadStream` instead.
  /// Defaults to `true` on web, `false` otherwise.
  ///
  /// If `withReadStream` is set, picked files will have
  /// its byte data available as a `Stream<List<int>>`
  /// which can be useful for uploading and processing
  /// large files. Defaults to `false`.
  ///
  /// If you want to track picking status, for example,
  /// because some files may take some time to be
  /// cached (particularly those picked from cloud
  /// providers), you may want to set [onFileLoading] handler
  /// that will give you the current status of picking.
  ///
  /// If `allowCompression` is set, it will allow media
  /// to apply the default OS compression.
  /// Defaults to `true`.
  ///
  /// `dialogTitle` can be optionally set on desktop
  /// platforms to set the modal window title. It will be ignored on
  /// other platforms.
  ///
  /// The result is wrapped in a `Either` which contains
  /// either a left `Failure` or right `List<PlatformFile>`.
  Future<List<PlatformFile>> pickFile({
    String? dialogTitle,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
  }) async {
    // Clear cache because it is buggy and will confuse
    // files of similar filenames+

    // TODO(@getBoolean): Test if diff files with the same name get confused
    // Commented out because adding files consequetively will
    // cause the previous upload to fail.
    // if (io.Platform.isIOS || io.Platform.isAndroid) {
    //   await FilePicker.platform.clearTemporaryFiles();
    // }

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      allowCompression: allowCompression,
      allowMultiple: allowMultiple,
      withData: withData,
      withReadStream: withReadStream,
    );

    if (result == null) {
      // User canceled the picker
      return [];
    }

    if (allowMultiple) {
      return _handleMultiple(result);
    } else {
      return _handleSingle(result);
    }
  }

  List<PlatformFile> _handleSingle(FilePickerResult result) {
    final PlatformFile file = result.files.first;

    return [file];
  }

  List<PlatformFile> _handleMultiple(FilePickerResult result) {
    final List<PlatformFile> files = result.files;
    return files;
  }

  // /// Opens a save file dialog which lets the user select a file path and a file
  // /// name to save a file.
  // ///
  // /// This function does not actually save a file. It only opens the dialog to
  // /// let the user choose a location and file name. This function only returns
  // /// the **path** to this (non-existing) file.
  // ///
  // /// This method is only available on desktop platforms (Linux, macOS &
  // /// Windows).
  // ///
  // /// [dialogTitle] can be set to display a custom title on desktop platforms.
  // /// [fileName] can be set to a non-empty string to provide a default file
  // /// name.
  // /// The file type filter [type] defaults to [FileType.any]. Optionally,
  // /// [allowedExtensions] might be provided (e.g. `[pdf, svg, jpg]`.). Both
  // /// parameters are just a proposal to the user as the save file dialog does
  // /// not enforce these restrictions.
  // ///
  // /// Returns Either a left `Failure` if aborted or a right `String` which resolves to
  // /// the absolute path of the selected file, if the user selected a file.
  // Future<Either<Failure, String>> saveFileDialog({
  //   String dialogTitle = 'Please select an output file:',
  //   String fileName = 'output-file.pdf',
  // }) async {
  //   final String? outputFile = await FilePicker.platform.saveFile(
  //     dialogTitle: dialogTitle,
  //     fileName: fileName,
  //   );

  //   if (outputFile == null) {
  //     // User canceled the picker
  //     return Left(Failure('User canceled the save file dialog'));
  //   }

  //   return Right(outputFile);
  // }

  /// Converts a [PlatformFile] object to dart io [File], returns either
  /// left `Failure` or right `File`
  Either<Failure, io.File> convertPlatformFileToIOFile(PlatformFile file) {
    final String? path = file.path;
    if (path == null) {
      return Left(Failure("File's path was null"));
    }
    return Right(io.File(path));
  }

  /// Check if a file exists on the device given the filename
  Future<bool> appFileExists(
      {required String userId, required String filename}) async {
    final String path = getPathFromFilename(userId: userId, filename: filename);
    if (await io.File(path).exists()) {
      return true;
    }
    return false;
  }

  /// Check if a file exists on the device given the filename
  bool appFileExistsSync({required String userId, required String filename}) {
    final String path = getPathFromFilename(userId: userId, filename: filename);
    if (io.File(path).existsSync()) {
      return true;
    }
    return false;
  }

  /// Save byte data to a file on the device
  Future<io.File> writeMemoryToFile({
    required Uint8List data,
    required String filepath,
    bool overwrite = false,
  }) async {
    try {
      final String path = getAppFilePath(filepath);
      final fileRef = io.File(path);

      if (overwrite == false && await fileRef.exists()) {
        throw AppException('File already exists');
      }

      return await fileRef.writeAsBytes(List<int>.from(data));
    } on Exception catch (e, st) {
      _log.e(e.toString(), e, st);
      throw AppException(e.toString());
    }
  }

  /// Load a file into memory and return the bytes
  Future<Uint8List> getFileInMemory(String filepath) {
    final file = io.File(filepath);
    return file.readAsBytes();
  }

  /// Takes a list of files and calculates the hash of each.
  Stream<FileHash> hashFileList(List<String> filePathList) {
    final fileHashStream =
        IsolateService.sendListAndReceiveStream<String, FileHash>(
      filePathList,
      receiveAndReturnService: IsolateService.readAndHashFileService,
    );
    return fileHashStream;
  }

  void saveToUploadQueueBox(List<FileHash> fileHashList) {
    for (final fileHash in fileHashList) {
      final String filepath = fileHash.filepath;

      _log.i('${filepath.split('/').last} Queued For Upload');

      unawaited(boxAddToUploadQueue(
        filepath,
        fileHash: fileHash,
      ));
    }
  }
}
