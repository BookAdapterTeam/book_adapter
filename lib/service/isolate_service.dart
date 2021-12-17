import 'dart:io' as io;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:crypto/crypto.dart';
// ignore: implementation_imports
import 'package:epubx/src/ref_entities/epub_byte_content_file_ref.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';

import 'storage_service.dart';

class IsolateService {
  /// Spawns an isolate and asynchronously sends List<T> for it to
  /// read and decode. Waits for the response containing the file hash
  /// before sending the next.
  ///
  /// Returns a stream that emits R.
  ///
  /// T and R may be any of the following types:
  ///   - [Null]
  ///   - [bool]
  ///   - [int]
  ///   - [double]
  ///   - [String]
  ///   - [List] or [Map] (whose elements are any of these)
  ///   - [TransferableTypedData]
  ///   - [SendPort]
  ///   - [Capability]
  ///
  /// Additiionally, T and R can contain any object, with the following exceptions:
  ///
  ///   - Objects with native resources (subclasses of e.g.
  ///     `NativeFieldWrapperClass1`). A [Socket] object for example referrs
  ///     internally to objects that have native resources attached and can
  ///     therefore not be sent.
  ///   - [ReceivePort]
  ///   - [DynamicLibrary]
  ///   - [Pointer]
  ///   - [UserTag]
  ///   - `MirrorReference`
  ///
  /// Apart from those exceptions any object can be sent. Objects that are
  /// identified as immutable (e.g. strings) will be shared whereas all other
  /// objects will be copied.
  static Future<R> sendSingleAndReceive<T, R>(
    T item, {
    required Future<void> Function(SendPort) receiveAndReturnService,
  }) async {
    final p = ReceivePort();
    await Isolate.spawn(receiveAndReturnService, p.sendPort);

    // Convert the ReceivePort into a StreamQueue to receive messages from the
    // spawned isolate using a pull-based interface. Events are stored in this
    // queue until they are accessed by `events.next`.
    final events = StreamQueue<dynamic>(p);

    // The first message from the spawned isolate is a SendPort. This port is
    // used to communicate with the spawned isolate.
    final SendPort sendPort = await events.next;

    // Send the next filename to be read and parsed
    sendPort.send(item);

    // Receive the loaded bytes and upload
    final R message = await events.next;

    // Add the result to the stream returned by this async* function.
    // Send a signal to the spawned isolate indicating that it should exit.
    sendPort.send(null);

    // Dispose the StreamQueue.
    await events.cancel();

    return message;
  }

  /// Spawns an isolate and asynchronously sends List<T> for it to
  /// read and decode. Waits for the response containing the file hash
  /// before sending the next.
  ///
  /// Returns a stream that emits R.
  ///
  /// T and R may be any of the following types:
  ///   - [Null]
  ///   - [bool]
  ///   - [int]
  ///   - [double]
  ///   - [String]
  ///   - [List] or [Map] (whose elements are any of these)
  ///   - [TransferableTypedData]
  ///   - [SendPort]
  ///   - [Capability]
  ///
  /// Additiionally, T and R can contain any object, with the following exceptions:
  ///
  ///   - Objects with native resources (subclasses of e.g.
  ///     `NativeFieldWrapperClass1`). A [Socket] object for example referrs
  ///     internally to objects that have native resources attached and can
  ///     therefore not be sent.
  ///   - [ReceivePort]
  ///   - [DynamicLibrary]
  ///   - [Pointer]
  ///   - [UserTag]
  ///   - `MirrorReference`
  ///
  /// Apart from those exceptions any object can be sent. Objects that are
  /// identified as immutable (e.g. strings) will be shared whereas all other
  /// objects will be copied.
  static Stream<R> sendListAndReceiveStream<T, R>(
    List<T> list, {
    required Future<void> Function(SendPort) receiveAndReturnService,
  }) async* {
    final p = ReceivePort();
    await Isolate.spawn(receiveAndReturnService, p.sendPort);

    // Convert the ReceivePort into a StreamQueue to receive messages from the
    // spawned isolate using a pull-based interface. Events are stored in this
    // queue until they are accessed by `events.next`.
    final events = StreamQueue<dynamic>(p);

    // The first message from the spawned isolate is a SendPort. This port is
    // used to communicate with the spawned isolate.
    final SendPort sendPort = await events.next;

    for (final item in list) {
      // Send the next filename to be read and parsed
      sendPort.send(item);

      // Receive the loaded bytes and return
      final R message = await events.next;

      // Add the result to the stream returned by this async* function.
      yield message;
    }

    // Send a signal to the spawned isolate indicating that it should exit.
    sendPort.send(null);

    p.close();

    // Dispose the StreamQueue.
    await events.cancel();
  }

  /// Spawns an isolate and asynchronously sends List<T> for it to
  /// read and decode. Waits for the response containing the file hash
  /// before sending the next.
  ///
  /// Returns a future that returns List<R>.
  ///
  /// T and R may be any of the following types:
  ///   - [Null]
  ///   - [bool]
  ///   - [int]
  ///   - [double]
  ///   - [String]
  ///   - [List] or [Map] (whose elements are any of these)
  ///   - [TransferableTypedData]
  ///   - [SendPort]
  ///   - [Capability]
  ///
  /// Additiionally, T and R can contain any object, with the following exceptions:
  ///
  ///   - Objects with native resources (subclasses of e.g.
  ///     `NativeFieldWrapperClass1`). A [Socket] object for example referrs
  ///     internally to objects that have native resources attached and can
  ///     therefore not be sent.
  ///   - [ReceivePort]
  ///   - [DynamicLibrary]
  ///   - [Pointer]
  ///   - [UserTag]
  ///   - `MirrorReference`
  ///
  /// Apart from those exceptions any object can be sent. Objects that are
  /// identified as immutable (e.g. strings) will be shared whereas all other
  /// objects will be copied.
  static Future<List<R>> sendListAndReceiveList<T, R>(
    List<T> list, {
    required Future<void> Function(SendPort) receiveAndReturnService,
  }) async {
    final p = ReceivePort();
    await Isolate.spawn(receiveAndReturnService, p.sendPort);

    // Convert the ReceivePort into a StreamQueue to receive messages from the
    // spawned isolate using a pull-based interface. Events are stored in this
    // queue until they are accessed by `events.next`.
    final events = StreamQueue<dynamic>(p);

    // The first message from the spawned isolate is a SendPort. This port is
    // used to communicate with the spawned isolate.
    final SendPort sendPort = await events.next;

    final messages = <R>[];
    for (final item in list) {
      // Send the next filename to be read and parsed
      sendPort.send(item);

      // Receive the loaded bytes and return
      final R message = await events.next;

      // Add the result to the stream returned by this async* function.
      messages.add(message);
    }

    // Send a signal to the spawned isolate indicating that it should exit.
    sendPort.send(null);

    p.close();

    // Dispose the StreamQueue.
    await events.cancel();

    return messages;
  }

  /// The entrypoint that runs on the spawned isolate. Receives messages from
  /// the main isolate, reads the contents of the file, and returns it
  static Future<void> readAndHashFileService(SendPort p) async {
    final log = Logger();
    log.i('Spawned isolate started.');

    // Send a SendPort to the main isolate so that it can send JSON strings to
    // this isolate.
    final commandPort = ReceivePort();
    p.send(commandPort.sendPort);

    // Wait for messages from the main isolate.
    await for (final message in commandPort) {
      if (message is String) {
        // Read and decode the file.
        final bytes = await io.File(message).readAsBytes();
        final bytesList = List<int>.from(bytes);

        // 1. Get MD5 and SHA1 of File Bytes
        final md5Hash = md5.convert(bytesList).toString();
        final sha1Hash = sha1.convert(bytesList).toString();

        // Send the result to the main isolate.
        p.send({
          StorageService.kFilepathKey: message,
          StorageService.kMD5Key: md5Hash,
          StorageService.kSHA1Key: sha1Hash,
        });
      } else if (message == null) {
        // Exit if the main isolate sends a null message, indicating there are no
        // more files to read and parse.
        break;
      }
    }

    log.i('Spawned isolate finished.');
    Isolate.exit();
  }

  /// The entrypoint that runs on the spawned isolate. Receives images from
  /// the main isolate, decodes the images, and returns it
  static Future<void> readAndDecodeImageService(SendPort p) async {
    final log = Logger();
    log.i('Spawned isolate started.');

    // Send a SendPort to the main isolate so that it can send JSON strings to
    // this isolate.
    final commandPort = ReceivePort();
    p.send(commandPort.sendPort);

    // Wait for messages from the main isolate.
    await for (final message in commandPort) {
      if (message is EpubByteContentFileRef) {
        // Read and decode the file.
        final imageContent = await message.readContent();
        final img.Image? cover = img.decodeImage(imageContent);

        // Send the result to the main isolate.
        p.send(cover);
      } else if (message == null) {
        // Exit if the main isolate sends a null message, indicating there are no
        // more files to read and parse.
        break;
      }
    }

    log.i('Spawned isolate finished.');
    Isolate.exit();
  }

  /// The entrypoint that runs on the spawned isolate. Receives an image from
  /// the main isolate, encodes the images, and returns the bytes
  static Future<void> readAndEncodeImageService(SendPort p) async {
    final log = Logger();
    log.i('Spawned isolate started.');

    // Send a SendPort to the main isolate so that it can send JSON strings to
    // this isolate.
    final commandPort = ReceivePort();
    p.send(commandPort.sendPort);

    // Wait for messages from the main isolate.
    await for (final message in commandPort) {
      if (message is img.Image) {
        // Read and decode the file.
        final dataList = img.encodeJpg(message);
        final bytes = Uint8List.fromList(dataList);

        // Send the result to the main isolate.
        p.send(bytes);
      } else if (message == null) {
        // Exit if the main isolate sends a null message, indicating there are no
        // more files to read and parse.
        break;
      }
    }

    log.i('Spawned isolate finished.');
    Isolate.exit();
  }
}
