import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Like [OkDialog], but with a "share" action that copies the message to
/// the clipboard for bug reports.
class ErrorReportDialog extends HookConsumerWidget {
  const ErrorReportDialog({super.key, required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(description)),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: "$title\n\n$description"));
            ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.export.clipboard.success);
          },
          child: Text(t.common.share),
        ),
        TextButton(onPressed: () => context.pop(), child: Text(t.common.ok)),
      ],
    );
  }
}
