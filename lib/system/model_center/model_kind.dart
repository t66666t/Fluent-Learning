/// Model kinds managed by Model Center.
enum ModelKind {
  transcription,
  translation,
  qa,
}

extension ModelKindLabel on ModelKind {
  String get displayName {
    switch (this) {
      case ModelKind.transcription:
        return '转录';
      case ModelKind.translation:
        return '翻译';
      case ModelKind.qa:
        return '问答';
    }
  }
}
