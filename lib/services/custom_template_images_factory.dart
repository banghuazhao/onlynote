import 'custom_template_images.dart';
import 'custom_template_images_stub.dart'
    if (dart.library.io) 'custom_template_images_io.dart' as device;

CustomTemplateImages createDeviceTemplateImages({String? documentsPath}) =>
    device.createDeviceTemplateImages(documentsPath: documentsPath);
