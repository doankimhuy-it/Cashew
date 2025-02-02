import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/account_and_backup.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/more_icons.dart';
import 'package:budget/widgets/navigation_framework.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/framework/page_framework.dart';
import 'package:budget/widgets/settings_containers.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:budget/widgets/outlined_button_stacked.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => AccountsPageState();
}

class AccountsPageState extends State<AccountsPage> {
  bool currentlyExporting = false;

  void refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget profileWidget = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dynamicPastel(context, Theme.of(context).colorScheme.primary,
            amount: 0.2),
      ),
      child: Center(
        child: TextFont(
            text: googleUser?.displayName![0] ?? "",
            fontSize: 60,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.bold,
            textColor: dynamicPastel(
                context, Theme.of(context).colorScheme.primary,
                amount: 0.85, inverse: false)),
      ),
    );
    return PageFramework(
      horizontalPadding: getHorizontalPaddingConstrained(context),
      dragDownToDismiss: true,
      expandedHeight: 56,
      title: getPlatform() == PlatformOS.isIOS
          ? "backup".tr()
          : "data-backup".tr(),
      appBarBackgroundColor: getPlatform() == PlatformOS.isIOS
          ? null
          : Theme.of(context).colorScheme.secondaryContainer,
      appBarBackgroundColorStart: getPlatform() == PlatformOS.isIOS
          ? null
          : Theme.of(context).colorScheme.secondaryContainer,
      bottomPadding: false,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: googleUser == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SettingsContainerOutlined(
                        title: getPlatform() == PlatformOS.isIOS
                            ? "google-drive-backup".tr()
                            : "sign-in-with-google".tr(),
                        icon: getPlatform() == PlatformOS.isIOS
                            ? MoreIcons.google_drive
                            : MoreIcons.google,
                        isExpanded: false,
                        onTap: () async {
                          loadingIndeterminateKey.currentState
                              ?.setVisibility(true);
                          try {
                            await signInAndSync(context, next: () {});
                          } catch (e) {
                            print("Error signing in: $e");
                          }
                        },
                      )
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 35),
                      getPlatform() == PlatformOS.isIOS
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                MoreIcons.google_drive,
                                size: 50,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : ClipOval(
                              child: googleUser == null ||
                                      googleUser!.photoUrl == null
                                  ? profileWidget
                                  : FadeInImage.memoryNetwork(
                                      fadeInDuration:
                                          const Duration(milliseconds: 100),
                                      fadeOutDuration:
                                          const Duration(milliseconds: 100),
                                      placeholder: kTransparentImage,
                                      image: googleUser!.photoUrl.toString(),
                                      height: 95,
                                      width: 95,
                                      imageErrorBuilder: (BuildContext context,
                                          Object exception,
                                          StackTrace? stackTrace) {
                                        return profileWidget;
                                      },
                                    ),
                            ),
                      const SizedBox(height: 10),
                      TextFont(
                        text: getPlatform() == PlatformOS.isIOS
                            ? "google-drive-backup".tr()
                            : (googleUser?.displayName ?? "").toString(),
                        textAlign: TextAlign.center,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 2),
                      TextFont(
                        text: (appStateSettings["currentUserEmail"] ?? "")
                            .toString(),
                        textAlign: TextAlign.center,
                        fontSize: 15,
                      ),
                      const SizedBox(height: 15),
                      IntrinsicWidth(
                        child: Button(
                          label: "logout".tr(),
                          onTap: () async {
                            final result = await signOutGoogle();
                            if (result == true) {
                              if (getIsFullScreen(context) == false) {
                                Navigator.maybePop(context);
                                settingsPageStateKey.currentState
                                    ?.refreshState();
                              } else {
                                pageNavigationFrameworkKey.currentState!
                                    .changePage(0, switchNavbar: true);
                              }
                            }
                          },
                          padding: const EdgeInsets.symmetric(
                              horizontal: 17, vertical: 12),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: IgnorePointer(
                                ignoring: currentlyExporting,
                                child: AnimatedOpacity(
                                  opacity: currentlyExporting ? 0.4 : 1,
                                  duration: const Duration(milliseconds: 200),
                                  child: OutlinedButtonStacked(
                                    text: "backup".tr(),
                                    iconData: appStateSettings["outlinedIcons"]
                                        ? Icons.cloud_upload_outlined
                                        : Icons.cloud_upload_rounded,
                                    onTap: () async {
                                      setState(() {
                                        currentlyExporting = true;
                                      });
                                      await createBackup(context,
                                          deleteOldBackups: true);
                                      if (mounted) {
                                        setState(() {
                                          currentlyExporting = false;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: OutlinedButtonStacked(
                                text: "restore".tr(),
                                iconData: appStateSettings["outlinedIcons"]
                                    ? Icons.cloud_download_outlined
                                    : Icons.cloud_download_rounded,
                                onTap: () async {
                                  await chooseBackup(context);
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SyncCloudBackupButton(
                                onTap: () async {
                                  chooseBackup(context,
                                      isManaging: true, isClientSync: true);
                                },
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: BackupsCloudBackupButton(
                                onTap: () async {
                                  await chooseBackup(context, isManaging: true);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      getPlatform() == PlatformOS.isIOS
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 7),
                              child: Tappable(
                                borderRadius: 15,
                                onTap: () {
                                  openUrl(
                                      "https://cashewapp.web.app/policy.html");
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  child: TextFont(
                                    text:
                                        "google-drive-backup-description".tr(),
                                    textAlign: TextAlign.center,
                                    fontSize: 14,
                                    maxLines: 10,
                                    textColor: getColor(context, "textLight"),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(height: 75),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class SyncCloudBackupButton extends StatelessWidget {
  const SyncCloudBackupButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButtonStacked(
      text: getPlatform() == PlatformOS.isIOS
          ? "devices".tr().capitalizeFirst
          : "sync".tr(),
      iconData: getPlatform() == PlatformOS.isIOS
          ? appStateSettings["outlinedIcons"]
              ? Icons.devices_outlined
              : Icons.devices_rounded
          : appStateSettings["outlinedIcons"]
              ? Icons.cloud_sync_outlined
              : Icons.cloud_sync_rounded,
      onTap: onTap,
    );
  }
}

class BackupsCloudBackupButton extends StatelessWidget {
  const BackupsCloudBackupButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButtonStacked(
      text: "backups".tr(),
      iconData: appStateSettings["outlinedIcons"]
          ? Icons.folder_outlined
          : Icons.folder_rounded,
      onTap: onTap,
    );
  }
}
