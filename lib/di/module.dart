import 'package:injectable/injectable.dart';
import 'package:onlynote/presentation/routes/routes.dart';

@module
abstract class RegisterCoreDependencies {
  final AppRouter appRouter = AppRouter();
}
