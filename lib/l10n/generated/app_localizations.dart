import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @thisBuildNeedsItsTaashOnlineServerConnection.
  ///
  /// In en, this message translates to:
  /// **'This build needs its TaashOnline server connection. You can explore the game guides while it is being configured.'**
  String get thisBuildNeedsItsTaashOnlineServerConnection;

  /// No description provided for @yourRoomIsNearlyReady.
  ///
  /// In en, this message translates to:
  /// **'Your room is nearly ready'**
  String get yourRoomIsNearlyReady;

  /// No description provided for @use125LettersNumbersOrSpaces.
  ///
  /// In en, this message translates to:
  /// **'Use 1–25 letters, numbers or spaces.'**
  String get use125LettersNumbersOrSpaces;

  /// No description provided for @useAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get useAtLeast6Characters;

  /// No description provided for @enterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get enterAValidEmailAddress;

  /// No description provided for @tapACardThenUseTheAction.
  ///
  /// In en, this message translates to:
  /// **'Tap a card, then use the action button. Dragging is optional.'**
  String get tapACardThenUseTheAction;

  /// No description provided for @inTCYarakIsTheRankAfter.
  ///
  /// In en, this message translates to:
  /// **'In TC, Yarak is the rank after the indicator.'**
  String get inTCYarakIsTheRankAfter;

  /// No description provided for @inDaketiMatchingACollectionSTop.
  ///
  /// In en, this message translates to:
  /// **'In Daketi, matching a collection’s top rank can steal it.'**
  String get inDaketiMatchingACollectionSTop;

  /// No description provided for @inBluffAnEmptyHandCanStill.
  ///
  /// In en, this message translates to:
  /// **'In Bluff, an empty hand can still be challenged.'**
  String get inBluffAnEmptyHandCanStill;

  /// No description provided for @bhabhiStartsWithHukamYakkaHY.
  ///
  /// In en, this message translates to:
  /// **'Bhabhi starts with Hukam Yakka — h-y.'**
  String get bhabhiStartsWithHukamYakkaHY;

  /// No description provided for @settingTheRoom.
  ///
  /// In en, this message translates to:
  /// **'Setting the room…'**
  String get settingTheRoom;

  /// No description provided for @taashonlineIsUnderMaintenanceYourSavedSession.
  ///
  /// In en, this message translates to:
  /// **'TaashOnline is under maintenance. Your saved session is safe. Please try again shortly.'**
  String get taashonlineIsUnderMaintenanceYourSavedSession;

  /// No description provided for @makeYourselfAtHome.
  ///
  /// In en, this message translates to:
  /// **'Make yourself at home'**
  String get makeYourselfAtHome;

  /// No description provided for @findRoom.
  ///
  /// In en, this message translates to:
  /// **'Find room'**
  String get findRoom;

  /// No description provided for @enterYourRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your room code'**
  String get enterYourRoomCode;

  /// No description provided for @virtualCoinsOnlyEntryFeesAreNot.
  ///
  /// In en, this message translates to:
  /// **'Virtual coins only. Entry fees are not refunded when you leave.'**
  String get virtualCoinsOnlyEntryFeesAreNot;

  /// No description provided for @otherPlayersCanFindYourRoomBots.
  ///
  /// In en, this message translates to:
  /// **'Other players can find your room. Bots may fill empty seats shortly.'**
  String get otherPlayersCanFindYourRoomBots;

  /// No description provided for @onlyPlayersWithYourCodeCanJoin.
  ///
  /// In en, this message translates to:
  /// **'Only players with your code can join. Invite enough friends to fill every seat.'**
  String get onlyPlayersWithYourCodeCanJoin;

  /// No description provided for @privateRoom.
  ///
  /// In en, this message translates to:
  /// **'Private room'**
  String get privateRoom;

  /// No description provided for @roomName.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomName;

  /// No description provided for @joinByCode.
  ///
  /// In en, this message translates to:
  /// **'Join by code'**
  String get joinByCode;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get createRoom;

  /// No description provided for @findARoom.
  ///
  /// In en, this message translates to:
  /// **'Find a room'**
  String get findARoom;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @leaders.
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get leaders;

  /// No description provided for @avatars.
  ///
  /// In en, this message translates to:
  /// **'Avatars'**
  String get avatars;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @checkYourInboxIncludingSpamOrJunk.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox, including Spam or Junk, for the password reset link.'**
  String get checkYourInboxIncludingSpamOrJunk;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @yourNameAtTheRoom.
  ///
  /// In en, this message translates to:
  /// **'Your name at the room'**
  String get yourNameAtTheRoom;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @letSPlay.
  ///
  /// In en, this message translates to:
  /// **'Let’s play'**
  String get letSPlay;

  /// No description provided for @fourFamiliarGamesARoomForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Four familiar games. A room for everyone.'**
  String get fourFamiliarGamesARoomForEveryone;

  /// No description provided for @yourNextCardNightStartsHere.
  ///
  /// In en, this message translates to:
  /// **'Your next card night\nstarts here.'**
  String get yourNextCardNightStartsHere;

  /// No description provided for @goodCardsBetterCompany.
  ///
  /// In en, this message translates to:
  /// **'Good cards. Better company.'**
  String get goodCardsBetterCompany;

  /// No description provided for @taashonline.
  ///
  /// In en, this message translates to:
  /// **'TaashOnline'**
  String get taashonline;

  /// No description provided for @pleaseSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get pleaseSignInToContinue;

  /// No description provided for @theServerCouldNotMatchYourAccount.
  ///
  /// In en, this message translates to:
  /// **'The server could not match your account. Please contact support.'**
  String get theServerCouldNotMatchYourAccount;

  /// No description provided for @theSessionChangedPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'The session changed. Please try again.'**
  String get theSessionChangedPleaseTryAgain;

  /// No description provided for @weCouldNotCompleteSignInPlease.
  ///
  /// In en, this message translates to:
  /// **'We could not complete sign-in. Please try again.'**
  String get weCouldNotCompleteSignInPlease;

  /// No description provided for @signInIsAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is already in progress.'**
  String get signInIsAlreadyInProgress;

  /// No description provided for @weCouldNotRestoreYourSavedSession.
  ///
  /// In en, this message translates to:
  /// **'We could not restore your saved session. Please sign in again.'**
  String get weCouldNotRestoreYourSavedSession;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar {value0}'**
  String avatar(Object value0);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @taashonline1001.
  ///
  /// In en, this message translates to:
  /// **'TaashOnline · 1.0.0 (1)'**
  String get taashonline1001;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get deletingAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @contactSherazTech.
  ///
  /// In en, this message translates to:
  /// **'Contact SherazTech'**
  String get contactSherazTech;

  /// No description provided for @accountDeletionInformation.
  ///
  /// In en, this message translates to:
  /// **'Account deletion information'**
  String get accountDeletionInformation;

  /// No description provided for @termsCommunityRules.
  ///
  /// In en, this message translates to:
  /// **'Terms & community rules'**
  String get termsCommunityRules;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @keepTheFeedbackSimplifyTheMovement.
  ///
  /// In en, this message translates to:
  /// **'Keep the feedback. Simplify the movement.'**
  String get keepTheFeedbackSimplifyTheMovement;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticFeedback;

  /// No description provided for @yourPreferenceIsSavedForFutureAudio.
  ///
  /// In en, this message translates to:
  /// **'Your preference is saved for future audio.'**
  String get yourPreferenceIsSavedForFutureAudio;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @audioAssetsAreNotAvailableInThis.
  ///
  /// In en, this message translates to:
  /// **'Audio assets are not available in this build.'**
  String get audioAssetsAreNotAvailableInThis;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @taashonlineAccount.
  ///
  /// In en, this message translates to:
  /// **'TaashOnline account'**
  String get taashonlineAccount;

  /// No description provided for @yourCARDNIGHT.
  ///
  /// In en, this message translates to:
  /// **'YOUR CARD NIGHT'**
  String get yourCARDNIGHT;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @weCouldNotConfirmAccountDeletionPlease.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm account deletion. Please try again.'**
  String get weCouldNotConfirmAccountDeletionPlease;

  /// No description provided for @yourTaashOnlineAccountProfileCoinsAvatarOwnership.
  ///
  /// In en, this message translates to:
  /// **'Your TaashOnline account, profile, coins, avatar ownership and game records will be removed. This cannot be undone.'**
  String get yourTaashOnlineAccountProfileCoinsAvatarOwnership;

  /// No description provided for @deleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteYourAccount;

  /// No description provided for @youCanSignBackInWheneverYou.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in whenever you’re ready for another card night.'**
  String get youCanSignBackInWheneverYou;

  /// No description provided for @leaveForNow.
  ///
  /// In en, this message translates to:
  /// **'Leave for now?'**
  String get leaveForNow;

  /// No description provided for @weCouldNotOpenTheLinkPlease.
  ///
  /// In en, this message translates to:
  /// **'We could not open the link. Please try again.'**
  String get weCouldNotOpenTheLinkPlease;

  /// No description provided for @thisLinkHasNotBeenConfiguredFor.
  ///
  /// In en, this message translates to:
  /// **'This link has not been configured for this build.'**
  String get thisLinkHasNotBeenConfiguredFor;

  /// No description provided for @supportEMAIL.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT_EMAIL'**
  String get supportEMAIL;

  /// No description provided for @accountDELETIONURL.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT_DELETION_URL'**
  String get accountDELETIONURL;

  /// No description provided for @termsURL.
  ///
  /// In en, this message translates to:
  /// **'TERMS_URL'**
  String get termsURL;

  /// No description provided for @privacyURL.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY_URL'**
  String get privacyURL;

  /// No description provided for @setsRunsAndALittleYarakMagic.
  ///
  /// In en, this message translates to:
  /// **'Sets, runs, and a little Yarak magic.'**
  String get setsRunsAndALittleYarakMagic;

  /// No description provided for @playItCoolCallTheirBluff.
  ///
  /// In en, this message translates to:
  /// **'Play it cool. Call their bluff.'**
  String get playItCoolCallTheirBluff;

  /// No description provided for @matchRanksCaptureCardsCollectPoints.
  ///
  /// In en, this message translates to:
  /// **'Match ranks. Capture cards. Collect points.'**
  String get matchRanksCaptureCardsCollectPoints;

  /// No description provided for @finishYourHandDodgeTheThullu.
  ///
  /// In en, this message translates to:
  /// **'Finish your hand. Dodge the Thullu.'**
  String get finishYourHandDodgeTheThullu;

  /// No description provided for @findYourWinningCombination.
  ///
  /// In en, this message translates to:
  /// **'Find your winning combination.'**
  String get findYourWinningCombination;

  /// No description provided for @leaveTheCardsKeepTheCompany.
  ///
  /// In en, this message translates to:
  /// **'Leave the cards. Keep the company.'**
  String get leaveTheCardsKeepTheCompany;

  /// No description provided for @yourNextGreatStoryStartsAtThe.
  ///
  /// In en, this message translates to:
  /// **'Your next great story starts at the room.'**
  String get yourNextGreatStoryStartsAtThe;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'{value0}  ·  {value1} coins'**
  String coins(Object value0, Object value1);

  /// No description provided for @nextGame.
  ///
  /// In en, this message translates to:
  /// **'Next game'**
  String get nextGame;

  /// No description provided for @previousGame.
  ///
  /// In en, this message translates to:
  /// **'Previous game'**
  String get previousGame;

  /// No description provided for @tissarChausar.
  ///
  /// In en, this message translates to:
  /// **'Tissar Chausar'**
  String get tissarChausar;

  /// No description provided for @tonightSROOM.
  ///
  /// In en, this message translates to:
  /// **'TONIGHT’S ROOM'**
  String get tonightSROOM;

  /// No description provided for @pullUpAChairPickYourGame.
  ///
  /// In en, this message translates to:
  /// **'Pull up a chair. Pick your game.'**
  String get pullUpAChairPickYourGame;

  /// No description provided for @goodTOSEEYOU.
  ///
  /// In en, this message translates to:
  /// **'GOOD TO SEE YOU, {value0}'**
  String goodTOSEEYOU(Object value0);

  /// No description provided for @openYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Open your profile'**
  String get openYourProfile;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @donkey.
  ///
  /// In en, this message translates to:
  /// **'Donkey'**
  String get donkey;

  /// No description provided for @tomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get tomato;

  /// No description provided for @heart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get heart;

  /// No description provided for @rose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get rose;

  /// No description provided for @applause.
  ///
  /// In en, this message translates to:
  /// **'Applause'**
  String get applause;

  /// No description provided for @grr.
  ///
  /// In en, this message translates to:
  /// **'Grr'**
  String get grr;

  /// No description provided for @ohNo.
  ///
  /// In en, this message translates to:
  /// **'Oh no'**
  String get ohNo;

  /// No description provided for @shukriya.
  ///
  /// In en, this message translates to:
  /// **'Shukriya'**
  String get shukriya;

  /// No description provided for @phew.
  ///
  /// In en, this message translates to:
  /// **'Phew'**
  String get phew;

  /// No description provided for @laugh.
  ///
  /// In en, this message translates to:
  /// **'Laugh'**
  String get laugh;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @messageTheRoom.
  ///
  /// In en, this message translates to:
  /// **'Message the room'**
  String get messageTheRoom;

  /// No description provided for @keepItFriendlyNoAbuseLinksOr.
  ///
  /// In en, this message translates to:
  /// **'Keep it friendly. No abuse, links or personal information.'**
  String get keepItFriendlyNoAbuseLinksOr;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @messagesAreSharedWithEveryoneAtThis.
  ///
  /// In en, this message translates to:
  /// **'Messages are shared with everyone at this room.'**
  String get messagesAreSharedWithEveryoneAtThis;

  /// No description provided for @sayAFriendlyHello.
  ///
  /// In en, this message translates to:
  /// **'Say a friendly hello'**
  String get sayAFriendlyHello;

  /// No description provided for @messagesAndReactionsAreHiddenOnThis.
  ///
  /// In en, this message translates to:
  /// **'Messages and reactions are hidden on this device. You can unmute any time.'**
  String get messagesAndReactionsAreHiddenOnThis;

  /// No description provided for @chatIsUnavailableForThisBuild.
  ///
  /// In en, this message translates to:
  /// **'Chat is unavailable for this build.'**
  String get chatIsUnavailableForThisBuild;

  /// No description provided for @muteRoomChat.
  ///
  /// In en, this message translates to:
  /// **'Mute room chat'**
  String get muteRoomChat;

  /// No description provided for @unmuteRoomChat.
  ///
  /// In en, this message translates to:
  /// **'Unmute room chat'**
  String get unmuteRoomChat;

  /// No description provided for @aroundTheRoom.
  ///
  /// In en, this message translates to:
  /// **'Around the room'**
  String get aroundTheRoom;

  /// No description provided for @yourMessageWasNotConfirmedCheckChat.
  ///
  /// In en, this message translates to:
  /// **'Your message was not confirmed. Check chat before sending again.'**
  String get yourMessageWasNotConfirmedCheckChat;

  /// No description provided for @linksAreNotAllowedInRoomChat.
  ///
  /// In en, this message translates to:
  /// **'Links are not allowed in room chat.'**
  String get linksAreNotAllowedInRoomChat;

  /// No description provided for @keepYourMessageTo150Characters.
  ///
  /// In en, this message translates to:
  /// **'Keep your message to 150 characters.'**
  String get keepYourMessageTo150Characters;

  /// No description provided for @searchNameOrCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Search name or country code'**
  String get searchNameOrCountryCode;

  /// No description provided for @chooseYourCountry.
  ///
  /// In en, this message translates to:
  /// **'Choose your country'**
  String get chooseYourCountry;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @weLlEmailYouALinkTo.
  ///
  /// In en, this message translates to:
  /// **'We’ll email you a link to reset your password.'**
  String get weLlEmailYouALinkTo;

  /// No description provided for @thereSASeatWithYourName.
  ///
  /// In en, this message translates to:
  /// **'There’s a seat\nwith your name on it.'**
  String get thereSASeatWithYourName;

  /// No description provided for @backToTheRoom.
  ///
  /// In en, this message translates to:
  /// **'Back to the room.'**
  String get backToTheRoom;

  /// No description provided for @learnTheGames.
  ///
  /// In en, this message translates to:
  /// **'Learn the games'**
  String get learnTheGames;

  /// No description provided for @weCouldNotConnectPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'We could not connect. Please try again.'**
  String get weCouldNotConnectPleaseTryAgain;

  /// No description provided for @chooseYourCountryToContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose your country to continue.'**
  String get chooseYourCountryToContinue;

  /// No description provided for @duplicateAvatarIDs.
  ///
  /// In en, this message translates to:
  /// **'Duplicate avatar IDs'**
  String get duplicateAvatarIDs;

  /// No description provided for @ustaad.
  ///
  /// In en, this message translates to:
  /// **'Ustaad'**
  String get ustaad;

  /// No description provided for @raahi.
  ///
  /// In en, this message translates to:
  /// **'Raahi'**
  String get raahi;

  /// No description provided for @invalidAvatarCatalog.
  ///
  /// In en, this message translates to:
  /// **'Invalid avatar catalog'**
  String get invalidAvatarCatalog;

  /// No description provided for @moreCoinsNeeded.
  ///
  /// In en, this message translates to:
  /// **'More coins needed'**
  String get moreCoinsNeeded;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockFree.
  ///
  /// In en, this message translates to:
  /// **'Unlock free'**
  String get unlockFree;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @virtualCoins.
  ///
  /// In en, this message translates to:
  /// **'{value0} virtual coins'**
  String virtualCoins(Object value0);

  /// No description provided for @inYourCollection.
  ///
  /// In en, this message translates to:
  /// **'In your collection'**
  String get inYourCollection;

  /// No description provided for @yourCurrentLook.
  ///
  /// In en, this message translates to:
  /// **'Your current look'**
  String get yourCurrentLook;

  /// No description provided for @noAvatarsInThisCollectionYet.
  ///
  /// In en, this message translates to:
  /// **'No avatars in this collection yet.'**
  String get noAvatarsInThisCollectionYet;

  /// No description provided for @checkCollection.
  ///
  /// In en, this message translates to:
  /// **'Check collection'**
  String get checkCollection;

  /// No description provided for @refreshingCollection.
  ///
  /// In en, this message translates to:
  /// **'Refreshing collection'**
  String get refreshingCollection;

  /// No description provided for @virtualCoins2.
  ///
  /// In en, this message translates to:
  /// **'{value0} virtual coins'**
  String virtualCoins2(Object value0);

  /// No description provided for @makeAnEntrance.
  ///
  /// In en, this message translates to:
  /// **'Make an entrance.'**
  String get makeAnEntrance;

  /// No description provided for @yourCollectionIsSavedWithYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your collection is saved with your account.'**
  String get yourCollectionIsSavedWithYourAccount;

  /// No description provided for @signInToChooseYourLook.
  ///
  /// In en, this message translates to:
  /// **'Sign in to choose your look'**
  String get signInToChooseYourLook;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get pleaseTryAgain;

  /// No description provided for @collectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Collection unavailable'**
  String get collectionUnavailable;

  /// No description provided for @loadingAvatars.
  ///
  /// In en, this message translates to:
  /// **'Loading avatars'**
  String get loadingAvatars;

  /// No description provided for @refreshCollectionAndBalance.
  ///
  /// In en, this message translates to:
  /// **'Refresh collection and balance'**
  String get refreshCollectionAndBalance;

  /// No description provided for @avatarCollection.
  ///
  /// In en, this message translates to:
  /// **'Avatar collection'**
  String get avatarCollection;

  /// No description provided for @weCouldNotChangeYourAvatarPlease.
  ///
  /// In en, this message translates to:
  /// **'We could not change your avatar. Please try again.'**
  String get weCouldNotChangeYourAvatarPlease;

  /// No description provided for @yourAvatarActionMayHaveCompletedRefresh.
  ///
  /// In en, this message translates to:
  /// **'Your avatar action may have completed. Refresh your balance and collection before making another change.'**
  String get yourAvatarActionMayHaveCompletedRefresh;

  /// No description provided for @unlockFor.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {value0}'**
  String unlockFor(Object value0);

  /// No description provided for @unlockForFree.
  ///
  /// In en, this message translates to:
  /// **'Unlock for free'**
  String get unlockForFree;

  /// No description provided for @virtualCoinsYourBalanceCoinsThisUnlocks.
  ///
  /// In en, this message translates to:
  /// **'{value0} virtual coins\nYour balance: {value1} coins\n\nThis unlocks the avatar. You can select it afterward.'**
  String virtualCoinsYourBalanceCoinsThisUnlocks(Object value0, Object value1);

  /// No description provided for @unlock2.
  ///
  /// In en, this message translates to:
  /// **'Unlock {value0}?'**
  String unlock2(Object value0);

  /// No description provided for @weCouldNotLoadTheAvatarCollection.
  ///
  /// In en, this message translates to:
  /// **'We could not load the avatar collection. Please try again.'**
  String get weCouldNotLoadTheAvatarCollection;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position {value0}{value1}'**
  String position(Object value0, Object value1);

  /// No description provided for @bronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get bronze;

  /// No description provided for @silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @rankedByTheServerSAllTime.
  ///
  /// In en, this message translates to:
  /// **'Ranked by the server’s all-time points. Only players with positive points appear.'**
  String get rankedByTheServerSAllTime;

  /// No description provided for @noPositiveScoresHaveBeenRecordedFor.
  ///
  /// In en, this message translates to:
  /// **'No positive scores have been recorded for this game yet.'**
  String get noPositiveScoresHaveBeenRecordedFor;

  /// No description provided for @theHonoursAreWaiting.
  ///
  /// In en, this message translates to:
  /// **'The honours are waiting'**
  String get theHonoursAreWaiting;

  /// No description provided for @refreshingLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Refreshing leaderboard'**
  String get refreshingLeaderboard;

  /// No description provided for @leaderboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard unavailable'**
  String get leaderboardUnavailable;

  /// No description provided for @loadingLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Loading leaderboard'**
  String get loadingLeaderboard;

  /// No description provided for @tc.
  ///
  /// In en, this message translates to:
  /// **'TC'**
  String get tc;

  /// No description provided for @tenPlayersOneGamePointsEarnedAt.
  ///
  /// In en, this message translates to:
  /// **'Ten players. One game. Points earned at the room.'**
  String get tenPlayersOneGamePointsEarnedAt;

  /// No description provided for @theRoomHonours.
  ///
  /// In en, this message translates to:
  /// **'The room honours'**
  String get theRoomHonours;

  /// No description provided for @leaveYourMark.
  ///
  /// In en, this message translates to:
  /// **'Leave your mark'**
  String get leaveYourMark;

  /// No description provided for @refreshLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Refresh leaderboard'**
  String get refreshLeaderboard;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @weCouldNotLoadTheLeaderboardPlease.
  ///
  /// In en, this message translates to:
  /// **'We could not load the leaderboard. Please try again.'**
  String get weCouldNotLoadTheLeaderboardPlease;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @taashonline10012.
  ///
  /// In en, this message translates to:
  /// **'TaashOnline 1.0.0 (1)'**
  String get taashonline10012;

  /// No description provided for @virtualCoinsRealCompany.
  ///
  /// In en, this message translates to:
  /// **'Virtual coins. Real company.'**
  String get virtualCoinsRealCompany;

  /// No description provided for @bhabhiDaketiBluffAndTissarChausarFamiliar.
  ///
  /// In en, this message translates to:
  /// **'Bhabhi, Daketi, Bluff and Tissar Chausar. Familiar games, new faces, and the shared joy of a good card night.'**
  String get bhabhiDaketiBluffAndTissarChausarFamiliar;

  /// No description provided for @madeForOneMoreRound.
  ///
  /// In en, this message translates to:
  /// **'Made for\none more round.'**
  String get madeForOneMoreRound;

  /// No description provided for @backToTheLobby.
  ///
  /// In en, this message translates to:
  /// **'Back to the lobby'**
  String get backToTheLobby;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place {value0}'**
  String place(Object value0);

  /// No description provided for @firstPlace.
  ///
  /// In en, this message translates to:
  /// **'First place'**
  String get firstPlace;

  /// No description provided for @theServerHasNotProvidedFinalPlaces.
  ///
  /// In en, this message translates to:
  /// **'The server has not provided final places. Your profile will show settled statistics when available.'**
  String get theServerHasNotProvidedFinalPlaces;

  /// No description provided for @viewFinalPlaces.
  ///
  /// In en, this message translates to:
  /// **'View final places'**
  String get viewFinalPlaces;

  /// No description provided for @theServerChecksYour433.
  ///
  /// In en, this message translates to:
  /// **'The server checks your 4 + 3 + 3 groups. An invalid claim leaves your hand unchanged.'**
  String get theServerChecksYour433;

  /// No description provided for @chooseOneCardToDiscard.
  ///
  /// In en, this message translates to:
  /// **'Choose one card to discard'**
  String get chooseOneCardToDiscard;

  /// No description provided for @drawFromStockOrTakeTheTop.
  ///
  /// In en, this message translates to:
  /// **'Draw from stock or take the top discard'**
  String get drawFromStockOrTakeTheTop;

  /// No description provided for @matchARankToCollectCardsYou.
  ///
  /// In en, this message translates to:
  /// **'Match a rank to collect cards. You may draw up to five.'**
  String get matchARankToCollectCardsYou;

  /// No description provided for @thePileStaysFaceDownOnlyThe.
  ///
  /// In en, this message translates to:
  /// **'The pile stays face down. Only the server knows the truth.'**
  String get thePileStaysFaceDownOnlyThe;

  /// No description provided for @play14CardsPassOrChallenge.
  ///
  /// In en, this message translates to:
  /// **'Play 1–4 cards, pass, or challenge'**
  String get play14CardsPassOrChallenge;

  /// No description provided for @choose24CardsAndDeclareA.
  ///
  /// In en, this message translates to:
  /// **'Choose 2–4 cards and declare a rank'**
  String get choose24CardsAndDeclareA;

  /// No description provided for @chooseOneCardToLead.
  ///
  /// In en, this message translates to:
  /// **'Choose one card to lead'**
  String get chooseOneCardToLead;

  /// No description provided for @openWithYakkaOfHukam.
  ///
  /// In en, this message translates to:
  /// **'Open with Yakka of Hukam'**
  String get openWithYakkaOfHukam;

  /// No description provided for @exploreTheRevealedCardsBeforeViewingThe.
  ///
  /// In en, this message translates to:
  /// **'Explore the revealed cards before viewing the final places.'**
  String get exploreTheRevealedCardsBeforeViewingThe;

  /// No description provided for @theWinningHand.
  ///
  /// In en, this message translates to:
  /// **'The winning hand'**
  String get theWinningHand;

  /// No description provided for @finalPlacesComeFromTheServerYour.
  ///
  /// In en, this message translates to:
  /// **'Final places come from the server. Your profile refreshes with the latest coins and XP.'**
  String get finalPlacesComeFromTheServerYour;

  /// No description provided for @yourLocalTurnTimeEndedLeavingThe.
  ///
  /// In en, this message translates to:
  /// **'Your local turn time ended. Leaving the room…'**
  String get yourLocalTurnTimeEndedLeavingThe;

  /// No description provided for @thisDeviceAllows60SecondsPerTurn.
  ///
  /// In en, this message translates to:
  /// **'This device allows 60 seconds per turn, or 120 for TC. When your local time ends, it requests leave. Reconnecting or resuming restarts this guide; it is not a server deadline.'**
  String get thisDeviceAllows60SecondsPerTurn;

  /// No description provided for @localTurnGuide.
  ///
  /// In en, this message translates to:
  /// **'Local turn guide'**
  String get localTurnGuide;

  /// No description provided for @yourPlaceMayBeLostAndThe.
  ///
  /// In en, this message translates to:
  /// **'Your place may be lost and the entry fee is not refunded. The remaining players can continue.'**
  String get yourPlaceMayBeLostAndThe;

  /// No description provided for @leaveThisRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave this room?'**
  String get leaveThisRoom;

  /// No description provided for @checkingYourMove.
  ///
  /// In en, this message translates to:
  /// **'Checking your move…'**
  String get checkingYourMove;

  /// No description provided for @thatActionCouldNotBeConfirmedCheck.
  ///
  /// In en, this message translates to:
  /// **'That action could not be confirmed. Check the room before trying again.'**
  String get thatActionCouldNotBeConfirmedCheck;

  /// No description provided for @offlineYourLastRoomIsStillHere.
  ///
  /// In en, this message translates to:
  /// **'Offline · your last room is still here'**
  String get offlineYourLastRoomIsStillHere;

  /// No description provided for @thisRoomIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This room is no longer available'**
  String get thisRoomIsNoLongerAvailable;

  /// No description provided for @connectionRestored.
  ///
  /// In en, this message translates to:
  /// **'Connection restored'**
  String get connectionRestored;

  /// No description provided for @backOnlineRestoringYourRoom.
  ///
  /// In en, this message translates to:
  /// **'Back online · restoring your room'**
  String get backOnlineRestoringYourRoom;

  /// No description provided for @reconnectingCheckingYourSeat.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting · checking your seat'**
  String get reconnectingCheckingYourSeat;

  /// No description provided for @gettingYourRoomReady.
  ///
  /// In en, this message translates to:
  /// **'Getting your room ready…'**
  String get gettingYourRoomReady;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @shareTheRoomCodeWithFriendsTo.
  ///
  /// In en, this message translates to:
  /// **'Share the room code with friends to fill your room.'**
  String get shareTheRoomCodeWithFriendsTo;

  /// No description provided for @botsMayFillEmptySeatsShortly.
  ///
  /// In en, this message translates to:
  /// **'Bots may fill empty seats shortly.'**
  String get botsMayFillEmptySeatsShortly;

  /// No description provided for @theGameStartsWhenEverySeatIs.
  ///
  /// In en, this message translates to:
  /// **'The game starts when every seat is filled.'**
  String get theGameStartsWhenEverySeatIs;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get leaveRoom;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @roomCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Room code copied'**
  String get roomCodeCopied;

  /// No description provided for @taashonlineIsTakingAMaintenanceBreak.
  ///
  /// In en, this message translates to:
  /// **'TaashOnline is taking a maintenance break.'**
  String get taashonlineIsTakingAMaintenanceBreak;

  /// No description provided for @connectionLostCheckingYourSeat.
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Checking your seat…'**
  String get connectionLostCheckingYourSeat;

  /// No description provided for @returnToLobby.
  ///
  /// In en, this message translates to:
  /// **'Return to lobby'**
  String get returnToLobby;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry connection'**
  String get retryConnection;

  /// No description provided for @backToTheRoom2.
  ///
  /// In en, this message translates to:
  /// **'Back to the room'**
  String get backToTheRoom2;

  /// No description provided for @selectCard.
  ///
  /// In en, this message translates to:
  /// **'Select card'**
  String get selectCard;

  /// No description provided for @deselectCard.
  ///
  /// In en, this message translates to:
  /// **'Deselect card'**
  String get deselectCard;

  /// No description provided for @moveLater.
  ///
  /// In en, this message translates to:
  /// **'Move {value0} later'**
  String moveLater(Object value0);

  /// No description provided for @moveEarlier.
  ///
  /// In en, this message translates to:
  /// **'Move {value0} earlier'**
  String moveEarlier(Object value0);

  /// No description provided for @useTheArrowsToArrangeYourHand.
  ///
  /// In en, this message translates to:
  /// **'Use the arrows to arrange your hand. Moving cards changes only your view.'**
  String get useTheArrowsToArrangeYourHand;

  /// No description provided for @yourCardsYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Your cards, your order'**
  String get yourCardsYourOrder;

  /// No description provided for @tapToSelectHoldToDragArrange.
  ///
  /// In en, this message translates to:
  /// **'Tap to select · hold to drag · arrange for a full view'**
  String get tapToSelectHoldToDragArrange;

  /// No description provided for @yourHandIsEmptyFollowTheRoom.
  ///
  /// In en, this message translates to:
  /// **'Your hand is empty. Follow the room for your result.'**
  String get yourHandIsEmptyFollowTheRoom;

  /// No description provided for @inspectAndArrangeYourCards.
  ///
  /// In en, this message translates to:
  /// **'Inspect and arrange your cards'**
  String get inspectAndArrangeYourCards;

  /// No description provided for @sortBySuitAndRank.
  ///
  /// In en, this message translates to:
  /// **'Sort by suit and rank'**
  String get sortBySuitAndRank;

  /// No description provided for @sortByRank.
  ///
  /// In en, this message translates to:
  /// **'Sort by rank'**
  String get sortByRank;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @yourHAND.
  ///
  /// In en, this message translates to:
  /// **'YOUR HAND  ·  {value0}'**
  String yourHAND(Object value0);

  /// No description provided for @chooseUpToFourCardsForBluff.
  ///
  /// In en, this message translates to:
  /// **'Choose up to four cards for Bluff.'**
  String get chooseUpToFourCardsForBluff;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @yakka.
  ///
  /// In en, this message translates to:
  /// **'YAKKA'**
  String get yakka;

  /// No description provided for @tapTo.
  ///
  /// In en, this message translates to:
  /// **'Tap to {value0}'**
  String tapTo(Object value0);

  /// No description provided for @faceDownCard.
  ///
  /// In en, this message translates to:
  /// **'Face-down card'**
  String get faceDownCard;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'{value0} cards'**
  String cards(Object value0);

  /// No description provided for @place2.
  ///
  /// In en, this message translates to:
  /// **'Place {value0}'**
  String place2(Object value0);

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @bot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get bot;

  /// No description provided for @cards2.
  ///
  /// In en, this message translates to:
  /// **'{value0}{value1}{value2}, {value3} cards{value4}'**
  String cards2(
    Object value0,
    Object value1,
    Object value2,
    Object value3,
    Object value4,
  );

  /// No description provided for @gola.
  ///
  /// In en, this message translates to:
  /// **'Gola'**
  String get gola;

  /// No description provided for @begi.
  ///
  /// In en, this message translates to:
  /// **'Begi'**
  String get begi;

  /// No description provided for @kinga.
  ///
  /// In en, this message translates to:
  /// **'Kinga'**
  String get kinga;

  /// No description provided for @yakka2.
  ///
  /// In en, this message translates to:
  /// **'Yakka'**
  String get yakka2;

  /// No description provided for @noSuit.
  ///
  /// In en, this message translates to:
  /// **'No suit'**
  String get noSuit;

  /// No description provided for @pawn.
  ///
  /// In en, this message translates to:
  /// **'Pawn'**
  String get pawn;

  /// No description provided for @hukam.
  ///
  /// In en, this message translates to:
  /// **'Hukam'**
  String get hukam;

  /// No description provided for @eit.
  ///
  /// In en, this message translates to:
  /// **'Eit'**
  String get eit;

  /// No description provided for @chirri.
  ///
  /// In en, this message translates to:
  /// **'Chirri'**
  String get chirri;

  /// No description provided for @unrecognizedCard.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized card'**
  String get unrecognizedCard;

  /// No description provided for @roomChat.
  ///
  /// In en, this message translates to:
  /// **'Room chat'**
  String get roomChat;

  /// No description provided for @chatMuted.
  ///
  /// In en, this message translates to:
  /// **'Chat muted'**
  String get chatMuted;

  /// No description provided for @yourTurn2.
  ///
  /// In en, this message translates to:
  /// **'Your turn · {value0}'**
  String yourTurn2(Object value0);

  /// No description provided for @backToLobby.
  ///
  /// In en, this message translates to:
  /// **'Back to lobby'**
  String get backToLobby;

  /// No description provided for @weReWaitingForTheServerTo.
  ///
  /// In en, this message translates to:
  /// **'We’re waiting for the server to confirm your place.'**
  String get weReWaitingForTheServerTo;

  /// No description provided for @yourSeatIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your seat is unavailable'**
  String get yourSeatIsUnavailable;

  /// No description provided for @roomOptions.
  ///
  /// In en, this message translates to:
  /// **'Room options'**
  String get roomOptions;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @yourCardsStayHiddenThisIsThe.
  ///
  /// In en, this message translates to:
  /// **'Your {value0} cards stay hidden. This is the rank you claim.'**
  String yourCardsStayHiddenThisIsThe(Object value0);

  /// No description provided for @whatRankDoYouDeclare.
  ///
  /// In en, this message translates to:
  /// **'What rank do you declare?'**
  String get whatRankDoYouDeclare;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @thisEndsYourTurnYourRemainingCards.
  ///
  /// In en, this message translates to:
  /// **'This ends your turn. Your remaining cards keep their order.'**
  String get thisEndsYourTurnYourRemainingCards;

  /// No description provided for @discard2.
  ///
  /// In en, this message translates to:
  /// **'Discard {value0}?'**
  String discard2(Object value0);

  /// No description provided for @followTheLeadSuitWhenYouHave.
  ///
  /// In en, this message translates to:
  /// **'Follow the lead suit when you have it.'**
  String get followTheLeadSuitWhenYouHave;

  /// No description provided for @anHonestPlayYouTakeThePile.
  ///
  /// In en, this message translates to:
  /// **'An honest play. You take the pile.'**
  String get anHonestPlayYouTakeThePile;

  /// No description provided for @bluffCaughtThePreviousPlayerTakesThe.
  ///
  /// In en, this message translates to:
  /// **'Bluff caught! The previous player takes the pile.'**
  String get bluffCaughtThePreviousPlayerTakesThe;

  /// No description provided for @weCouldNotConfirmLeavingCheckYour.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm leaving. Check your connection, then try again.'**
  String get weCouldNotConfirmLeavingCheckYour;

  /// No description provided for @checkMyHand.
  ///
  /// In en, this message translates to:
  /// **'Check my hand'**
  String get checkMyHand;

  /// No description provided for @claimYour433.
  ///
  /// In en, this message translates to:
  /// **'Claim your 4 + 3 + 3?'**
  String get claimYour433;

  /// No description provided for @claimVictory.
  ///
  /// In en, this message translates to:
  /// **'Claim victory'**
  String get claimVictory;

  /// No description provided for @recycle.
  ///
  /// In en, this message translates to:
  /// **'Recycle'**
  String get recycle;

  /// No description provided for @takeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Take discard'**
  String get takeDiscard;

  /// No description provided for @drawStock.
  ///
  /// In en, this message translates to:
  /// **'Draw stock'**
  String get drawStock;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// No description provided for @playCards.
  ///
  /// In en, this message translates to:
  /// **'Play {value0} cards'**
  String playCards(Object value0);

  /// No description provided for @playCard.
  ///
  /// In en, this message translates to:
  /// **'Play card'**
  String get playCard;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @audioPackUnavailableInThisBuild.
  ///
  /// In en, this message translates to:
  /// **'Audio pack unavailable in this build'**
  String get audioPackUnavailableInThisBuild;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room {value0}'**
  String room(Object value0);

  /// No description provided for @yourRoom.
  ///
  /// In en, this message translates to:
  /// **'Your room'**
  String get yourRoom;

  /// No description provided for @sendCoins.
  ///
  /// In en, this message translates to:
  /// **'Send · {value0} coins'**
  String sendCoins(Object value0);

  /// No description provided for @spendVirtualCoins.
  ///
  /// In en, this message translates to:
  /// **'Spend {value0} virtual coins {value1}.'**
  String spendVirtualCoins(Object value0, Object value1);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send {value0}?'**
  String send(Object value0);

  /// No description provided for @youNeedVirtualCoinsForThisReaction.
  ///
  /// In en, this message translates to:
  /// **'You need {value0} virtual coins for this reaction.'**
  String youNeedVirtualCoinsForThisReaction(Object value0);

  /// No description provided for @coins2.
  ///
  /// In en, this message translates to:
  /// **'{value0} coins'**
  String coins2(Object value0);

  /// No description provided for @balanceCoins.
  ///
  /// In en, this message translates to:
  /// **'Balance: {value0} coins'**
  String balanceCoins(Object value0);

  /// No description provided for @expressYourself.
  ///
  /// In en, this message translates to:
  /// **'Express yourself'**
  String get expressYourself;

  /// No description provided for @theReactionCatalogCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'The reaction catalog could not be loaded.'**
  String get theReactionCatalogCouldNotBeLoaded;

  /// No description provided for @costsVirtualCoinsReviewBeforeSending.
  ///
  /// In en, this message translates to:
  /// **'Costs virtual coins · review before sending'**
  String get costsVirtualCoinsReviewBeforeSending;

  /// No description provided for @sendAReaction.
  ///
  /// In en, this message translates to:
  /// **'Send a reaction'**
  String get sendAReaction;

  /// No description provided for @exploreCollection.
  ///
  /// In en, this message translates to:
  /// **'Explore collection'**
  String get exploreCollection;

  /// No description provided for @botsPlayByTheSameGameRules.
  ///
  /// In en, this message translates to:
  /// **'Bots play by the same game rules.'**
  String get botsPlayByTheSameGameRules;

  /// No description provided for @botPlayer.
  ///
  /// In en, this message translates to:
  /// **'Bot player'**
  String get botPlayer;

  /// No description provided for @playerStatistics.
  ///
  /// In en, this message translates to:
  /// **'Player statistics'**
  String get playerStatistics;

  /// No description provided for @noCardsCollectedYet.
  ///
  /// In en, this message translates to:
  /// **'No cards collected yet.'**
  String get noCardsCollectedYet;

  /// No description provided for @collectedCardsTheLastCardIsOn.
  ///
  /// In en, this message translates to:
  /// **'{value0} collected cards · the last card is on top'**
  String collectedCardsTheLastCardIsOn(Object value0);

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @setsTheYarakRank.
  ///
  /// In en, this message translates to:
  /// **'Sets the Yarak rank'**
  String get setsTheYarakRank;

  /// No description provided for @indicator.
  ///
  /// In en, this message translates to:
  /// **'Indicator'**
  String get indicator;

  /// No description provided for @cards3.
  ///
  /// In en, this message translates to:
  /// **'{value0} cards'**
  String cards3(Object value0);

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @cardsAreYarak.
  ///
  /// In en, this message translates to:
  /// **'{value0} cards are Yarak'**
  String cardsAreYarak(Object value0);

  /// No description provided for @findYour433.
  ///
  /// In en, this message translates to:
  /// **'Find your 4 + 3 + 3'**
  String get findYour433;

  /// No description provided for @tissarCHAUSAR.
  ///
  /// In en, this message translates to:
  /// **'TISSAR CHAUSAR'**
  String get tissarCHAUSAR;

  /// No description provided for @exploreYourCollection.
  ///
  /// In en, this message translates to:
  /// **'Explore your collection'**
  String get exploreYourCollection;

  /// No description provided for @thePlayAreaIsClear.
  ///
  /// In en, this message translates to:
  /// **'The play area is clear'**
  String get thePlayAreaIsClear;

  /// No description provided for @makeTheMatchTakeTheCards.
  ///
  /// In en, this message translates to:
  /// **'Make the match. Take the cards.'**
  String get makeTheMatchTakeTheCards;

  /// No description provided for @daketi.
  ///
  /// In en, this message translates to:
  /// **'DAKETI'**
  String get daketi;

  /// No description provided for @hiddenPileCards.
  ///
  /// In en, this message translates to:
  /// **'Hidden pile, {value0} cards'**
  String hiddenPileCards(Object value0);

  /// No description provided for @keepAStraightFace.
  ///
  /// In en, this message translates to:
  /// **'Keep a straight face'**
  String get keepAStraightFace;

  /// No description provided for @bluff.
  ///
  /// In en, this message translates to:
  /// **'BLUFF'**
  String get bluff;

  /// No description provided for @playACardToBeginTheTrick.
  ///
  /// In en, this message translates to:
  /// **'Play a card to begin the trick'**
  String get playACardToBeginTheTrick;

  /// No description provided for @followSuitWhenYouCan.
  ///
  /// In en, this message translates to:
  /// **'Follow suit when you can'**
  String get followSuitWhenYouCan;

  /// No description provided for @theRoomIsYours.
  ///
  /// In en, this message translates to:
  /// **'The room is yours'**
  String get theRoomIsYours;

  /// No description provided for @thullu.
  ///
  /// In en, this message translates to:
  /// **'Thullu!'**
  String get thullu;

  /// No description provided for @bhabhi.
  ///
  /// In en, this message translates to:
  /// **'BHABHI'**
  String get bhabhi;

  /// No description provided for @waitingForTheLatestRoom.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the latest room…'**
  String get waitingForTheLatestRoom;

  /// No description provided for @rankUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rank unavailable'**
  String get rankUnavailable;

  /// No description provided for @mythic.
  ///
  /// In en, this message translates to:
  /// **'Mythic'**
  String get mythic;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// No description provided for @grandmaster.
  ///
  /// In en, this message translates to:
  /// **'Grandmaster'**
  String get grandmaster;

  /// No description provided for @master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get master;

  /// No description provided for @elite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get elite;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @hotShot.
  ///
  /// In en, this message translates to:
  /// **'Hot Shot'**
  String get hotShot;

  /// No description provided for @veteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get veteran;

  /// No description provided for @upNComer.
  ///
  /// In en, this message translates to:
  /// **'Up N Comer'**
  String get upNComer;

  /// No description provided for @amateur.
  ///
  /// In en, this message translates to:
  /// **'Amateur'**
  String get amateur;

  /// No description provided for @tinkerer.
  ///
  /// In en, this message translates to:
  /// **'Tinkerer'**
  String get tinkerer;

  /// No description provided for @apprentice.
  ///
  /// In en, this message translates to:
  /// **'Apprentice'**
  String get apprentice;

  /// No description provided for @rookie.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get rookie;

  /// No description provided for @newbie.
  ///
  /// In en, this message translates to:
  /// **'Newbie'**
  String get newbie;

  /// No description provided for @unranked.
  ///
  /// In en, this message translates to:
  /// **'Unranked'**
  String get unranked;

  /// No description provided for @mythicAchievedKeepMakingYourMark.
  ///
  /// In en, this message translates to:
  /// **'Mythic achieved. Keep making your mark.'**
  String get mythicAchievedKeepMakingYourMark;

  /// No description provided for @pointsAreSavedRankProgressIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Points are saved. Rank progress is unavailable for this range.'**
  String get pointsAreSavedRankProgressIsUnavailable;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank {value0} · {value1}'**
  String rank(Object value0, Object value1);

  /// No description provided for @firstRankAtPoints.
  ///
  /// In en, this message translates to:
  /// **'First rank at {value0} points'**
  String firstRankAtPoints(Object value0);

  /// No description provided for @noCompletedGamesRecordedYetYourStory.
  ///
  /// In en, this message translates to:
  /// **'No completed games recorded yet. Your story starts with the next room.'**
  String get noCompletedGamesRecordedYetYourStory;

  /// No description provided for @currentWinStreak.
  ///
  /// In en, this message translates to:
  /// **'Current win streak'**
  String get currentWinStreak;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get winRate;

  /// No description provided for @gamesWon.
  ///
  /// In en, this message translates to:
  /// **'Games won'**
  String get gamesWon;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games played'**
  String get gamesPlayed;

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get totalPoints;

  /// No description provided for @atTheRoom.
  ///
  /// In en, this message translates to:
  /// **'At the room'**
  String get atTheRoom;

  /// No description provided for @yourGameYourStory.
  ///
  /// In en, this message translates to:
  /// **'Your game, your story'**
  String get yourGameYourStory;

  /// No description provided for @joinedDateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Joined date unavailable'**
  String get joinedDateUnavailable;

  /// No description provided for @atTheRoomSince.
  ///
  /// In en, this message translates to:
  /// **'At the room since {value0}'**
  String atTheRoomSince(Object value0);

  /// No description provided for @refreshingProfile.
  ///
  /// In en, this message translates to:
  /// **'Refreshing profile'**
  String get refreshingProfile;

  /// No description provided for @thisPlayerCouldNotBeFound.
  ///
  /// In en, this message translates to:
  /// **'This player could not be found.'**
  String get thisPlayerCouldNotBeFound;

  /// No description provided for @profileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable'**
  String get profileUnavailable;

  /// No description provided for @loadingPlayerProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading player profile'**
  String get loadingPlayerProfile;

  /// No description provided for @botsKeepTheGameMovingTheyDo.
  ///
  /// In en, this message translates to:
  /// **'Bots keep the game moving. They do not have a persistent player profile.'**
  String get botsKeepTheGameMovingTheyDo;

  /// No description provided for @meetYourRoomBot.
  ///
  /// In en, this message translates to:
  /// **'Meet your room bot'**
  String get meetYourRoomBot;

  /// No description provided for @refreshProfile.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile'**
  String get refreshProfile;

  /// No description provided for @playerProfile.
  ///
  /// In en, this message translates to:
  /// **'Player profile'**
  String get playerProfile;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @weCouldNotLoadThisProfilePlease.
  ///
  /// In en, this message translates to:
  /// **'We could not load this profile. Please try again.'**
  String get weCouldNotLoadThisProfilePlease;

  /// No description provided for @youNeedMoreCoins.
  ///
  /// In en, this message translates to:
  /// **'You need {value0} more coins.'**
  String youNeedMoreCoins(Object value0);

  /// No description provided for @coins3.
  ///
  /// In en, this message translates to:
  /// **'{value0} coins'**
  String coins3(Object value0);

  /// No description provided for @yourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get yourBalance;

  /// No description provided for @coins4.
  ///
  /// In en, this message translates to:
  /// **'{value0} coins'**
  String coins4(Object value0);

  /// No description provided for @entryFee.
  ///
  /// In en, this message translates to:
  /// **'Entry fee'**
  String get entryFee;

  /// No description provided for @findAnotherRoom.
  ///
  /// In en, this message translates to:
  /// **'Find another room'**
  String get findAnotherRoom;

  /// No description provided for @thisRoomHasStarted.
  ///
  /// In en, this message translates to:
  /// **'This room has started'**
  String get thisRoomHasStarted;

  /// No description provided for @enterCoins.
  ///
  /// In en, this message translates to:
  /// **'Enter · {value0} coins'**
  String enterCoins(Object value0);

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'{value0} · {value1}/{value2} players'**
  String players(Object value0, Object value1, Object value2);

  /// No description provided for @lookingForARoom.
  ///
  /// In en, this message translates to:
  /// **'Looking for a room…'**
  String get lookingForARoom;

  /// No description provided for @enterTheSixCharacterRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-character room code.'**
  String get enterTheSixCharacterRoomCode;

  /// No description provided for @abc234.
  ///
  /// In en, this message translates to:
  /// **'ABC 234'**
  String get abc234;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get roomCode;

  /// No description provided for @createEnter.
  ///
  /// In en, this message translates to:
  /// **'Create & enter'**
  String get createEnter;

  /// No description provided for @morePlayers.
  ///
  /// In en, this message translates to:
  /// **'More players'**
  String get morePlayers;

  /// No description provided for @fewerPlayers.
  ///
  /// In en, this message translates to:
  /// **'Fewer players'**
  String get fewerPlayers;

  /// No description provided for @seatsAtYourRoom.
  ///
  /// In en, this message translates to:
  /// **'Seats at your room'**
  String get seatsAtYourRoom;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @use125EnglishLettersNumbersOr.
  ///
  /// In en, this message translates to:
  /// **'Use 1–25 English letters, numbers or spaces.'**
  String get use125EnglishLettersNumbersOr;

  /// No description provided for @fridayCardNight.
  ///
  /// In en, this message translates to:
  /// **'Friday card night'**
  String get fridayCardNight;

  /// No description provided for @weLlFindAPublicRoomWith.
  ///
  /// In en, this message translates to:
  /// **'We’ll find a public room with room for you.'**
  String get weLlFindAPublicRoomWith;

  /// No description provided for @pasteTheSixCharacterCodeYourFriend.
  ///
  /// In en, this message translates to:
  /// **'Paste the six-character code your friend shared.'**
  String get pasteTheSixCharacterCodeYourFriend;

  /// No description provided for @chooseTheGameWeLlDealThe.
  ///
  /// In en, this message translates to:
  /// **'Choose the game. We’ll deal the cards.'**
  String get chooseTheGameWeLlDealThe;

  /// No description provided for @friendsAreExpectingYou.
  ///
  /// In en, this message translates to:
  /// **'Friends are\nexpecting you.'**
  String get friendsAreExpectingYou;

  /// No description provided for @makeRoomForAGoodNight.
  ///
  /// In en, this message translates to:
  /// **'Make room for\na good night.'**
  String get makeRoomForAGoodNight;

  /// No description provided for @theROOMISYOURS.
  ///
  /// In en, this message translates to:
  /// **'THE ROOM IS YOURS'**
  String get theROOMISYOURS;

  /// No description provided for @findYourCompany.
  ///
  /// In en, this message translates to:
  /// **'Find your company'**
  String get findYourCompany;

  /// No description provided for @weCouldNotCreateTheRoomPlease.
  ///
  /// In en, this message translates to:
  /// **'We could not create the room. Please try again.'**
  String get weCouldNotCreateTheRoomPlease;

  /// No description provided for @theRoomMayHaveBeenCreatedBut.
  ///
  /// In en, this message translates to:
  /// **'The room may have been created, but its code was not received. Check your connection before creating another room.'**
  String get theRoomMayHaveBeenCreatedBut;

  /// No description provided for @entryFeeVirtualCoinsBalanceCoins.
  ///
  /// In en, this message translates to:
  /// **'Entry fee: {value0} virtual coins.\nBalance: {value1} coins.\n\n{value2}'**
  String entryFeeVirtualCoinsBalanceCoins(
    Object value0,
    Object value1,
    Object value2,
  );

  /// No description provided for @createAndEnter.
  ///
  /// In en, this message translates to:
  /// **'Create and enter {value0}?'**
  String createAndEnter(Object value0);

  /// No description provided for @youNeedVirtualCoinsToEnterThis.
  ///
  /// In en, this message translates to:
  /// **'You need {value0} virtual coins to enter this room.'**
  String youNeedVirtualCoinsToEnterThis(Object value0);

  /// No description provided for @weCouldNotReadThisRoomPlease.
  ///
  /// In en, this message translates to:
  /// **'We could not read this room. Please try again.'**
  String get weCouldNotReadThisRoomPlease;

  /// No description provided for @thisIsALearningExerciseItDoes.
  ///
  /// In en, this message translates to:
  /// **'This is a learning exercise. It does not spend coins or change a live game.'**
  String get thisIsALearningExerciseItDoes;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice again'**
  String get practiceAgain;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @tryAgain2.
  ///
  /// In en, this message translates to:
  /// **'Try again. {value0}'**
  String tryAgain2(Object value0);

  /// No description provided for @tapACardToLearnItsName.
  ///
  /// In en, this message translates to:
  /// **'Tap a card to learn its name.'**
  String get tapACardToLearnItsName;

  /// No description provided for @practiceSTEPOF3.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE · STEP {value0} OF 3'**
  String practiceSTEPOF3(Object value0);

  /// No description provided for @fromFirstCardToOneMoreRound.
  ///
  /// In en, this message translates to:
  /// **'From first card\nto one more round.'**
  String get fromFirstCardToOneMoreRound;

  /// No description provided for @learnATYOURPACE.
  ///
  /// In en, this message translates to:
  /// **'LEARN AT YOUR PACE'**
  String get learnATYOURPACE;

  /// No description provided for @pickAnotherCardToDiscardTheServer.
  ///
  /// In en, this message translates to:
  /// **'Pick another card to discard. The server validates your claim and reveals the winning hand.'**
  String get pickAnotherCardToDiscardTheServer;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @noChooseAnotherCard.
  ///
  /// In en, this message translates to:
  /// **'No, choose another card'**
  String get noChooseAnotherCard;

  /// No description provided for @canYouImmediatelyReturnThePickedDiscard.
  ///
  /// In en, this message translates to:
  /// **'Can you immediately return the picked discard?'**
  String get canYouImmediatelyReturnThePickedDiscard;

  /// No description provided for @drawStockOrTakeTheTopDiscard.
  ///
  /// In en, this message translates to:
  /// **'Draw stock or take the top discard to reach eleven, then discard to return to ten. You cannot immediately return the card you just took from discard. A claim can be checked with ten or eleven cards.'**
  String get drawStockOrTakeTheTopDiscard;

  /// No description provided for @drawArrangeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Draw, arrange, discard'**
  String get drawArrangeDiscard;

  /// No description provided for @yakkaFollowsKingaEveryYakkaBecomesA.
  ///
  /// In en, this message translates to:
  /// **'Yakka follows Kinga. Every Yakka becomes a wildcard for this game.'**
  String get yakkaFollowsKingaEveryYakkaBecomesA;

  /// No description provided for @ifTheIndicatorIsKingaWhichRank.
  ///
  /// In en, this message translates to:
  /// **'If the indicator is Kinga, which rank is Yarak?'**
  String get ifTheIndicatorIsKingaWhichRank;

  /// No description provided for @yarakIsTheRankImmediatelyAfterThe.
  ///
  /// In en, this message translates to:
  /// **'Yarak is the rank immediately after the indicator, wrapping Yakka to 2. Cards of that rank are wild. The indicator stays visible and Yarak does not change on recycle.'**
  String get yarakIsTheRankImmediatelyAfterThe;

  /// No description provided for @meetYourYarak.
  ///
  /// In en, this message translates to:
  /// **'Meet your Yarak'**
  String get meetYourYarak;

  /// No description provided for @pawn345IsASame.
  ///
  /// In en, this message translates to:
  /// **'Pawn 3–4–5 is a same-suit run. A whole winning hand still needs server validation.'**
  String get pawn345IsASame;

  /// No description provided for @anUnrelatedTrio.
  ///
  /// In en, this message translates to:
  /// **'An unrelated trio'**
  String get anUnrelatedTrio;

  /// No description provided for @isThisAValidTypeOfGroup.
  ///
  /// In en, this message translates to:
  /// **'Is this a valid type of group?'**
  String get isThisAValidTypeOfGroup;

  /// No description provided for @buildOneGroupOfFourAndTwo.
  ///
  /// In en, this message translates to:
  /// **'Build one group of four and two groups of three. Groups can be same-rank sets or consecutive cards of one suit. You begin with ten cards.'**
  String get buildOneGroupOfFourAndTwo;

  /// No description provided for @find433.
  ///
  /// In en, this message translates to:
  /// **'Find 4 + 3 + 3'**
  String get find433;

  /// No description provided for @yakkaIsWorth20PointsWatchExposed.
  ///
  /// In en, this message translates to:
  /// **'Yakka is worth 20 points. Watch exposed collection tops for valuable captures.'**
  String get yakkaIsWorth20PointsWatchExposed;

  /// No description provided for @howManyPointsIsYakkaWorth.
  ///
  /// In en, this message translates to:
  /// **'How many points is Yakka worth?'**
  String get howManyPointsIsYakkaWorth;

  /// No description provided for @yourFinalCollectionDecidesYourPointsYakka.
  ///
  /// In en, this message translates to:
  /// **'Your final collection decides your points. Yakka is 20; Kinga, Begi and Gola are 10; every numeric card is 5. The server orders the final standings.'**
  String get yourFinalCollectionDecidesYourPointsYakka;

  /// No description provided for @makeEveryCardCount.
  ///
  /// In en, this message translates to:
  /// **'Make every card count'**
  String get makeEveryCardCount;

  /// No description provided for @afterStockRunsOutEveryPlayedCard.
  ///
  /// In en, this message translates to:
  /// **'After stock runs out, every played card advances the turn.'**
  String get afterStockRunsOutEveryPlayedCard;

  /// No description provided for @noPlayAdvances.
  ///
  /// In en, this message translates to:
  /// **'No, play advances'**
  String get noPlayAdvances;

  /// No description provided for @stockIsEmptyDoesACaptureKeep.
  ///
  /// In en, this message translates to:
  /// **'Stock is empty. Does a capture keep your turn?'**
  String get stockIsEmptyDoesACaptureKeep;

  /// No description provided for @keepAnEyeOnTheTops.
  ///
  /// In en, this message translates to:
  /// **'Keep an eye on the tops'**
  String get keepAnEyeOnTheTops;

  /// No description provided for @matchingRanks.
  ///
  /// In en, this message translates to:
  /// **'Matching ranks'**
  String get matchingRanks;

  /// No description provided for @matchingSuits.
  ///
  /// In en, this message translates to:
  /// **'Matching suits'**
  String get matchingSuits;

  /// No description provided for @whatMakesACapture.
  ///
  /// In en, this message translates to:
  /// **'What makes a capture?'**
  String get whatMakesACapture;

  /// No description provided for @startWithFourCardsDrawFromStock.
  ///
  /// In en, this message translates to:
  /// **'Start with four cards. Draw from stock while your hand has fewer than five. Matching ranks captures room cards and can steal matching tops of collections.'**
  String get startWithFourCardsDrawFromStock;

  /// No description provided for @buildYourCollection.
  ///
  /// In en, this message translates to:
  /// **'Build your collection'**
  String get buildYourCollection;

  /// No description provided for @waitForServerConfirmationACaughtProvisional.
  ///
  /// In en, this message translates to:
  /// **'Wait for server confirmation. A caught provisional winner is restored to play.'**
  String get waitForServerConfirmationACaughtProvisional;

  /// No description provided for @itMayStillBeChallenged.
  ///
  /// In en, this message translates to:
  /// **'It may still be challenged'**
  String get itMayStillBeChallenged;

  /// No description provided for @always.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get always;

  /// No description provided for @isAnEmptyHandAnImmediateFinal.
  ///
  /// In en, this message translates to:
  /// **'Is an empty hand an immediate final victory?'**
  String get isAnEmptyHandAnImmediateFinal;

  /// No description provided for @ifTheLastPlayIsABluff.
  ///
  /// In en, this message translates to:
  /// **'If the last play is a bluff, that player takes the pile. If honest, you take it. An empty hand stays provisional until the next player accepts it or the challenge resolves.'**
  String get ifTheLastPlayIsABluff;

  /// No description provided for @callItCarefully.
  ///
  /// In en, this message translates to:
  /// **'Call it carefully'**
  String get callItCarefully;

  /// No description provided for @theRoundKeepsItsDeclaredRankUntil.
  ///
  /// In en, this message translates to:
  /// **'The round keeps its declared rank until resolved. Your hidden cards need not match your claim.'**
  String get theRoundKeepsItsDeclaredRankUntil;

  /// No description provided for @yesEveryTurn.
  ///
  /// In en, this message translates to:
  /// **'Yes, every turn'**
  String get yesEveryTurn;

  /// No description provided for @noKeepTheDeclaredRank.
  ///
  /// In en, this message translates to:
  /// **'No, keep the declared rank'**
  String get noKeepTheDeclaredRank;

  /// No description provided for @canTheNextPlayerChangeAnActive.
  ///
  /// In en, this message translates to:
  /// **'Can the next player change an active rank?'**
  String get canTheNextPlayerChangeAnActive;

  /// No description provided for @laterPlaysUse14CardsAnd.
  ///
  /// In en, this message translates to:
  /// **'Later plays use 1–4 cards and keep the declared rank. You can pass or challenge the previous play on your turn.'**
  String get laterPlaysUse14CardsAnd;

  /// No description provided for @keepTheStoryGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep the story going'**
  String get keepTheStoryGoing;

  /// No description provided for @howManyCardsOpenANewRound.
  ///
  /// In en, this message translates to:
  /// **'How many cards open a new round?'**
  String get howManyCardsOpenANewRound;

  /// No description provided for @finishYourCardsTheHYHolder.
  ///
  /// In en, this message translates to:
  /// **'Finish your cards. The h-y holder starts, but can play any 2–4 cards face-down and declare a rank.'**
  String get finishYourCardsTheHYHolder;

  /// No description provided for @eitGolaIsHighestInTheLead.
  ///
  /// In en, this message translates to:
  /// **'Eit Gola is highest in the lead suit. Pawn Kinga gives the Thullu.'**
  String get eitGolaIsHighestInTheLead;

  /// No description provided for @thePawnKingaPlayer.
  ///
  /// In en, this message translates to:
  /// **'The Pawn Kinga player'**
  String get thePawnKingaPlayer;

  /// No description provided for @theEitGolaPlayer.
  ///
  /// In en, this message translates to:
  /// **'The Eit Gola player'**
  String get theEitGolaPlayer;

  /// No description provided for @whoTakesThisOffSuitThullu.
  ///
  /// In en, this message translates to:
  /// **'Who takes this off-suit Thullu?'**
  String get whoTakesThisOffSuitThullu;

  /// No description provided for @theHighestLeadSuitPlayerPicksUp.
  ///
  /// In en, this message translates to:
  /// **'The highest lead-suit player picks up the trick when someone legally goes off-suit. A normal completed trick clears; its highest player leads next if still active.'**
  String get theHighestLeadSuitPlayerPicksUp;

  /// No description provided for @watchTheThullu.
  ///
  /// In en, this message translates to:
  /// **'Watch the Thullu'**
  String get watchTheThullu;

  /// No description provided for @youMustFollowEitWhileYouHave.
  ///
  /// In en, this message translates to:
  /// **'You must follow Eit while you have it. The server checks your move.'**
  String get youMustFollowEitWhileYouHave;

  /// No description provided for @anEitCard.
  ///
  /// In en, this message translates to:
  /// **'An Eit card'**
  String get anEitCard;

  /// No description provided for @eitLeadsAndYouHoldEitWhat.
  ///
  /// In en, this message translates to:
  /// **'Eit leads and you hold Eit. What do you play?'**
  String get eitLeadsAndYouHoldEitWhat;

  /// No description provided for @whenYouHaveTheLeadSuitYou.
  ///
  /// In en, this message translates to:
  /// **'When you have the lead suit, you must play it. After the first trick, an off-suit card can give Thullu to the highest lead-suit player.'**
  String get whenYouHaveTheLeadSuitYou;

  /// No description provided for @followTheLead.
  ///
  /// In en, this message translates to:
  /// **'Follow the lead'**
  String get followTheLead;

  /// No description provided for @hukamYakkaStartsTheFirstTrickThe.
  ///
  /// In en, this message translates to:
  /// **'Hukam Yakka starts the first trick. The server assigns the first turn.'**
  String get hukamYakkaStartsTheFirstTrickThe;

  /// No description provided for @anyKinga.
  ///
  /// In en, this message translates to:
  /// **'Any Kinga'**
  String get anyKinga;

  /// No description provided for @hukamYakka.
  ///
  /// In en, this message translates to:
  /// **'Hukam Yakka'**
  String get hukamYakka;

  /// No description provided for @whichCardOpensTheFirstTrick.
  ///
  /// In en, this message translates to:
  /// **'Which card opens the first trick?'**
  String get whichCardOpensTheFirstTrick;

  /// No description provided for @finishYourHandBeforeTheLastPlayer.
  ///
  /// In en, this message translates to:
  /// **'Finish your hand before the last player. The first turn belongs to whoever holds Hukam Yakka, h-y.'**
  String get finishYourHandBeforeTheLastPlayer;

  /// No description provided for @leaveTheCardsBehind.
  ///
  /// In en, this message translates to:
  /// **'Leave the cards behind'**
  String get leaveTheCardsBehind;

  /// No description provided for @weCouldNotConnectToTheRoom.
  ///
  /// In en, this message translates to:
  /// **'We could not connect to the room. Your room code is {value0}.'**
  String weCouldNotConnectToTheRoom(Object value0);

  /// No description provided for @letSGetYouConnected.
  ///
  /// In en, this message translates to:
  /// **'Let’s get you connected'**
  String get letSGetYouConnected;

  /// No description provided for @learnTheFourGames.
  ///
  /// In en, this message translates to:
  /// **'Learn the four games'**
  String get learnTheFourGames;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
