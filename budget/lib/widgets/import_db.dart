import 'dart:convert';

import 'package:budget/colors.dart';
import 'package:budget/database/binary_string_conversion.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/add_transaction_page.dart';
import 'package:budget/struct/database_global.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/account_and_backup.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/dropdown_select.dart';
import 'package:budget/widgets/global_snackbar.dart';
import 'package:budget/widgets/open_bottom_sheet.dart';
import 'package:budget/widgets/open_popup.dart';
import 'package:budget/widgets/open_snackbar.dart';
import 'package:budget/widgets/progress_bar.dart';
import 'package:budget/widgets/settings_containers.dart';
import 'package:budget/widgets/text_input.dart';
import 'package:budget/widgets/text_widgets.dart';
import 'package:drift/drift.dart' hide Column, Table;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:budget/widgets/framework/popup_framework.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io';
import 'package:budget/struct/random_constants.dart';
import 'package:universal_html/html.dart' show AnchorElement;
import 'package:path/path.dart' as p;

Future<bool> importDBFileFromDevice(BuildContext context) async {
  // For some reason, iOS does not let us select SQL files if we limit
  FilePickerResult? result = getPlatform() == PlatformOS.isIOS
      ? await FilePicker.platform.pickFiles()
      : await FilePicker.platform.pickFiles(
          allowedExtensions: ['sql', 'sqlite'],
          type: FileType.custom,
        );
  if (result == null) {
    openSnackbar(SnackbarMessage(
      title: "error-importing".tr(),
      description: "no-file-selected".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.warning_outlined
          : Icons.warning_rounded,
    ));
    return false;
  }
  if (kIsWeb) {
    Uint8List fileBytes = result.files.single.bytes!;
    await overwriteDefaultDB(fileBytes);
  } else {
    File file = File(result.files.single.path ?? "");
    Uint8List fileBytes = await file.readAsBytes();
    await overwriteDefaultDB(fileBytes);
  }
  resetLanguageToSystem(context);
  await updateSettings("databaseJustImported", true,
      pagesNeedingRefresh: [], updateGlobalState: false);
  return true;
}

Future importDB(BuildContext context, {ignoreOverwriteWarning = false}) async {
  dynamic result = ignoreOverwriteWarning == true
      ? true
      : await openPopup(
          context,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.warning_outlined
              : Icons.warning_rounded,
          title: "data-overwrite-warning".tr(),
          description: "data-overwrite-warning-description".tr(),
          onCancel: () {
            Navigator.pop(context, false);
          },
          onCancelLabel: "cancel".tr(),
          onSubmit: () {
            Navigator.pop(context, true);
          },
          onSubmitLabel: "ok".tr(),
        );
  if (result == true) {
    await openPopup(
      context,
      icon: appStateSettings["outlinedIcons"]
          ? Icons.file_open_outlined
          : Icons.file_open_rounded,
      title: "select-backup-file".tr(),
      description: "select-backup-file-description".tr(),
      onSubmit: () {
        Navigator.pop(context);
      },
      onSubmitLabel: "ok".tr(),
    );
    await openLoadingPopupTryCatch(
      () async {
        return await importDBFileFromDevice(context);
      },
      onSuccess: (result) {
        if (result != false) restartAppPopup(context);
      },
    );
  }
}

class ImportDB extends StatelessWidget {
  const ImportDB({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      onTap: () async {
        await importDB(context);
      },
      title: "import-data-file".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.download_outlined
          : Icons.download_rounded,
    );
  }
}
