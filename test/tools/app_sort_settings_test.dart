import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_sort_settings.dart';

import '../support/memory_preferences.dart';

void main() {
  test('a stored order round-trips and unknown values fall back to manual',
      () async {
    final store = MemoryPreferences();
    expect(
        await AppSortSettings(preferences: store)
            .setOrder(NoteSortOrder.titleDesc),
        isTrue);
    expect(store.values[AppSortSettings.storageKey], 'titleDesc');

    final reopened = AppSortSettings(preferences: store);
    await reopened.load();
    expect(reopened.order, NoteSortOrder.titleDesc);

    store.values[AppSortSettings.storageKey] = 'byLengthOfTitle';
    await reopened.load();
    expect(reopened.order, NoteSortOrder.manual);

    store.values.remove(AppSortSettings.storageKey);
    await reopened.load();
    expect(reopened.order, NoteSortOrder.manual);
  });

  // The preferences plugin throws until its platform instance is registered,
  // so holding, reading or writing this preference must never be what brings
  // a screen down.
  test('an unavailable preference store never throws', () async {
    final settings = AppSortSettings();
    expect(settings.order, NoteSortOrder.manual);
    await expectLater(settings.load(), completes);
    expect(settings.order, NoteSortOrder.manual);
    await expectLater(settings.setOrder(NoteSortOrder.titleAsc), completes);
    // The choice still applies in memory; only its persistence is lost.
    expect(settings.order, NoteSortOrder.titleAsc);
  });
}
