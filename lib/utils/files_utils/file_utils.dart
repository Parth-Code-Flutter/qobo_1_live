import 'package:qobo_one_live/utils/alert_message_utils/alert_message_utils.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Common utilities for opening document/file links from project Docs & Files.
///
/// Use from both admin and employee Docs & Files screens so that:
/// - Web links (e.g. https://example.com) open in the system browser.
/// - File URLs (e.g. Google Cloud Storage) open in the default app (browser or viewer).
abstract final class FileUtils {
  FileUtils._();

  /// Opens a document or link URL in the appropriate app.
  ///
  /// - [url] The `file` field from the document (can be a web link or file URL).
  /// - Returns [true] if the URL was launched, [false] otherwise (e.g. empty URL or launch failed).
  ///
  /// Behavior:
  /// - Empty or invalid URL: shows error message, returns false.
  /// - Web links (http/https): open in external browser.
  /// - File URLs (e.g. storage URLs): open in external app (browser or system handler).
  static Future<bool> openFileOrLink(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _showError('No link or file URL available.');
      return false;
    }

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (e) {
      LoggerUtils.logException('FileUtils.openFileOrLink parse', e);
      _showError('Invalid URL.');
      return false;
    }

    if (!uri.hasScheme) {
      _showError('Invalid URL.');
      return false;
    }

    try {
      // Prefer opening in external app: browser for links, default handler for files
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          _showError('Could not open link.');
          return false;
        }
        return true;
      } else {
        _showError('Could not open link.');
        return false;
      }
    } catch (e) {
      LoggerUtils.logException('FileUtils.openFileOrLink launch', e);
      _showError('Could not open link.');
      return false;
    }
  }

  /// Opens the platform file picker and returns a list of selected file paths.
  ///
  /// - Returns a non-empty `List<String>` of paths if the user selected file(s).
  /// - Returns an empty list if the user cancels or if an error occurs.
  /// - Shows a generic error snackbar on unexpected failures.
  static Future<List<String>> pickFilePaths() async {
    try {
      LoggerUtils.logger.i('FileUtils.pickFilePaths: opening file picker');
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) {
        return <String>[];
      }
      final paths = result.files
          .map((f) => f.path)
          .whereType<String>()
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (paths.isEmpty) {
        _showError('Unable to read selected file paths.');
      }
      return paths;
    } catch (e) {
      LoggerUtils.logException('FileUtils.pickFilePaths', e);
      _showError('Could not open file picker.');
      return <String>[];
    }
  }

  /// Shows an error message to the user (snackbar).
  static void _showError(String message) {
    try {
      Get.find<AlertMessageUtils>().showErrorSnackBar(message);
    } catch (_) {
      LoggerUtils.logger.w('FileUtils: could not show error snackbar');
    }
  }
}
