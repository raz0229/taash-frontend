import 'package:taash/l10n/copy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// English copy catalog and Flutter localization boundary. Add Urdu/Roman Urdu
/// delegates when reviewed translations exist; gameplay IDs never translate.
class S {
  const S();
  static const delegate = _StringsDelegate();
  static S of(BuildContext context) =>
      Localizations.of<S>(context, S) ?? const S();
  static const appName = Copy.taashonline;
  static const tagline = Copy.goodCardsBetterCompany;
  static const welcome = Copy.yourNextCardNightStartsHere;
  static const intro = Copy.fourFamiliarGamesARoomForEveryone;
  static const signIn = Copy.letSPlay;
  static const register = Copy.createAccount;
  static const email = Copy.emailAddress;
  static const password = Copy.password;
  static const displayName = Copy.yourNameAtTheRoom;
  static const forgot = Copy.forgotPassword;
  static const reset = Copy.sendResetLink;
  static const resetSent = Copy.checkYourInboxIncludingSpamOrJunk;
  static const country = Copy.country;
  static const home = Copy.home;
  static const learn = Copy.learn;
  static const shop = Copy.avatars;
  static const leaders = Copy.leaders;
  static const about = Copy.about;
  static const quickMatch = Copy.findARoom;
  static const createRoom = Copy.createRoom;
  static const joinRoom = Copy.joinByCode;
  static const roomName = Copy.roomName;
  static const privateRoom = Copy.privateRoom;
  static const privateHint = Copy.onlyPlayersWithYourCodeCanJoin;
  static const publicHint = Copy.otherPlayersCanFindYourRoomBots;
  static const coinNote = Copy.virtualCoinsOnlyEntryFeesAreNot;
  static const enterCode = Copy.enterYourRoomCode;
  static const lookup = Copy.findRoom;
  static const settings = Copy.makeYourselfAtHome;
  static const maintenance = 'A short break at the room';
  static const maintenanceMessage =
      Copy.taashonlineIsUnderMaintenanceYourSavedSession;
  static const loading = Copy.settingTheRoom;
  static const tips = [
    Copy.bhabhiStartsWithHukamYakkaHY,
    Copy.inBluffAnEmptyHandCanStill,
    Copy.inDaketiMatchingACollectionSTop,
    Copy.inTCYarakIsTheRankAfter,
    Copy.tapACardThenUseTheAction,
  ];
  static const invalidEmail = Copy.enterAValidEmailAddress;
  static const invalidPassword = Copy.useAtLeast6Characters;
  static const invalidName = Copy.use125LettersNumbersOrSpaces;
  static const noServerTitle = Copy.yourRoomIsNearlyReady;
  static const noServerBody = Copy.thisBuildNeedsItsTaashOnlineServerConnection;
}

class _StringsDelegate extends LocalizationsDelegate<S> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<S> load(Locale locale) => SynchronousFuture(const S());
  @override
  bool shouldReload(_StringsDelegate old) => false;
}
