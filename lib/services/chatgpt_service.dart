import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class ChatGptService {
  static const String _apiKey =
      'sk-';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  final Dio _dio = Dio();

  Future<String> getResponse(String prompt) async {
    final response =
        await _dio.post('https://api.openai.com/v1/chat/completions',
            data: {
              'model': 'gpt-3.5-turbo',
              'messages': [
                {"role": "user", "content": prompt}
              ],
              "temperature": 1,
              "top_p": 1,
              "n": 1,
              "stream": false,
              "max_tokens": 250,
              "presence_penalty": 0,
              "frequency_penalty": 0
            },
            options: Options(headers: {'Authorization': 'Bearer $_apiKey'}));

    if (response.statusCode == 200) {
      return response.data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get response from ChatGPT API');
    }
  }

  // Stream<String> getResponseStream(String prompt) async* {
  //   final response = await http.post(
  //     Uri.parse(_apiUrl),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $_apiKey',
  //     },
  //     body: jsonEncode({
  //       'model': 'gpt-3.5-turbo',
  //       'messages': [
  //         {"role": "user", "content": prompt}
  //       ],
  //       "temperature": 1,
  //       "top_p": 1,
  //       "n": 1,
  //       "stream": true,
  //       "max_tokens": 250,
  //       "presence_penalty": 0,
  //       "frequency_penalty": 0
  //     }),
  //
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final stream = response.stream.transform(utf8.decoder);
  //     final buffer = StringBuffer();
  //     await for (var chunk in stream) {
  //       buffer.write(chunk);
  //       final String jsonString = buffer.toString();
  //       try {
  //         final jsonResponse = jsonDecode(jsonString);
  //         final String text = jsonResponse['choices'][0]['text'];
  //         yield text.trim();
  //         buffer.clear();
  //       } on FormatException {
  //         // Do nothing, wait for more data to arrive
  //       }
  //     }
  //   } else {
  //     throw Exception('Failed to get response from ChatGPT API');
  //   }
  // }

  Stream<String> getResponseStream(String prompt) async* {
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 1,
        'top_p': 1,
        'n': 1,
        'stream': true,
        'max_tokens': 250,
        'presence_penalty': 0,
        'frequency_penalty': 0,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $_apiKey'},
        responseType: ResponseType.stream,
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get response from ChatGPT API');
    }
    await for (final chunk in response.data.stream) {
      final jsonString = utf8.decode(chunk);
      final regex = RegExp(r'data: (.+)', multiLine: true);
      final match = regex.firstMatch(jsonString);
      if (match != null) {
        final jsonData = match.group(1);
        final json = jsonDecode(jsonData!);
        final choices = json['choices'];
        // 进一步处理 choices 数据
        for (final choice in choices) {
          if (choice['delta'] != null && choice['delta']['content'] != null) {
            final content = choice['delta']['content'] as String;
            print("content: $content");
            yield content;
          }
        }
      } else {
        throw Exception('Failed to extract JSON data');
      }
    }
  }
}
