import 'package:google_vision/google_vision.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OcrService {
  static final logger = Logger(
    printer: PrettyPrinter(),
  );

  Future<String?> performOcrAndLog(String imagePath) async {
    try {
      // Retrieve the API key from secure storage
      final apiKey = dotenv.get('API_KEY');

      final googleVision = GoogleVision().withApiKey(
        apiKey,
        // additionalHeaders: {'com.xxx.xxx': 'X-Ios-Bundle-Identifier'},
      );

      logger.i('checking...');

      // Read the image file into a buffer
      final buffer = await File(imagePath).readAsBytes();
      final byteBuffer = buffer.buffer; // Convert Uint8List to ByteBuffer

      List<EntityAnnotation> ocrResponse = await googleVision.image
          .textDetection(JsonImage.fromBuffer(byteBuffer) // Use ByteBuffer here
              );

      // Extract text from the response
      final textAnnotations = ocrResponse.map((e) => e.description).firstWhere(
          (description) => description.isNotEmpty,
          orElse: () => '');

      logger.i('textAnnotations: \n$textAnnotations');

      logger.i('OCR performed successfully');

      return textAnnotations;
    } catch (e) {
      logger.e(e);
      return null;
    }
  }
}
