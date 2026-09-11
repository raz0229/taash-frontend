import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart' as iau;
import 'package:taash/core/update/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('checkForUpdate degrades to no update off the Play Store', () async {
    final service = InAppUpdateService();
    await service.checkForUpdate();
    expect(service.status, AppUpdateStatus.none);
    expect(service.checking, isFalse);
    service.dispose();
  });

  test('startFlexibleUpdate fails quietly off the Play Store', () async {
    final service = InAppUpdateService();
    await service.checkForUpdate();
    final result = await service.startFlexibleUpdate();
    expect(result, iau.AppUpdateResult.inAppUpdateFailed);
    expect(service.status, AppUpdateStatus.none);
    service.dispose();
  });

  test('startFlexibleUpdate is a no-op once dismissed', () async {
    final service = InAppUpdateService();
    service.dismiss();
    await service.checkForUpdate();
    expect(service.status, AppUpdateStatus.none);
    service.dispose();
  });
}