import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nd_test_assistant/services/screenshot_service.dart';
import 'package:nd_test_assistant/services/ocr_service.dart';
import 'package:nd_test_assistant/screens/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  final logger = Logger();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await ScreenshotService().drawAndCaptureScreenshot();
            if (result != null) {
              logger.i("Screenshot saved to: $result");
              String? ocrResult = await OcrService().performOcrAndLog(result);

              if (ocrResult != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(ocrResult: ocrResult),
                  ),
                );
              }
            }
          },
          child: const Text('Capture Portion of Screen'),
        ),
      ),
    );
  }
}
