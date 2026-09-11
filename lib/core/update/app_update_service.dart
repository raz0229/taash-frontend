import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Visible state of a Google Play flexible in-app update.
enum AppUpdateStatus {
  /// No update is available, or in-app updates are not supported here.
  none,

  /// An update is available and the user has not been asked yet.
  available,

  /// The update is downloading in the background behind the app.
  downloading,

  /// The download finished; the install still needs user consent to restart.
  readyToInstall,

  /// The user dismissed the available-update prompt.
  dismissed,
}

/// Coordinates Google Play flexible app updates.
///
/// Flexible updates download the new build in the background while the user
/// keeps playing; installing is deferred until the user explicitly restarts.
/// A plain [AppUpdateStatus.none] is emitted for any environment that cannot
/// run the Play In-App Updates API (side-loads, non-Play builds, offline,
/// test hosts) so the app never blocks on an update check.
class InAppUpdateService extends ChangeNotifier {
  InAppUpdateService({this.minStalenessDays = 0});

  /// Only offer the update once Google Play has known about it for this many
  /// days. Null staleness (unknown) always qualifies.
  final int minStalenessDays;

  AppUpdateStatus _status = AppUpdateStatus.none;
  AppUpdateStatus get status => _status;

  bool _checking = false;

  /// True while a Play update check is in flight.
  bool get checking => _checking;

  int? _availableVersionCode;

  /// Version code of the pending update, if any.
  int? get availableVersionCode => _availableVersionCode;

  StreamSubscription<InstallStatus>? _installSub;

  /// Asks Google Play whether an update is available and, when it qualifies
  /// for a flexible download, surfaces it as [AppUpdateStatus.available].
  Future<void> checkForUpdate() async {
    if (_checking) return;
    if (_status == AppUpdateStatus.downloading ||
        _status == AppUpdateStatus.readyToInstall) {
      return;
    }
    _checking = true;
    notifyListeners();
    try {
      if (_status != AppUpdateStatus.dismissed) {
        _refreshStatus(await InAppUpdate.checkForUpdate());
      }
    } on Exception {
      _status = AppUpdateStatus.none;
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  void _refreshStatus(AppUpdateInfo info) {
    _availableVersionCode = info.availableVersionCode;
    final staleEnough =
        info.clientVersionStalenessDays == null ||
        info.clientVersionStalenessDays! >= minStalenessDays;
    final downloadable =
        info.updateAvailability == UpdateAvailability.updateAvailable &&
        info.flexibleUpdateAllowed &&
        info.installStatus != InstallStatus.downloaded &&
        info.installStatus != InstallStatus.installed;
    _status = downloadable && staleEnough
        ? AppUpdateStatus.available
        : AppUpdateStatus.none;
  }

  /// Begins a background flexible download. The user can keep using the app;
  /// listeners observe the ongoing [status] while it downloads.
  Future<AppUpdateResult> startFlexibleUpdate() async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success) {
        _status = AppUpdateStatus.none;
        notifyListeners();
        return result;
      }
      _status = AppUpdateStatus.downloading;
      _installSub?.cancel();
      _installSub = InAppUpdate.installUpdateListener.listen(_onInstallStatus);
      notifyListeners();
      return result;
    } on Exception {
      _status = AppUpdateStatus.none;
      notifyListeners();
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  void _onInstallStatus(InstallStatus status) {
    switch (status) {
      case InstallStatus.downloaded:
        if (_status == AppUpdateStatus.downloading) {
          _status = AppUpdateStatus.readyToInstall;
          notifyListeners();
        }
      case InstallStatus.failed:
      case InstallStatus.canceled:
        if (_status == AppUpdateStatus.downloading ||
            _status == AppUpdateStatus.readyToInstall) {
          _status = AppUpdateStatus.none;
          notifyListeners();
        }
      default:
        break;
    }
  }

  /// Installs the downloaded update and restarts the app.
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } on Exception {
      _status = AppUpdateStatus.none;
      notifyListeners();
    }
  }

  /// Records that the user declined this prompt. [checkForUpdate] will not
  /// re-offer until the next app launch.
  void dismiss() {
    if (_status == AppUpdateStatus.available) {
      _status = AppUpdateStatus.dismissed;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _installSub?.cancel();
    super.dispose();
  }
}