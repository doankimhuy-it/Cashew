import 'dart:convert';
import 'package:budget/functions.dart';
import 'package:budget/pages/auto_transactions_page_email.dart';
import 'package:budget/struct/icon_objects.dart';
import 'package:budget/struct/keyboard_intents.dart';
import 'package:budget/widgets/fade_in.dart';
import 'package:budget/struct/language_map.dart';
import 'package:budget/struct/initialize_biometrics.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/util/on_app_resume.dart';
import 'package:budget/widgets/util/watch_for_day_change.dart';
import 'package:budget/widgets/watch_all_wallets.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/on_boarding_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/notifications_global.dart';
import 'package:budget/widgets/navigation_sidebar.dart';
import 'package:budget/widgets/global_loading_progress.dart';
import 'package:budget/struct/scroll_behavior_override.dart';
import 'package:budget/widgets/global_snackbar.dart';
import 'package:budget/struct/initialize_notifications.dart';
import 'package:budget/widgets/navigation_framework.dart';
import 'package:budget/widgets/restart_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:budget/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_preview/device_preview.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';

// Requires hot restart when changed
bool enableDevicePreview = false;
bool allowDebugFlags = true;
bool allowDangerousDebugFlags = kDebugMode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  database = await constructDb('db');
  notificationPayload = await initializeNotifications();
  entireAppLoaded = false;
  currenciesJSON = await json.decode(
      await rootBundle.loadString('assets/static/generated/currencies.json'));
  languageNamesJSON = await json
      .decode(await rootBundle.loadString('assets/static/language-names.json'));
  await initializeSettings();
  tz.initializeTimeZones();
  final String? locationName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(locationName ?? "America/New_York"));
  iconObjects.sort((a, b) => (a.mostLikelyCategoryName ?? a.icon)
      .compareTo((b.mostLikelyCategoryName ?? b.icon)));
  setHighRefreshRate();
  runApp(
    DevicePreview(
      enabled: enableDevicePreview,
      builder: (context) => EasyLocalization(
        // The custom LocaleLoader only references the LangCode
        useOnlyLangCode: false,
        assetLoader: RootBundleAssetLoaderCustomLocaleLoader(),
        supportedLocales: supportedLocales.values.toList(),
        path: 'assets/translations/generated',
        fallbackLocale: supportedLocales.values.toList().first,
        child: RestartApp(
          child: InitializeApp(key: appStateKey),
        ),
      ),
    ),
  );
}

late Map<String, dynamic> currenciesJSON;
late Map<String, dynamic> languageNamesJSON;
bool biometricsAvailable = false;
late bool entireAppLoaded;
late PackageInfo packageInfoGlobal;

GlobalKey<_InitializeAppState> appStateKey = GlobalKey();
GlobalKey<PageNavigationFrameworkState> pageNavigationFrameworkKey =
    GlobalKey();

class InitializeApp extends StatefulWidget {
  InitializeApp({Key? key}) : super(key: key);

  @override
  State<InitializeApp> createState() => _InitializeAppState();
}

class _InitializeAppState extends State<InitializeApp> {
  void refreshAppState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return App(key: ValueKey("Main App"));
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FeatureDiscovery(
    //   child:
    print("Rebuilt Material App");

    return MaterialApp(
      showPerformanceOverlay: kProfileMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale:
          enableDevicePreview ? DevicePreview.locale(context) : context.locale,
      // localeListResolutionCallback: (systemLocales, supportedLocales) {
      //   print("LOCALE:" + context.locale.toString());
      //   print("LOCALE:" + Platform.localeName);
      //   return null;
      // },
      shortcuts: shortcuts,
      actions: keyboardIntents,
      themeAnimationDuration: Duration(milliseconds: 300),
      key: ValueKey(1),
      title: 'Cashew',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          // the page route animation is set in pushRoute() - functions.dart
          TargetPlatform.android: appStateSettings["iOSNavigation"]
              ? CupertinoPageTransitionsBuilder()
              : ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
        fontFamily: appStateSettings["font"],
        fontFamilyFallback: ['Inter'],
        colorScheme: getColorScheme(Brightness.light),
        useMaterial3: true,
        applyElevationOverlayColor: false,
        typography: Typography.material2014(),
        canvasColor: appStateSettings["materialYou"]
            ? lightenPastel(
                getSettingConstants(appStateSettings)["accentColor"],
                amount: 0.91)
            : Colors.white,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: getSystemUiOverlayStyle(Brightness.light),
        ),
        splashColor: appStateSettings["materialYou"]
            ? darkenPastel(
                    lightenPastel(
                        getSettingConstants(appStateSettings)["accentColor"],
                        amount: 0.8),
                    amount: 0.2)
                .withOpacity(0.5)
            : null,
        extensions: <ThemeExtension<dynamic>>[appColorsLight],
      ),
      darkTheme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          // the page route animation is set in pushRoute() - functions.dart
          TargetPlatform.android: appStateSettings["iOSNavigation"]
              ? CupertinoPageTransitionsBuilder()
              : ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
        fontFamily: appStateSettings["font"],
        fontFamilyFallback: ['Inter'],
        colorScheme: getColorScheme(Brightness.dark),
        useMaterial3: true,
        typography: Typography.material2014(),
        canvasColor: appStateSettings["materialYou"]
            ? darkenPastel(getSettingConstants(appStateSettings)["accentColor"],
                amount: 0.92)
            : Colors.black,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: getSystemUiOverlayStyle(Brightness.dark),
        ),
        splashColor: getPlatform() == PlatformOS.isIOS
            ? Colors.transparent
            : appStateSettings["materialYou"]
                ? darkenPastel(
                        lightenPastel(
                            getSettingConstants(
                                appStateSettings)["accentColor"],
                            amount: 0.86),
                        amount: 0.1)
                    .withOpacity(0.2)
                : null,
        extensions: <ThemeExtension<dynamic>>[appColorsDark],
      ),
      scrollBehavior: ScrollBehaviorOverride(),
      themeMode: getSettingConstants(appStateSettings)["theme"],
      home: AnimatedSwitcher(
          duration: Duration(milliseconds: 1200),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final inAnimation =
                Tween<Offset>(begin: Offset(-1.0, 0.0), end: Offset(0.0, 0.0))
                    .animate(animation);
            final outAnimation =
                Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset(0.0, 0.0))
                    .animate(animation);

            if (child.key == ValueKey("Onboarding")) {
              return ClipRect(
                child: SlideTransition(
                  position: inAnimation,
                  child: child,
                ),
              );
            } else {
              return ClipRect(
                child: SlideTransition(position: outAnimation, child: child),
              );
            }
          },
          child: appStateSettings["hasOnboarded"] != true
              ? OnBoardingPage(key: ValueKey("Onboarding"))
              : PageNavigationFramework(key: pageNavigationFrameworkKey)),
      builder: (context, child) {
        if (kReleaseMode) {
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return Container(color: Colors.transparent);
          };
        }

        Widget mainWidget = OnAppResume(
          onAppResume: () async {
            await setHighRefreshRate();
          },
          child: InitializeBiometrics(
            child: InitializeNotificationService(
              child: WatchForDayChange(
                child: WatchAllWallets(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: getIsFullScreen(context)
                                ? Duration(milliseconds: 1500)
                                : Duration.zero,
                            curve: Curves.easeInOutCubicEmphasized,
                            width: getWidthNavigationSidebar(context),
                            color: Theme.of(context).canvasColor,
                          ),
                          Expanded(
                            child: Builder(builder: (context) {
                              double rightPaddingSafeArea =
                                  MediaQuery.paddingOf(context).right;
                              bool hasRightSafeArea = rightPaddingSafeArea > 0;
                              double leftPaddingSafeArea =
                                  MediaQuery.paddingOf(context).left;
                              bool hasLeftSafeArea = leftPaddingSafeArea > 0 &&
                                  getIsFullScreen(context) == false;
                              // Only enable left safe area if no navigation sidebar
                              return Stack(
                                children: [
                                  hasRightSafeArea || hasLeftSafeArea
                                      ? Container(
                                          color: Theme.of(context).canvasColor,
                                        )
                                      : SizedBox.shrink(),
                                  hasRightSafeArea || hasLeftSafeArea
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                            right: hasRightSafeArea
                                                ? rightPaddingSafeArea
                                                : 0,
                                            left: hasLeftSafeArea
                                                ? leftPaddingSafeArea
                                                : 0,
                                          ),
                                          child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.horizontal(
                                                right: hasRightSafeArea
                                                    ? Radius.circular(25)
                                                    : Radius.circular(0),
                                                left: hasLeftSafeArea
                                                    ? Radius.circular(25)
                                                    : Radius.circular(0),
                                              ),
                                              child:
                                                  child ?? SizedBox.shrink()),
                                        )
                                      : child ?? SizedBox.shrink(),
                                  GlobalSnackbar(key: snackbarKey),
                                  hasRightSafeArea
                                      ? Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            width: rightPaddingSafeArea,
                                            color:
                                                Theme.of(context).canvasColor,
                                          ),
                                        )
                                      : SizedBox.shrink(),
                                  hasLeftSafeArea
                                      ? Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: leftPaddingSafeArea,
                                            color:
                                                Theme.of(context).canvasColor,
                                          ),
                                        )
                                      : SizedBox.shrink(),
                                  // Gradient fade to right overflow, disabled for now
                                  // because many pages have full screen elements/banners etc
                                  // hasRightSafeArea
                                  //     ? Padding(
                                  //         padding: EdgeInsets.only(
                                  //             right: rightPaddingSafeArea),
                                  //         child: Align(
                                  //           alignment: Alignment.centerRight,
                                  //           child: Container(
                                  //             width: 12,
                                  //             foregroundDecoration: BoxDecoration(
                                  //               gradient: LinearGradient(
                                  //                 colors: [
                                  //                   Theme.of(context)
                                  //                       .canvasColor
                                  //                       .withOpacity(0.0),
                                  //                   Theme.of(context).canvasColor,
                                  //                 ],
                                  //                 begin: Alignment.centerLeft,
                                  //                 end: Alignment.centerRight,
                                  //                 stops: [0.1, 1],
                                  //               ),
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       )
                                  //     : SizedBox.shrink(),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                      NavigationSidebar(key: sidebarStateKey),
                      // The persistent global Widget stack (stays on navigation change)
                      GlobalLoadingIndeterminate(key: loadingIndeterminateKey),
                      GlobalLoadingProgress(key: loadingProgressKey),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        return mainWidget;
      },
    );
  }
}
