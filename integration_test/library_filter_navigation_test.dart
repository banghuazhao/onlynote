import 'package:integration_test/integration_test.dart';

import '../test/presentation/daily_note_calendar_navigation_test.dart'
    as regression;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  regression.main();
}
