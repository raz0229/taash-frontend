import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/billing/billing_service.dart';
import 'package:taash/core/billing/play_billing_gateway.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/core/storage/session_store.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/features/home/discount_tab.dart';
import 'package:taash/features/shop/coins_shop_tab.dart';
import 'package:taash/features/shop/shop_screen.dart';
import 'package:taash/l10n/copy.dart';

class MemorySessionStore implements SessionStore {
  @override
  Future<AuthSession?> read() async => null;
  @override
  Future<void> write(AuthSession session) async {}
  @override
  Future<void> clear() async {}
}

const catalogJson = {
  'enabled': true,
  'currency': 'PKR',
  'packs': [
    {
      'product_id': 'coins_5k',
      'coins': 5000,
      'base_price_pkr': 450,
      'title': 'Starter',
      'tagline': 'A quick top-up',
      'badge': 'Popular',
    },
    {
      'product_id': 'coins_100k',
      'coins': 100000,
      'base_price_pkr': 9000,
      'title': 'High Roller',
      'tagline': 'The biggest bang for your buck',
      'badge': 'Great Value',
      'savings_percent': 25,
    },
  ],
};

const playerJson = {
  'id': 'uid-a',
  'display_name': 'Sana',
  'coins': 2000,
  'xp': 0,
  'selected_pfp': 0,
  'unlocked_pfps': [0, 1],
  'country': 'PK',
  'created_at': '2026-09-05T00:00:00Z',
};

const AppConfig config = AppConfig(
  backendUrl: 'https://api.example.test',
  firebaseApiKey: 'k',
  iapEnabled: true,
  iapProductIds: ['coins_5k', 'coins_100k'],
);

ApiClient fakeApi() => ApiClient(
  config: config,
  client: MockClient((request) async {
    final body = switch (request.url.path) {
      '/v1/iap/products' => catalogJson,
      _ => playerJson,
    };
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }),
)..tokenProvider = () async => 'test-token';

class FakePlayStore implements PlayBillingGateway {
  FakePlayStore({this.available = true, this.prices = const {}});
  final bool available;
  final Map<String, String> prices;

  @override
  Future<bool> isAvailable() async => available;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        notFoundIDs: const [],
        productDetails: [
          for (final e in prices.entries)
            ProductDetails(
              id: e.key,
              title: e.key,
              description: e.key,
              price: e.value,
              rawPrice: 1,
              currencyCode: 'PKR',
            ),
        ],
      );
  @override
  Future<bool> buyConsumable(
    PurchaseParam p, {
    required bool autoConsume,
  }) async => true;
  @override
  Future<void> restorePurchases() async {}
}

AuthController signedIn() {
  final auth = AuthController(api: fakeApi(), store: MemorySessionStore())
    ..status = AuthStatus.authenticated
    ..profile = PlayerProfile.fromJson(playerJson);
  auth.api.tokenProvider = () async => 'test-token';
  return auth;
}

void phone(WidgetTester tester, {double textScale = 1}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget host(Widget child, {double textScale = 1}) => MaterialApp(
  theme: T.theme,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: inner!,
  ),
  home: Scaffold(body: SafeArea(child: child)),
);

/// The rect of a whole tab, icon and label. The text sits inside the tab, so the
/// text's own rect says nothing about where the bar has scrolled to.
Rect tabRect(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
);

void main() {
  testWidgets('no shop tab label is ever truncated', (tester) async {
    phone(tester);
    final auth = signedIn();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      host(ShopScreen(auth: auth, api: auth.api)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    for (final label in ['Avatars', 'Skins', 'Thulla SFX']) {
      final finder = find.text(label);
      expect(finder, findsOneWidget, reason: label);
      final text = tester.widget<Text>(finder);
      final painter = TextPainter(
        text: TextSpan(text: text.data, style: text.style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(
          tester.element(finder),
        ),
      )..layout();
      final painted = tester.getSize(finder).width;
      expect(
        painted,
        greaterThanOrEqualTo(painter.width - 0.5),
        reason: '$label is truncated: painted $painted of ${painter.width}',
      );
    }
  });

  testWidgets('selecting a tab pins it to the edge and drops the last',
      (tester) async {
    phone(tester);
    final auth = signedIn();
    addTearDown(auth.dispose);
    await tester.pumpWidget(host(ShopScreen(auth: auth, api: auth.api)));
    await tester.pump(const Duration(milliseconds: 500));

    final bar = tester.getRect(find.byType(SingleChildScrollView).first);
    // Avatars selected: the bar sits at rest and the next tab peeks in.
    expect(tabRect(tester, 'Avatars').left, moreOrLessEquals(bar.left, epsilon: 1));
    expect(
      tabRect(tester, 'Skins').right,
      lessThanOrEqualTo(bar.right + 0.5),
    );

    await tester.tap(find.text('Skins'));
    // The reveal lands in a post-frame callback and the bar has no animation
    // here, so two frames is all it needs: one to select, one to repaint.
    await tester.pump();
    await tester.pump();

    // Skins now leads: Avatars has scrolled out of the bar, Thulla SFX is in.
    expect(tabRect(tester, 'Skins').left, moreOrLessEquals(bar.left, epsilon: 1));
    expect(tabRect(tester, 'Avatars').right, lessThanOrEqualTo(bar.left + 0.5));
    expect(
      tabRect(tester, 'Thulla SFX').right,
      lessThanOrEqualTo(bar.right + 0.5),
    );
  });

  testWidgets('the Coins Shop opens on its own tab, scrolled into view',
      (tester) async {
    phone(tester);
    final auth = signedIn();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      host(
        ShopScreen(
          auth: auth,
          api: auth.api,
          initialTab: ShopScreen.coinsShopTabIndex,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final bar = tester.getRect(find.byType(SingleChildScrollView).first);
    expect(
      tabRect(tester, 'Coins Shop').right,
      lessThanOrEqualTo(bar.right + 0.5),
    );
    expect(tabRect(tester, 'Avatars').right, lessThanOrEqualTo(bar.left + 0.5));
  });

  testWidgets('no shop tab label is truncated at 2x text', (tester) async {
    phone(tester, textScale: 2);
    final auth = signedIn();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      host(ShopScreen(auth: auth, api: auth.api), textScale: 2),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final finder = find.text('Thulla SFX');
    final text = tester.widget<Text>(finder);
    final painter = TextPainter(
      text: TextSpan(text: text.data, style: text.style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(2),
    )..layout();
    expect(
      tester.getSize(finder).width,
      greaterThanOrEqualTo(painter.width - 0.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a coin pack leads with its badge and its artwork', (tester) async {
    phone(tester);
    final auth = signedIn();
    addTearDown(auth.dispose);
    final billing = BillingService(
      config: config,
      api: auth.api,
      playerId: () => auth.playerId,
      gateway: FakePlayStore(
        prices: const {'coins_5k': 'PKR 450.00', 'coins_100k': 'PKR 9000.00'},
      ),
    );
    addTearDown(billing.dispose);

    await tester.pumpWidget(
      host(CoinsShopTab(auth: auth, billing: billing)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    // The section title is gone; the tab bar names it.
    expect(find.text('Coins Shop'), findsNothing);
    expect(find.text(Copy.coinsShopSubtitle), findsOneWidget);

    // Badges lead the tile, above the bundle name.
    final badge = tester.getRect(find.text('Great Value'));
    final name = tester.getRect(find.text('High Roller'));
    expect(badge.bottom, lessThanOrEqualTo(name.top));

    // Artwork: one bundled asset per pack, named after the product id.
    String assetOf(Image image) {
      ImageProvider provider = image.image;
      if (provider is ResizeImage) provider = provider.imageProvider;
      return provider is AssetImage ? provider.assetName : '';
    }

    final art = find.byWidgetPredicate(
      (w) => w is Image && assetOf(w).startsWith('assets/purchases/'),
    );
    expect(art, findsNWidgets(2));
    expect(assetOf(tester.widget<Image>(art.first)), 'assets/purchases/coins_5k.png');

    // The saving is a tag hung off the top-right corner, and hangs inwards.
    expect(find.text('SAVE 25%'), findsOneWidget);
    expect(find.text('SAVE 0%'), findsNothing);
    final card = tester.getRect(
      find
          .ancestor(
            of: find.text('SAVE 25%'),
            matching: find.byType(Stack),
          )
          .first,
    );
    final rotate = find
        .ancestor(of: find.text('SAVE 25%'), matching: find.byType(Transform))
        .first;
    // getRect already applies the rotation, so this is the tag's real footprint.
    final box = tester.getRect(rotate);
    final m = tester.widget<Transform>(rotate).transform.storage;
    expect(
      math.atan2(m[1], m[0]),
      moreOrLessEquals(-.11, epsilon: 0.002),
      reason: 'a price tag hangs tilted',
    );
    expect(
      box.left,
      greaterThanOrEqualTo(card.left - 0.01),
      reason: 'the saving tag must hang inwards',
    );
    expect(box.right, lessThanOrEqualTo(card.right + 0.01));
    expect(box.top, greaterThanOrEqualTo(card.top - 0.01));
    expect(
      box.height,
      lessThan(card.height / 2),
      reason: 'the tag sits on the header band, not over the price',
    );

    // The Buy button spans the tile's content width, edge to edge under the
    // header rather than hugging the label.
    final buy = find.widgetWithText(FilledButton, 'Buy').first;
    final headerRow = find
        .ancestor(of: art.first, matching: find.byType(Row))
        .first;
    expect(
      tester.getSize(buy).width,
      moreOrLessEquals(tester.getSize(headerRow).width, epsilon: 0.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the home discount badge shows its copy inside the disc',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(
      host(Align(alignment: Alignment.centerLeft, child: DiscountTab(onTap: () {}))),
    );
    await tester.pump();

    // The whole point of the badge is the wording, stacked on two lines so it
    // fits a circle: "GET" over "DISCOUNTS", in white.
    for (final line in [Copy.getDiscountsTop, Copy.getDiscountsBottom]) {
      expect(find.text(line), findsOneWidget, reason: line);
      expect(
        tester.widget<Text>(find.text(line)).style?.color,
        const Color(0xFFFFFFFF),
        reason: '$line must be white to read on the red badge',
      );
    }

    final top = tester.getRect(find.text(Copy.getDiscountsTop));
    final bottom = tester.getRect(find.text(Copy.getDiscountsBottom));
    expect(top.bottom, lessThanOrEqualTo(bottom.top), reason: 'GET is on top');

    // And it must actually be legible: unscaled, and not cut off by the edge
    // the badge hangs over.
    for (final line in [Copy.getDiscountsTop, Copy.getDiscountsBottom]) {
      final finder = find.text(line);
      final painted = tester.getSize(finder).width;
      final style = tester.widget<Text>(finder).style!;
      final natural = TextPainter(
        text: TextSpan(text: line, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(
        painted,
        greaterThanOrEqualTo(natural.width - 0.5),
        reason: '$line is scaled down to $painted of ${natural.width}: '
            'too small to read',
      );
      expect(tester.getRect(finder).left, greaterThanOrEqualTo(0),
          reason: '$line runs off the left edge');
    }
  });

  testWidgets('the home discount badge opens the Coins Shop', (tester) async {
    phone(tester);
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerLeft,
            child: DiscountTab(onTap: () => opened++),
          ),
        ),
      ),
    );
    await tester.pump();
    // A spiky disc peeking off the left edge, not a full-width row: the badge
    // must stay square-ish and be clipped by the screen edge it hangs off.
    final badge = tester.getSize(
      find.byType(DiscountTab),
    );
    expect(badge.width, moreOrLessEquals(badge.height, epsilon: 0.5));
    expect(badge.width, lessThan(140));
    await tester.tap(find.text(Copy.getDiscountsBottom));
    await tester.pump();
    expect(opened, 1);

    // The icon is not the label: a screen reader still announces the whole
    // affordance, so the badge must keep saying what it is for.
    final semantics = tester.getSemantics(
      find.bySemanticsLabel(Copy.getDiscounts),
    );
    expect(semantics.label, Copy.getDiscounts);
  });
}

