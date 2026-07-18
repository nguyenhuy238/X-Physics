import 'package:flutter/material.dart';

Future<bool> showUnsavedChangesDialog({
  required BuildContext context,
  required String title,
  required String message,
  String stayLabel = 'Tiếp tục chỉnh sửa',
  String leaveLabel = 'Thoát',
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(stayLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(leaveLabel),
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> confirmDiscardChanges({
  required BuildContext context,
  required bool hasChanges,
  String title = 'Hủy thay đổi?',
  String message = 'Dữ liệu đã nhập chưa được lưu.',
  String stayLabel = 'Tiếp tục chỉnh sửa',
  String leaveLabel = 'Hủy thay đổi',
}) async {
  if (!hasChanges) {
    return true;
  }
  return showUnsavedChangesDialog(
    context: context,
    title: title,
    message: message,
    stayLabel: stayLabel,
    leaveLabel: leaveLabel,
  );
}
