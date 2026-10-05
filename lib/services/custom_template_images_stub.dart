import 'custom_template_images.dart';

CustomTemplateImages createDeviceTemplateImages({String? documentsPath}) =>
    _UnsupportedImages();

class _UnsupportedImages implements CustomTemplateImages {
  @override
  Future<List<String>> copyToTemplate(List<String> sources) async {
    if (sources.isNotEmpty) throw UnsupportedError('Device photos unavailable');
    return [];
  }

  @override
  Future<List<String>> copyToNote(List<String> sources) =>
      copyToTemplate(sources);
  @override
  Future<void> deleteTemplates(List<String> paths) async {}
  @override
  Future<void> pruneTemplates(Set<String> keep) async {}
}
