import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import for markdown support
import 'package:logger/logger.dart';
import 'package:nd_test_assistant/services/openai_service.dart';
import 'package:nd_test_assistant/services/screenshot_service.dart';
import 'package:nd_test_assistant/services/ocr_service.dart';

// Tell me how to create a flat array from an array of nested arrays

class ChatScreen extends StatefulWidget {
  final String ocrResult;

  const ChatScreen({super.key, required this.ocrResult});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final logger = Logger();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Start chat for OCR result, if available at initialization
    if (widget.ocrResult.isNotEmpty) {
      _startChat(widget.ocrResult);
    }
  }

  // Function to start the AI response
  void _startChat(String message) async {
    if (_isProcessing) return; // Prevent new requests if one is processing
    setState(() {
      _isProcessing = true;
    });

    try {
      final stream = OpenaiService().sendMessageStream(message);
      StringBuffer fullMessage = StringBuffer();

      await for (final gptResult in stream) {
        fullMessage.write(gptResult);

        // Update UI incrementally as responses are streamed
        setState(() {
          if (_messages.isEmpty || _messages.last.startsWith("You: ")) {
            _messages.add(gptResult); // New message starts
          } else {
            _messages[_messages.length - 1] +=
                gptResult; // Append to last message
          }
        });
      }

      logger.i("GPT Response: ${fullMessage.toString()}");
    } catch (error) {
      logger.e("Error: $error"); // Log any errors for debugging
    } finally {
      setState(() {
        _isProcessing = false; // Ensure new requests can proceed
      });
    }
  }

  // Send message from user input
  void _sendMessage() {
    final message = _controller.text;
    if (message.isNotEmpty && !_isProcessing) {
      setState(() {
        _messages.add("You: $message"); // Display user message in chat
      });
      _controller.clear();
      _startChat(message); // Start AI response for user-typed message
    }
  }

  // Handle OCR-based screenshot chat
  void _takeNewScreenshot() async {
    if (_isProcessing) return; // Prevent overlapping requests

    final result = await ScreenshotService().drawAndCaptureScreenshot();
    if (result != null) {
      logger.i("Screenshot saved to: $result");
      String? ocrResult = await OcrService().performOcrAndLog(result);
      if (ocrResult != null) {
        _startChat(ocrResult); // Start chat for OCR result
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: MarkdownBody(
                      data: _messages[index],
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, fontSize: 12.0),
                        code: const TextStyle(
                          backgroundColor: Colors.black12,
                          color: Colors.green,
                          fontFamily: 'monospace',
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        hintStyle:
                            TextStyle(color: Colors.white54, fontSize: 10.0),
                      ),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10.0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, size: 14.0),
                    onPressed: _isProcessing ? null : _sendMessage,
                    color: Colors.white,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, size: 14.0),
                    onPressed: _takeNewScreenshot,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
