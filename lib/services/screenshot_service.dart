import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class ScreenshotService {
  static final logger = Logger();
  static const MethodChannel _channel =
      MethodChannel('com.ndtechassistant.screenshot');

  Future<String?> drawAndCaptureScreenshot() async {
    try {
      final result = await _channel.invokeMethod('drawRectAndCapture');
      return result;
    } on PlatformException catch (e) {
      logger.e("Failed to capture screenshot: '${e.message}'.");
      return null;
    } catch (e) {
      logger.e("Unexpected error: $e");
      return null;
    }
  }
}
