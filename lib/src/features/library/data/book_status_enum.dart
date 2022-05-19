enum BookStatus {
  /// The book file is downloaded to this device
  downloaded,

  /// The book file is currrently being downloaded to this device
  downloading,

  /// The book is waiting to download
  downloadWaiting,

  /// The book file is not downloaded to this device
  notDownloaded,

  /// An error occured during download
  ///
  /// The checksum of the file does not match the saved checksum.
  ///
  /// This could be caused by the download being interrupted, or
  /// the file on the server is corrupted.
  errorDownloading,
}