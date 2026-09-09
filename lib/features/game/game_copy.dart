import 'package:taash/l10n/copy.dart';

/// English game copy. Kept in one feature catalog for future ARB migration.
abstract final class GameCopy {
  static const waiting = Copy.makeYourselfAtHome;
  static const waitingDetail = Copy.theGameStartsWhenEverySeatIs;
  static const publicBots = Copy.botsMayFillEmptySeatsShortly;
  static const privateWaiting = Copy.shareTheRoomCodeWithFriendsTo;
  static const yourTurn = Copy.yourTurn;
  static const syncing = Copy.gettingYourRoomReady;
  static const reconnecting = Copy.reconnectingCheckingYourSeat;
  static const rejoining = Copy.backOnlineRestoringYourRoom;
  static const recovered = Copy.connectionRestored;
  static const unavailable = Copy.thisRoomIsNoLongerAvailable;
  static const offline = Copy.offlineYourLastRoomIsStillHere;
  static const actionFailed = Copy.thatActionCouldNotBeConfirmedCheck;
  static const mutationPending = Copy.checkingYourMove;
  static const leaveTitle = Copy.leaveThisRoom;
  static const leaveMessage = Copy.yourPlaceMayBeLostAndThe;
  static const localTimer = Copy.localTurnGuide;
  static const localTimerDetail = Copy.thisDeviceAllows60SecondsPerTurn;
  static const timerExpired = Copy.yourLocalTurnTimeEndedLeavingThe;
  static const resultTitle = 'A room well played';
  static const resultDetail = Copy.finalPlacesComeFromTheServerYour;
  static const revealTitle = Copy.theWinningHand;
  static const revealDetail = Copy.exploreTheRevealedCardsBeforeViewingThe;
  static const bhabhiOpening = Copy.openWithYakkaOfHukam;
  static const bhabhiLead = Copy.chooseOneCardToLead;
  static const bluffOpening = Copy.choose24CardsAndDeclareA;
  static const bluffFollowing = Copy.play14CardsPassOrChallenge;
  static const bluffHidden = Copy.thePileStaysFaceDownOnlyThe;
  static const daketiGuide = Copy.matchARankToCollectCardsYou;
  static const tcDraw = Copy.drawFromStockOrTakeTheTop;
  static const tcDiscard = Copy.chooseOneCardToDiscard;
  static const tcPickupRule =
      'A card just taken from discard cannot be returned this turn.';
  static const tcClaim = Copy.theServerChecksYour433;
}
