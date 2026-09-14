import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/system/media_picker/media_picker_request.dart';
import 'package:fluent_learning/system/media_picker/media_picker_result.dart';
import 'package:fluent_learning/widgets/internal_video_picker_dialog.dart';

export 'package:fluent_learning/system/media_picker/media_picker_request.dart';
export 'package:fluent_learning/system/media_picker/media_picker_result.dart';

/// Opens the single app-wide media library picker.
///
/// Returns [MediaPickerResult] on confirm, or `null` if the user cancels.
Future<MediaPickerResult?> showAppMediaPicker(
  BuildContext context,
  MediaPickerRequest request,
) {
  final library = context.read<LibraryService>();
  return showDialog<MediaPickerResult>(
    context: context,
    builder: (ctx) => InternalVideoPickerDialog(
      libraryService: library,
      request: request,
    ),
  );
}
