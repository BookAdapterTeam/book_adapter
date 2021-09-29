import 'dart:io';

import 'package:book_adapter/data/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider to easily get access to the [FirebaseService] functions
final storageServiceProvider = Provider<StorageService>((ref) {
  return const StorageService();
});

/// A utility class to handle all Firebase calls
class StorageService {
  const StorageService();

  /// Selects a directory and returns its absolute path.
  ///
  /// On Android, this requires to be running on SDK 21 or above, else won't work.
  /// Returns `null` if folder path couldn't be resolved.
  ///
  /// `dialogTitle` can be set to display a custom title on desktop platforms. It will be ignored on Web & IO.
  ///
  /// Note: Some Android paths are protected, hence can't be accessed and will return `/` instead.
  Future<Either<Failure, String>> pickDirectory({String? dialogTitle}) async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);

    if (selectedDirectory == null) {
      return Left(Failure('User canceled the directory picker or Android SDK not 21 or above'));
    }

    return Right(selectedDirectory);
  }

  /// Retrieves the file(s) from the underlying platform
  ///
  /// Default `type` set to [FileType.any] with `allowMultiple` set to `false`.
  /// Optionally, `allowedExtensions` might be provided (e.g. `[pdf, svg, jpg]`.).
  ///
  /// If `withData` is set, picked files will have its byte data immediately available on memory as `Uint8List`
  /// which can be useful if you are picking it for server upload or similar. However, have in mind that
  /// enabling this on IO (iOS & Android) may result in out of memory issues if you allow multiple picks or
  /// pick huge files. Use `withReadStream` instead. Defaults to `true` on web, `false` otherwise.
  ///
  /// If `withReadStream` is set, picked files will have its byte data available as a `Stream<List<int>>`
  /// which can be useful for uploading and processing large files. Defaults to `false`.
  ///
  /// If you want to track picking status, for example, because some files may take some time to be
  /// cached (particularly those picked from cloud providers), you may want to set [onFileLoading] handler
  /// that will give you the current status of picking.
  ///
  /// If `allowCompression` is set, it will allow media to apply the default OS compression.
  /// Defaults to `true`.
  ///
  /// `dialogTitle` can be optionally set on desktop platforms to set the modal window title. It will be ignored on
  /// other platforms.
  ///
  /// The result is wrapped in a `Either` which contains either a left `Failure` or right `List<PlatformFile>`.
  Future<Either<Failure, List<PlatformFile>>> pickFile({
    String? dialogTitle,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
  }) async {
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
      return Left(Failure('User canceled the file picker'));
    }

    if (allowMultiple) {
      return Right(handleMultiple(result));
    } else {
      return Right(handleSingle(result));
    }
  }

  List<PlatformFile> handleSingle(FilePickerResult result) {
    final PlatformFile file = result.files.first;

    return [file];
  }

  List<PlatformFile> handleMultiple(FilePickerResult result) {
    final List<PlatformFile> files = result.files;
    return files;
  }

  // / Opens a save file dialog which lets the user select a file path and a file
  // / name to save a file.
  // /
  // / This function does not actually save a file. It only opens the dialog to
  // / let the user choose a location and file name. This function only returns
  // / the **path** to this (non-existing) file.
  // /
  // / This method is only available on desktop platforms (Linux, macOS &
  // / Windows).
  // /
  // / [dialogTitle] can be set to display a custom title on desktop platforms.
  // / [fileName] can be set to a non-empty string to provide a default file
  // / name.
  // / The file type filter [type] defaults to [FileType.any]. Optionally,
  // / [allowedExtensions] might be provided (e.g. `[pdf, svg, jpg]`.). Both
  // / parameters are just a proposal to the user as the save file dialog does
  // / not enforce these restrictions.
  // /
  // / Returns Either a left `Failure` if aborted or a right `String` which resolves to
  // / the absolute path of the selected file, if the user selected a file.
  // Future<Either<Failure, String>> saveFileDialog({String dialogTitle = 'Please select an output file:', String fileName = 'output-file.pdf'}) async {
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
  Either<Failure, File> convertPlatformFileToIOFile(PlatformFile file) {
    final String? path = file.path;
    if (path == null) {
      return Left(Failure("File's path was null"));
    }
    return Right(File(path));
  }

}