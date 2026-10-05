import 'package:onlynote/services/custom_template_images.dart';

class MemoryTemplateImages implements CustomTemplateImages {
  int _next = 0;
  final deleted = <String>[];
  @override
  Future<List<String>> copyToTemplate(List<String> sources) async => [
        for (final _ in sources) 'template_images/copy_${_next++}.jpg',
      ];
  @override
  Future<List<String>> copyToNote(List<String> sources) async => [
        for (final _ in sources) 'note_images/copy_${_next++}.jpg',
      ];
  @override
  Future<void> deleteTemplates(List<String> paths) async =>
      deleted.addAll(paths);
  @override
  Future<void> pruneTemplates(Set<String> keep) async {}
}
