import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:kiwi/models/chat_model.dart';
import 'package:kiwi/models/message.dart';

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
            await Future.delayed(Duration(milliseconds: 100));
          }
        }
      } else {
        throw Exception('Failed to extract JSON data');
      }
    }
  }

  static Future<List<Message>> sendMessage(
      {required String prompt, required String modelId}) async {
    try {
      log("prompt: $prompt , modelId: $modelId");
      var response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          'model': modelId,
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 1,
          'max_tokens': 250,
          'presence_penalty': 2,
          'frequency_penalty': 0,
        }),
      );

      Map jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      log("jsonResponse: $jsonResponse");

      if (jsonResponse['error'] != null) {
        throw Exception(jsonResponse['error']['message']);
      }
      List<Message> chatList = [];
      if (jsonResponse['choices'].length > 0) {
        chatList = List.generate(
            jsonResponse['choices'].length,
            (index) => Message(chatIndex: 1,
                text: jsonResponse['choices'][index]['message']['content'],isUserMessage: false ));
      }
      return chatList;
    } catch (e) {
      log("error $e");
      rethrow;
    }
  }
}
