const maxPhotoTextLength = 100000;

enum PhotoTextStatus { text, noText, unsupported, failed }

class PhotoTextResult {
  const PhotoTextResult(this.status, {this.text = ''});
  final PhotoTextStatus status;
  final String text;
}
