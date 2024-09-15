import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenaiService {
  final String apiKey = dotenv.get('GPT_API_KEY');
  final String apiUrl = "https://api.openai.com/v1/chat/completions";

  OpenaiService();

  Stream<String> sendMessageStream(String message) async* {
    final request = http.Request('POST', Uri.parse(apiUrl));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });

    request.body = jsonEncode({
      "model": "gpt-4",
      "messages": [
        {
          "role": "system",
          "content":
              "You are a senior mobile and web app engineer specialising in react and react native code. However as a full stack javascript and typescript developer you have knowledge of a wide range of engineering techniques, platforms and frameworks. As a helpful assistant provide formatted code examples and give an explanation to how you arrived at these examples and the processes or steps taken."
        },
        {"role": "user", "content": message}
      ],
      "max_tokens": 1500, // Increased token limit
      "temperature": 0.7,
      "stream": true, // Enable streaming
    });

    // Set up the HTTP client with a longer timeout
    final httpClient = http.Client();
    final response =
        await httpClient.send(request).timeout(const Duration(minutes: 2));

    // Stream the response
    final stream =
        response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (var line in stream) {
      if (line.startsWith('data: ')) {
        final jsonData = line.substring(6);
        if (jsonData.trim() == '[DONE]') {
          break; // Stop the stream when the response is done
        }
        if (jsonData.isNotEmpty) {
          final decodedJson = jsonDecode(jsonData);
          final deltaContent = decodedJson['choices'][0]['delta']['content'];
          if (deltaContent != null) {
            yield deltaContent; // Yield only the incremental part
          }
        }
      }
    }
  }
}
