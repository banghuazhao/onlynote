import 'package:get_it/get_it.dart';
import 'package:onlynote/generated/l10n.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => S());
}
