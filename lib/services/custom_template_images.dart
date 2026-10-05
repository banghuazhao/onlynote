abstract interface class CustomTemplateImages {
  Future<List<String>> copyToTemplate(List<String> sources);
  Future<List<String>> copyToNote(List<String> sources);
  Future<void> deleteTemplates(List<String> paths);
  Future<void> pruneTemplates(Set<String> keep);
}

bool isOwnedTemplateImagePath(String path) =>
    RegExp(r'^template_images/[a-zA-Z0-9_-]+\.[a-zA-Z0-9]{1,10}$')
        .hasMatch(path);
