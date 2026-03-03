/// Stub for non-web platforms
void downloadFile(List<int> bytes, String fileName, String mimeType) {
  throw UnsupportedError('Download is only supported on web');
}
